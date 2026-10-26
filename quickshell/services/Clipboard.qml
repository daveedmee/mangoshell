pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Singleton {
    id: root

    property var items: []
    property bool loading: false
    property string pendingId: ""

    function refresh() {
        if (listProcess.running)
            return;
        root.loading = true;
        listProcess.running = true;
    }

    function copy(id) {
        if (!id || copyProcess.running)
            return;
        root.pendingId = id;
        copyProcess.command = ["bash", Settings.paths.shellScripts + "/clipboard-copy.sh", "" + id];
        copyProcess.running = true;
    }

    function remove(id) {
        if (!id || deleteProcess.running)
            return;
        deleteProcess.command = ["bash", Settings.paths.shellScripts + "/clipboard-delete.sh", "" + id];
        deleteProcess.running = true;
    }

    function clear() {
        if (clearProcess.running)
            return;
        clearProcess.running = true;
    }

    function filtered(query, type) {
        const q = ("" + (query || "")).toLowerCase().trim();
        const source = root.items || [];
        const out = [];
        for (let i = 0; i < source.length; i++) {
            const item = source[i];
            if (type === "text" && item.type !== "text")
                continue;
            if (type === "image" && item.type !== "image")
                continue;
            if (q.length > 0) {
                const hay = (item.preview + " " + item.mime).toLowerCase();
                if (!hay.includes(q))
                    continue;
            }
            out.push(item);
        }
        return out;
    }

    Process {
        id: listProcess
        command: ["bash", Settings.paths.shellScripts + "/clipboard-list.sh", "80"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text || "[]");
                    root.items = Array.isArray(data) ? data : [];
                } catch (e) {
                    console.warn("Clipboard: could not parse index:", e);
                    root.items = [];
                }
                root.loading = false;
            }
        }
        onExited: root.loading = false
    }

    Process {
        id: copyProcess
        stdout: StdioCollector {}
        onExited: {
            root.pendingId = "";
            ShellState.closeOverlay();
        }
    }

    Process {
        id: deleteProcess
        stdout: StdioCollector {}
        onExited: root.refresh()
    }

    Process {
        id: clearProcess
        command: ["bash", Settings.paths.shellScripts + "/clipboard-clear.sh"]
        stdout: StdioCollector {}
        onExited: root.refresh()
    }

    Component.onCompleted: root.refresh()
}
