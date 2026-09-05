import QtQuick 2.0
import Sailfish.Silica 1.0

CoverBackground {
    id: cover

    Column {
        anchors {
            horizontalCenter: parent.horizontalCenter
            verticalCenter: parent.verticalCenter
            verticalCenterOffset: -Theme.paddingLarge
        }
        width: parent.width
        spacing: Theme.paddingLarge

        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(cover.width * 0.48, cover.height * 0.32)
            height: width
            source: "/usr/share/icons/hicolor/172x172/apps/harbour-proton-bridge-manager.png"
            fillMode: Image.PreserveAspectFit
            smooth: true
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Theme.itemSizeLarge
            height: Math.max(1, Theme.paddingSmall / 4)
            radius: height / 2
            color: Theme.highlightColor
            opacity: 0.7
        }

        Label {
            width: parent.width - Theme.paddingLarge * 2
            anchors.horizontalCenter: parent.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            maximumLineCount: 2
            color: Theme.primaryColor
            font.pixelSize: Theme.fontSizeLarge
            font.weight: Font.DemiBold
            //% "ProtonBridge Control"
            text: qsTrId("main.title")
        }
    }
}
