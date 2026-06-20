import QtQuick
import QtQuick.Controls

ProgressBar {
    id: root

    property color track_color: services.MatugenService.background
    property color fill_color: services.MatugenService.primary

    from: 0.0
    to: 1.0

    background: Rectangle {
        implicitWidth: root.implicitWidth
        implicitHeight: root.implicitHeight
        color: root.track_color
        radius: token_radius_full
    }

    contentItem: Item {
        implicitWidth: root.implicitWidth
        implicitHeight: root.implicitHeight

        Rectangle {
            width: root.visualPosition * parent.width
            height: parent.height
            color: root.fill_color
            radius: height / 2
        }
    }
}
