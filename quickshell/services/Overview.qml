pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Singleton {
    id: root

    property var clients: []
    property string shot: ""
    property int previewVersion: 0
    property bool loading: false
    property bool previewsLoading: false
    property bool active: false
    property var pendingFocusId: 0
    property string error: ""

    function capture() {
        if (root.loading)
            return;
        root.loading = true;
        root.previewsLoading = false;
        root.error = "";
        root.clients = [];
        root.shot = "";
        previewProcess.running = false;
        captureProcess.running = true;
    }

    function focusClient(id) {
        const target = Number(id);
        if (target <= 0)
            return;

        // Let the overlay unmap first. Otherwise Mango restores focus to the
        // previously active client while the layer surface is still closing.
        root.pendingFocusId = target;
        ShellState.closeOverlay();
        focusTimer.restart();
    }

    function closeClient(id) {
        Mango.closeClient(id);
        removeClient(id);
    }

    function forceCloseClient(id) {
        const target = Number(id);
        if (target <= 0)
            return;

        let pid = 0;
        for (let i = 0; i < root.clients.length; i++) {
            if (Number(root.clients[i].id) === target) {
                pid = Number(root.clients[i].pid) || 0;
                break;
            }
        }

        // A window can expose a PID, but Xwayland clients occasionally do
        // not. In that case fall back to Mango's normal close request.
        if (pid > 0)
            Quickshell.execDetached(["kill", "-9", "" + pid]);
        else
            Mango.closeClient(target);

        removeClient(target);
    }

    function removeClient(id) {
        const next = [];
        for (let i = 0; i < root.clients.length; i++) {
            if (Number(root.clients[i].id) !== Number(id))
                next.push(root.clients[i]);
        }
        root.clients = next;

        if (next.length === 0) {
            root.active = false;
            ShellState.closeOverlay();
        }
    }

    function leave() {
        root.active = false;
    }

    Connections {
        target: ShellState
        function onOverlayChanged() {
            if (root.active && ShellState.overlay !== "overview")
                root.active = false;
        }
    }

    IpcHandler {
        target: "overview"

        function capture(): void { root.capture(); }
        function focus(id: int): void { root.focusClient(id); }
        function forceClose(id: int): void { root.forceCloseClient(id); }
        function close(): void {
            ShellState.closeOverlay();
            root.leave();
        }
    }

    Timer {
        id: focusTimer
        interval: 90
        repeat: false
        onTriggered: {
            if (root.pendingFocusId > 0)
                Mango.focusClient(root.pendingFocusId);
            root.pendingFocusId = 0;
        }
    }

    Process {
        id: captureProcess
        command: ["bash", Settings.paths.shellScripts + "/overview-capture.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text || "{}");
                    root.clients = Array.isArray(data.clients) ? data.clients : [];
                    root.shot = data.shot || "";
                    if (data.error)
                        root.error = data.error;
                    root.loading = false;
                    root.active = root.clients.length > 0;
                    if (root.active) {
                        ShellState.openOverlay("overview");
                        root.previewsLoading = true;
                        previewProcess.running = true;
                    } else {
                        ShellState.closeOverlay();
                    }
                } catch (e) {
                    root.error = "Could not read overview capture";
                    root.clients = [];
                    root.shot = "";
                    root.loading = false;
                    ShellState.closeOverlay();
                }
            }
        }
        onExited: {
            if (root.loading) {
                root.loading = false;
                root.error = "Overview capture failed";
                ShellState.closeOverlay();
            }
        }
    }

    Process {
        id: previewProcess
        command: ["bash", Settings.paths.shellScripts + "/overview-previews.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text || "{}");
                    const previews = Array.isArray(data.previews) ? data.previews : [];
                    const byId = {};
                    for (let i = 0; i < previews.length; i++)
                        byId["" + previews[i].id] = previews[i].preview || "";

                    const next = [];
                    for (let i = 0; i < root.clients.length; i++) {
                        const client = Object.assign({}, root.clients[i]);
                        client.preview = byId["" + client.id] || "";
                        next.push(client);
                    }
                    root.clients = next;
                    root.previewVersion += 1;
                } catch (e) {
                    // Keep the client list; cards fall back to their app icon.
                }
                root.previewsLoading = false;
            }
        }
        onExited: root.previewsLoading = false
    }
}
