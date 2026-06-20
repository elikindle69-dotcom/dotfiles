pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    signal sidebarToggled(bool visible)
    signal launcherToggled(bool visible)
}
