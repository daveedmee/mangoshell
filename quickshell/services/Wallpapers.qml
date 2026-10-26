pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Singleton {
    id: root

    property var items: []
    property var folders: []
    property bool loading: false
    property bool applying: false
    property var info: null
    property bool infoLoading: false

    // Wallpaper placement is intentionally separate from the Matugen palette.
    property string displayMode: "fill"
    property string displayColor: "#000000"
    property bool displayLoaded: false
    property bool displayPending: false

    function refresh() {
        if (listProcess.running)
            return;
        root.loading = true;
        listProcess.running = true;
    }

    function apply(path) {
        if (!path || root.applying)
            return;
        root.applying = true;
        applyProcess.command = ["bash", Settings.paths.mangoScripts + "/set-wallpaper.sh", path];
        applyProcess.running = true;
    }

    function inspect(path) {
        if (!path)
            return;
        root.info = null;
        root.infoLoading = true;
        if (infoProcess.running)
            infoProcess.running = false;
        infoProcess.command = ["bash", Settings.paths.shellScripts + "/wallpaper-info.sh", path];
        infoProcess.running = true;
    }

    function pickRandom(list) {
        if (!list || list.length === 0)
            return null;
        return list[Math.floor(Math.random() * list.length)];
    }

    function setDisplayMode(mode) {
        if (!mode || mode === root.displayMode)
            return;
        root.displayMode = mode;
        root.scheduleDisplayApply();
    }

    function setDisplayColor(color) {
        if (!color || color === root.displayColor)
            return;
        root.displayColor = color;
        root.scheduleDisplayApply();
    }

    function scheduleDisplayApply() {
        if (!root.displayLoaded)
            return;
        displayDebounce.restart();
    }

    function applyDisplay() {
        if (displayApply.running) {
            root.displayPending = true;
            return;
        }
        displayApply.command = [
            "bash", Settings.paths.shellScripts + "/wallpaper-display.sh", "apply",
            "--mode", root.displayMode,
            "--color", root.displayColor
        ];
        displayApply.running = true;
    }

    function filtered(query, folder) {
        const q = ("" + (query || "")).toLowerCase().trim();
        const f = folder || "All";
        const source = root.items || [];
        const out = [];

        for (let i = 0; i < source.length; i++) {
            const item = source[i];
            if (f !== "All" && item.folder !== f)
                continue;
            if (q.length > 0) {
                const hay = (item.name + " " + item.path + " " + item.folder).toLowerCase();
                if (!hay.includes(q))
                    continue;
            }
            out.push(item);
        }
        return out;
    }

    Process {
        id: listProcess
        command: ["bash", Settings.paths.shellScripts + "/wallpapers-list.sh", Settings.paths.wallpapers]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text || "[]");
                    root.items = Array.isArray(data) ? data : [];
                    const set = {};
                    for (let i = 0; i < root.items.length; i++)
                        set[root.items[i].folder] = true;
                    root.folders = Object.keys(set).sort();
                } catch (e) {
                    console.warn("Wallpapers: could not parse index:", e);
                    root.items = [];
                    root.folders = [];
                }
                root.loading = false;
            }
        }
        onExited: root.loading = false
    }

    Process {
        id: applyProcess
        stdout: StdioCollector {}
        onExited: {
            root.applying = false;
            ShellState.closeOverlay();
        }
    }

    Process {
        id: infoProcess
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.info = JSON.parse(text || "{}");
                } catch (e) {
                    root.info = null;
                }
                root.infoLoading = false;
            }
        }
        onExited: root.infoLoading = false
    }

    Process {
        id: displayLoad
        command: ["bash", Settings.paths.shellScripts + "/wallpaper-display.sh", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text || "{}");
                    root.displayMode = data.mode || "fill";
                    root.displayColor = data.color || "#000000";
                } catch (e) {
                    root.displayMode = "fill";
                    root.displayColor = "#000000";
                }
                root.displayLoaded = true;
            }
        }
    }

    Process {
        id: displayApply
        stdout: StdioCollector {}
        onExited: {
            if (root.displayPending) {
                root.displayPending = false;
                root.applyDisplay();
            }
        }
    }

    Timer {
        id: displayDebounce
        interval: 140
        repeat: false
        onTriggered: root.applyDisplay()
    }

    Component.onCompleted: {
        // The wallpaper index is only needed when the gallery opens. Keeping
        // the scan out of shell startup avoids walking ~/Bilder (possibly an
        // external drive) on every login.
        displayLoad.running = true;
    }
}
