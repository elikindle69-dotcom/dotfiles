import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "./LocalComponents" as LocalComponents

PanelWindow {
    id: power_menu_root

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    focusable: true
    visible: false

    property int selected_index: 0
    property int last_row_index: 0

    onVisibleChanged: {
        if (visible) {
            selected_index = 0
            last_row_index = 0
            forceActiveFocus()
        }
    }

    IpcHandler {
        target: "powermenu"

        function visibility(vis: bool) {
            power_menu_root.visible = vis
        }

        function toggle() {
            power_menu_root.visible = !power_menu_root.visible
        }
    }

    HyprlandFocusGrab {
        active: power_menu_root.visible
        windows: [power_menu_root]
        onCleared: power_menu_root.visible = false
    }

    Item {
        id: focus_item
        anchors.fill: parent
        focus: true
        opacity: 0

        Keys.onPressed: (event) => {
            switch (event.key) {
            case Qt.Key_Escape:
                power_menu_root.visible = false
                event.accepted = true
                break
            case Qt.Key_Left:
            case Qt.Key_H:
                if (selected_index < 5)
                    selected_index = (selected_index - 1 + 5) % 5
                event.accepted = true
                break
            case Qt.Key_Right:
            case Qt.Key_L:
                if (selected_index < 5)
                    selected_index = (selected_index + 1) % 5
                event.accepted = true
                break
            case Qt.Key_Down:
            case Qt.Key_J:
                if (selected_index < 5) {
                    last_row_index = selected_index
                    selected_index = 5
                }
                event.accepted = true
                break
            case Qt.Key_Up:
            case Qt.Key_K:
                if (selected_index === 5)
                    selected_index = last_row_index
                event.accepted = true
                break
            case Qt.Key_Return:
            case Qt.Key_Enter:
                _activate_selected()
                event.accepted = true
                break
            }
        }
    }

    function _activate_selected() {
        switch (selected_index) {
        case 0: _do_action(["loginctl", "lock-session"]); break
        case 1: _do_action(["systemctl", "suspend"]); break
        case 2: _do_action(["hyprctl", "dispatch", "exit"]); break
        case 3: _do_action(["systemctl", "reboot"]); break
        case 4: _do_action(["systemctl", "poweroff"]); break
        case 5: power_menu_root.visible = false; break
        }
    }

    Rectangle {
        anchors.fill: parent
        color: services.MatugenService.scrim
        opacity: 0.6

        MouseArea {
            anchors.fill: parent
            onClicked: power_menu_root.visible = false
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: token_spacing_lg

        Text {
            text: "Power Options"
            color: services.MatugenService.primary
            font: token_typography_headline
            Layout.alignment: Qt.AlignHCenter
        }

        RowLayout {
            spacing: token_spacing_lg
            Layout.alignment: Qt.AlignHCenter

            LocalComponents.PowerMenuButton {
                label: "Lock"
                icon: "lock"
                destructive: false
                selected: power_menu_root.selected_index === 0
                onClicked: power_menu_root._do_action(["loginctl", "lock-session"])
            }

            LocalComponents.PowerMenuButton {
                label: "Suspend"
                icon: "mode_standby"
                destructive: false
                selected: power_menu_root.selected_index === 1
                onClicked: power_menu_root._do_action(["systemctl", "suspend"])
            }

            LocalComponents.PowerMenuButton {
                label: "Logout"
                icon: "logout"
                destructive: true
                selected: power_menu_root.selected_index === 2
                onClicked: power_menu_root._do_action(["hyprctl", "dispatch", "exit"])
            }

            LocalComponents.PowerMenuButton {
                label: "Reboot"
                icon: "restart_alt"
                destructive: true
                selected: power_menu_root.selected_index === 3
                onClicked: power_menu_root._do_action(["systemctl", "reboot"])
            }

            LocalComponents.PowerMenuButton {
                label: "Shutdown"
                icon: "power_settings_new"
                destructive: true
                selected: power_menu_root.selected_index === 4
                onClicked: power_menu_root._do_action(["systemctl", "poweroff"])
            }
        }

        LocalComponents.PowerMenuButton {
            label: "Cancel"
            icon: "close"
            selected: power_menu_root.selected_index === 5
            Layout.alignment: Qt.AlignHCenter
            button_height: token_spacing_xl * 3
            onClicked: power_menu_root.visible = false
        }
    }

    Process { id: power_proc }

    function _do_action(command) {
        power_menu_root.visible = false
        power_proc.exec({ command: command })
    }
}
