import QtQuick 2.0
import Sailfish.Silica 1.0
import "pages"
import "components" as Components

ApplicationWindow {
    property alias toaster: toasterElement

    id: app
    initialPage: Component { CheckStatusPage { } }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: defaultAllowedOrientations

    Components.Toaster {
        id: toasterElement
    }
}
