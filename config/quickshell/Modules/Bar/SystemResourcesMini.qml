import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../../Components" as Components

Components.Pill {
    id: root

    pill_color: services.MatugenService.inverse_primary

    width: _layout.implicitWidth + horizontal_padding * 2
    height: token_spacing_lg

    IpcHandler {
        target: "bar/systemresourcemini"

        function reloadall() {
            cpu.repaint()
            memory.repaint()
            swap_pie.repaint()
            disk_pie.repaint()
        }
    }

    RowLayout {
        id: _layout
        anchors.centerIn: parent

        Components.SystemResourcePie {
            id: cpu
            value: services.SystemResourceService.cpu
            icon: "planner_review"
        }

        Components.SystemResourcePie {
            id: memory
            value: services.SystemResourceService.memory
            icon: "memory"
        }

        Components.SystemResourcePie {
            id: swap_pie
            value: services.SystemResourceService.swap
            icon: "swap_horiz"
        }

        Components.SystemResourcePie {
            id: disk_pie
            value: services.SystemResourceService.disk
            icon: "storage"
        }
    }
}
