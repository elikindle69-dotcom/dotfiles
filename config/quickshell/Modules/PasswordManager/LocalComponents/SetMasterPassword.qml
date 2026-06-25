import QtQuick
import QtQuick.Layouts
import "../../../Components" as Components

ColumnLayout {
    id: root

    signal passwordCreated()
    signal cancelled()

    property string _password: ""
    property string _confirm: ""
    property bool _showPassword: false

    spacing: token_spacing_md

    Text {
        text: "Choose a strong master password. This will be used to encrypt and decrypt your vault."
        color: services.MatugenService.on_surface_variant
        font: token_typography_body
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }

    // Password field
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

            Components.IconText {
                icon_text: "key"
                icon_color: services.MatugenService.on_surface_variant
            }

            TextInput {
                id: passwordInput
                Layout.fillWidth: true
                Layout.fillHeight: true
                echoMode: root._showPassword ? TextInput.Normal : TextInput.Password
                color: services.MatugenService.on_surface
                font: token_typography_body
                verticalAlignment: Text.AlignVCenter
                selectByMouse: true
                focus: true

                onTextChanged: root._password = text

                Text {
                    text: "Master password"
                    font: parent.font
                    visible: parent.text.length === 0 && !parent.activeFocus
                    anchors.verticalCenter: parent.verticalCenter
                    color: services.MatugenService.on_surface_variant
                }
            }

            Components.IconText {
                icon_text: root._showPassword ? "visibility" : "visibility_off"
                icon_color: services.MatugenService.on_surface_variant

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root._showPassword = !root._showPassword
                }
            }
        }
    }

    // Strength meter
    RowLayout {
        Layout.fillWidth: true
        spacing: token_spacing_sm

        Repeater {
            model: 4

            Rectangle {
                Layout.fillWidth: true
                height: 4
                radius: 2
                color: {
                    const strength = _calcStrength(root._password)
                    if (index >= strength) return services.MatugenService.surface_container_highest
                    if (strength <= 1) return services.MatugenService.error
                    if (strength === 2) return services.MatugenService.tertiary
                    if (strength === 3) return services.MatugenService.primary
                    return services.MatugenService.primary
                }
            }
        }

        Text {
            text: {
                const s = _calcStrength(root._password)
                if (s <= 1) return "Weak"
                if (s === 2) return "Fair"
                if (s === 3) return "Strong"
                return "Very Strong"
            }
            color: services.MatugenService.on_surface_variant
            font: token_typography_body
            visible: root._password.length > 0
        }
    }

    // Confirm field
    Rectangle {
        Layout.fillWidth: true
        height: token_spacing_xl * 3
        radius: token_radius_sm
        color: services.MatugenService.surface_container_high
        border.width: confirmInput.activeFocus ? 2 : 1
        border.color: {
            if (confirmInput.activeFocus) return services.MatugenService.primary
            if (root._confirm.length > 0 && root._confirm !== root._password) return services.MatugenService.error
            return services.MatugenService.outline
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: token_spacing_sm
            spacing: token_spacing_sm

            Components.IconText {
                icon_text: "key"
                icon_color: services.MatugenService.on_surface_variant
            }

            TextInput {
                id: confirmInput
                Layout.fillWidth: true
                Layout.fillHeight: true
                echoMode: root._showPassword ? TextInput.Normal : TextInput.Password
                color: services.MatugenService.on_surface
                font: token_typography_body
                verticalAlignment: Text.AlignVCenter
                selectByMouse: true

                onTextChanged: root._confirm = text

                Text {
                    text: "Confirm password"
                    font: parent.font
                    visible: parent.text.length === 0 && !parent.activeFocus
                    anchors.verticalCenter: parent.verticalCenter
                    color: services.MatugenService.on_surface_variant
                }
            }
        }
    }

    Text {
        text: "Passwords do not match"
        color: services.MatugenService.error
        font: token_typography_body
        visible: root._confirm.length > 0 && root._confirm !== root._password
    }

    Text {
        text: "Minimum 12 characters"
        color: services.MatugenService.error
        font: token_typography_body
        visible: root._password.length > 0 && root._password.length < 12
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
            color: _canCreate() ? services.MatugenService.primary : services.MatugenService.surface_container_highest

            Text {
                anchors.centerIn: parent
                text: "Create"
                color: _canCreate() ? services.MatugenService.on_primary : services.MatugenService.on_surface_variant
                font: token_typography_body
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: _canCreate() ? Qt.PointingHandCursor : Qt.ArrowCursor
                enabled: _canCreate()
                onClicked: {
                    services.CryptoService.setMasterPassword(root._password)
                }
            }
        }
    }

    function _canCreate() {
        return root._password.length >= 12 && root._password === root._confirm
    }

    function _calcStrength(pw) {
        if (pw.length === 0) return 0
        let score = 0
        if (pw.length >= 12) score++
        if (pw.length >= 16) score++
        if (/[A-Z]/.test(pw) && /[a-z]/.test(pw)) score++
        if (/[0-9]/.test(pw)) score++
        if (/[^A-Za-z0-9]/.test(pw)) score++
        return Math.min(score, 4)
    }
}
