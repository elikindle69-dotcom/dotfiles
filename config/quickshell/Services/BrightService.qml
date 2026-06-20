pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string screen_device: "intel_backlight"
    property string kbd_device: ""

    readonly property string screen_path:
        "/sys/class/backlight/" + screen_device

    readonly property bool screen_available: screen_device !== ""

    property real screen_bright: 0.0
    property int screen_max_brightness: 1

    function sync_screen() {
        screen_brightness_file.reload()

        const current = parseInt(screen_brightness_file.text().trim())
        const value = current / screen_max_brightness

        console.log("[BrightService] sync_screen", current, screen_max_brightness, value)

        screen_bright = value
    }

    Component.onCompleted: {
        detect_device.exec({ command: ["ls", "/sys/class/backlight/"] })
    }

    function set_screen_brightness(value) {
        if (!screen_available)
            return

        const perc = Math.round(
            Math.max(0, Math.min(1, value)) * 100
        )

        screen_bright = Math.max(0, Math.min(1, value))

        set_screen.exec({
            command: [
                "brightnessctl",
                "-d",
                screen_device,
                "set",
                perc + "%"
            ]
        })
    }

    Process {
        id: detect_device
        command: ["ls", "/sys/class/backlight/"]

        stdout: StdioCollector {
            onStreamFinished: {
                const devices = this.text.trim().split("\n").filter(s => s.length > 0)
                if (devices.length > 0) {
                    root.screen_device = devices[0]
                    console.log("[BrightService] detected screen device:", devices[0])

                    screen_max_brightness = parseInt(screen_max_file.text().trim())
                    sync_screen()
                } else {
                    console.log("[BrightService] no backlight device found")
                    root.screen_device = ""
                }

                detect_kbd_device.exec({ command: ["brightnessctl", "--list"] })
            }
        }
    }

    Process {
        id: detect_kbd_device
        command: ["brightnessctl", "--list"]

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n")
                for (let line of lines) {
                    const match = line.match(/Device\s+(\S+).*keyboard/)
                    if (match) {
                        root.kbd_device = match[1]
                        console.log("[BrightService] detected kbd device:", match[1])
                        set_kbd.exec({
                            command: [
                                "brightnessctl",
                                "--device=" + match[1],
                                "set",
                                "1"
                            ]
                        })
                        return
                    }
                }
                console.log("[BrightService] no keyboard backlight found")
            }
        }
    }

    FileView {
        id: screen_brightness_file
        blockLoading: true
        path: screen_path + "/brightness"
        watchChanges: true

        onLoaded: {
            console.log("[screen] loaded", text())
            sync_screen()
        }

        onLoadFailed: err => {
            console.log("[screen] load failed", err)
        }

        onFileChanged: {
            console.log("[screen] file changed")
            reload()
        }
    }

    FileView {
        id: screen_max_file
        blockLoading: true
        path: screen_path + "/max_brightness"
    }

    Process { id: set_screen }
    Process { id: set_kbd }
}
