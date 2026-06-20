//@ pragma DropExpensiveFonts
//@ pragma ShellId quickshell-eli

import Quickshell
import Quickshell.Wayland
import QtQuick

import "./Modules/Bar" as Bar
import "./Modules/Sidebar" as Sidebar
import "./Modules/Launcher" as Launcher
import "./Modules/Osd" as Osd
import "./Modules/Notifications" as Notifications
import "./Modules/PowerMenu" as PowerMenu
import "./Modules/Screenshot" as Screenshot
import "./Services" as Services
import "./Components" as Components


ShellRoot {
    FontLoader {
        id: material_symbols_font
        source: "./Assets/Fonts/MaterialSymbols.ttf"
    }


    // Design Tokens
    readonly property int token_spacing_none: 0
    readonly property int token_spacing_xs: 4
    readonly property int token_spacing_sm: 8
    readonly property int token_spacing_md: 16
    readonly property int token_spacing_lg: 24
    readonly property int token_spacing_xl: 32
    readonly property int token_spacing_2xl: 48

    readonly property int token_radius_none: 0
    readonly property int token_radius_sm: 4
    readonly property int token_radius_md: 12
    readonly property int token_radius_lg: 16
    readonly property int token_radius_full: 999 

    readonly property var token_typography_font_head: "Roboto"
    readonly property var token_typography_font: "Roboto"
    readonly property var token_typography_icon_font: material_symbols_font.font.family
    readonly property font token_typography_display: Qt.font({ family: token_typography_font_head, pointSize: 45, weight: Font.Medium })
    readonly property font token_typography_headline: Qt.font({ family: token_typography_font_head, pointSize: 24, weight: Font.Medium })
    readonly property font token_typography_body: Qt.font({ family: token_typography_font, pointSize: 12, weight: Font.Normal })
    readonly property font token_typography_icon: Qt.font({ family: token_typography_icon_font, pointSize: 10, weight: Font.Normal })
    readonly property font token_typography_icon_large: Qt.font({ family: token_typography_icon_font, pointSize: 20, weight: Font.Bold })

    readonly property int token_motion_duration_short: 150
    readonly property int token_motion_duration_medium: 250
    readonly property int token_motion_duration_long: 400

    readonly property var token_motion_curve_standard: [0.25, 0.1, 0.25, 1]
    readonly property var token_motion_curve_emphasis: [0.22, 1, 0.36, 1]
    readonly property var token_motion_curve_subtle: [0.2, 0, 0.2, 1]
    readonly property var token_motion_curve_linear: [0.5, 0, 0.5, 1]
    readonly property var token_motion_curve_express: [0.2, 0.8, 0.2, 1]

    readonly property var services: Services
    readonly property var components: Components

    // Config
    readonly property bool config_debug_mode: false
    readonly property int config_low_battery_threshold: 20
    readonly property string config_web_search_prefix: "?"

    Bar.Main      { id: bar }
    Sidebar.Main  { id: sidebar}
    Launcher.Main { id: launcher }
    Osd.Main      { id: osd }
    Notifications.Main { id: notifications }
    PowerMenu.Main     { id: power_menu }
    Screenshot.Main    { id: screenshot }
}
