import QtQuick
import QtQuick.Layouts
import "../../../Components" as Components

Rectangle {
    id: root

    property string label: ""
    property string icon: ""
    property bool destructive: false

    signal clicked()

    Layout.fillWidth: true
    height: token_spacing_xl
    radius: token_radius_md
    color: destructive ? services.MatugenService.error_container : services.MatugenService.secondary_container

    Behavior on color {
        ColorAnimation { duration: token_motion_duration_short }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: token_spacing_sm
        spacing: token_spacing_sm

        Components.IconText {
            icon_text: root.icon
            icon_color: destructive ? services.MatugenService.on_error_container : services.MatugenService.on_secondary_container
            visible: root.icon !== ""
        }

        Text {
            Layout.fillWidth: true
            text: root.label
            font: token_typography_body
            color: destructive ? services.MatugenService.on_error_container : services.MatugenService.on_secondary_container
            horizontalAlignment: Text.AlignHCenter
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
