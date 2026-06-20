import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../../../Components" as Components

PanelWindow {
    anchors {
        top: true
    }

    margins {
        top: token_spacing_sm
    }

    IpcHandler {
        target: "systemresourcepopup"

        function reloadall() {
            cpu.repaint()
            memory.repaint()
            swap_pie.repaint()
            disk_pie.repaint()
        }
    }

    implicitWidth: rootlayout.width + token_spacing_xl
    implicitHeight: 64 + token_spacing_md * 3
    color: "transparent"
    exclusionMode: ExclusionMode.Normal

    Rectangle {
        anchors.fill: parent
        radius: token_radius_full
        color: services.MatugenService.background
        RowLayout {
            id: rootlayout
            spacing: token_spacing_sm
            anchors.margins: token_spacing_sm
            anchors.centerIn: parent

            Components.SystemResourcePie {
                id: cpu
                value: services.SystemResourceService.cpu
                icon: "planner_review"
                show_label: true
                chart_size: 64
            }

            Components.SystemResourcePie {
                id: memory
                value: services.SystemResourceService.memory
                icon: "memory"
                show_label: true
                chart_size: 64
            }

            Components.SystemResourcePie {
                id: swap_pie
                value: services.SystemResourceService.swap
                icon: "swap_horiz"
                show_label: true
                chart_size: 64
            }

            Components.SystemResourcePie {
                id: disk_pie
                value: services.SystemResourceService.disk
                icon: "storage"
                show_label: true
                chart_size: 64
            }
        }
    }
}
