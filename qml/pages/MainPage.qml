import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    property bool accountsLoaded: false
    property bool loading: true
    property string error
    property var accounts: []

    id: page
    allowedOrientations: Orientation.All

    BusyLabel {
        running: loading
        //% "Loading..."
        text: qsTrId("main.loading")
    }

    RemorsePopup {
        id: removeAccountRemorse
    }

    Connections {
        target: controller

        onBridgeStarted: {
            if (success) {
                pageStack.replace("CheckStatusPage.qml");
                return;
            }

            loading = false;
            //% "Starting the bridge failed, please try again."
            error = qsTrId("main.error.starting_bridge")
        }

        onAccountsFetched: {
            loading = false;
            if (!success) {
                //% "Failed to fetch a list of accounts. Please close and reopen the app."
                error = qsTrId("main.error.account_fetch");
                return;
            }

            page.accounts = accounts;
            accountsLoaded = true;
        }

        onTotpRequired: {
            loading = false;
            //% "You either forgot to include totp or it was invalid."
            error = qsTrId("main.error.totp_required");
            return;
        }

        onAccountLoginFinished: {
            if (!success) {
                loading = false;
                //% "Something went wrong when logging in. Please try again."
                error = qsTrId("main.error.login_failed");
                return;
            }

            controller.getAccounts();
        }

        onAccountRemoved: {
            if (!success) {
                loading = false;
                //% "Something went wrong when removing the account. Please try again."
                error = qsTrId("main.error.remove_failed");
                return;
            }

            controller.getAccounts();
        }
    }

    SilicaFlickable {
        visible: !loading
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column

            width: page.width
            spacing: Theme.paddingLarge

            PullDownMenu {
                MenuItem {
                    //% "Start the bridge"
                    text: qsTrId("main.start_bridge")
                    onClicked: {
                        loading = true;
                        controller.start();
                    }
                }

                MenuItem {
                    visible: accountsLoaded
                    //% "Add an account"
                    text: qsTrId("main.add_accounts")
                    onClicked: {
                        const dialog = pageStack.push("AddAccountPage.qml");
                        dialog.accepted.connect(function() {
                            controller.addAccount(dialog.username, dialog.password, dialog.totp);
                            loading = true;
                        });
                    }
                }
            }

            PageHeader {
                //% "ProtonBridge Control"
                title: qsTrId("main.title")
            }

            Label {
                visible: accountsLoaded && accounts.length === 0
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.Wrap
                //% "No accounts are currently configured, use the pull down menu to add one."
                text: qsTrId("main.no_accounts")
            }

            Label {
                visible: error !== ''
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.Wrap
                text: error
                color: Theme.errorColor
            }

            ExpandingSectionGroup {
                width: parent.width
                currentIndex: -1
                Repeater {
                    model: accounts
                    delegate: ExpandingSection {
                        width: parent.width
                        title: modelData.username

                        content.sourceComponent: Column {
                            width: parent.width
                            spacing: Theme.paddingMedium

                            Label {
                                x: Theme.horizontalPageMargin
                                width: parent.width - Theme.horizontalPageMargin * 2
                                //% "Account credentials"
                                text: qsTrId("main.account.credentials")
                                color: Theme.highlightColor
                                font.pixelSize: Theme.fontSizeMedium
                                horizontalAlignment: Text.AlignLeft
                            }

                            Column {
                                x: Theme.horizontalPageMargin
                                width: parent.width - Theme.horizontalPageMargin * 2

                                Label {
                                    width: parent.width
                                    //% "Username"
                                    text: qsTrId("main.account.username")
                                    color: Theme.secondaryColor
                                    font.pixelSize: Theme.fontSizeExtraSmall
                                    horizontalAlignment: Text.AlignLeft
                                }

                                Row {
                                    width: parent.width

                                    Label {
                                        width: parent.width - copyUsernameButton.width
                                        height: copyUsernameButton.height
                                        text: modelData.username
                                        verticalAlignment: Text.AlignVCenter
                                        horizontalAlignment: Text.AlignLeft
                                    }

                                    IconButton {
                                        id: copyUsernameButton
                                        icon.source: "image://theme/icon-m-clipboard"
                                        onClicked: {
                                            Clipboard.text = modelData.username;
                                            //% "Copied to clipboard"
                                            app.toaster.show(qsTrId("main.account.copied"));
                                        }
                                    }
                                }
                            }

                            Column {
                                x: Theme.horizontalPageMargin
                                width: parent.width - Theme.horizontalPageMargin * 2

                                Label {
                                    width: parent.width
                                    //% "Bridge password"
                                    text: qsTrId("main.account.password")
                                    color: Theme.secondaryColor
                                    font.pixelSize: Theme.fontSizeExtraSmall
                                    horizontalAlignment: Text.AlignLeft
                                }

                                Row {
                                    width: parent.width

                                    Label {
                                        width: parent.width - copyPasswordButton.width
                                        height: copyPasswordButton.height
                                        text: modelData.password
                                        fontSizeMode: Text.HorizontalFit
                                        minimumPixelSize: Theme.fontSizeTiny
                                        verticalAlignment: Text.AlignVCenter
                                        horizontalAlignment: Text.AlignLeft
                                    }

                                    IconButton {
                                        id: copyPasswordButton
                                        icon.source: "image://theme/icon-m-clipboard"
                                        onClicked: {
                                            Clipboard.text = modelData.password;
                                            //% "Copied to clipboard"
                                            app.toaster.show(qsTrId("main.account.copied"));
                                        }
                                    }
                                }
                            }

                            Label {
                                x: Theme.horizontalPageMargin
                                width: parent.width - Theme.horizontalPageMargin * 2
                                //% "Connection ports"
                                text: qsTrId("main.account.connection_ports")
                                color: Theme.highlightColor
                                font.pixelSize: Theme.fontSizeMedium
                                horizontalAlignment: Text.AlignLeft
                            }

                            Row {
                                x: Theme.horizontalPageMargin
                                width: parent.width - Theme.horizontalPageMargin * 2
                                spacing: Theme.paddingLarge

                                Column {
                                    width: (parent.width - parent.spacing) / 2

                                    Label {
                                        width: parent.width
                                        //% "IMAP port"
                                        text: qsTrId("main.account.imap_port")
                                        color: Theme.secondaryColor
                                        font.pixelSize: Theme.fontSizeExtraSmall
                                        horizontalAlignment: Text.AlignLeft
                                    }

                                    Row {
                                        width: parent.width

                                        Label {
                                            width: parent.width - copyImapPortButton.width
                                            height: copyImapPortButton.height
                                            text: modelData.imapPort
                                            verticalAlignment: Text.AlignVCenter
                                            horizontalAlignment: Text.AlignLeft
                                        }

                                        IconButton {
                                            id: copyImapPortButton
                                            icon.source: "image://theme/icon-m-clipboard"
                                            onClicked: {
                                                Clipboard.text = modelData.imapPort.toString();
                                                //% "Copied to clipboard"
                                                app.toaster.show(qsTrId("main.account.copied"));
                                            }
                                        }
                                    }
                                }

                                Column {
                                    width: (parent.width - parent.spacing) / 2

                                    Label {
                                        width: parent.width
                                        //% "SMTP port"
                                        text: qsTrId("main.account.smtp_port")
                                        color: Theme.secondaryColor
                                        font.pixelSize: Theme.fontSizeExtraSmall
                                        horizontalAlignment: Text.AlignLeft
                                    }

                                    Row {
                                        width: parent.width

                                        Label {
                                            width: parent.width - copySmtpPortButton.width
                                            height: copySmtpPortButton.height
                                            text: modelData.smtpPort
                                            verticalAlignment: Text.AlignVCenter
                                            horizontalAlignment: Text.AlignLeft
                                        }

                                        IconButton {
                                            id: copySmtpPortButton
                                            icon.source: "image://theme/icon-m-clipboard"
                                            onClicked: {
                                                Clipboard.text = modelData.smtpPort.toString();
                                                //% "Copied to clipboard"
                                                app.toaster.show(qsTrId("main.account.copied"));
                                            }
                                        }
                                    }
                                }
                            }

                            Label {
                                x: Theme.horizontalPageMargin
                                width: parent.width - Theme.horizontalPageMargin * 2
                                wrapMode: Text.Wrap
                                horizontalAlignment: Text.AlignLeft
                                color: Theme.secondaryColor
                                font.pixelSize: Theme.fontSizeSmall
                                //% "Use STARTTLS for both IMAP and SMTP connections."
                                text: qsTrId("main.account.starttls_info")
                            }

                            Button {
                                x: Theme.horizontalPageMargin
                                width: parent.width - Theme.horizontalPageMargin * 2
                                //% "Remove account"
                                text: qsTrId("main.account.remove")
                                onClicked: {
                                    var username = modelData.username;

                                    removeAccountRemorse.execute(
                                        //% "Remove account"
                                        qsTrId("main.account.remove"),
                                        function() {
                                            controller.removeAccount(username);
                                            loading = true;
                                        },
                                        5000
                                    );
                                }
                            }

                            Item {
                                width: 1
                                height: Theme.paddingLarge
                            }
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        controller.getAccounts();
    }
}
