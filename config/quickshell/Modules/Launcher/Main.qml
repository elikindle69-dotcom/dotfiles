import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import "../../Components" as Components
import "./LocalComponents" as LocalComponents

PanelWindow {
    id: module_root
    anchors { top: true }

    margins {
        top: token_spacing_xl * 2
    }

    color: services.MatugenService.background
    implicitWidth: token_spacing_xl * 32
    implicitHeight: main_layout.implicitHeight
    exclusionMode: ExclusionMode.Ignore
    focusable: true
    visible: false

    IpcHandler {
        target: "launcher"

        function visibility(visiblility: bool) {
            module_root.visible = visiblility
            services.EventBus.launcherToggled(visiblility)
        }

        function toggle() {
            module_root.visible = !module_root.visible
            services.EventBus.launcherToggled(module_root.visible)
        }
    }

    HyprlandFocusGrab {
        active: module_root.visible
        windows: [ module_root ]
        onCleared: {
            module_root.visible = false
            clear_launcher()
        }
    }

    function clear_launcher() {
        display_label.text = ""
        services.LauncherService.clear()
    }

    function copy_to_clipboard(text) {
        Quickshell.execDetached(["wl-copy", String(text)])
    }

    function ddg_search(query) {
        const url = "https://duckduckgo.com/?q=" + encodeURIComponent(query)
        Quickshell.execDetached(["xdg-open", url])
    }

    Column {
        id: main_layout
        width: parent.width
        spacing: token_spacing_xs

        Item {
            width: parent.width
            height: token_spacing_xl

            TextInput {
                id: display_label
                anchors.fill: parent
                anchors.leftMargin: token_spacing_sm
                anchors.rightMargin: token_spacing_sm
                font: token_typography_body
                verticalAlignment: Text.AlignVCenter
                color: services.MatugenService.primary
                selectionColor: services.MatugenService.primary
                clip: true
                selectByMouse: true
                focus: true
                Keys.enabled: true

                onTextChanged: services.LauncherService.filter(display_label.text)

                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Escape) {
                        module_root.visible = false
                        clear_launcher()
                        event.accepted = true
                        return
                    }

                    if (event.key === Qt.Key_Down) {
                        services.LauncherService.select_next()
                        event.accepted = true
                        return
                    }

                    if (event.key === Qt.Key_Up) {
                        services.LauncherService.select_prev()
                        event.accepted = true
                        return
                    }

                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        const svc = services.LauncherService

                        if (svc.results.length > 0 && svc.selected_index < svc.results.length) {
                            const item = svc.results[svc.selected_index]

                            switch (item.type) {
                            case "application":
                                item.app.execute()
                                break
                            case "websearch":
                                ddg_search(item.query)
                                break
                            case "calculation":
                                copy_to_clipboard(item.value)
                                display_label.text = String(item.value)
                                event.accepted = true
                                return
                            }

                            display_label.text = ""
                            svc.clear()
                            module_root.visible = false
                            event.accepted = true
                            return
                        }

                        display_label.text = ""
                        svc.clear()
                        module_root.visible = false
                        clear_launcher()
                        event.accepted = true
                        return
                    }
                }

                Text {
                    text: "Type search query..."
                    font: parent.font
                    visible: parent.text.length === 0
                    anchors.verticalCenter: parent.verticalCenter
                    color: services.MatugenService.primary
                }
            }

            Rectangle {
                width: parent.width
                height: parent.height
                color: services.MatugenService.background
                z: -1
            }
        }

        Column {
            width: parent.width
            spacing: token_spacing_xs / 2
            visible: services.LauncherService.results.length > 0

            Repeater {
                model: services.LauncherService.results

                LocalComponents.LauncherResult {
                    entry: modelData
                    is_selected: services.LauncherService.selected_index === index
                    onActivated: {
                        if (entry.type === "application") {
                            entry.app.execute()
                        } else if (entry.type === "websearch") {
                            ddg_search(entry.query)
                        } else if (entry.type === "calculation") {
                            copy_to_clipboard(entry.value)
                            display_label.text = String(entry.value)
                        }
                        display_label.text = ""
                        services.LauncherService.clear()
                        module_root.visible = false
                    }
                }
            }
        }
    }
}
