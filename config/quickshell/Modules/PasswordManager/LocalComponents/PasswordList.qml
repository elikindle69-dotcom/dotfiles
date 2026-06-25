import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../../Components" as Components

ColumnLayout {
    id: root

    signal entrySelected(string id)
    signal addRequested()

    property string selectedEntryId: ""

    spacing: token_spacing_sm

    // Search bar
    Rectangle {
        Layout.fillWidth: true
        height: token_spacing_xl * 3
        radius: token_radius_sm
        color: services.MatugenService.surface_container_high

        RowLayout {
            anchors.fill: parent
            anchors.margins: token_spacing_sm
            spacing: token_spacing_sm

            Components.IconText {
                icon_text: "search"
                icon_color: services.MatugenService.on_surface_variant
            }

            TextInput {
                id: searchInput
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: services.MatugenService.on_surface
                font: token_typography_body
                verticalAlignment: Text.AlignVCenter
                selectByMouse: true
                focus: true

                onTextChanged: services.VaultService.search(text)

                Text {
                    text: "Search passwords..."
                    font: parent.font
                    visible: parent.text.length === 0 && !parent.activeFocus
                    anchors.verticalCenter: parent.verticalCenter
                    color: services.MatugenService.on_surface_variant
                }
            }

            Components.IconText {
                icon_text: "close"
                icon_color: services.MatugenService.on_surface_variant
                visible: searchInput.text.length > 0

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        searchInput.text = ""
                        services.VaultService.search("")
                    }
                }
            }
        }
    }

    // Category tabs
    ScrollView {
        Layout.fillWidth: true
        height: token_spacing_xl * 2.5
        clip: true

        Row {
            spacing: token_spacing_xs

            Repeater {
                model: services.VaultService.categoryList

                Rectangle {
                    width: categoryLabel.implicitWidth + token_spacing_md * 2
                    height: token_spacing_xl * 2
                    radius: token_radius_full
                    color: services.VaultService.selectedCategory === modelData
                        ? services.MatugenService.primary
                        : services.MatugenService.surface_container

                    Text {
                        id: categoryLabel
                        anchors.centerIn: parent
                        text: modelData
                        color: services.VaultService.selectedCategory === modelData
                            ? services.MatugenService.on_primary
                            : services.MatugenService.on_surface
                        font: token_typography_body
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: services.VaultService.filterByCategory(modelData)
                    }
                }
            }
        }
    }

    // Entry list
    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: token_radius_sm
        color: services.MatugenService.surface_container_low
        clip: true

        ListView {
            id: listView
            anchors.fill: parent
            anchors.margins: token_spacing_xs
            model: services.VaultService.displayEntries
            spacing: token_spacing_xs

            Connections {
                target: services.VaultService

                function onDisplayEntriesChanged() {
                    listView.model = services.VaultService.displayEntries
                }
            }

            delegate: PasswordEntry {
                width: listView.width
                entry: modelData
                isSelected: modelData.id === root.selectedEntryId

                onClicked: root.entrySelected(modelData.id)
            }

            // Empty state
            ColumnLayout {
                anchors.centerIn: parent
                spacing: token_spacing_md
                visible: listView.count === 0

                Components.IconText {
                    icon_text: "key"
                    icon_color: services.MatugenService.on_surface_variant
                    large: true
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: searchInput.text ? "No matching passwords" : "No passwords yet"
                    color: services.MatugenService.on_surface_variant
                    font: token_typography_body
                    Layout.alignment: Qt.AlignHCenter
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: token_spacing_xl * 2.5
                    radius: token_radius_md
                    color: services.MatugenService.primary
                    visible: !searchInput.text

                    Text {
                        anchors.centerIn: parent
                        text: "Add your first password"
                        color: services.MatugenService.on_primary
                        font: token_typography_body
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.addRequested()
                    }
                }
            }
        }
    }

    // Footer
    RowLayout {
        Layout.fillWidth: true
        spacing: token_spacing_sm

        Text {
            text: services.VaultService.displayEntries.length + " entries"
            color: services.MatugenService.on_surface_variant
            font: token_typography_body
        }

        Item { Layout.fillWidth: true }

        Rectangle {
            width: token_spacing_xl * 2
            height: token_spacing_xl * 2
            radius: token_radius_full
            color: services.MatugenService.primary

            Components.IconText {
                anchors.centerIn: parent
                icon_text: "add"
                icon_color: services.MatugenService.on_primary
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.addRequested()
            }
        }
    }
}
