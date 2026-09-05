import QtQuick 2.0
import Sailfish.Silica 1.0

import cz.chrastecky 1.0

import "../scripts/helpers.js" as Helpers

Page {
    property var queue: []
    property var safeCaller: Helpers.safeCallerFactory(queue, page)
    property bool loading: currentStatus === -1
    property int currentStatus: -1
    property string error

    id: page
    allowedOrientations: Orientation.All

    Connections {
        target: controller

        onBridgeStatusReported: {
            currentStatus = status;

            if (status === BridgeController.Stopped || status === BridgeController.NotFound) {
                safeCaller(function() {
                    pageStack.replace("MainPage.qml");
                });
            }
        }

        onBridgeStopped: {
            if (!success) {
                //% "Stopping the bridge failed, please try again later."
                error = qsTrId("check.error.stopping")
            } else {
                error = '';
            }
        }
    }

    Connections {
        target: pageStack

        onBusyChanged: {
            if (pageStack.busy) {
                return;
            }

            var job;
            while (job = queue.pop()) {
                job();
            }
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            visible: currentStatus === BridgeController.Started

            MenuItem {
                //% "Stop the bridge"
                text: qsTrId("check.pull_down.stop_bridge")
                onClicked: {
                    currentStatus = -1
                    controller.stop();
                }
            }
        }

        Column {
            id: column

            width: page.width
            spacing: Theme.paddingLarge

            PageHeader {
                //% "Checking bridge status"
                title: qsTrId("check.title")
            }

            BusyLabel {
                running: loading
                visible: loading
                //% "The current bridge status is being loaded."
                text: qsTrId("check.loading_status");
            }

            Label {
                visible: currentStatus === BridgeController.Unknown && !error
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.Wrap
                //% "The bridge did not report any known status, cannot continue."
                text: qsTrId("check.bridge_unknown_status")
                color: Theme.errorColor
            }

            Label {
                visible: error !== ''
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.Wrap
                text: error
                color: Theme.errorColor
            }

            Label {
                visible: currentStatus === BridgeController.Started && !error
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.Wrap
                //% "The bridge is currently started, please stop the bridge using the pull down menu before continuing."
                text: qsTrId("check.bridge_is_started")
            }
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: error === ''

        onTriggered: {
            controller.getStatus();
        }
    }
}
