pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string path: ""

    property var json_data: ({})
    property string mode: "dark"

    Process {
        id: home_proc
        command: ["printenv", "HOME"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.path = this.text.trim() + "/.theme.json"
                file.reload()
            }
        }
    }

    Component.onCompleted: {
        home_proc.exec({})
    }

    FileView {
        id: file
        path: root.path
        watchChanges: true
        blockLoading: true

        onLoaded: root.reload_colors()
        onFileChanged: reload()
    }

    function reload_colors() {
        try {
            const data = JSON.parse(file.text())

            root.json_data = data
            root.mode = data.mode || "default"

            if (root.path !== "")
                console.log("[MatugenService] reloaded, mode:", root.mode)
        } catch (e) {
            console.error("[MatugenService] parse error:", e)
        }
    }

    function get_color(name) {
        const c = json_data.colors?.[name]
        if (!c)
            return "#808080"

        return c[mode]?.color
            ?? c.default?.color
            ?? "#808080"
    }

    property color background: get_color("background")
    property color error: get_color("error")
    property color error_container: get_color("error_container")
    property color inverse_on_surface: get_color("inverse_on_surface")
    property color inverse_primary: get_color("inverse_primary")
    property color inverse_surface: get_color("inverse_surface")
    property color on_background: get_color("on_background")
    property color on_error: get_color("on_error")
    property color on_error_container: get_color("on_error_container")
    property color on_primary: get_color("on_primary")
    property color on_primary_container: get_color("on_primary_container")
    property color on_primary_fixed: get_color("on_primary_fixed")
    property color on_primary_fixed_variant: get_color("on_primary_fixed_variant")
    property color on_secondary: get_color("on_secondary")
    property color on_secondary_container: get_color("on_secondary_container")
    property color on_secondary_fixed: get_color("on_secondary_fixed")
    property color on_secondary_fixed_variant: get_color("on_secondary_fixed_variant")
    property color on_surface: get_color("on_surface")
    property color on_surface_variant: get_color("on_surface_variant")
    property color on_tertiary: get_color("on_tertiary")
    property color on_tertiary_container: get_color("on_tertiary_container")
    property color on_tertiary_fixed: get_color("on_tertiary_fixed")
    property color on_tertiary_fixed_variant: get_color("on_tertiary_fixed_variant")
    property color outline: get_color("outline")
    property color outline_variant: get_color("outline_variant")
    property color primary: get_color("primary")
    property color primary_container: get_color("primary_container")
    property color primary_fixed: get_color("primary_fixed")
    property color primary_fixed_dim: get_color("primary_fixed_dim")
    property color secondary: get_color("secondary")
    property color secondary_container: get_color("secondary_container")
    property color secondary_fixed: get_color("secondary_fixed")
    property color secondary_fixed_dim: get_color("secondary_fixed_dim")
    property color tertiary: get_color("tertiary")
    property color tertiary_container: get_color("tertiary_container")
    property color tertiary_fixed: get_color("tertiary_fixed")
    property color tertiary_fixed_dim: get_color("tertiary_fixed_dim")
    property color surface: get_color("surface")
    property color surface_bright: get_color("surface_bright")
    property color surface_dim: get_color("surface_dim")
    property color surface_tint: get_color("surface_tint")
    property color surface_variant: get_color("surface_variant")
    property color surface_container: get_color("surface_container")
    property color surface_container_lowest: get_color("surface_container_lowest")
    property color surface_container_low: get_color("surface_container_low")
    property color surface_container_high: get_color("surface_container_high")
    property color surface_container_highest: get_color("surface_container_highest")
    property color scrim: get_color("scrim")
    property color shadow: get_color("shadow")
}
