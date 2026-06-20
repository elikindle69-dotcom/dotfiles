import QtQuick
import QtQuick.Layouts
import "../../../Components" as Components

Rectangle {
    id: root

    property string label: ""
    property string icon: ""
    property bool destructive: false
    property bool selected: false
    property real button_height: token_spacing_xl * 6

    signal clicked()

    width: token_spacing_xl * 6
    height: button_height
    radius: token_radius_lg
    color: {
        if (selected) return destructive ? services.MatugenService.error : services.MatugenService.primary
        return destructive ? services.MatugenService.error_container : services.MatugenService.surface_container
    }

    border.width: selected ? 2 : 0
    border.color: destructive ? services.MatugenService.error : services.MatugenService.primary

    Behavior on color {
        ColorAnimation { duration: token_motion_duration_short }
    }

    Behavior on scale {
        NumberAnimation {
            duration: token_motion_duration_short
            easing.type: Easing.Bezier
            easing.bezierCurve: token_motion_curve_emphasis
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: token_spacing_sm

        Components.IconText {
            icon_text: root.icon
            icon_color: root.selected
                ? (root.destructive ? services.MatugenService.on_error : services.MatugenService.on_primary)
                : (root.destructive ? services.MatugenService.on_error_container : services.MatugenService.on_surface)
            large: true
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            text: root.label
            font: token_typography_body
            color: root.selected
                ? (root.destructive ? services.MatugenService.on_error : services.MatugenService.on_primary)
                : (root.destructive ? services.MatugenService.on_error_container : services.MatugenService.on_surface)
            Layout.alignment: Qt.AlignHCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true

        onEntered: root.scale = 0.95
        onExited: root.scale = 1.0
        onClicked: root.clicked()
    }
}
