import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    implicitHeight: token_spacing_md
    implicitWidth: rootrect.width

    Rectangle {
        id: rootrect
        height: root.height
        width: row.implicitWidth + token_spacing_md
        radius: token_radius_full
        color: services.MatugenService.inverse_primary

        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: token_spacing_sm

            Repeater {
                model: Hyprland.workspaces

                delegate: Rectangle {
                    required property var modelData

                    visible: !modelData.name.startsWith("special:")
                    width: token_spacing_md
                    height: token_spacing_md
                    radius: token_radius_full

                    property bool is_active: modelData.focused || modelData.active
                    property bool is_hovered: workspace_mouse_area.containsMouse

                    scale: is_active ? 1.15 : (is_hovered ? 1.1 : 1.0)

                    Behavior on scale {
                        NumberAnimation { duration: token_motion_duration_short; easing.type: Easing.Bezier; easing.bezierCurve: token_motion_curve_express }
                    }

                    Behavior on color {
                        ColorAnimation { duration: token_motion_duration_short }
                    }

                    color: is_active
                        ? services.MatugenService.primary
                        : services.MatugenService.secondary_container

                    MouseArea {
                        id: workspace_mouse_area
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: modelData.activate()
                    }

                    Text {
                        anchors.centerIn: parent
                        text: modelData.id
                        font: token_typography_body
                        color: is_active
                            ? services.MatugenService.on_primary
                            : services.MatugenService.on_secondary_container
                    }
                }
            }
        }
    }
}
