import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    function show(text, timeout) {
        textLabel.text = text;
        hideTimer.interval = timeout || 3000;
        hideTimer.restart();
        opacity = 1;
    }

    opacity: 0
    z: 100

    Behavior on opacity {
        NumberAnimation { duration: 300 }
    }

    Timer {
        id: hideTimer
        repeat: false
        onTriggered: parent.opacity = 0
    }

    Rectangle {
        width: textLabel.width + Theme.horizontalPageMargin * 2
        height: textLabel.height + Theme.paddingSmall * 2
        x: Screen.width / 2 - width / 2
        y: Screen.height - Theme.itemSizeMedium
        color: "black"
        opacity: 0.9
        radius: Theme.paddingLarge

        Label {
            id: textLabel
            anchors.centerIn: parent
            color: Theme.lightPrimaryColor
        }
    }
}
