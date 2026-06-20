pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property list<MprisPlayer> available_players: Mpris.players.values
    property MprisPlayer active_player: null
    property real active_player_stable_length: 0

    readonly property string app_icon_name: {
        if (!active_player) return ""
        const de = active_player.desktopEntry
        if (de && de.length > 0) return de
        return active_player.identity || ""
    }

    Connections {
        target: root.active_player
        function onTrackTitleChanged() {
            root.active_player_stable_length = (root.active_player && root.active_player.lengthSupported && root.active_player.length > 1) ? root.active_player.length : 0
            if (root.is_idle(root.active_player))
                root._resolve_active_player()
        }
        function onTrackArtistChanged() {
            if (root.is_idle(root.active_player))
                root._resolve_active_player()
        }
        function onLengthChanged() {
            if (root.active_player && root.active_player.lengthSupported && root.active_player.length > 1) {
                root.active_player_stable_length = root.active_player.length
            }
        }
        function onPlaybackStateChanged() {
            if (root.is_idle(root.active_player))
                root._resolve_active_player()
        }
    }

    onActive_playerChanged: {
        active_player_stable_length = (active_player && active_player.lengthSupported && active_player.length > 1) ? active_player.length : 0
    }

    onAvailable_playersChanged: _resolve_active_player()
    Component.onCompleted: _resolve_active_player()

    Instantiator {
        model: root.available_players
        delegate: Connections {
            required property MprisPlayer modelData
            target: modelData
            function onIsPlayingChanged() {
                if (modelData.isPlaying)
                    root._resolve_active_player()
            }
        }
    }

    function is_idle(player: MprisPlayer): bool {
        return player
            && player.playbackState === MprisPlaybackState.Stopped
            && !player.trackTitle
            && !player.trackArtist
    }

    function _resolve_active_player(): void {
        const playing = available_players.find(p => p.isPlaying)
        if (playing) {
            active_player = playing
            console.log("[MprisService] active player:", playing.identity, "-", playing.trackTitle, "-", playing.trackArtist)
            return
        }
        if (active_player && available_players.indexOf(active_player) >= 0 && !is_idle(active_player))
            return

        active_player = available_players.find(p => p.canControl && !is_idle(p)) ?? null
        console.log("[MprisService] fallback player:", active_player?.identity ?? "none", "-", active_player?.trackTitle ?? "", "-", active_player?.trackArtist ?? "")
    }

    Timer {
        interval: 1000
        running: root.active_player?.playbackState === MprisPlaybackState.Playing
        repeat: true
        onTriggered: root.active_player?.positionChanged()
    }
}
