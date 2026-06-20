import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property string icon: ""
    property bool toggled: false
    property color active_color: services.MatugenService.primary
    property color inactive_color: services.MatugenService.surface
    property color icon_active_color: services.MatugenService.on_primary
    property color icon_inactive_color: services.MatugenService.on_surface

    signal clicked()

    color: toggled ? active_color : inactive_color
    height: token_spacing_xl + token_spacing_sm
    radius: token_radius_md

    Behavior on color {
        ColorAnimation { duration: token_motion_duration_short }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: token_spacing_sm
        spacing: token_spacing_sm

        IconText {
            icon_text: root.icon
            icon_color: root.toggled ? root.icon_active_color : root.icon_inactive_color
            large: true
        }

        Text {
            Layout.fillWidth: true
            text: root.toggled ? "On" : "Off"
            font: token_typography_body
            color: root.toggled ? root.icon_active_color : root.icon_inactive_color
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true

        onEntered: root.scale = 0.97
        onExited: root.scale = 1.0
        onClicked: root.clicked()

        Behavior on scale {
            NumberAnimation { duration: token_motion_duration_short; easing.type: Easing.Bezier; easing.bezierCurve: token_motion_curve_emphasis }
        }
    }
}
