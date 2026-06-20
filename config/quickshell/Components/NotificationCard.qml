import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property var notification_entry: null
    property bool is_hovered: hover_area.containsMouse
    property real drag_offset: 0
    property string app_icon_path: ""

    signal dismiss()
    signal purge()
    signal actionInvoked(string action_identifier)

    Layout.maximumWidth: 1000
    Layout.fillWidth: true
    implicitHeight: card_col.implicitHeight + token_spacing_md * 2
    radius: token_radius_md
    color: services.MatugenService.surface

    border.width: 1
    border.color: services.MatugenService.outline_variant

    opacity: 1 - Math.min(drag_offset / (width * 0.5), 1)

    Behavior on opacity {
        NumberAnimation { duration: token_motion_duration_short }
    }

    x: drag_offset

    Component.onCompleted: {
        const icon = notification_entry?.app_icon || ""
        if (icon.length > 0) {
            services.IconService.resolve(icon, function(path) {
                root.app_icon_path = path
            })
        }
    }

    Connections {
        target: services.IconService
        function onIconResolved(name, path) {
            const icon = root.notification_entry?.app_icon || ""
            if (name === icon || icon === name) {
                root.app_icon_path = path
            }
        }
    }

    RowLayout {
        id: card_col
        anchors.fill: parent
        anchors.margins: token_spacing_md
        spacing: token_spacing_sm

        Image {
            source: root.app_icon_path
            visible: source != ""
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            Layout.alignment: Qt.AlignTop
            sourceSize: Qt.size(32, 32)
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            layer.enabled: true
        }

        Image {
            source: root.notification_entry?.image ?? ""
            visible: source != ""
            Layout.preferredWidth: 120
            Layout.preferredHeight: 120
            Layout.maximumWidth: 120
            Layout.maximumHeight: 120
            Layout.alignment: Qt.AlignTop
            fillMode: Image.PreserveAspectCrop
            clip: true
            asynchronous: true
            layer.enabled: true

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
            Layout.fillWidth: true
            spacing: token_spacing_xs

            Text {
                text: root.notification_entry?.summary || ""
                font: token_typography_headline
                wrapMode: Text.WordWrap
                color: services.MatugenService.on_surface
                Layout.fillWidth: true
            }

            Text {
                text: root.notification_entry?.body || ""
                font: token_typography_body
                wrapMode: Text.WordWrap
                color: services.MatugenService.on_surface_variant
                Layout.fillWidth: true
                visible: text.length > 0
            }

            Row {
                spacing: token_spacing_sm
                visible: root.notification_entry?.actions?.length > 0

                Repeater {
                    model: root.notification_entry?.actions ?? []

                    Rectangle {
                        width: action_label.implicitWidth + token_spacing_md * 2
                        height: token_spacing_xl
                        radius: token_radius_sm
                        color: services.MatugenService.primary_container

                        Text {
                            id: action_label
                            anchors.centerIn: parent
                            text: modelData.text
                            font: token_typography_body
                            color: services.MatugenService.on_primary_container
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.actionInvoked(modelData.identifier)
                        }
                    }
                }
            }
        }

        MouseArea {
            Layout.preferredWidth: token_spacing_lg
            Layout.fillHeight: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.purge()

            Text {
                anchors.centerIn: parent
                text: "close"
                font: token_typography_icon
                color: services.MatugenService.on_surface_variant
            }
        }
    }

    MouseArea {
        id: hover_area
        anchors.fill: parent
        hoverEnabled: true
        preventStealing: true

        property real press_x: 0
        property bool dragging: false

        onPressed: (mouse) => {
            press_x = mouse.x
            dragging = false
        }

        onPositionChanged: (mouse) => {
            if (pressed) {
                const dx = mouse.x - press_x
                if (Math.abs(dx) > 5) {
                    dragging = true
                }
                if (dragging && dx > 0) {
                    root.drag_offset = dx
                }
            }
        }

        onReleased: {
            if (root.drag_offset > root.width * 0.1) {
                root.purge()
            } else {
                root.drag_offset = 0
            }
            dragging = false
        }

        onCanceled: {
            root.drag_offset = 0
            dragging = false
        }
    }
}
