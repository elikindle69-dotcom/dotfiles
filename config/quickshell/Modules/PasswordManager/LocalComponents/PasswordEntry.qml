import QtQuick
import QtQuick.Layouts
import "../../../Components" as Components

Rectangle {
    id: root

    property var entry: null
    property bool isSelected: false

    signal clicked()

    height: token_spacing_xl * 4
    radius: token_radius_sm
    color: isSelected ? services.MatugenService.primary_container : services.MatugenService.surface_container
    border.width: isSelected ? 1 : 0
    border.color: services.MatugenService.primary

    Behavior on color {
        ColorAnimation { duration: token_motion_duration_short }
    }

    Behavior on scale {
        NumberAnimation {
            duration: token_motion_duration_short
            easing.type: Easing.Bezier
            easing.bezierCurve: token_motion_curve_emphasis
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: token_spacing_sm
        spacing: token_spacing_sm

        // Category dot
        Rectangle {
            width: 8
            height: 8
            radius: 4
            color: _getCategoryColor(root.entry ? root.entry.category : "other")
        }

        // Info
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: root.entry ? root.entry.name : ""
                color: isSelected ? services.MatugenService.on_primary_container : services.MatugenService.on_surface
                font: Qt.font({ family: token_typography_body.family, pointSize: token_typography_body.pointSize, weight: Font.Bold })
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: root.entry ? root.entry.username : ""
                color: isSelected ? services.MatugenService.on_primary_container : services.MatugenService.on_surface_variant
                font: token_typography_body
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        // URL domain
        Text {
            text: _getDomain(root.entry ? root.entry.url : "")
            color: services.MatugenService.on_surface_variant
            font: Qt.font({ family: token_typography_body.family, pointSize: token_typography_body.pointSize * 0.85 })
            visible: text.length > 0
            elide: Text.ElideRight
            Layout.maximumWidth: token_spacing_xl * 8
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true

        onEntered: root.scale = 0.98
        onExited: root.scale = 1.0
        onClicked: root.clicked()
    }

    function _getDomain(url) {
        if (!url) return ""
        try {
            const u = url.replace(/^https?:\/\//, "")
            return u.split("/")[0]
        } catch (e) {
            return url
        }
    }

    function _getCategoryColor(category) {
        switch (category) {
        case "dev": return services.MatugenService.primary
        case "social": return services.MatugenService.tertiary
        case "finance": return services.MatugenService.secondary
        case "email": return services.MatugenService.error
        default: return services.MatugenService.on_surface_variant
        }
    }
}
