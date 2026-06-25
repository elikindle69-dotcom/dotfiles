import QtQuick
import QtQuick.Layouts
import "../../../Components" as Components

ColumnLayout {
    id: root

    signal unlockAttempt(string password)

    property string _password: ""
    property bool _showPassword: false
    property bool _shaking: false

    spacing: token_spacing_md

    Components.IconText {
        icon_text: "lock"
        icon_color: services.MatugenService.primary
        large: true
        Layout.alignment: Qt.AlignHCenter
    }

    Text {
        text: "Enter your master password to unlock"
        color: services.MatugenService.on_surface_variant
        font: token_typography_body
        Layout.alignment: Qt.AlignHCenter
    }

    Item {
        Layout.fillWidth: true
        height: token_spacing_xl * 3

        x: root._shaking ? token_spacing_sm : 0

        Behavior on x {
            SequentialAnimation {
                NumberAnimation { to: token_spacing_sm; duration: 50 }
                NumberAnimation { to: -token_spacing_sm; duration: 50 }
                NumberAnimation { to: token_spacing_sm / 2; duration: 50 }
                NumberAnimation { to: 0; duration: 50 }
            }
        }

        Rectangle {
            anchors.fill: parent
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
                    enabled: !root._shaking

                    onTextChanged: root._password = text

                    Keys.onReturnPressed: _doUnlock()
                    Keys.onEnterPressed: _doUnlock()

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
    }

    Rectangle {
        Layout.fillWidth: true
        height: token_spacing_xl * 3
        radius: token_radius_md
        color: root._password.length >= 12 ? services.MatugenService.primary : services.MatugenService.surface_container_highest

        Text {
            anchors.centerIn: parent
            text: "Unlock"
            color: root._password.length >= 12 ? services.MatugenService.on_primary : services.MatugenService.on_surface_variant
            font: token_typography_body
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: root._password.length >= 12 ? Qt.PointingHandCursor : Qt.ArrowCursor
            enabled: root._password.length >= 12 && !root._shaking
            onClicked: _doUnlock()
        }
    }

    function _doUnlock() {
        if (root._password.length < 12 || root._shaking) return
        root._shaking = false
        root.unlockAttempt(root._password)
    }

    Connections {
        target: services.CryptoService

        function onUnlockFailed(reason) {
            root._shaking = true
            shakeTimer.start()
        }
    }

    Timer {
        id: shakeTimer
        interval: 300
        onTriggered: root._shaking = false
    }
}
