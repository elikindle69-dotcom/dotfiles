import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../Components" as Components

PanelWindow {
    id: screenshot_root

    anchors {
        bottom: true
        right: true
    }

    margins {
        bottom: token_spacing_xl * 3
        right: token_spacing_sm
    }

    implicitWidth: preview.implicitWidth + token_spacing_md * 2
    implicitHeight: preview.implicitHeight + token_spacing_md * 2
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: show_preview

    property bool show_preview: false
    property string pending_mode: ""

    IpcHandler {
        target: "screenshot"

        function start() {
            console.log("[Screenshot] IPC start (region)")
            services.ScreenshotService.capture_region()
        }

        function fullscreen() {
            console.log("[Screenshot] IPC fullscreen")
            services.ScreenshotService.capture_full()
        }

        function active() {
            console.log("[Screenshot] IPC active")
            services.ScreenshotService.capture_active()
        }

        function cancel() {
            console.log("[Screenshot] IPC cancel")
            services.ScreenshotService.cancel()
        }
    }

    Connections {
        target: services.ScreenshotService

        function onCaptureRequested(mode) {
            console.log("[Screenshot] capture requested:", mode)
            pending_mode = mode
            var cmd
            switch (mode) {
                case "region":
                    cmd = ["sh", "-c", "grim -g \"$(slurp -d)\" - | tee /tmp/qs_screenshot.png"]
                    break
                case "active":
                    cmd = ["sh", "-c", "ACTIVE=$(hyprctl activewindow -j | jq -r '.address') && grim -g \"$(hyprctl clients -j | jq -r --arg addr \"$ACTIVE\" '.[] | select(.address == $addr) | \"\\(.at[0]),\\(.at[1]) \\(.size[0])x\\(.size[1])\"')\" - | tee /tmp/qs_screenshot.png"]
                    break
                case "full":
                default:
                    cmd = ["sh", "-c", "grim - | tee /tmp/qs_screenshot.png"]
                    break
            }
            grim_proc.exec({ command: cmd })
        }

        function onCancelled() {
            console.log("[Screenshot] capture cancelled")
            show_preview = false
            pending_mode = ""
        }

        function onLast_screenshot_pathChanged() {
            if (services.ScreenshotService.last_screenshot_path.length > 0) {
                preview.screenshot_path = services.ScreenshotService.last_screenshot_path
                screenshot_root.show_preview = true
                preview.restart_timer()
            }
        }
    }

    Components.ScreenshotPreview {
        id: preview
        anchors.centerIn: parent

        onCopyClicked: {
            services.ScreenshotService.copy_to_clipboard(screenshot_path)
            screenshot_root.show_preview = false
        }

        onSaveClicked: {
            services.ScreenshotService.save_to_pictures(screenshot_path)
            screenshot_root.show_preview = false
        }

        onDismiss: screenshot_root.show_preview = false
    }

    Process {
        id: grim_proc

        onRunningChanged: {
            if (!running && exitCode === 0) {
                services.ScreenshotService.finish_capture("/tmp/qs_screenshot.png")
            } else if (!running && exitCode !== 0) {
                services.ScreenshotService.fail_capture("Process exited with code " + exitCode)
            }
        }
    }
}
