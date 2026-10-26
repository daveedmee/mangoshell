pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Singleton {
    id: root

    property var items: []
    property bool loading: false
    property bool actionRunning: false
    property string actionDevice: ""
    property string actionKind: ""
    property string lastError: ""

    // The Devices popover only deals with attached USB storage. Tiny boot
    // partitions (for example Ventoy's VTOYEFI) are intentionally hidden.
    readonly property var usbItems: {
        const result = [];
        for (let i = 0; i < root.items.length; i++) {
            const item = root.items[i];
            if (!item || item.usb !== true)
                continue;
            if (Number(item.size) < 64 * 1024 * 1024)
                continue;
            result.push(item);
        }
        result.sort(function(a, b) {
            if (a.mounted !== b.mounted)
                return a.mounted ? -1 : 1;
            return ("" + (a.name || a.device)).localeCompare("" + (b.name || b.device));
        });
        return result;
    }
    readonly property int usbCount: root.usbItems.length
    readonly property int mountedUsbCount: {
        let count = 0;
        for (let i = 0; i < root.usbItems.length; i++) {
            if (root.usbItems[i].mounted)
                count += 1;
        }
        return count;
    }

    function refresh() {
        if (sample.running)
            return;
        root.loading = true;
        sample.running = true;
    }

    function mount(item) {
        root.runAction("mount", item);
    }

    function unmount(item) {
        root.runAction("unmount", item);
    }

    function runAction(kind, item) {
        if (!item || !item.device || root.actionRunning)
            return;
        root.lastError = "";
        root.actionRunning = true;
        root.actionDevice = item.device;
        root.actionKind = kind;
        actionProcess.command = ["udisksctl", kind, "-b", item.device];
        actionProcess.running = true;
    }

    function open(item) {
        if (!item || !item.mounted || !item.mountpoint || item.mountpoint.length === 0)
            return;
        Quickshell.execDetached(["xdg-open", item.mountpoint]);
    }

    function formatBytes(value) {
        const size = Number(value);
        if (!isFinite(size) || size <= 0)
            return "—";
        if (size >= 1024 * 1024 * 1024 * 1024)
            return (size / (1024 * 1024 * 1024 * 1024)).toFixed(1) + " TB";
        if (size >= 1024 * 1024 * 1024)
            return (size / (1024 * 1024 * 1024)).toFixed(0) + " GB";
        if (size >= 1024 * 1024)
            return (size / (1024 * 1024)).toFixed(0) + " MB";
        return Math.round(size / 1024) + " KB";
    }

    Process {
        id: sample
        command: ["bash", Settings.paths.shellScripts + "/storage-list.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text || "[]");
                    root.items = Array.isArray(data) ? data : [];
                } catch (e) {
                    console.warn("Storage: could not parse drives:", e);
                    root.items = [];
                }
                root.loading = false;
            }
        }
        onExited: root.loading = false
    }

    Process {
        id: actionProcess
        stderr: StdioCollector {
            id: actionError
            waitForEnd: true
        }
        onExited: function(exitCode, exitStatus) {
            root.actionRunning = false;
            if (exitCode !== 0) {
                const detail = (actionError.text || "").trim().split("\n")[0];
                root.lastError = (root.actionKind === "mount"
                    ? "Could not mount " : "Could not unmount ")
                    + root.actionDevice
                    + (detail.length > 0 ? ": " + detail : "");
            } else {
                root.lastError = "";
            }
            root.actionDevice = "";
            root.actionKind = "";
            root.refresh();
        }
    }

    Timer {
        interval: 10000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()
}
