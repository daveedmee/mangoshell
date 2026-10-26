pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    // Active defaults. These are what applications are currently using.
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var sinkAudio: root.sink ? root.sink.audio : null
    readonly property var sourceAudio: root.source ? root.source.audio : null

    readonly property bool ready: root.sinkAudio !== null && root.sink.ready
    readonly property bool sourceReady: root.sourceAudio !== null && root.source.ready

    readonly property int sinkPercent: root.sinkAudio ? Math.round(root.sinkAudio.volume * 100) : 0
    readonly property int sourcePercent: root.sourceAudio ? Math.round(root.sourceAudio.volume * 100) : 0
    readonly property bool sinkMuted: root.sinkAudio ? root.sinkAudio.muted : false
    readonly property bool sourceMuted: root.sourceAudio ? root.sourceAudio.muted : false

    // Backwards-compatible names used by the bar module and older callers.
    readonly property var audio: root.sinkAudio
    readonly property int percent: root.sinkPercent
    readonly property bool muted: root.sinkMuted

    // Hardware devices only. KDE's applet hides virtual and monitor devices by
    // default; the current device is kept visible even if it is virtual.
    readonly property var sinks: root.deviceList(root.sink, true)
    readonly property var sources: root.deviceList(root.source, false)

    // KDE's microphone indicator appears while a capture stream exists, even
    // if that stream is currently silent.
    readonly property bool micInUse: {
        const nodes = Pipewire.nodes.values;
        for (let i = 0; i < nodes.length; i++) {
            const node = nodes[i];
            if (!node || !node.isStream || !node.audio)
                continue;

            const props = node.properties || {};
            const mediaClass = props["media.class"] || "";
            if (mediaClass === "Stream/Input/Audio")
                return true;
        }
        return false;
    }

    // Per-application playback streams. Keep the raw node objects in this
    // list: rebuilding wrapper objects whenever a volume changes destroys the
    // delegate under the user's pointer and makes the sliders feel
    // click-only. Live values are read from each node by the helper functions
    // below, so the model stays stable for the whole lifetime of a stream.
    readonly property var streams: {
        const nodes = Pipewire.nodes.values;
        const list = [];

        for (let i = 0; i < nodes.length; i++) {
            const node = nodes[i];
            if (!node || !node.isStream || !node.audio)
                continue;

            const props = node.properties || {};
            const mediaClass = props["media.class"] || "";
            if (mediaClass !== "Stream/Output/Audio" && mediaClass !== "Stream/Input/Audio")
                continue;

            list.push(node);
        }

        list.sort(function(a, b) {
            const aInput = root.streamIsInput(a);
            const bInput = root.streamIsInput(b);
            if (aInput !== bInput)
                return aInput ? 1 : -1;
            return root.streamName(a).localeCompare(root.streamName(b));
        });
        return list;
    }

    function streamProperties(node) {
        return (node && node.properties) || ({});
    }

    function streamName(node) {
        const props = root.streamProperties(node);
        const binary = props["application.process.binary"] || "";
        return "" + (props["application.name"]
            || binary
            || props["media.name"]
            || (node && node.name)
            || "Application");
    }

    function streamIcon(node) {
        const props = root.streamProperties(node);
        return "" + (props["application.icon-name"]
            || props["application.process.binary"]
            || "");
    }

    function streamIsInput(node) {
        return root.streamProperties(node)["media.class"] === "Stream/Input/Audio";
    }

    function streamPercent(node) {
        return node && node.audio ? Math.round(node.audio.volume * 100) : 0;
    }

    function streamMuted(node) {
        return node && node.audio ? node.audio.muted : false;
    }

    function setStreamVolume(stream, percent) {
        const node = stream && stream.node ? stream.node : stream;
        if (!node || !node.audio)
            return;
        const volume = Math.max(0, Math.min(1, percent / 100));
        node.audio.volume = volume;
        node.audio.muted = volume <= 0;
    }

    function toggleStreamMute(stream) {
        const node = stream && stream.node ? stream.node : stream;
        if (!node || !node.audio)
            return;
        node.audio.muted = !node.audio.muted;
    }

    readonly property bool allSourcesMuted: {
        const list = root.sources;
        if (list.length === 0)
            return false;

        for (let i = 0; i < list.length; i++) {
            if (!list[i].audio || !list[i].audio.muted)
                return false;
        }
        return true;
    }

    // Sources the indicator muted itself. Unmuting restores only these, so a
    // source the user muted manually stays muted.
    property var mutedByIndicator: ({})

    function isDummy(node) {
        return node !== null && node !== undefined && node.name === "auto_null";
    }

    function isVirtual(node) {
        if (!node || root.isDummy(node))
            return true;

        const name = (node.name || "").toLowerCase();
        if (name.endsWith(".monitor"))
            return true;

        const properties = node.properties || {};
        const virtual = properties["node.virtual"];
        return virtual === true || virtual === "true";
    }

    function nodeLabel(node) {
        if (!node)
            return "";
        return node.nickname || node.description || node.name || "";
    }

    function deviceList(current, wantSink) {
        const nodes = Pipewire.nodes.values;
        const list = [];

        for (let i = 0; i < nodes.length; i++) {
            const node = nodes[i];
            if (!node || !node.audio || node.isStream)
                continue;
            if (node.isSink !== wantSink)
                continue;
            if (root.isVirtual(node) && node !== current)
                continue;
            list.push(node);
        }

        list.sort(function(a, b) {
            if (a === current)
                return -1;
            if (b === current)
                return 1;
            return root.nodeLabel(a).localeCompare(root.nodeLabel(b));
        });

        return list;
    }

    // Pipewire's preferred-default hint does not always change the active
    // default immediately under WirePlumber. `wpctl set-default` updates the
    // configured default and takes effect right away.
    function setSink(node) {
        if (node)
            Quickshell.execDetached(["wpctl", "set-default", String(node.id)]);
    }

    function setSource(node) {
        if (node)
            Quickshell.execDetached(["wpctl", "set-default", String(node.id)]);
    }

    function setSinkVolume(percent) {
        if (!root.sinkAudio)
            return;

        const volume = Math.max(0, Math.min(1, percent / 100));
        root.sinkAudio.volume = volume;
        root.sinkAudio.muted = volume <= 0;
    }

    function setSourceVolume(percent) {
        if (!root.sourceAudio)
            return;

        const volume = Math.max(0, Math.min(1, percent / 100));
        root.sourceAudio.volume = volume;
        root.sourceAudio.muted = volume <= 0;
    }

    function changeSinkVolumeBy(percent) {
        root.setSinkVolume(root.sinkPercent + percent);
    }

    function changeSourceVolumeBy(percent) {
        root.setSourceVolume(root.sourcePercent + percent);
    }

    // Fractional delta kept for the previous bar implementation.
    function changeVolume(delta) {
        root.changeSinkVolumeBy(delta * 100);
    }

    function toggleSinkMute() {
        if (root.sinkAudio)
            root.sinkAudio.muted = !root.sinkAudio.muted;
    }

    function toggleSourceMute() {
        if (root.sourceAudio)
            root.sourceAudio.muted = !root.sourceAudio.muted;
    }

    function toggleMute() {
        root.toggleSinkMute();
    }

    // KDE-style privacy toggle: mute every input source, remembering which
    // ones this action muted so unmuting can restore their previous state.
    function toggleAllSourceMutes() {
        const list = root.sources;
        if (list.length === 0)
            return;

        if (root.allSourcesMuted) {
            const remembered = root.mutedByIndicator || {};

            for (let i = 0; i < list.length; i++) {
                const node = list[i];
                if (!node.audio || remembered[node.id] !== true)
                    continue;
                node.audio.muted = false;
            }

            // Sources the user muted manually are not in the memory map and
            // therefore stay muted.
            root.mutedByIndicator = ({});
            return;
        }

        const remembered = Object.assign({}, root.mutedByIndicator || {});
        for (let i = 0; i < list.length; i++) {
            const node = list[i];
            if (!node.audio)
                continue;
            if (!node.audio.muted) {
                node.audio.muted = true;
                remembered[node.id] = true;
            }
        }
        root.mutedByIndicator = remembered;
    }

    // Bind every audio node, including streams. This keeps device and
    // per-application mixer state live, gives the all-mic privacy toggle access
    // to all sources, and populates the properties used for filtering/labels.
    PwObjectTracker {
        objects: Pipewire.nodes.values.filter(function(node) {
            return node && node.audio;
        })
    }
}
