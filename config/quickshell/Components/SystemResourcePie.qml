import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property real value: 0
    property string icon: ""
    property bool show_label: false
    property int chart_size: 16

    property color chart_color: services.MatugenService.on_primary_fixed_variant
    property color chart_background: services.MatugenService.background
    property color icon_color: services.MatugenService.primary

    width: chart_size
    height: show_label ? chart_size + token_spacing_xs + token_typography_body.pointSize * 2 : chart_size

    PieChart {
        id: pie
        width: root.chart_size
        height: root.chart_size
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        value: root.value
        color: root.chart_color
        background: root.chart_background

        IconText {
            anchors.centerIn: parent
            icon_text: root.icon
            icon_color: root.icon_color
        }
    }

    Text {
        visible: root.show_label
        font: token_typography_body
        color: root.icon_color
        text: Math.round(root.value * 100) + "%"
        anchors.top: pie.bottom
        anchors.topMargin: token_spacing_xs
        anchors.horizontalCenter: parent.horizontalCenter
    }

    function repaint() {
        pie.repaint()
    }
}
