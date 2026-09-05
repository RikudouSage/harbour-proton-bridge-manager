#include "bridgecontroller.h"

#include <QDBusReply>
#include <QDBusObjectPath>
#include <QtConcurrent>
#include <QProcess>
#include <QDebug>

namespace {
    constexpr auto unitName = "proton-bridge.service";
    const auto scriptsPath = QStringLiteral("/usr/share/harbour-proton-bridge-manager/expect");
}

BridgeController::BridgeController(QObject *parent) : QObject(parent)
{
    qRegisterMetaType<BridgeStatus>("BridgeStatus");
}

void BridgeController::getStatus()
{
    QtConcurrent::run([=] {
        emit bridgeStatusReported(getStatusSync());
    });
}

void BridgeController::stop()
{
    QtConcurrent::run([=] {
        QDBusReply<QDBusObjectPath> reply = manager.call("StopUnit", unitName, "replace");
        emit bridgeStopped(reply.isValid());
    });
}

void BridgeController::start()
{
    QtConcurrent::run([=] {
        QDBusReply<QDBusObjectPath> reply = manager.call("StartUnit", unitName, "replace");
        emit bridgeStarted(reply.isValid());
    });
}

void BridgeController::getAccounts()
{
    QtConcurrent::run([=] {
        bool success = false;
        const auto accounts = getAccountsSync(success);

        if (!success) {
            emit accountsFetched(false);
            return;
        }

        QVariantList result;
        result.reserve(accounts.size());

        for (const auto &account : accounts) {
            result.append(account.toVariantMap());
        }

        emit accountsFetched(true, result);
    });
}

void BridgeController::addAccount(const QString &username, const QString &password, const QString &totp)
{
    QtConcurrent::run([=] {
        const auto result = addAccountSync(username, password, totp);
        switch (result) {
        case AddAccountStatus::Error:
            emit accountLoginFinished(false);
            break;
        case AddAccountStatus::Success:
            emit accountLoginFinished(true);
            break;
        case AddAccountStatus::TotpRequired:
            emit totpRequired();
            break;
        }
    });
}

void BridgeController::removeAccount(const QString &username)
{
    QtConcurrent::run([=] {
        emit accountRemoved(removeAccountSync(username));
    });
}

BridgeController::BridgeStatus BridgeController::getStatusSync()
{
    QDBusReply<QDBusObjectPath> unitReply = manager.call("GetUnit", unitName);

    if (!unitReply.isValid()) {
        const auto error = unitReply.error();

        if (error.name() == "org.freedesktop.systemd1.NoSuchUnit") {
            return NotFound;
        }

        return Unknown;
    }

    QDBusInterface properties(
        "org.freedesktop.systemd1",
        unitReply.value().path(),
        "org.freedesktop.DBus.Properties",
        QDBusConnection::sessionBus()
    );

    QDBusReply<QVariant> stateReply = properties.call(
        QStringLiteral("Get"),
        QStringLiteral("org.freedesktop.systemd1.Unit"),
        QStringLiteral("ActiveState")
    );

    if (!stateReply.isValid()) {
        return Unknown;
    }

    const auto state = stateReply.value().toString();

    if (state == "active") {
        return Started;
    }

    if (state == "inactive" || state == "failed") {
        return Stopped;
    }

    return Unknown;
}

QList<BridgeController::Account> BridgeController::getAccountsSync(bool &success)
{
    QProcess process;
    process.start("expect", QStringList{scriptsPath + "/get_accounts.exp"});

    if (!process.waitForStarted()) {
        success = false;
        qWarning() << "Failed to start get_accounts.exp";
        return {};
    }

    if (!process.waitForFinished(10000)) {
        process.kill();
        process.waitForFinished();
        qWarning() << "get_accounts.exp timed out";
        success = false;
        return {};
    }

    const auto stdoutData = process.readAllStandardOutput();
    const auto stderrData = process.readAllStandardError();

    if (process.exitStatus() != QProcess::NormalExit || process.exitCode() != 0) {
        qWarning() << "get_accounts.exp failed:" << QString::fromUtf8(stderrData);
        success = false;
        return {};
    }

    const auto accountsOutput = QString::fromUtf8(stdoutData);

    success = true;
    return parseAccounts(sanitizeBridgeOutput(accountsOutput));
}

BridgeController::AddAccountStatus BridgeController::addAccountSync(const QString &username, const QString &password, const QString &totp)
{
    QProcess process;
    process.start("expect", QStringList{scriptsPath + "/add_account.exp"});

    if (!process.waitForStarted()) {
        qWarning() << "Failed to start add_account.exp";
        return AddAccountStatus::Error;
    }


    QByteArray input;
    input += username.toUtf8();
    input += '\n';

    input += password.toUtf8();
    input += '\n';

    input += totp.toUtf8(); // may be empty
    input += '\n';

    process.write(input);
    process.closeWriteChannel();

    if (!process.waitForFinished(20000)) {
        process.kill();
        process.waitForFinished();

        qWarning() << "add_account.exp timed out";
        return AddAccountStatus::Error;
    }

    const auto out = process.readAllStandardOutput();
    const auto err = process.readAllStandardError();

    if (process.exitStatus() != QProcess::NormalExit) {
        qWarning() << "add_account.exp crashed: " << out << "\n\n" << err;
        return AddAccountStatus::Error;
    }

#ifdef QT_DEBUG
    qDebug() << "STDOUT: " << out;
    qDebug() << "STDERR: " << err;
#endif

    switch (process.exitCode()) {
    case 0:
        return AddAccountStatus::Success;
    case 3:
        return AddAccountStatus::TotpRequired;
    default:
        return AddAccountStatus::Error;
    }
}

bool BridgeController::removeAccountSync(const QString &username)
{
    QProcess process;
    process.start("expect", QStringList{scriptsPath + "/delete_account.exp", username});

    if (!process.waitForStarted()) {
        qWarning() << "Failed to start delete_account.exp";
        return false;
    }

    if (!process.waitForFinished(20000)) {
        process.kill();
        process.waitForFinished();

        qWarning() << "delete_account.exp timed out";
        return false;
    }

    if (process.exitStatus() != QProcess::NormalExit || process.exitCode() != 0) {
        qWarning() << "Abnormal exit or non zero exit code.";
        return false;
    }

    return true;
}

QList<BridgeController::Account> BridgeController::parseAccounts(const QString &output)
{
#ifdef QT_DEBUG
    qDebug() << output;
#endif

    if (output.contains("No active accounts")) {
        return {};
    }

    QList<Account> accounts;

    const QRegularExpression accountRegex(
        R"(Configuration for ([^\r\n]+)\s+IMAP Settings\s+Address:\s+[^\r\n]+\s+IMAP port:\s+(\d+)\s+Username:\s+([^\r\n]+)\s+Password:\s+([^\r\n]+)\s+Security:\s+[^\r\n]+\s+SMTP Settings\s+Address:\s+[^\r\n]+\s+SMTP port:\s+(\d+)\s+Username:\s+([^\r\n]+)\s+Password:\s+([^\r\n]+))"
    );
    auto matchIterator = accountRegex.globalMatch(output);

    while (matchIterator.hasNext()) {
        const QRegularExpressionMatch match = matchIterator.next();

        bool imapOk = false;
        bool smtpOk = false;

        const uint imapPort = match.captured(2).toUInt(&imapOk);
        const uint smtpPort = match.captured(5).toUInt(&smtpOk);

        if (!imapOk || !smtpOk ||
            imapPort > std::numeric_limits<quint16>::max() ||
            smtpPort > std::numeric_limits<quint16>::max()) {
            continue;
        }

        Account account;
        account.username = match.captured(1).trimmed();

        // IMAP and SMTP Bridge passwords should normally be identical.
        account.password = match.captured(4).trimmed();

        account.imapPort = static_cast<quint16>(imapPort);
        account.smtpPort = static_cast<quint16>(smtpPort);

        accounts.append(account);
    }

    return accounts;
}

QString BridgeController::sanitizeBridgeOutput(const QString &output)
{
    QString text = output;
    static const QRegularExpression ansiRegex("\x1B\\[[0-?]*[ -/]*[@-~]");

    text.remove(ansiRegex);
    text.remove(QChar('\b'));
    text.replace(QStringLiteral("\r\n"), QStringLiteral("\n"));
    text.remove(QChar('\r'));

    return text;
}
