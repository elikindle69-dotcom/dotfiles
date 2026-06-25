import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../../Components" as Components
import "./LocalComponents" as LocalComponents

PanelWindow {
    id: pm_root

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

    property string view: "unlock"
    property string selectedEntryId: ""
    property bool isEditing: false

    onVisibleChanged: {
        if (visible) {
            _resetActivity()
            if (services.CryptoService.isFirstRun) {
                view = "set_password"
            } else if (services.CryptoService.isUnlocked) {
                view = "list"
            } else {
                view = "unlock"
            }
            card.forceActiveFocus()
        } else {
            _cleanup()
        }
    }

    IpcHandler {
        target: "passwordmanager"

        function toggle() {
            pm_root.visible = !pm_root.visible
            services.EventBus.passwordManagerToggled(pm_root.visible)
        }

        function visibility(vis: bool) {
            pm_root.visible = vis
            services.EventBus.passwordManagerToggled(vis)
        }

        function set_master_password() {
            pm_root.visible = true
            pm_root.view = "set_password"
            services.EventBus.passwordManagerToggled(true)
        }

        function unlock(pw: string) {
            services.CryptoService.unlock(pw)
        }

        function lock() {
            services.CryptoService.lock()
            services.VaultService._wipe()
            pm_root.view = "unlock"
            pm_root.visible = false
            services.EventBus.vaultLocked()
        }

        function add(name: string, user: string, pass: string, url: string, notes: string, cat: string) {
            services.VaultService.addEntry(name, user, pass, url, notes, cat)
        }

        function get(name: string): string {
            const entry = services.VaultService.getEntryByName(name)
            return entry ? JSON.stringify(entry) : "{}"
        }

        function list(): string {
            const result = []
            const entries = services.VaultService.entries
            for (const id in entries) {
                result.push(entries[id])
            }
            return JSON.stringify(result)
        }

        function deleteentry(name: string) {
            const entry = services.VaultService.getEntryByName(name)
            if (entry) services.VaultService.deleteEntry(entry.id)
        }

        function search(query: string): string {
            services.VaultService.search(query)
            const result = []
            const entries = services.VaultService.displayEntries
            for (let i = 0; i < entries.length; i++) {
                result.push(entries[i])
            }
            return JSON.stringify(result)
        }
    }

    HyprlandFocusGrab {
        active: pm_root.visible
        windows: [pm_root]
        onCleared: pm_root.visible = false
    }

    // Auto-lock timer
    Timer {
        id: autoLockTimer
        interval: 300000
        onTriggered: {
            if (services.CryptoService.isUnlocked) {
                services.CryptoService.lock()
                services.VaultService._wipe()
                pm_root.view = "unlock"
                services.EventBus.vaultLocked()
            }
        }
    }

    // Clipboard clear timer
    property string _clipboardEntryId: ""
    property string _clipboardField: ""

    Timer {
        id: clipboardClearTimer
        interval: 30000
        onTriggered: {
            Quickshell.execDetached(["wl-copy", ""])
            pm_root._clipboardEntryId = ""
            pm_root._clipboardField = ""
        }
    }

    // Card with keyboard handling (defined above)

    function _selectNext() {
        const list = services.VaultService.displayEntries
        if (list.length === 0) return

        const currentIdx = _findSelectedIndex()
        if (currentIdx < list.length - 1) {
            pm_root.selectedEntryId = list[currentIdx + 1].id
        } else {
            pm_root.selectedEntryId = list[0].id
        }
    }

    function _selectPrev() {
        const list = services.VaultService.displayEntries
        if (list.length === 0) return

        const currentIdx = _findSelectedIndex()
        if (currentIdx > 0) {
            pm_root.selectedEntryId = list[currentIdx - 1].id
        } else {
            pm_root.selectedEntryId = list[list.length - 1].id
        }
    }

    function _findSelectedIndex() {
        const list = services.VaultService.displayEntries
        for (let i = 0; i < list.length; i++) {
            if (list[i].id === pm_root.selectedEntryId) return i
        }
        return -1
    }

    function _resetActivity() {
        autoLockTimer.restart()
    }

    function _cleanup() {
        pm_root.selectedEntryId = ""
        pm_root.isEditing = false
    }

    function copyToClipboard(text, entryId, field) {
        Quickshell.execDetached(["wl-copy", String(text)])
        _clipboardEntryId = entryId
        _clipboardField = field
        clipboardClearTimer.restart()
    }

    Rectangle {
        anchors.fill: parent
        color: services.MatugenService.scrim
        opacity: 0.85

        MouseArea {
            anchors.fill: parent
            onClicked: pm_root.visible = false
        }
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: 520
        height: Math.min(headerCol.height + bodyCol.implicitHeight + token_spacing_lg * 2 + 48, parent.height * 0.85)
        radius: token_radius_lg
        color: services.MatugenService.surface_container
        focus: true

        border.width: 1
        border.color: services.MatugenService.outline_variant

        Keys.onPressed: (event) => {
            _resetActivity()

            if (event.key === Qt.Key_Escape) {
                if (pm_root.view === "detail" || pm_root.view === "add" || pm_root.view === "edit") {
                    pm_root.view = "list"
                } else {
                    pm_root.visible = false
                }
                event.accepted = true
                return
            }

            if (pm_root.view === "list") {
                if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
                    _selectNext()
                    event.accepted = true
                } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
                    _selectPrev()
                    event.accepted = true
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    if (pm_root.selectedEntryId) {
                        pm_root.view = "detail"
                    }
                    event.accepted = true
                } else if (event.key === Qt.Key_Delete) {
                    if (pm_root.selectedEntryId) {
                        services.VaultService.deleteEntry(pm_root.selectedEntryId)
                        pm_root.selectedEntryId = ""
                    }
                    event.accepted = true
                } else if (event.key === Qt.Key_N && (event.modifiers & Qt.ControlModifier)) {
                    pm_root.view = "add"
                    event.accepted = true
                }
            }
        }

        Behavior on height {
            NumberAnimation {
                duration: token_motion_duration_medium
                easing.type: Easing.Bezier
                easing.bezierCurve: token_motion_curve_emphasis
            }
        }

        Column {
            id: headerCol
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: token_spacing_lg

            RowLayout {
                width: parent.width
                spacing: token_spacing_sm

                Components.IconText {
                    icon_text: "lock"
                    icon_color: services.MatugenService.primary
                    large: true
                }

                Text {
                    text: {
                        switch (pm_root.view) {
                        case "set_password": return "Create Master Password"
                        case "unlock": return "Unlock Vault"
                        case "list": return "Passwords"
                        case "detail": return "Entry"
                        case "add": return "Add Entry"
                        case "edit": return "Edit Entry"
                        default: return "Vault"
                        }
                    }
                    color: services.MatugenService.on_surface
                    font: token_typography_headline
                    Layout.fillWidth: true
                }

                Components.IconText {
                    icon_text: "add"
                    icon_color: services.MatugenService.primary
                    visible: pm_root.view === "list"

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: pm_root.view = "add"
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: services.MatugenService.outline_variant
            }
        }

        Flickable {
            id: bodyFlickable
            anchors.top: headerCol.bottom
            anchors.topMargin: token_spacing_md
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: errorBar.visible ? errorBar.top : parent.bottom
            anchors.bottomMargin: errorBar.visible ? token_spacing_sm : token_spacing_lg
            anchors.leftMargin: token_spacing_lg
            anchors.rightMargin: token_spacing_lg
            contentHeight: bodyCol.implicitHeight
            clip: true
            flickableDirection: Flickable.VerticalFlick

            Column {
                id: bodyCol
                width: parent.width
                spacing: token_spacing_md

                Loader {
                    id: contentLoader
                    width: parent.width
                    sourceComponent: {
                        switch (pm_root.view) {
                        case "set_password": return setPasswordComponent
                        case "unlock": return unlockComponent
                        case "list": return listComponent
                        case "detail": return detailComponent
                        case "add": return formComponent
                        case "edit": return formComponent
                        default: return unlockComponent
                        }
                    }
                }
            }
        }

        Rectangle {
            id: errorBar
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: token_spacing_lg
            height: errorText.text ? token_spacing_xl * 2 : 0
            visible: errorText.text !== ""
            radius: token_radius_sm
            color: services.MatugenService.error_container

            Behavior on height {
                NumberAnimation { duration: token_motion_duration_short }
            }

            Text {
                id: errorText
                anchors.centerIn: parent
                text: ""
                color: services.MatugenService.on_error_container
                font: token_typography_body
                width: parent.width - token_spacing_md
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }
        }
    }

    Component {
        id: setPasswordComponent
        LocalComponents.SetMasterPassword {
            onPasswordCreated: {
                pm_root.view = "unlock"
            }
        }
    }

    Component {
        id: unlockComponent
        LocalComponents.UnlockPrompt {
            onUnlockAttempt: function(password) {
                services.CryptoService.unlock(password)
            }
        }
    }

    Component {
        id: listComponent
        LocalComponents.PasswordList {
            selectedEntryId: pm_root.selectedEntryId
            onEntrySelected: function(id) {
                pm_root.selectedEntryId = id
                pm_root.view = "detail"
            }
            onAddRequested: {
                pm_root.view = "add"
            }
        }
    }

    Component {
        id: detailComponent
        LocalComponents.PasswordDetail {
            entryId: pm_root.selectedEntryId
            onBack: pm_root.view = "list"
            onEdit: {
                pm_root.view = "edit"
            }
            onCopied: function(text, field) {
                pm_root.copyToClipboard(text, pm_root.selectedEntryId, field)
            }
            onDeleted: function(id) {
                services.VaultService.deleteEntry(id)
                pm_root.selectedEntryId = ""
                pm_root.view = "list"
            }
        }
    }

    Component {
        id: formComponent
        LocalComponents.EntryForm {
            entryId: pm_root.view === "edit" ? pm_root.selectedEntryId : ""
            onSaved: {
                pm_root.view = "list"
            }
            onCancelled: {
                pm_root.view = "list"
            }
        }
    }

    Connections {
        target: services.CryptoService

        function onPasswordSet() {
            console.log("[PM:debug] onPasswordSet")
            errorText.text = ""
            pm_root.view = "unlock"
        }

        function onUnlockSucceeded() {
            console.log("[PM:debug] onUnlockSucceeded, view=list")
            errorText.text = ""
            pm_root.view = "list"
            services.EventBus.vaultUnlocked()
        }

        function onUnlockFailed(reason) {
            console.log("[PM:debug] onUnlockFailed: " + reason)
            errorText.text = reason
            errorClearTimer.restart()
        }

        function onOperationFailed(error) {
            console.log("[PM:debug] onOperationFailed: " + error)
            errorText.text = error
            errorClearTimer.restart()
        }
    }

    Timer {
        id: errorClearTimer
        interval: 3000
        onTriggered: errorText.text = ""
    }
}
