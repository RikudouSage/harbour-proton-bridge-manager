import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    property string username
    property string password
    property string totp

    id: page
    allowedOrientations: Orientation.All
    canAccept: username !== '' && password !== ''

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height
    }

    Column {
        id: column

        width: page.width
        spacing: Theme.paddingLarge

        DialogHeader {
            //% "Create account"
            acceptText: qsTrId("add.accept_text")
            //% "Cancel"
            cancelText: qsTrId("add.cancel_text")
        }

        TextField {
            //% "Username"
            label: qsTrId("add.username.label")
            onTextChanged: username = text
            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhPreferLowercase
        }

        TextField {
            //% "Password"
            label: qsTrId("add.password.label")
            onTextChanged: password = text
            inputMethodHints: Qt.ImhHiddenText | Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
        }

        TextField {
            //% "TOTP code"
            label: qsTrId("add.totp.label")
            //% "Only provide the code if you have an authenticator configured."
            description: qsTrId("add.totp.description")
            onTextChanged: totp = text
            inputMethodHints: Qt.ImhDigitsOnly
        }
    }
}
