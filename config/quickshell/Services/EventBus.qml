pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    signal sidebarToggled(bool visible)
    signal launcherToggled(bool visible)
    signal passwordManagerToggled(bool visible)
    signal vaultUnlocked()
    signal vaultLocked()
}
