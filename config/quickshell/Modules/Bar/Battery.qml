import QtQuick
import "../../Components" as Components

Components.Pill {
    id: root

    pill_color: services.BatteryService.is_low
        ? services.MatugenService.error_container
        : services.MatugenService.inverse_primary

    width: _label.implicitWidth + horizontal_padding * 2
    height: token_spacing_lg

    Components.IconText {
        id: _label
        anchors.centerIn: parent
        icon_text: services.BatteryService.state_label
        icon_color: services.MatugenService.primary
        font: token_typography_body
    }
}
