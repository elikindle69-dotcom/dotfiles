import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../../Components" as Components

PanelWindow {
    id: osd_root

    anchors {
        bottom: true
    }

    margins {
        bottom: token_spacing_xl * 3
    }

    implicitHeight: token_spacing_xl * 2
    implicitWidth: token_spacing_xl * 8
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: is_visible

    property int osd_value: 0
    property int osd_interval: 3000
    property string osd_type: "volume"
    property bool is_visible: false

    Timer {
        id: hide_timer
        interval: osd_interval
        repeat: false
        onTriggered: is_visible = false
    }

    function restart_timer() {
        hide_timer.stop()
        hide_timer.start()
    }

    IpcHandler {
        target: "osd"

        function osd(value: int, interval: int) {
            osd_interval = interval
            osd_value = value
            is_visible = true
            restart_timer()
        }

        function hide() {
            is_visible = false
        }
    }

    Connections {
        target: services.AudioService

        function onPercentageChanged() {
            osd_type = "volume"
            osd_value = services.AudioService.percentage
            is_visible = true
            restart_timer()
        }

        function onMutedChanged() {
            osd_type = "volume"
            osd_value = 0
            is_visible = true
            restart_timer()
        }
    }

    Connections {
        target: services.BrightService

        function onScreen_brightChanged() {
            osd_type = "brightness"
            osd_value = Math.round(
                services.BrightService.screen_bright * 100
            )
            is_visible = true
            restart_timer()
        }
    }

    Rectangle {
        id: osd_content
        anchors.fill: parent
        color: services.MatugenService.background
        radius: token_radius_lg

        opacity: is_visible ? 1 : 0
        y: is_visible ? 0 : token_spacing_xl

        Behavior on opacity {
            NumberAnimation { duration: token_motion_duration_short; easing.type: Easing.Bezier; easing.bezierCurve: token_motion_curve_subtle }
        }

        Behavior on y {
            NumberAnimation { duration: token_motion_duration_short; easing.type: Easing.Bezier; easing.bezierCurve: token_motion_curve_subtle }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: token_spacing_md

            Components.ProgressBar {
                id: control
                value: osd_value / 100
                track_color: services.MatugenService.inverse_primary
                implicitHeight: token_spacing_md
                implicitWidth: token_spacing_xl * 6
            }

            Text {
                text: osd_value
                color: services.MatugenService.primary
            }
        }
    }
}
