TARGET = harbour-proton-bridge-manager

CONFIG += sailfishapp c++20
QT += dbus concurrent

SOURCES += src/harbour-proton-bridge-manager.cpp \
    src/bridgecontroller.cpp

expect.path = /usr/share/harbour-proton-bridge-manager/expect
expect.files = $$PWD/expect/*.exp
INSTALLS += expect

DISTFILES += qml/harbour-proton-bridge-manager.qml \
    qml/components/Toaster.qml \
    qml/cover/CoverPage.qml \
    qml/pages/AddAccountPage.qml \
    qml/pages/CheckStatusPage.qml \     \
    qml/pages/MainPage.qml \
    qml/scripts/helpers.js \
    rpm/harbour-proton-bridge-manager.changes.in \
    rpm/harbour-proton-bridge-manager.changes.run.in \
    rpm/harbour-proton-bridge-manager.spec \
    translations/*.ts \
    harbour-proton-bridge-manager.desktop \
    expect/*.exp

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

# to disable building translations every time, comment out the
# following CONFIG line
CONFIG += sailfishapp_i18n sailfishapp_i18n_idbased

# German translation is enabled as an example. If you aren't
# planning to localize your app, remember to comment out the
# following TRANSLATIONS line. And also do not forget to
# modify the localized app name in the the .desktop file.
TRANSLATIONS += translations/harbour-proton-bridge-manager-en.ts \
                translations/harbour-proton-bridge-manager-cs.ts

HEADERS += \
    src/bridgecontroller.h
