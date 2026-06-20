import QtQuick

Rectangle {
    id: root

    property color pill_color: "transparent"
    property int horizontal_padding: token_spacing_md

    color: pill_color
    radius: token_radius_full
}
