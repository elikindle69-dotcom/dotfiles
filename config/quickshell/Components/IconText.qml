import QtQuick

Text {
    id: root

    property string icon_text: ""
    property color icon_color: services.MatugenService.on_surface
    property bool large: false

    font: large ? token_typography_icon_large : token_typography_icon
    color: icon_color
    text: icon_text
    verticalAlignment: Text.AlignVCenter
}
