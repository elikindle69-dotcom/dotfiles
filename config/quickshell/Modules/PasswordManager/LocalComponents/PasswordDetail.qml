import QtQuick
import QtQuick.Layouts
import "../../../Components" as Components

ColumnLayout {
    id: root

    property string entryId: ""
    property var entry: null

    signal back()
    signal edit()
    signal copied(string text, string field)
    signal deleted(string id)

    spacing: token_spacing_sm

    Component.onCompleted: _loadEntry()
    onEntryIdChanged: _loadEntry()

    function _loadEntry() {
        if (entryId) {
            entry = services.VaultService.getEntry(entryId)
        } else {
            entry = null
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: token_spacing_sm

        Components.IconText {
            icon_text: "arrow_back"
            icon_color: services.MatugenService.primary

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.back()
            }
        }

        Text {
            text: entry ? entry.name : ""
            color: services.MatugenService.on_surface
            font: token_typography_headline
            Layout.fillWidth: true
            elide: Text.ElideRight
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: services.MatugenService.outline_variant
    }

    // Username
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2
        visible: entry !== null && entry.username.length > 0

        Text {
            text: "Username"
            color: services.MatugenService.on_surface_variant
            font: Qt.font({ family: token_typography_body.family, pointSize: token_typography_body.pointSize * 0.85 })
        }

        Rectangle {
            Layout.fillWidth: true
            height: token_spacing_xl * 2.5
            radius: token_radius_sm
            color: services.MatugenService.surface_container_high

            RowLayout {
                anchors.fill: parent
                anchors.margins: token_spacing_sm

                Text {
                    text: entry ? entry.username : ""
                    color: services.MatugenService.on_surface
                    font: token_typography_body
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Components.IconText {
                    icon_text: "content_copy"
                    icon_color: services.MatugenService.on_surface_variant
                    width: 16
                    height: 16

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.entry) root.copied(root.entry.username, "username")
                        }
                    }
                }
            }
        }
    }

    // Password
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2
        visible: entry !== null

        property bool revealed: false

        Text {
            text: "Password"
            color: services.MatugenService.on_surface_variant
            font: Qt.font({ family: token_typography_body.family, pointSize: token_typography_body.pointSize * 0.85 })
        }

        Rectangle {
            Layout.fillWidth: true
            height: token_spacing_xl * 2.5
            radius: token_radius_sm
            color: services.MatugenService.surface_container_high

            RowLayout {
                anchors.fill: parent
                anchors.margins: token_spacing_sm

                Text {
                    text: {
                        if (!entry) return ""
                        if (parent.parent.parent.revealed) return entry.password
                        return "•".repeat(Math.min(entry.password.length, 24))
                    }
                    color: services.MatugenService.on_surface
                    font: token_typography_body
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Components.IconText {
                    icon_text: parent.parent.parent.revealed ? "visibility_off" : "visibility"
                    icon_color: services.MatugenService.on_surface_variant
                    width: 16
                    height: 16

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: parent.parent.parent.parent.parent.revealed = !parent.parent.parent.parent.parent.revealed
                    }
                }

                Components.IconText {
                    icon_text: "content_copy"
                    icon_color: services.MatugenService.on_surface_variant
                    width: 16
                    height: 16

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.entry) root.copied(root.entry.password, "password")
                        }
                    }
                }
            }
        }
    }

    // URL
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2
        visible: entry !== null && entry.url.length > 0

        Text {
            text: "URL"
            color: services.MatugenService.on_surface_variant
            font: Qt.font({ family: token_typography_body.family, pointSize: token_typography_body.pointSize * 0.85 })
        }

        Rectangle {
            Layout.fillWidth: true
            height: token_spacing_xl * 2.5
            radius: token_radius_sm
            color: services.MatugenService.surface_container_high

            RowLayout {
                anchors.fill: parent
                anchors.margins: token_spacing_sm

                Text {
                    text: entry ? entry.url : ""
                    color: services.MatugenService.primary
                    font: token_typography_body
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Components.IconText {
                    icon_text: "content_copy"
                    icon_color: services.MatugenService.on_surface_variant
                    width: 16
                    height: 16

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.entry) root.copied(root.entry.url, "url")
                        }
                    }
                }
            }
        }
    }

    // Category
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2
        visible: entry !== null

        Text {
            text: "Category"
            color: services.MatugenService.on_surface_variant
            font: Qt.font({ family: token_typography_body.family, pointSize: token_typography_body.pointSize * 0.85 })
        }

        Rectangle {
            Layout.fillWidth: true
            height: token_spacing_xl * 2.5
            radius: token_radius_sm
            color: services.MatugenService.surface_container_high

            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: token_spacing_sm
                text: entry ? entry.category : ""
                color: services.MatugenService.on_surface
                font: token_typography_body
            }
        }
    }

    // Notes
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2
        visible: entry !== null && entry.notes.length > 0

        Text {
            text: "Notes"
            color: services.MatugenService.on_surface_variant
            font: Qt.font({ family: token_typography_body.family, pointSize: token_typography_body.pointSize * 0.85 })
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: notesText.implicitHeight + token_spacing_md * 2
            radius: token_radius_sm
            color: services.MatugenService.surface_container_high

            Text {
                id: notesText
                anchors.fill: parent
                anchors.margins: token_spacing_sm
                text: entry ? entry.notes : ""
                color: services.MatugenService.on_surface
                font: token_typography_body
                wrapMode: Text.WordWrap
            }
        }
    }

    // Timestamps
    RowLayout {
        Layout.fillWidth: true
        spacing: token_spacing_md
        visible: entry !== null

        ColumnLayout {
            spacing: 2
            Layout.fillWidth: true

            Text {
                text: "Created"
                color: services.MatugenService.on_surface_variant
                font: Qt.font({ family: token_typography_body.family, pointSize: token_typography_body.pointSize * 0.85 })
            }

            Text {
                text: entry ? _formatDate(entry.created) : ""
                color: services.MatugenService.on_surface
                font: token_typography_body
            }
        }

        ColumnLayout {
            spacing: 2
            Layout.fillWidth: true

            Text {
                text: "Modified"
                color: services.MatugenService.on_surface_variant
                font: Qt.font({ family: token_typography_body.family, pointSize: token_typography_body.pointSize * 0.85 })
            }

            Text {
                text: entry ? _formatDate(entry.modified) : ""
                color: services.MatugenService.on_surface
                font: token_typography_body
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: services.MatugenService.outline_variant
    }

    // Actions
    RowLayout {
        Layout.fillWidth: true
        spacing: token_spacing_md

        Rectangle {
            Layout.fillWidth: true
            height: token_spacing_xl * 3
            radius: token_radius_md
            color: services.MatugenService.primary

            Text {
                anchors.centerIn: parent
                text: "Edit"
                color: services.MatugenService.on_primary
                font: token_typography_body
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.edit()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: token_spacing_xl * 3
            radius: token_radius_md
            color: services.MatugenService.error_container

            Text {
                anchors.centerIn: parent
                text: "Delete"
                color: services.MatugenService.on_error_container
                font: token_typography_body
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.entry) root.deleted(root.entry.id)
                }
            }
        }
    }

    function _formatDate(timestamp) {
        if (!timestamp) return ""
        const d = new Date(timestamp)
        return d.toLocaleDateString() + " " + d.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })
    }
}
