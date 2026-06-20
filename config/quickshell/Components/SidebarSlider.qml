import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: root

    property string icon: ""
    property real slider_value: 0
    property color icon_color: services.MatugenService.primary
    property color track_color: services.MatugenService.primary
    property color bg_color: services.MatugenService.surface

    signal valueChanged(real value)

    color: bg_color
    height: token_spacing_xl + token_spacing_sm
    radius: token_radius_md

    Behavior on color {
        ColorAnimation { duration: token_motion_duration_short }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: token_spacing_sm
        spacing: token_spacing_sm

        IconText {
            icon_text: root.icon
            icon_color: root.icon_color
            large: true
        }

        Slider {
            id: slider
            Layout.fillWidth: true
            from: 0.0
            to: 1.0
            value: root.slider_value
            live: true
            onMoved: root.valueChanged(value)

            background: Rectangle {
                x: slider.leftPadding
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                width: slider.availableWidth
                height: token_spacing_xs
                radius: token_spacing_xs / 2
                color: root.bg_color

                Rectangle {
                    width: slider.visualPosition * parent.width
                    height: parent.height
                    color: root.track_color
                    radius: token_spacing_xs / 2
                }
            }

            handle: Rectangle {
                x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                width: token_spacing_md
                height: token_spacing_md
                radius: token_spacing_sm
                color: root.track_color
            }
        }

        Text {
            text: Math.round(root.slider_value * 100)
            font: token_typography_body
            color: root.icon_color
            Layout.minimumWidth: 30
            horizontalAlignment: Text.AlignRight
        }
    }
}
