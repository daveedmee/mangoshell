pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Shared runtime references. Not user configuration.
    property var barWindow: null
    property var barWindows: ({})
    property real centerBarWidth: 0

    // Anchor of the WM layout button, used by the layout dropdown.
    property real layoutAnchorX: 0
    property real layoutAnchorY: 0

    // Custom tray context menu. The handle belongs to the SystemTray item;
    // the x coordinate is relative to the bar/screen and is clamped by the
    // overlay host so the menu never leaves the output.
    property var trayMenu: null
    property real trayMenuX: 0

    // One overlay at a time: controls, notifications, media, calendar, volume,
    // network, bluetooth, devices, tray, session, gallery, clipboard, overview.
    property string overlay: ""
    readonly property bool overlayOpen: overlay !== ""
    readonly property bool sidebarOpen: overlay === "controls" || overlay === "notifications"
    readonly property bool overlayBlocksBar: overlay === "session" || overlay === "gallery"
        || overlay === "clipboard" || overlay === "overview"

    function openOverlay(name) {
        if (!name || name === "")
            return;
        root.overlay = name;
    }

    function closeOverlay() {
        root.overlay = "";
    }

    function toggleOverlay(name) {
        if (root.overlay === name)
            root.overlay = "";
        else
            root.openOverlay(name);
    }

    function isOpen(name) {
        return root.overlay === name;
    }

    // ── OSD ─────────────────────────────────────────────────────────────
    property bool osdVisible: false
    property string osdKind: "volume"
    property string osdLabel: "Output"
    property int osdValue: 0
    property string osdText: "0%"
    property bool osdMuted: false

    function showOsd(kind, label, value, text, muted) {
        root.osdKind = kind;
        root.osdLabel = label;
        root.osdValue = Math.max(0, Math.min(100, Number(value)));
        root.osdText = text === undefined || text === null || text === ""
            ? root.osdValue + "%"
            : ("" + text);
        root.osdMuted = muted === true;
        root.osdVisible = true;
    }

    function hideOsd() {
        root.osdVisible = false;
    }

    IpcHandler {
        target: "mangoflow"

        function toggle(name: string): void { root.toggleOverlay(name); }
        function open(name: string): void { root.openOverlay(name); }
        function close(): void { root.closeOverlay(); }
        function controls(): void { root.toggleOverlay("controls"); }
        function notifications(): void { root.toggleOverlay("notifications"); }
        function media(): void { root.toggleOverlay("media"); }
        function calendar(): void { root.toggleOverlay("calendar"); }
        function volume(): void { root.toggleOverlay("volume"); }
        function network(): void { root.toggleOverlay("network"); }
        function bluetooth(): void { root.toggleOverlay("bluetooth"); }
        function devices(): void { root.toggleOverlay("devices"); }
        function session(): void { root.toggleOverlay("session"); }
        function overview(): void { root.toggleOverlay("overview"); }
        function gallery(): void { root.toggleOverlay("gallery"); }
        function clipboard(): void { root.toggleOverlay("clipboard"); }
    }

    IpcHandler {
        target: "osd"

        function volume(value: int): void {
            root.showOsd("volume", "Output", value, value <= 0 ? "Muted" : value + "%", value <= 0);
        }

        function mic(value: int): void {
            root.showOsd("mic", "Microphone", value, value <= 0 ? "Muted" : value + "%", value <= 0);
        }

        function brightness(value: int): void {
            root.showOsd("brightness", "Brightness", value, value + "%", false);
        }

        function mute(kind: string, muted: bool): void {
            if (kind === "mic") {
                const value = muted ? 0 : 68;
                root.showOsd("mic", "Microphone", value, muted ? "Muted" : value + "%", muted);
            } else {
                const value = muted ? 0 : 68;
                root.showOsd("volume", "Output", value, muted ? "Muted" : value + "%", muted);
            }
        }

        function show(kind: string, label: string, value: int, text: string): void {
            root.showOsd(kind, label, value, text, false);
        }
    }
}
