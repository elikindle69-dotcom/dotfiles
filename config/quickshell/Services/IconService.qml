pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var cache: ({})

    function resolve(name, callback) {
        if (!name || name.length === 0) {
            callback("")
            return
        }

        if (name.startsWith("/") || name.startsWith("file://")) {
            callback(name)
            return
        }

        if (cache[name]) {
            callback(cache[name])
            return
        }

        const clean = name.replace(/\.svg$|\.png$|\.xpm$/, "")

        icon_lookup.exec({
            command: ["sh", "-c", `
                for dir in "$HOME/.local/share/icons" /usr/share/icons /usr/local/share/icons; do
                    for theme in yamis Adwaita hicolor; do
                        for size in scalable 48x48 64x64 128x128; do
                            for ctx in apps categories devices mimetypes status preferences; do
                                for ext in svg png xpm; do
                                    f="$dir/$theme/$size/$ctx/$clean.$ext"
                                    if [ -f "$f" ]; then
                                        echo "$f"
                                        exit 0
                                    fi
                                done
                            done
                        done
                    done
                done
                exit 1
            `]
        })
    }

    Process {
        id: icon_lookup

        stdout: StdioCollector {
            onStreamFinished: {
                const path = this.text.trim()
                if (path.length > 0) {
                    const name = path.split("/").pop().replace(/\.[^.]+$/, "")
                    root.cache[name] = path
                    root.iconResolved(name, path)
                }
            }
        }
    }

    signal iconResolved(string name, string path)
}
