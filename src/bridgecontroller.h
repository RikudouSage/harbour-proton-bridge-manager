#ifndef BRIDGECONTROLLER_H
#define BRIDGECONTROLLER_H

#include <QObject>
#include <QDBusInterface>
#include <QList>
#include <QVariantMap>
#include <QVariantList>

class BridgeController : public QObject
{
    Q_OBJECT
public:
    struct Account {
        QString username;
        QString password;
        quint16 imapPort;
        quint16 smtpPort;

        QVariantMap toVariantMap() const
        {
            return {
                { "username", username },
                { "password", password },
                { "imapPort", imapPort },
                { "smtpPort", smtpPort }
            };
        }
    };

    enum BridgeStatus {
        NotFound,
        Unknown,
        Started,
        Stopped,
    };
    enum AddAccountStatus {
        Error,
        Success,
        TotpRequired,
    };

    Q_ENUM(BridgeStatus)

public:
    explicit BridgeController(QObject *parent = nullptr);

    Q_INVOKABLE void getStatus();
    Q_INVOKABLE void stop();
    Q_INVOKABLE void start();

    Q_INVOKABLE void getAccounts();
    Q_INVOKABLE void addAccount(const QString &username, const QString &password, const QString &totp);
    Q_INVOKABLE void removeAccount(const QString &username);

signals:
    void bridgeStatusReported(BridgeStatus status);
    void bridgeStopped(bool success);
    void bridgeStarted(bool success);

    void accountsFetched(bool success);
    void accountsFetched(bool success, const QVariantList &accounts);
    void totpRequired();
    void accountLoginFinished(bool success);
    void accountRemoved(bool success);

private:
    BridgeStatus getStatusSync();
    QList<Account> getAccountsSync(bool &success);
    AddAccountStatus addAccountSync(const QString &username, const QString &password, const QString &totp);
    bool removeAccountSync(const QString &username);

    QList<Account> parseAccounts(const QString &output);
    QString sanitizeBridgeOutput(const QString &output);

private:
    QDBusInterface manager = QDBusInterface(
        "org.freedesktop.systemd1",
        "/org/freedesktop/systemd1",
        "org.freedesktop.systemd1.Manager",
        QDBusConnection::sessionBus()
    );
};

Q_DECLARE_METATYPE(BridgeController::BridgeStatus)

#endif // BRIDGECONTROLLER_H
