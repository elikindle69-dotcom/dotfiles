pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property int next_id: 0
    property var notifications: []
    property var history: []
    property int popup_timeout: 5000
    readonly property int history_count: history.length

    NotificationServer {
        id: server

        keepOnReload: false
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        imageSupported: true
        persistenceSupported: false

        onNotification: (notification) => {
            notification.tracked = true

            const entry = {
                id: root.next_id++,
                notification: notification,
                app_name: notification.appName || "Unknown",
                app_icon: notification.appIcon || "",
                image: notification.image || "",
                summary: notification.summary || "",
                body: notification.body || "",
                urgency: notification.urgency,
                actions: [],
                timestamp: Date.now(),
                expired: false
            }

            for (let i = 0; i < notification.actions.length; i++) {
                entry.actions.push({
                    identifier: notification.actions[i].identifier,
                    text: notification.actions[i].text
                })
            }

            root.notifications = [entry].concat(root.notifications)

            notification.closed.connect((reason) => {
                root._move_to_history(entry.id)
            })
        }
    }

    function dismiss(id) {
        const idx = root.notifications.findIndex(n => n.id === id)
        if (idx >= 0) {
            const entry = root.notifications[idx]
            entry.notification.dismiss()
            root._move_to_history(id)
        }
    }

    function purge(id) {
        const idx = root.notifications.findIndex(n => n.id === id)
        if (idx >= 0) {
            const entry = root.notifications[idx]
            entry.notification.dismiss()
            root.notifications = root.notifications.filter(n => n.id !== id)
        }
    }

    function invoke_action(id, action_identifier) {
        const entry = root.notifications.find(n => n.id === id)
        if (entry) {
            for (let i = 0; i < entry.notification.actions.length; i++) {
                if (entry.notification.actions[i].identifier === action_identifier) {
                    entry.notification.actions[i].invoke()
                    return
                }
            }
        }
    }

    function _move_to_history(id) {
        const idx = root.notifications.findIndex(n => n.id === id)
        if (idx < 0) return
        const entry = root.notifications[idx]
        root.notifications = root.notifications.filter(n => n.id !== id)
        const snapshot = {
            id: entry.id,
            app_name: entry.app_name,
            app_icon: entry.app_icon,
            image: entry.image,
            summary: entry.summary,
            body: entry.body,
            urgency: entry.urgency,
            actions: entry.actions,
            timestamp: entry.timestamp
        }
        root.history = [snapshot].concat(root.history)
    }

    function clear_history() {
        root.history = []
    }

    function _cleanup() {
        root.notifications = root.notifications.filter(n => !n.expired)
    }
}
