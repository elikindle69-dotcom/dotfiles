import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property var entry: null
    property bool is_selected: false

    signal activated()

    width: parent ? parent.width : 0
    height: token_spacing_xl

    color: is_selected ? services.MatugenService.primary : services.MatugenService.background

    Behavior on color {
        ColorAnimation { duration: token_motion_duration_short }
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: token_spacing_sm
        anchors.rightMargin: token_spacing_sm
        spacing: token_spacing_sm

        Text {
            width: token_spacing_lg
            text: root.entry?.icon || "help"
            font: token_typography_icon
            anchors.verticalCenter: parent.verticalCenter
            color: is_selected ? services.MatugenService.background : services.MatugenService.primary
        }

        Text {
            width: parent.width - token_spacing_lg - token_spacing_sm
            text: root.entry?.name || ""
            font: token_typography_body
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            color: is_selected ? services.MatugenService.background : services.MatugenService.primary
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
