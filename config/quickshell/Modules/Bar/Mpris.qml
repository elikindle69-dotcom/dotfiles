import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import "../../Components" as Components

Components.Pill {
    id: root

    property MprisPlayer player: services.MprisService.active_player

    pill_color: services.MatugenService.inverse_primary
    visible: player?.trackTitle ?? false

    width: _layout.implicitWidth + horizontal_padding * 2
    height: token_spacing_lg

    RowLayout {
        id: _layout
        anchors.centerIn: parent
        spacing: token_spacing_md

        property string resolved_icon: ""

        Image {
            id: player_icon
            Layout.preferredWidth: token_spacing_lg
            Layout.preferredHeight: token_spacing_lg
            sourceSize: Qt.size(token_spacing_lg, token_spacing_lg)
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            visible: source != ""
            source: _layout.resolved_icon
        }

        Connections {
            target: services.MprisService
            function onApp_icon_nameChanged() {
                _layout.resolved_icon = ""
                const name = services.MprisService.app_icon_name
                if (name.length > 0) {
                    services.IconService.resolve(name, function(path) {
                        _layout.resolved_icon = path
                    })
                }
            }
        }

        Component.onCompleted: {
            const name = services.MprisService.app_icon_name
            if (name.length > 0) {
                services.IconService.resolve(name, function(path) {
                    _layout.resolved_icon = path
                })
            }
        }

        Text {
            text: (player?.trackTitle ?? "") + " - " + (player?.trackArtist ?? "")
            font: token_typography_body
            color: services.MatugenService.primary
        }

        RowLayout {
            Components.IconText {
                icon_text: "skip_previous"
                icon_color: services.MatugenService.primary

                MouseArea {
                    anchors.fill: parent
                    onClicked: player?.previous()
                    cursorShape: Qt.PointingHandCursor
                }
            }

            Components.IconText {
                icon_text: player?.isPlaying ? "pause" : "play_arrow"
                icon_color: services.MatugenService.primary

                MouseArea {
                    anchors.fill: parent
                    onClicked: player.isPlaying = !player?.isPlaying
                    cursorShape: Qt.PointingHandCursor
                }
            }

            Components.IconText {
                icon_text: "skip_next"
                icon_color: services.MatugenService.primary

                MouseArea {
                    anchors.fill: parent
                    onClicked: player?.next()
                    cursorShape: Qt.PointingHandCursor
                }
            }

            Components.ProgressBar {
                id: control
                value: (player && player.length > 0) ? (player.position / parseFloat(player.length)) : 0.0
                implicitHeight: token_spacing_sm
                implicitWidth: 100
            }
        }
    }
}
