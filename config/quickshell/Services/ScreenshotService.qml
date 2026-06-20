pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string save_directory: ""
    property string last_screenshot_path: ""
    property bool is_capturing: false
    property string capture_mode: ""

    signal captureRequested(string mode)
    signal captureComplete(string path)
    signal captureFailed(string reason)
    signal cancelled()

    Process {
        id: home_proc
        command: ["printenv", "HOME"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.save_directory = this.text.trim() + "/Pictures/Screenshots"
                console.log("[ScreenshotService] save_directory:", root.save_directory)
                root._ensure_directory()
            }
        }
    }

    Component.onCompleted: {
        home_proc.exec({ command: ["printenv", "HOME"] })
    }

    function _ensure_directory() {
        mkdir_proc.exec({ command: ["mkdir", "-p", save_directory] })
    }

    function _generate_filename() {
        const now = new Date()
        const pad = (n) => String(n).padStart(2, "0")
        const ts = now.getFullYear() + "-"
            + pad(now.getMonth() + 1) + "-"
            + pad(now.getDate()) + "_"
            + pad(now.getHours())
            + pad(now.getMinutes())
            + pad(now.getSeconds())
        return save_directory + "/screenshot_" + ts + ".png"
    }

    function capture_full() {
        if (is_capturing) return
        is_capturing = true
        capture_mode = "full"
        console.log("[ScreenshotService] capture_full requested")
        captureRequested("full")
    }

    function capture_region() {
        if (is_capturing) return
        is_capturing = true
        capture_mode = "region"
        console.log("[ScreenshotService] capture_region requested")
        captureRequested("region")
    }

    function capture_active() {
        if (is_capturing) return
        is_capturing = true
        capture_mode = "active"
        console.log("[ScreenshotService] capture_active requested")
        captureRequested("active")
    }

    function finish_capture(path) {
        console.log("[ScreenshotService] capture finished:", path)
        is_capturing = false
        capture_mode = ""
        last_screenshot_path = path
        captureComplete(path)
    }

    function fail_capture(reason) {
        console.error("[ScreenshotService] capture failed:", reason)
        is_capturing = false
        capture_mode = ""
        captureFailed(reason)
    }

    function cancel() {
        console.log("[ScreenshotService] capture cancelled")
        is_capturing = false
        capture_mode = ""
        cancelled()
    }

    function copy_to_clipboard(path) {
        console.log("[ScreenshotService] copying to clipboard:", path)
        Quickshell.execDetached(["sh", "-c", "cat '" + path + "' | wl-copy -t image/png"])
    }

    function save_to_pictures(path) {
        const dest = _generate_filename()
        console.log("[ScreenshotService] saving to:", dest)
        save_proc.exec({ command: ["cp", path, dest] })
        return dest
    }

    Process { id: mkdir_proc }
    Process { id: save_proc }
}
