import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../Components" as Components

PanelWindow {
    id: notif_root

    anchors {
        top: true
        right: true
    }

    margins {
        top: token_spacing_xl + token_spacing_sm
        right: token_spacing_sm
    }

    implicitWidth: token_spacing_xl * 16
    implicitHeight: content_layout.implicitHeight + token_spacing_md * 2
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    visible: services.NotificationService.notifications.length > 0

    IpcHandler {
        target: "notifications"

        function dismissall() {
            const notifs = services.NotificationService.notifications.slice()
            for (let i = 0; i < notifs.length; i++) {
                services.NotificationService.purge(notifs[i].id)
            }
        }

        function dismiss(id: int) {
            services.NotificationService.purge(id)
        }
    }

    ScrollView {
        id: flickable
        anchors.fill: parent
        clip: true

        ColumnLayout {
            id: content_layout
            width: parent.width
            anchors.margins: token_spacing_sm
            spacing: token_spacing_sm

            Repeater {
                model: services.NotificationService.notifications

                Components.NotificationCard {
                    Layout.fillWidth: true
                    Layout.maximumWidth: 1000
                    notification_entry: modelData

                    Timer {
                        id: expire_timer
                        interval: services.NotificationService.popup_timeout
                        running: !modelData.expired && !parent.is_hovered
                        repeat: false
                        onTriggered: {
                            if (modelData && !modelData.expired) {
                                services.NotificationService.dismiss(modelData.id)
                            }
                        }
                    }

                    onPurge: services.NotificationService.purge(modelData.id)
                    onActionInvoked: (identifier) => services.NotificationService.invoke_action(modelData.id, identifier)
                }
            }
        }
    }
}
