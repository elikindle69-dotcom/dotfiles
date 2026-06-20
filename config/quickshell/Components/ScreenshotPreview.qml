import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property string screenshot_path: ""
    property int dismiss_timeout: 3000

    signal copyClicked()
    signal saveClicked()
    signal dismiss()

    implicitHeight: content_row.implicitHeight + token_spacing_md * 2
    implicitWidth: content_row.implicitWidth + token_spacing_md * 2
    radius: token_radius_md
    color: services.MatugenService.surface
    border.width: 1
    border.color: services.MatugenService.outline_variant

    Timer {
        id: auto_dismiss_timer
        interval: root.dismiss_timeout
        repeat: false
        onTriggered: root.dismiss()
    }

    function restart_timer() {
        auto_dismiss_timer.stop()
        auto_dismiss_timer.start()
    }

    RowLayout {
        id: content_row
        anchors.fill: parent
        anchors.margins: token_spacing_md
        spacing: token_spacing_sm

        Image {
            id: preview_image
            source: root.screenshot_path
            visible: status === Image.Ready
            Layout.preferredWidth: 160
            Layout.preferredHeight: 90
            fillMode: Image.PreserveAspectCrop
            clip: true
            asynchronous: true

            Rectangle {
                anchors.fill: parent
                color: "transparent"
                radius: token_radius_sm
                border.width: 1
                border.color: services.MatugenService.outline_variant
                visible: parent.status === Image.Ready
            }
        }

        ColumnLayout {
            spacing: token_spacing_xs

            Text {
                text: "Screenshot saved"
                font: token_typography_body
                color: services.MatugenService.on_surface
            }

            Row {
                spacing: token_spacing_sm

                Rectangle {
                    width: copy_label.implicitWidth + token_spacing_md * 2
                    height: token_spacing_xl
                    radius: token_radius_sm
                    color: copy_area.containsMouse
                        ? services.MatugenService.primary
                        : services.MatugenService.primary_container

                    Text {
                        id: copy_label
                        anchors.centerIn: parent
                        text: "copy"
                        font: token_typography_icon
                        color: services.MatugenService.on_primary_container
                    }

                    MouseArea {
                        id: copy_area
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: root.copyClicked()
                    }
                }

                Rectangle {
                    width: save_label.implicitWidth + token_spacing_md * 2
                    height: token_spacing_xl
                    radius: token_radius_sm
                    color: save_area.containsMouse
                        ? services.MatugenService.secondary
                        : services.MatugenService.secondary_container

                    Text {
                        id: save_label
                        anchors.centerIn: parent
                        text: "save"
                        font: token_typography_icon
                        color: services.MatugenService.on_secondary_container
                    }

                    MouseArea {
                        id: save_area
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: root.saveClicked()
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: restart_timer()
    }
}
