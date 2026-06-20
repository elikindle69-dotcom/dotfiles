import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../Components" as Components
import "./LocalComponents" as LocalComponents

PanelWindow {
    id: sidebar_root

    anchors {
        top: true
        right: true
        bottom: true
    }

    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    implicitWidth: token_spacing_xl * 16
    visible: false
    color: services.MatugenService.background
    focusable: true

    property bool wifi_enabled: true
    property bool bluetooth_enabled: true

    IpcHandler {
        target: "sidebar"

        function visibility(vis: bool) {
            sidebar_root.visible = vis
            services.EventBus.sidebarToggled(vis)
            if (vis) focus_item.forceActiveFocus()
        }

        function toggle() {
            sidebar_root.visible = !sidebar_root.visible
            services.EventBus.sidebarToggled(sidebar_root.visible)
            if (sidebar_root.visible) focus_item.forceActiveFocus()
        }
    }

    Process { id: wifi_toggle_proc }
    Process { id: bluetooth_toggle_proc }
    Process { id: power_proc }

    Process {
        id: init_rfkill
        command: ["rfkill", "list"]

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.split("\n")
                    let in_wifi = false
                    let in_bt = false

                for (let l of lines) {
                    if (l.includes("Wireless LAN")) {
                        in_wifi = true
                        in_bt = false
                    } else if (l.includes("Bluetooth")) {
                        in_wifi = false
                        in_bt = true
                    } else if (l.trim() === "") {
                        in_wifi = false
                        in_bt = false
                    }

                    if (l.includes("Soft blocked: yes") || l.includes("Hard blocked: yes")) {
                        if (in_wifi) sidebar_root.wifi_enabled = false
                        if (in_bt) sidebar_root.bluetooth_enabled = false
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        init_rfkill.exec({})
    }

    Item {
        id: focus_item
        anchors.fill: parent
        focus: true
        opacity: 0

        Behavior on opacity {
            NumberAnimation { duration: token_motion_duration_medium; easing.type: Easing.OutCubic }
        }

        Component.onCompleted: opacity = 1

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                sidebar_root.visible = false
                services.EventBus.sidebarToggled(false)
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: token_spacing_md
            spacing: token_spacing_sm

            Text {
                text: "System Controls"
                font: token_typography_headline
                color: services.MatugenService.primary
                Layout.bottomMargin: token_spacing_sm
            }

            Components.SidebarToggle {
                icon: "wifi"
                toggled: sidebar_root.wifi_enabled
                Layout.fillWidth: true
                Layout.preferredHeight: token_spacing_xl + token_spacing_sm
                onClicked: {
                    sidebar_root.wifi_enabled = !sidebar_root.wifi_enabled
                    wifi_toggle_proc.exec({
                        command: ["sh", "-c", sidebar_root.wifi_enabled ? "rfkill unblock wifi" : "rfkill block wifi"]
                    })
                }
            }

            Components.SidebarToggle {
                icon: "bluetooth"
                toggled: sidebar_root.bluetooth_enabled
                Layout.fillWidth: true
                Layout.preferredHeight: token_spacing_xl + token_spacing_sm
                onClicked: {
                    sidebar_root.bluetooth_enabled = !sidebar_root.bluetooth_enabled
                    bluetooth_toggle_proc.exec({
                        command: ["sh", "-c", sidebar_root.bluetooth_enabled ? "rfkill unblock bluetooth" : "rfkill block bluetooth"]
                    })
                }
            }

            Components.SidebarSlider {
                icon: "volume_up"
                slider_value: services.AudioService.volume
                Layout.fillWidth: true
                Layout.preferredHeight: token_spacing_xl + token_spacing_sm
                onValueChanged: services.AudioService.set_volume(value)
            }

            Components.SidebarSlider {
                icon: "brightness_6"
                slider_value: services.BrightService.screen_bright
                Layout.fillWidth: true
                Layout.preferredHeight: token_spacing_xl + token_spacing_sm
                onValueChanged: services.BrightService.set_screen_brightness(value)
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: services.MatugenService.outline_variant
                Layout.topMargin: token_spacing_sm
            }

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Notifications"
                    font: token_typography_body
                    color: services.MatugenService.on_surface_variant
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    visible: services.NotificationService.notifications.length > 0 || services.NotificationService.history_count > 0
                    Layout.preferredWidth: token_spacing_xl + token_spacing_sm
                    Layout.preferredHeight: token_spacing_xl + token_spacing_sm
                    radius: token_radius_md
                    color: clear_all_area.containsMouse ? services.MatugenService.surface_variant : "transparent"

                    Components.IconText {
                        anchors.centerIn: parent
                        icon_text: "clear_all"
                        icon_color: services.MatugenService.on_surface_variant
                        large: true
                    }

                    MouseArea {
                        id: clear_all_area
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: {
                            const notifs = services.NotificationService.notifications.slice()
                            for (let i = 0; i < notifs.length; i++) {
                                services.NotificationService.purge(notifs[i].id)
                            }
                            services.NotificationService.clear_history()
                        }
                    }
                }
            }

            ScrollView {
                id: notif_scroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                Flickable {
                    id: notif_flick
                    contentWidth: notif_scroll.availableWidth
                    contentHeight: notif_column.implicitHeight
                    flickableDirection: Flickable.VerticalFlick
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: notif_column
                        width: parent.width
                        anchors.margins: token_spacing_sm
                        spacing: token_spacing_xs

                        Repeater {
                            model: services.NotificationService.notifications

                            Components.NotificationCard {
                                Layout.fillWidth: true
                                Layout.maximumWidth: 1000
                                notification_entry: modelData
                                onPurge: services.NotificationService.purge(modelData.id)
                                onActionInvoked: (action_identifier) => services.NotificationService.invoke_action(modelData.id, action_identifier)
                            }
                        }

                        Text {
                            text: "No notifications"
                            font: token_typography_body
                            color: services.MatugenService.on_surface_variant
                            visible: services.NotificationService.notifications.length === 0 && services.NotificationService.history_count === 0
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            Layout.topMargin: token_spacing_xl
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: services.MatugenService.outline_variant
                            visible: services.NotificationService.history_count > 0
                            Layout.topMargin: token_spacing_sm
                        }

                        Text {
                            text: "History"
                            font: token_typography_body
                            color: services.MatugenService.on_surface_variant
                            visible: services.NotificationService.history_count > 0
                            Layout.topMargin: token_spacing_sm
                        }

                        Repeater {
                            model: services.NotificationService.history

                            Components.NotificationCard {
                                Layout.fillWidth: true
                                Layout.maximumWidth: 1000
                                notification_entry: modelData
                                opacity: 0.7
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: services.MatugenService.outline_variant
            }

            Text {
                text: "Power"
                font: token_typography_body
                color: services.MatugenService.on_surface_variant
                Layout.topMargin: token_spacing_sm
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: token_spacing_sm

                LocalComponents.PowerButton {
                    Layout.fillWidth: true
                    label: "Suspend"
                    icon: "mode_standby"
                    destructive: false
                    onClicked: power_proc.exec({ command: ["systemctl", "suspend"] })
                }

                LocalComponents.PowerButton {
                    Layout.fillWidth: true
                    label: "Logout"
                    icon: "logout"
                    destructive: true
                    onClicked: power_proc.exec({ command: ["hyprctl", "dispatch", "exit"] })
                }

                LocalComponents.PowerButton {
                    Layout.fillWidth: true
                    label: "Reboot"
                    icon: "restart_alt"
                    destructive: true
                    onClicked: power_proc.exec({ command: ["systemctl", "reboot"] })
                }

                LocalComponents.PowerButton {
                    Layout.fillWidth: true
                    label: "Shutdown"
                    icon: "power_settings_new"
                    destructive: true
                    onClicked: power_proc.exec({ command: ["systemctl", "poweroff"] })
                }
            }
        }
    }
}
