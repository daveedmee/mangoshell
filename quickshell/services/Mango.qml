pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string socketPath: ""
    property bool focusQueryReady: false
    property var tagsByMonitor: ({})
    property var focusedClient: null
    property var clients: []
    property var layouts: []

    readonly property var primaryTags: {
        const keys = Object.keys(tagsByMonitor);
        return keys.length > 0 ? tagsByMonitor[keys[0]] : [];
    }

    readonly property string focusedTitle: {
        if (!focusedClient)
            return "";

        const title = focusedClient.title || "";
        return title.replace(/[\r\n\t]+/g, " ").trim();
    }

    readonly property string focusedAppId: focusedClient ? (focusedClient.appid || "") : ""
    readonly property int focusedClientId: focusedClient ? Number(focusedClient.id) : 0
    readonly property int clientCount: clients.length

    function tagsFor(monitor) {
        if (monitor && tagsByMonitor[monitor])
            return tagsByMonitor[monitor];
        return primaryTags;
    }

    function activeTagFor(monitor) {
        const tags = tagsFor(monitor);
        for (let i = 0; i < tags.length; i++) {
            if (tags[i].is_active)
                return tags[i];
        }
        return null;
    }

    function tagState(monitor, index) {
        const tags = tagsFor(monitor);
        let active = false;
        let occupied = false;
        let urgent = false;

        for (let i = 0; i < tags.length; i++) {
            const tag = tags[i];
            if (Number(tag.index) !== Number(index))
                continue;

            if (tag.is_urgent)
                urgent = true;
            if (tag.is_active)
                active = true;
            if ((tag.client_count || 0) > 0)
                occupied = true;
        }

        if (urgent)
            return "urgent";
        if (active)
            return "active";
        if (occupied)
            return "occupied";
        return "empty";
    }

    function tagHasClients(monitor, index) {
        const tags = tagsFor(monitor);
        for (let i = 0; i < tags.length; i++) {
            const tag = tags[i];
            if (Number(tag.index) === Number(index))
                return (tag.client_count || 0) > 0;
        }
        return false;
    }

    function tagClientCount(monitor, index) {
        const tags = tagsFor(monitor);
        for (let i = 0; i < tags.length; i++) {
            const tag = tags[i];
            if (Number(tag.index) === Number(index))
                return Number(tag.client_count || 0);
        }
        return 0;
    }

    function layoutNameFor(monitor) {
        const tag = activeTagFor(monitor);
        if (!tag || !tag.layout)
            return "";

        const names = {
            "T": "Tile",
            "S": "Scroller",
            "G": "Grid",
            "M": "Monocle",
            "K": "Deck",
            "CT": "Center Tile",
            "RT": "Right Tile",
            "VS": "Vertical Scroller",
            "VT": "Vertical Tile",
            "VG": "Vertical Grid",
            "VK": "Vertical Deck",
            "DW": "Dwindle",
            "F": "Fair",
            "VF": "Vertical Fair"
        };

        return names[tag.layout] || tag.layout;
    }

    function layoutCodeFor(monitor) {
        const tag = activeTagFor(monitor);
        return tag && tag.layout ? tag.layout : "";
    }

    function applyTags(line) {
        if (!line || line.length === 0)
            return;

        try {
            const data = JSON.parse(line);
            const monitors = data.all_tags || [];
            const next = {};

            for (let i = 0; i < monitors.length; i++) {
                const monitor = monitors[i];
                if (monitor && monitor.monitor)
                    next[monitor.monitor] = monitor.tags || [];
            }

            root.tagsByMonitor = next;
        } catch (e) {
            console.warn("Mango: could not parse all-tags:", e);
        }
    }

    function applyFocus(line) {
        if (!line || line.trim().length === 0)
            return;

        try {
            const data = JSON.parse(line);
            root.focusedClient = data && data.id ? data : null;
        } catch (e) {
            root.focusedClient = null;
        }
    }

    function applyClients(line) {
        if (!line || line.trim().length === 0)
            return;

        try {
            const data = JSON.parse(line);
            root.clients = Array.isArray(data.clients) ? data.clients : [];
        } catch (e) {
            console.warn("Mango: could not parse all-clients:", e);
        }
    }

    function applyLayouts(text) {
        try {
            const data = JSON.parse(text || "{}");
            root.layouts = Array.isArray(data.layouts) ? data.layouts : [];
        } catch (e) {
            console.warn("Mango: could not parse layouts:", e);
        }
    }

    function dispatch(command) {
        if (root.socketPath.length === 0)
            return;

        Quickshell.execDetached([
            "env",
            "MANGO_INSTANCE_SIGNATURE=" + root.socketPath,
            "mmsg", "dispatch", command
        ]);
    }

    function viewTag(tag) {
        dispatch("view," + tag + ",0");
    }

    function focusClient(id) {
        if (id === undefined || id === null || Number(id) <= 0)
            return;
        if (root.socketPath.length === 0)
            return;

        // focusid ignores its value argument: the target client is selected by
        // the trailing client,<id> address, not by focusid,<id>.
        dispatch("focusid client," + Number(id));
    }

    function closeClient(id) {
        if (id === undefined || id === null || Number(id) <= 0)
            return;
        // Mango accepts the target at either end of a dispatch expression.
        dispatch("killclient client," + Number(id));
    }

    function toggleOverview() {
        dispatch("toggleoverview");
    }

    function enterOverview() {
        dispatch("enteroverview");
    }

    function leaveOverview() {
        dispatch("leaveoverview");
    }

    function switchLayout() {
        dispatch("switch_layout");
    }

    function setLayout(name) {
        if (!name || name.length === 0)
            return;
        dispatch("setlayout," + name);
    }

    function viewLeft() {
        dispatch("viewtoleft_have_client");
    }

    function viewRight() {
        dispatch("viewtoright_have_client");
    }

    function startWatches() {
        if (root.socketPath.length === 0)
            return;

        if (!tagsProcess.running)
            tagsProcess.running = true;
        if (!focusProcess.running)
            focusProcess.running = true;
        if (!clientsProcess.running)
            clientsProcess.running = true;
        if (root.focusQueryReady && !focusQuery.running)
            focusQuery.running = true;
        if (root.layouts.length === 0 && typeof layoutsProcess !== "undefined"
                && !layoutsProcess.running)
            layoutsProcess.running = true;
    }

    function probeSocket() {
        if (!socketProbe.running)
            socketProbe.running = true;
    }

    Process {
        id: socketProbe
        command: [
            "sh", "-c",
            "runtime=\"${XDG_RUNTIME_DIR:-/run/user/$(id -u)}\"; " +
            "for pid in $(pgrep -x mango); do if [ -S \"$runtime/mango-$pid.sock\" ]; then echo \"$runtime/mango-$pid.sock\"; exit 0; fi; done; " +
            "if [ -S \"$MANGO_INSTANCE_SIGNATURE\" ]; then echo \"$MANGO_INSTANCE_SIGNATURE\"; exit 0; fi; " +
            "ls -t \"$runtime\"/mango-*.sock 2>/dev/null | head -n 1"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const path = text.trim();
                if (path.length > 0) {
                    root.socketPath = path;
                    root.startWatches();
                } else {
                    retryTimer.restart();
                }
            }
        }
        onExited: {
            if (root.socketPath.length === 0)
                retryTimer.restart();
        }
    }

    Process {
        id: tagsProcess
        running: false
        environment: ({ MANGO_INSTANCE_SIGNATURE: root.socketPath })
        command: ["mmsg", "watch", "all-tags"]
        stdout: SplitParser {
            onRead: function(line) { root.applyTags(line); }
        }
        onExited: {
            root.socketPath = "";
            root.probeSocket();
        }
    }

    Process {
        id: focusProcess
        running: false
        environment: ({ MANGO_INSTANCE_SIGNATURE: root.socketPath })
        command: ["mmsg", "watch", "focusing-client"]
        stdout: SplitParser {
            onRead: function(line) { root.applyFocus(line); }
        }
        onExited: {
            root.socketPath = "";
            root.probeSocket();
        }
    }

    Process {
        id: clientsProcess
        running: false
        environment: ({ MANGO_INSTANCE_SIGNATURE: root.socketPath })
        command: ["mmsg", "watch", "all-clients"]
        stdout: SplitParser {
            onRead: function(line) { root.applyClients(line); }
        }
        onExited: {
            root.socketPath = "";
            root.probeSocket();
        }
    }

    Process {
        id: focusQuery
        running: false
        environment: ({ MANGO_INSTANCE_SIGNATURE: root.socketPath })
        command: ["mmsg", "get", "focusing-client"]
        stdout: StdioCollector {
            onStreamFinished: root.applyFocus(text)
        }
        Component.onCompleted: {
            root.focusQueryReady = true;
            if (root.socketPath.length > 0)
                focusQuery.running = true;
        }
    }

    Process {
        id: layoutsProcess
        running: false
        environment: ({ MANGO_INSTANCE_SIGNATURE: root.socketPath })
        command: ["mmsg", "get", "layouts"]
        stdout: StdioCollector {
            onStreamFinished: root.applyLayouts(text)
        }
    }

    Timer {
        id: retryTimer
        interval: 1000
        repeat: false
        onTriggered: root.probeSocket()
    }

    Component.onCompleted: root.probeSocket()
}
