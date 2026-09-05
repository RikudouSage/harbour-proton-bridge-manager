#ifdef QT_QML_DEBUG
#include <QtQuick>
#endif

#include <QQuickView>
#include <QScopedPointer>
#include <QGuiApplication>
#include <QtQml>
#include <QQmlEngine>
#include <QTranslator>

#include <sailfishapp.h>

constexpr auto TRANSLATION_INSTALL_DIR = "/usr/share/harbour-proton-bridge-manager/translations";

#include "bridgecontroller.h"

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    QScopedPointer<QQuickView> v(SailfishApp::createView());

    QTranslator *defaultLang = new QTranslator(app.data());
    if (!defaultLang->load("harbour-proton-bridge-manager-en", TRANSLATION_INSTALL_DIR)) {
        qWarning() << "Could not load English translation file!";
    }
    QCoreApplication::installTranslator(defaultLang);

    QTranslator *translator = new QTranslator(app.data());
    if (!translator->load(QLocale(QLocale::system().name()), "harbour-proton-bridge-manager", "-", TRANSLATION_INSTALL_DIR)) {
        qWarning() << "Could not load translations for" << QLocale::system().name();
    }
    QCoreApplication::installTranslator(translator);

#ifdef QT_DEBUG
    v->rootContext()->setContextProperty("isDebug", true);
#else
    v->rootContext()->setContextProperty("isDebug", false);
#endif

    v->rootContext()->setContextProperty("controller", new BridgeController(app.data()));
    qmlRegisterUncreatableType<BridgeController>("cz.chrastecky", 1, 0, "BridgeController", "Constructing is disallowed");

    v->setSource(SailfishApp::pathToMainQml());
    v->show();

    return app->exec();
}
