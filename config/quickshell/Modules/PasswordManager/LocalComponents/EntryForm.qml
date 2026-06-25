import QtQuick
import QtQuick.Layouts
import "../../../Components" as Components

ColumnLayout {
    id: root

    property string entryId: ""
    property var entry: null
    property bool isEditing: entryId.length > 0

    signal saved()
    signal cancelled()

    spacing: token_spacing_sm

    Component.onCompleted: _loadEntry()
    onEntryIdChanged: _loadEntry()

    property string _name: ""
    property string _username: ""
    property string _password: ""
    property string _url: ""
    property string _notes: ""
    property string _category: "other"
    property bool _showPassword: false

    function _loadEntry() {
        if (isEditing) {
            entry = services.VaultService.getEntry(entryId)
            if (entry) {
                _name = entry.name
                _username = entry.username
                _password = entry.password
                _url = entry.url
                _notes = entry.notes
                _category = entry.category
            }
        } else {
            entry = null
            _name = ""
            _username = ""
            _password = ""
            _url = ""
            _notes = ""
            _category = "other"
        }
    }

    // Name
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        Text {
            text: "Name *"
            color: services.MatugenService.on_surface_variant
            font: Qt.font({ family: token_typography_body.family, pointSize: token_typography_body.pointSize * 0.85 })
        }

        Rectangle {
            Layout.fillWidth: true
            height: token_spacing_xl * 3
            radius: token_radius_sm
            color: services.MatugenService.surface_container_high
            border.width: nameInput.activeFocus ? 2 : 1
            border.color: nameInput.activeFocus ? services.MatugenService.primary : services.MatugenService.outline

            TextInput {
                id: nameInput
                anchors.fill: parent
                anchors.margins: token_spacing_sm
                color: services.MatugenService.on_surface
                font: token_typography_body
                verticalAlignment: Text.AlignVCenter
                selectByMouse: true
                text: root._name

                onTextChanged: root._name = text

                Text {
                    text: "e.g. GitHub"
                    font: parent.font
                    visible: parent.text.length === 0 && !parent.activeFocus
                    anchors.verticalCenter: parent.verticalCenter
                    color: services.MatugenService.on_surface_variant
                }
            }
        }
    }

    // Username
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        Text {
            text: "Username"
            color: services.MatugenService.on_surface_variant
            font: Qt.font({ family: token_typography_body.family, pointSize: token_typography_body.pointSize * 0.85 })
        }

        Rectangle {
            Layout.fillWidth: true
            height: token_spacing_xl * 3
            radius: token_radius_sm
            color: services.MatugenService.surface_container_high
            border.width: usernameInput.activeFocus ? 2 : 1
            border.color: usernameInput.activeFocus ? services.MatugenService.primary : services.MatugenService.outline

            TextInput {
                id: usernameInput
                anchors.fill: parent
                anchors.margins: token_spacing_sm
                color: services.MatugenService.on_surface
                font: token_typography_body
                verticalAlignment: Text.AlignVCenter
                selectByMouse: true
                text: root._username

                onTextChanged: root._username = text

                Text {
                    text: "e.g. eli"
                    font: parent.font
                    visible: parent.text.length === 0 && !parent.activeFocus
                    anchors.verticalCenter: parent.verticalCenter
                    color: services.MatugenService.on_surface_variant
                }
            }
        }
    }

    // Password
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        Text {
            text: "Password *"
            color: services.MatugenService.on_surface_variant
            font: Qt.font({ family: token_typography_body.family, pointSize: token_typography_body.pointSize * 0.85 })
        }

        Rectangle {
            Layout.fillWidth: true
            height: token_spacing_xl * 3
            radius: token_radius_sm
            color: services.MatugenService.surface_container_high
            border.width: passwordInput.activeFocus ? 2 : 1
            border.color: passwordInput.activeFocus ? services.MatugenService.primary : services.MatugenService.outline

            RowLayout {
                anchors.fill: parent
                anchors.margins: token_spacing_sm
                spacing: token_spacing_sm

                TextInput {
                    id: passwordInput
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    echoMode: root._showPassword ? TextInput.Normal : TextInput.Password
                    color: services.MatugenService.on_surface
                    font: token_typography_body
                    verticalAlignment: Text.AlignVCenter
                    selectByMouse: true
                    text: root._password

                    onTextChanged: root._password = text

                    Text {
                        text: "Enter password"
                        font: parent.font
                        visible: parent.text.length === 0 && !parent.activeFocus
                        anchors.verticalCenter: parent.verticalCenter
                        color: services.MatugenService.on_surface_variant
                    }
                }

                Components.IconText {
                    icon_text: root._showPassword ? "visibility_off" : "visibility"
                    icon_color: services.MatugenService.on_surface_variant
                    width: 16
                    height: 16

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root._showPassword = !root._showPassword
                    }
                }

                Components.IconText {
                    icon_text: "casino"
                    icon_color: services.MatugenService.primary
                    width: 16
                    height: 16

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            services.CryptoService.generatePassword(20, function(pw) {
                                root._password = pw
                                root._showPassword = true
                            })
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

        Text {
            text: "URL"
            color: services.MatugenService.on_surface_variant
            font: Qt.font({ family: token_typography_body.family, pointSize: token_typography_body.pointSize * 0.85 })
        }

        Rectangle {
            Layout.fillWidth: true
            height: token_spacing_xl * 3
            radius: token_radius_sm
            color: services.MatugenService.surface_container_high
            border.width: urlInput.activeFocus ? 2 : 1
            border.color: urlInput.activeFocus ? services.MatugenService.primary : services.MatugenService.outline

            TextInput {
                id: urlInput
                anchors.fill: parent
                anchors.margins: token_spacing_sm
                color: services.MatugenService.on_surface
                font: token_typography_body
                verticalAlignment: Text.AlignVCenter
                selectByMouse: true
                text: root._url

                onTextChanged: root._url = text

                Text {
                    text: "e.g. https://github.com"
                    font: parent.font
                    visible: parent.text.length === 0 && !parent.activeFocus
                    anchors.verticalCenter: parent.verticalCenter
                    color: services.MatugenService.on_surface_variant
                }
            }
        }
    }

    // Category
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        Text {
            text: "Category"
            color: services.MatugenService.on_surface_variant
            font: Qt.font({ family: token_typography_body.family, pointSize: token_typography_body.pointSize * 0.85 })
        }

        Flow {
            Layout.fillWidth: true
            spacing: token_spacing_xs

            Repeater {
                model: services.VaultService.categoryList.filter(function(c) { return c !== "all" })

                Rectangle {
                    width: catLabel.implicitWidth + token_spacing_md * 2
                    height: token_spacing_xl * 2
                    radius: token_radius_full
                    color: root._category === modelData
                        ? services.MatugenService.primary
                        : services.MatugenService.surface_container

                    Text {
                        id: catLabel
                        anchors.centerIn: parent
                        text: modelData
                        color: root._category === modelData
                            ? services.MatugenService.on_primary
                            : services.MatugenService.on_surface
                        font: token_typography_body
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root._category = modelData
                    }
                }
            }
        }
    }

    // Notes
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        Text {
            text: "Notes"
            color: services.MatugenService.on_surface_variant
            font: Qt.font({ family: token_typography_body.family, pointSize: token_typography_body.pointSize * 0.85 })
        }

        Rectangle {
            Layout.fillWidth: true
            height: token_spacing_xl * 5
            radius: token_radius_sm
            color: services.MatugenService.surface_container_high
            border.width: notesInput.activeFocus ? 2 : 1
            border.color: notesInput.activeFocus ? services.MatugenService.primary : services.MatugenService.outline

            TextInput {
                id: notesInput
                anchors.fill: parent
                anchors.margins: token_spacing_sm
                color: services.MatugenService.on_surface
                font: token_typography_body
                selectByMouse: true
                wrapMode: TextInput.Wrap
                text: root._notes

                onTextChanged: root._notes = text

                Text {
                    text: "Additional notes..."
                    font: parent.font
                    visible: parent.text.length === 0 && !parent.activeFocus
                    anchors.top: parent.top
                    color: services.MatugenService.on_surface_variant
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: services.MatugenService.outline_variant
    }

    // Buttons
    RowLayout {
        Layout.fillWidth: true
        spacing: token_spacing_md

        Rectangle {
            Layout.fillWidth: true
            height: token_spacing_xl * 3
            radius: token_radius_md
            color: services.MatugenService.surface_container

            Text {
                anchors.centerIn: parent
                text: "Cancel"
                color: services.MatugenService.on_surface
                font: token_typography_body
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.cancelled()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: token_spacing_xl * 3
            radius: token_radius_md
            color: root._canSave() ? services.MatugenService.primary : services.MatugenService.surface_container_highest

            Text {
                anchors.centerIn: parent
                text: root.isEditing ? "Update" : "Save"
                color: root._canSave() ? services.MatugenService.on_primary : services.MatugenService.on_surface_variant
                font: token_typography_body
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: root._canSave() ? Qt.PointingHandCursor : Qt.ArrowCursor
                enabled: root._canSave()
                onClicked: _doSave()
            }
        }
    }

    function _canSave() {
        return root._name.length > 0 && root._password.length > 0
    }

    function _doSave() {
        if (root.isEditing && root.entryId) {
            services.VaultService.updateEntry(root.entryId, {
                name: root._name,
                username: root._username,
                password: root._password,
                url: root._url,
                notes: root._notes,
                category: root._category
            })
        } else {
            services.VaultService.addEntry(
                root._name,
                root._username,
                root._password,
                root._url,
                root._notes,
                root._category
            )
        }
        root.saved()
    }
}
