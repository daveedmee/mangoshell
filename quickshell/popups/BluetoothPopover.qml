import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import ".."
import "../components"

Rectangle {
    id: popover

    implicitWidth: Settings.overlay.bluetoothWidth
    implicitHeight: 82 + body.implicitHeight + 16
    radius: Theme.radiusPanel
    color: Theme.panel
    border.width: 1
    border.color: Theme.border
    clip: true

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool enabled: popover.adapter !== null && popover.adapter.enabled
    // Only show the scanning state when this panel started discovery. Another
    // application can keep the shared adapter discovering in the background;
    // that must not make the panel look as if it scans on its own.
    property bool scanRequested: false
    readonly property bool scanning: popover.scanRequested
        && popover.adapter !== null && popover.adapter.discovering
    // The scan control uses the same width as the compact Connect button in
    // the paired-device rows so the two sections line up vertically.
    readonly property int compactActionWidth: 62
    property var kdeBatteries: []
    readonly property int connectedCount: {
        const list = popover.allDevices;
        let count = 0;
        for (let i = 0; i < list.length; i++) {
            if (list[i].connected)
                count += 1;
        }
        return count;
    }
    readonly property var allDevices: {
        const source = popover.adapter ? popover.adapter.devices.values : [];
        const list = source.slice();
        list.sort(function(a, b) {
            if (a.connected !== b.connected)
                return a.connected ? -1 : 1;
            if (a.paired !== b.paired)
                return a.paired ? -1 : 1;
            return popover.deviceName(a).localeCompare(popover.deviceName(b));
        });
        return list;
    }
    readonly property var connectedDevices: popover.devicesWhere(true, true)
    readonly property var pairedDevices: popover.devicesWhere(false, true)
    readonly property var availableDevices: popover.devicesWhere(false, false)

    function devicesWhere(connected, paired) {
        const list = popover.allDevices;
        const out = [];
        for (let i = 0; i < list.length; i++) {
            if (list[i].connected === connected && list[i].paired === paired)
                out.push(list[i]);
        }
        return out;
    }

    function deviceName(device) {
        if (!device)
            return "Unknown device";
        return device.deviceName || device.name || "Unknown device";
    }

    // BlueZ exposes freedesktop icon names (audio-headset, input-gaming, …).
    // Map them to the Material Symbols used everywhere else in the shell
    // instead of loading a mix of icon-theme pictograms.
    function deviceGlyph(device) {
        const icon = device && device.icon ? ("" + device.icon) : "";
        if (icon.indexOf("audio-headset") === 0
                || icon.indexOf("audio-headphones") === 0)
            return Glyphs.headphones;
        if (icon.indexOf("audio-") === 0)
            return Glyphs.speaker;
        if (icon.indexOf("input-gaming") === 0)
            return Glyphs.gamepad;
        if (icon.indexOf("input-keyboard") === 0)
            return Glyphs.keyboard;
        if (icon.indexOf("input-mouse") === 0)
            return Glyphs.mouse;
        if (icon.indexOf("input-tablet") === 0)
            return Glyphs.tablet;
        if (icon.indexOf("phone") === 0)
            return Glyphs.smartphone;
        if (icon.indexOf("computer") === 0)
            return Glyphs.computer;
        if (icon.indexOf("printer") === 0)
            return Glyphs.printer;
        if (icon.indexOf("camera-") === 0)
            return Glyphs.camera;
        if (icon.indexOf("video-") === 0 || icon.indexOf("multimedia") === 0)
            return Glyphs.tv;
        if (icon.indexOf("scanner") === 0)
            return Glyphs.scanner;
        if (icon.indexOf("modem") === 0 || icon.indexOf("network-") === 0)
            return Glyphs.router;
        return Glyphs.bluetooth;
    }

    function normalizedName(value) {
        return ("" + (value || "")).trim().toLocaleLowerCase();
    }

    function kdeBatteryFor(device) {
        if (!device)
            return null;
        const name = popover.normalizedName(popover.deviceName(device));
        for (let i = 0; i < popover.kdeBatteries.length; i++) {
            const entry = popover.kdeBatteries[i];
            if (entry && popover.normalizedName(entry.name) === name)
                return entry;
        }
        return null;
    }

    function batteryPercent(device) {
        // KDE Connect reports the phone's own battery state and charging flag,
        // which is more useful than BlueZ's occasionally stale Battery1 value.
        const kde = popover.kdeBatteryFor(device);
        if (kde && isFinite(Number(kde.charge)))
            return Math.max(0, Math.min(100, Math.round(Number(kde.charge))));

        if (!device || !device.batteryAvailable)
            return -1;
        const raw = Number(device.battery);
        if (!isFinite(raw))
            return -1;
        return Math.round(raw <= 1 ? raw * 100 : raw);
    }

    function batteryCharging(device) {
        const kde = popover.kdeBatteryFor(device);
        return !!(kde && kde.charging === true);
    }

    function subtitle(device) {
        if (!device)
            return "";
        const parts = [];
        const battery = popover.batteryPercent(device);
        if (battery >= 0)
            parts.push("Battery " + battery + "%");
        if (popover.batteryCharging(device))
            parts.push("Charging");
        if (device.pairing)
            parts.push("Pairing…");
        else if (device.connected)
            parts.push("Connected");
        else if (device.paired)
            parts.push("Paired");
        else
            parts.push("Available");
        if (device.address && device.address.length > 0)
            parts.push(device.address);
        return parts.join(" · ");
    }

    function actionLabel(device) {
        if (!device)
            return "";
        if (device.pairing)
            return "Pairing…";
        if (device.connected)
            return "Disconnect";
        if (device.paired)
            return "Connect";
        return "Pair";
    }

    function activateDevice(device) {
        if (!device)
            return;
        if (device.connected)
            device.disconnect();
        else if (device.paired)
            device.connect();
        else
            device.pair();
    }

    // Scanning is entirely manual. Stop discovery left over from an earlier
    // session when the popover opens, and stop it again when the popover is
    // destroyed so closing the panel never leaves the adapter searching.
    function stopDiscovery() {
        popover.scanRequested = false;
        if (popover.adapter && popover.adapter.discovering)
            popover.adapter.discovering = false;
    }

    function toggleScanning() {
        if (!popover.adapter)
            return;

        if (popover.scanning) {
            popover.scanRequested = false;
            popover.adapter.discovering = false;
        } else {
            popover.scanRequested = true;
            popover.adapter.discovering = true;
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
    }

    Item {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 14
        height: 44

        Label {
            anchors.left: parent.left
            anchors.top: parent.top
            value: "BlueZ"
            eyebrow: true
            size: 8
            color: Theme.dim
            opacityValue: 0.7
        }

        Label {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.topMargin: 12
            value: "Bluetooth"
            strong: true
            size: 17
            color: Theme.fg
        }

        Row {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 2
            spacing: 8

            ToggleSwitch {
                anchors.verticalCenter: parent.verticalCenter
                checked: popover.enabled
                interactive: popover.adapter !== null
                onToggled: {
                    if (popover.adapter)
                        popover.adapter.enabled = !popover.adapter.enabled;
                }
            }

            IconButton {
                icon: Glyphs.close
                iconSize: 17
                size: 28
                iconColor: Theme.dim
                onClicked: ShellState.closeOverlay()
            }
        }
    }

    Column {
        id: body
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 6
        spacing: 11

        Rectangle {
            width: parent.width
            height: 58
            radius: Theme.radiusPanel
            color: Theme.card
            border.width: 1
            border.color: Theme.alpha(Theme.fg, 0.065)

            Rectangle {
                x: 11
                anchors.verticalCenter: parent.verticalCenter
                width: 32
                height: 32
                radius: Theme.radiusCard
                color: popover.enabled
                    ? Theme.primaryContainer
                    : Theme.alpha(Theme.fg, 0.06)

                Icon {
                    anchors.centerIn: parent
                    name: popover.enabled ? Glyphs.bluetooth : Glyphs.bluetoothSearching
                    size: 18
                    filled: popover.enabled
                    color: popover.enabled ? Theme.primaryContainerText : Theme.dim
                }
            }

            Column {
                anchors.left: parent.left
                anchors.leftMargin: 54
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Label {
                    width: parent.width
                    value: popover.adapter
                        ? (popover.adapter.name || "Bluetooth adapter")
                        : "No Bluetooth adapter"
                    strong: true
                    size: 11
                    color: Theme.fg
                }

                Label {
                    width: parent.width
                    value: popover.adapter === null
                        ? "Bluetooth is unavailable on this system"
                        : (!popover.enabled
                            ? "Off"
                            : (popover.connectedCount > 0
                                ? popover.connectedCount + (popover.connectedCount === 1 ? " device connected" : " devices connected")
                                : "On · ready to connect"))
                    size: 8
                    color: Theme.dim
                    opacityValue: 0.68
                }
            }
        }

        Column {
            visible: popover.enabled
            width: parent.width
            spacing: 5

            Item {
                width: parent.width
                height: 18

                Label {
                    anchors.left: parent.left
                    value: "Connected"
                    strong: true
                    size: 11
                    color: Theme.fg
                }

                Label {
                    anchors.right: parent.right
                    value: popover.connectedCount
                    size: 8
                    color: Theme.dim
                    opacityValue: 0.55
                }
            }

            Repeater {
                model: popover.connectedDevices

                delegate: DeviceRow {
                    width: parent.width
                }
            }

            Label {
                visible: popover.connectedCount === 0
                width: parent.width
                value: "No devices connected"
                size: 9
                color: Theme.dim
                opacityValue: 0.5
            }
        }

        Column {
            visible: popover.enabled && popover.pairedDevices.length > 0
            width: parent.width
            spacing: 5

            Item {
                width: parent.width
                height: 18

                Label {
                    anchors.left: parent.left
                    value: "Paired"
                    strong: true
                    size: 11
                    color: Theme.fg
                }

                Label {
                    anchors.right: parent.right
                    value: popover.pairedDevices.length
                    size: 8
                    color: Theme.dim
                    opacityValue: 0.55
                }
            }

            Repeater {
                model: popover.pairedDevices

                delegate: DeviceRow {
                    width: parent.width
                }
            }
        }

        Column {
            visible: popover.enabled
            width: parent.width
            spacing: 5

            Item {
                width: parent.width
                height: 22

                Label {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    value: "Add a device"
                    strong: true
                    size: 11
                    color: Theme.fg
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    width: popover.compactActionWidth
                    height: 24
                    radius: Theme.radiusControl
                    color: scanMouse.containsMouse ? Theme.hover : Theme.input
                    border.width: 1
                    border.color: popover.scanning
                        ? Theme.alpha(Theme.primary, 0.35)
                        : Theme.border

                    Row {
                        anchors.centerIn: parent
                        spacing: 5

                        Icon {
                            name: Glyphs.bluetoothSearching
                            size: 13
                            color: popover.scanning ? Theme.primary : Theme.dim
                        }

                        Label {
                            value: popover.scanning ? "Stop" : "Scan"
                            size: 9
                            color: popover.scanning ? Theme.primary : Theme.dim
                        }
                    }

                    MouseArea {
                        id: scanMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: popover.adapter !== null
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: popover.toggleScanning()
                    }
                }
            }

            Repeater {
                model: popover.availableDevices.slice(0, 8)

                delegate: DeviceRow {
                    width: parent.width
                }
            }
        }

        Rectangle {
            visible: !popover.enabled
            width: parent.width
            height: 42
            radius: Theme.radiusCard
            color: Theme.alpha(Theme.fg, 0.035)
            border.width: 1
            border.color: Theme.alpha(Theme.fg, 0.055)

            Label {
                anchors.centerIn: parent
                value: popover.adapter === null
                    ? "No adapter found"
                    : "Turn Bluetooth on to see devices"
                size: 9
                color: Theme.dim
                opacityValue: 0.7
            }
        }
    }


    Process {
        id: kdeBatteryProcess
        command: ["bash", Settings.paths.shellScripts + "/kdeconnect-battery.sh"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    const data = JSON.parse(text || "[]");
                    popover.kdeBatteries = Array.isArray(data) ? data : [];
                } catch (e) {
                    popover.kdeBatteries = [];
                }
            }
        }
    }

    Timer {
        interval: 15000
        repeat: true
        running: true
        onTriggered: {
            if (!kdeBatteryProcess.running)
                kdeBatteryProcess.running = true;
        }
    }

    Component.onCompleted: {
        popover.stopDiscovery();
        kdeBatteryProcess.running = true;
    }

    Component.onDestruction: popover.stopDiscovery()

    component DeviceRow: Item {
        id: row

        required property var modelData
        readonly property var device: modelData

        height: 46

            Rectangle {
                anchors.fill: parent
                radius: Theme.radiusCard
                color: rowMouse.containsMouse ? Theme.hover : "transparent"
            }

            Rectangle {
                x: 5
                anchors.verticalCenter: parent.verticalCenter
                width: 28
                height: 28
                radius: Theme.radiusControl
                color: Theme.alpha(Theme.fg, 0.05)

                Icon {
                    anchors.centerIn: parent
                    name: popover.deviceGlyph(row.device)
                    size: 17
                    color: Theme.dim
                }
            }

            Column {
                anchors.left: parent.left
                anchors.leftMargin: 43
                anchors.right: action.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Label {
                    width: parent.width
                    value: popover.deviceName(row.device)
                    strong: true
                    size: 10
                    color: Theme.alpha(Theme.fg, 0.86)
                }

                Label {
                    width: parent.width
                    value: popover.subtitle(row.device)
                    size: 8
                    color: popover.batteryPercent(row.device) >= 0
                        ? Theme.primary
                        : Theme.dim
                    opacityValue: 0.68
                }
            }

            Rectangle {
                id: action
                anchors.right: parent.right
                anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(popover.compactActionWidth, actionLabel.implicitWidth + 18)
                height: 24
                radius: Theme.radiusControl
                color: actionMouse.containsMouse
                    ? Theme.alpha(Theme.primary, 0.14)
                    : Theme.input
                border.width: 1
                border.color: row.device && row.device.connected
                    ? Theme.alpha(Theme.primary, 0.32)
                    : Theme.border

                Label {
                    id: actionLabel
                    anchors.centerIn: parent
                    value: popover.actionLabel(row.device)
                    size: 8
                    color: row.device && row.device.connected ? Theme.primary : Theme.dim
                }

                MouseArea {
                    id: actionMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: row.device && !row.device.pairing
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: popover.activateDevice(row.device)
                }
            }

            MouseArea {
                id: rowMouse
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: action.left
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
            }
        }
}
