pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real cpu: 0.0
    property real memory: 0.0
    property real swap: 0.0
    property real disk: 0.0
    property int processes: 0

    property int interval_ms: 1500
    property int _last_cpu_idle: 0
    property int _last_cpu_total: 0

    Timer {
        interval: root.interval_ms
        running: true
        repeat: true
        onTriggered: {
            cpu_proc.running = true
            mem_proc.running = true
            disk_proc.running = true
            processes_proc.running = true
        }
    }

    Process {
        id: cpu_proc
        command: ["head", "-n", "1", "/proc/stat"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const line = this.text.trim()
                const p = line.split(/\s+/)

                let total = 0
                for (let i = 1; i < p.length; i++) {
                    const v = Number(p[i])
                    if (!isNaN(v)) total += v
                }

                const idle = (Number(p[4]) || 0) + (Number(p[5]) || 0)

                const diff_idle = idle - root._last_cpu_idle
                const diff_total = total - root._last_cpu_total

                let usage = 0
                if (diff_total > 0) {
                    usage = 1 - (diff_idle / diff_total)
                }

                root.cpu = Math.max(0, Math.min(1, usage))

                root._last_cpu_idle = idle
                root._last_cpu_total = total
            }
        }
    }

    Process {
        id: mem_proc
        command: ["head", "-n", "20", "/proc/meminfo"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.split("\n")

                let mem_total = 0
                let mem_avail = 0

                let swap_total = 0
                let swap_free = 0

                for (let l of lines) {
                    if (l.startsWith("MemTotal:"))
                        mem_total = Number(l.match(/\d+/)[0])
                    else if (l.startsWith("MemAvailable:"))
                        mem_avail = Number(l.match(/\d+/)[0])
                    else if (l.startsWith("SwapTotal:"))
                        swap_total = Number(l.match(/\d+/)[0])
                    else if (l.startsWith("SwapFree:"))
                        swap_free = Number(l.match(/\d+/)[0])
                }

                if (mem_total > 0) {
                    root.memory = (mem_total - mem_avail) / mem_total
                }

                if (swap_total > 0) {
                    root.swap = (swap_total - swap_free) / swap_total
                }
            }
        }
    }

    Process {
        id: disk_proc
        command: ["df", "-P", "/"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n")
                if (lines.length < 2) return

                const p = lines[1].split(/\s+/)

                const used = Number(p[2]) || 0
                const avail = Number(p[3]) || 0

                const total = used + avail

                root.disk = total > 0 ? used / total : 0
            }
        }
    }

    Process {
        id: processes_proc
        command: ["grep", "processes", "/proc/stat"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const total = Number(text.match(/\d+/)[0])
                root.processes = total
            }
        }
    }
}
