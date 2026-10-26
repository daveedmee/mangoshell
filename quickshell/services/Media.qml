pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import ".."

Singleton {
    id: root

    readonly property var player: {
        const players = Mpris.players.values;
        for (let i = 0; i < players.length; i++) {
            if (players[i] && players[i].isPlaying)
                return players[i];
        }
        return players.length > 0 ? players[0] : null;
    }

    readonly property bool available: player !== null
    readonly property bool isPlaying: player ? player.isPlaying : false
    readonly property string title: player && player.trackTitle ? player.trackTitle : ""
    readonly property string artist: player && player.trackArtist ? player.trackArtist : ""
    readonly property string album: player && player.trackAlbum ? player.trackAlbum : ""
    readonly property string artUrl: player && player.trackArtUrl ? player.trackArtUrl : ""
    readonly property double length: player && player.length > 0 ? player.length : 0
    readonly property bool canNext: player ? player.canGoNext : false
    readonly property bool canPrevious: player ? player.canGoPrevious : false
    readonly property bool canToggle: player ? player.canTogglePlaying : false
    readonly property bool canSeek: player ? player.canSeek : false
    readonly property bool shuffleSupported: player ? player.shuffleSupported : false
    readonly property string identity: player && player.identity ? player.identity : ""

    property double tick: 0
    readonly property double position: {
        if (!player)
            return 0;
        const base = player.position > 0 ? player.position : 0;
        return Math.max(0, Math.min(root.length, base + (root.isPlaying ? root.tick : 0)));
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.isPlaying
        onTriggered: root.tick += 1
    }

    Connections {
        target: root.player
        function onPositionChanged() { root.tick = 0; }
        function onTrackChanged() { root.tick = 0; }
    }

    function toggle() {
        if (root.player)
            root.player.togglePlaying();
    }

    function next() {
        if (root.player && root.canNext)
            root.player.next();
    }

    function previous() {
        if (root.player && root.canPrevious)
            root.player.previous();
    }

    function seek(seconds) {
        if (root.player && root.canSeek && root.length > 0)
            root.player.position = Math.max(0, Math.min(root.length, seconds));
    }

    function toggleShuffle() {
        if (root.player && root.shuffleSupported)
            root.player.shuffle = !root.player.shuffle;
    }

    function formatTime(seconds) {
        const s = Math.max(0, Math.floor(seconds || 0));
        const m = Math.floor(s / 60);
        const r = s % 60;
        return m + ":" + (r < 10 ? "0" : "") + r;
    }

    function sourceFor(url) {
        if (!url)
            return "";
        if (url.startsWith("file://") || url.startsWith("http://") || url.startsWith("https://") || url.startsWith("image://"))
            return url;
        if (url.startsWith("/"))
            return "file://" + url;
        return url;
    }
}
