import Quickshell
import QtQuick
import "../../Components" as Components

Components.Pill {
    id: root

    pill_color: services.MatugenService.inverse_primary

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    property string time: Qt.formatDateTime(clock.date, "hh:mm ap")

    width: _label.implicitWidth + horizontal_padding * 2
    height: token_spacing_lg

    Components.IconText {
        id: _label
        anchors.centerIn: parent
        icon_text: root.time
        icon_color: services.MatugenService.primary
        font: token_typography_body
    }
}
