pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    PwObjectTracker {
        id: sink_tracker
        objects: sink ? [sink] : []
        onObjectsChanged: {
            if (objects.length === 0 && sink) {
                objects = [sink]
            }
        }
    }

    PwObjectTracker {
        id: source_tracker
        objects: source ? [source] : []
        onObjectsChanged: {
            if (objects.length === 0 && source) {
                objects = [source]
            }
        }
    }

    readonly property bool sink_ready: sink !== null && sink.audio !== null
    readonly property bool source_ready: source !== null && source.audio !== null

    readonly property bool muted: sink_ready ? (sink.audio.muted ?? false) : false
    readonly property real volume: sink_ready ? Math.max(0, Math.min(1.5, sink.audio.volume ?? 0)) : 0
    readonly property int percentage: Math.round(volume * 100)

    readonly property bool source_muted: source_ready ? (source.audio.muted ?? false) : false
    readonly property real source_volume: source_ready ? Math.max(0, Math.min(1.5, source.audio.volume ?? 0)) : 0
    readonly property int source_percentage: Math.round(source_volume * 100)

    function set_volume(new_volume) {
        if (sink_ready && sink.audio) {
            sink.audio.muted = false
            sink.audio.volume = Math.max(0, Math.min(1.5, new_volume))
        }
    }

    function toggle_mute() {
        if (sink_ready && sink.audio) {
            sink.audio.muted = !sink.audio.muted
        }
    }

    function increase_volume() {
        set_volume(volume + 0.05)
    }

    function decrease_volume() {
        set_volume(volume - 0.05)
    }

    function set_source_volume(new_volume) {
        if (source_ready && source.audio) {
            source.audio.muted = false
            source.audio.volume = Math.max(0, Math.min(1.5, new_volume))
        }
    }

    function toggle_source_mute() {
        if (source_ready && source.audio) {
            source.audio.muted = !source.audio.muted
        }
    }
}
