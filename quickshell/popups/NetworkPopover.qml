import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import Quickshell.Io
import ".."
import "../components"

Rectangle {
    id: popover

    implicitWidth: Settings.overlay.popoverWidth
    implicitHeight: 76 + body.implicitHeight + 16
    radius: Theme.radiusPanel
    color: Theme.panel
    border.width: 1
    border.color: Theme.border
    clip: true

    readonly property var devices: Networking.devices.values
    // Quickshell's Networking API only reports Wi-Fi and wired devices. VPN
    // interfaces (WireGuard, tun/tap, NetworkManager VPNs) are enumerated from
    // nmcli so they still appear alongside the physical interfaces. When the
    // IVPN client manages the tunnel it is preferred, because it reconnects
    // the profile as soon as NetworkManager deactivates it.
    property var nmcliVpns: []
    property bool ivpnAvailable: false
    property bool ivpnConnected: false
    property string ivpnDetail: ""
    readonly property var ivpnRows: [{
        name: "IVPN",
        connection: "IVPN",
        manager: "ivpn",
        type: "wireguard",
        device: "",
        state: popover.ivpnConnected ? "activated" : "deactivated",
        connected: popover.ivpnConnected,
        detail: popover.ivpnDetail
    }]
    readonly property var vpnDevices: popover.ivpnAvailable
        ? popover.ivpnRows
        : popover.nmcliVpns
    property bool actionRunning: false
    property string actionTarget: ""
    property bool actionDesiredOn: false
    property string lastError: ""
    readonly property var connectedDevice: {
        const list = Networking.devices.values;
        for (let i = 0; i < list.length; i++) {
            if (list[i].connected)
                return list[i];
        }
        return null;
    }
    readonly property var wifiDevice: {
        const list = Networking.devices.values;
        for (let i = 0; i < list.length; i++) {
            if (list[i].type === DeviceType.Wifi)
                return list[i];
        }
        return null;
    }
    readonly property bool hasWifi: popover.wifiDevice !== null
    readonly property string connectedWifiName: {
        const device = popover.connectedDevice;
        if (!device || device.type !== DeviceType.Wifi)
            return "";
        const networks = device.networks.values;
        for (let i = 0; i < networks.length; i++) {
            if (networks[i].connected)
                return networks[i].name;
        }
        return "";
    }
    readonly property string currentTitle: {
        if (!popover.connectedDevice)
            return "Not connected";
        if (popover.connectedDevice.type === DeviceType.Wifi)
            return popover.connectedWifiName.length > 0 ? popover.connectedWifiName : "Wi-Fi";
        return "Ethernet";
    }
    readonly property string currentSubtitle: {
        if (!popover.connectedDevice)
            return "No active network connection";
        const address = popover.connectedDevice.address || "";
        const name = popover.connectedDevice.name || "";
        return name + (address.length > 0 ? " · " + address : "");
    }

    function deviceIcon(device) {
        if (!device)
            return Glyphs.networkUnknown;
        if (device.type === DeviceType.Wifi)
            return Glyphs.wifi;
        if (device.type === DeviceType.Wired)
            return Glyphs.ethernet;
        return Glyphs.networkUnknown;
    }

    function deviceLabel(device) {
        if (!device)
            return "Network";
        if (device.type === DeviceType.Wired)
            return "Wired";
        if (device.type === DeviceType.Wifi)
            return "Wi-Fi";
        return device.name || "Network";
    }

    function vpnTypeLabel(type) {
        if (type === "wireguard")
            return "WireGuard";
        if (type === "tun")
            return "Tunnel";
        if (type === "tap")
            return "TAP";
        if (type === "vpn")
            return "VPN";
        return type ? type.charAt(0).toUpperCase() + type.slice(1) : "VPN";
    }

    function isBusy(target) {
        return popover.actionRunning && popover.actionTarget === target;
    }

    function vpnActionTarget(vpn) {
        if (!vpn)
            return "";
        return vpn.manager === "ivpn" ? "ivpn" : vpn.name;
    }

    function vpnBusy(vpn) {
        return popover.actionRunning
            && popover.actionTarget === popover.vpnActionTarget(vpn);
    }

    function vpnStatusText(vpn) {
        if (!vpn)
            return "";
        if (popover.vpnBusy(vpn))
            return popover.actionDesiredOn ? "Connecting…" : "Disconnecting…";
        return vpn.connected ? "Connected" : "Disconnected";
    }

    function deviceStatusText(device) {
        if (!device)
            return "";
        if (device.type === DeviceType.Wifi) {
            if (!Networking.wifiEnabled)
                return "Off";
            return device.connected ? "Connected" : "On";
        }
        if (popover.isBusy(device.name))
            return popover.actionDesiredOn ? "Connecting…" : "Disconnecting…";
        return device.connected ? "Connected" : "Disconnected";
    }

    function deviceToggleChecked(device) {
        if (!device)
            return false;
        if (device.type === DeviceType.Wifi)
            return Networking.wifiEnabled;
        if (popover.isBusy(device.name))
            return popover.actionDesiredOn;
        return device.connected;
    }

    // nmcli -t escapes ':' inside values. Split on unescaped separators and
    // unescape the result so connection names with colons survive intact.
    function splitNmcliLine(line) {
        const fields = [];
        let value = "";
        for (let i = 0; i < line.length; i++) {
            const ch = line.charAt(i);
            if (ch === "\\" && i + 1 < line.length) {
                value += line.charAt(i + 1);
                i += 1;
            } else if (ch === ":") {
                fields.push(value);
                value = "";
            } else {
                value += ch;
            }
        }
        fields.push(value);
        return fields;
    }

    function applyVpnList(text) {
        const lines = ("" + text).split("\n");
        const vpnTypes = ["wireguard", "vpn", "tun", "tap"];
        const list = [];

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();
            if (line.length === 0)
                continue;

            const parts = popover.splitNmcliLine(line);
            if (parts.length < 3)
                continue;

            const type = parts[1];
            if (vpnTypes.indexOf(type) === -1)
                continue;

            const active = parts[2] === "yes";
            list.push({
                name: parts[0],
                connection: parts[0],
                manager: "nmcli",
                type: type,
                device: "",
                state: active ? "activated" : "deactivated",
                connected: active,
                detail: ""
            });
        }

        popover.nmcliVpns = list;
    }

    function applyIvpnStatus(text) {
        const lines = ("" + text).split("\n");
        let connected = false;
        let detail = "";

        for (let i = 0; i < lines.length; i++) {
            const trimmed = lines[i].trim();
            const indented = lines[i].length > 0
                && (lines[i].charAt(0) === " " || lines[i].charAt(0) === "\t");
            const colon = trimmed.indexOf(":");
            if (colon <= 0) {
                if (connected && detail.length === 0 && indented
                        && trimmed.indexOf("[") >= 0) {
                    const server = trimmed.match(/^(\S+)\s*\[([^\]]+)\],\s*([^,]+)/);
                    detail = server
                        ? server[2] + " · " + server[3].trim()
                        : trimmed;
                }
                continue;
            }

            const key = trimmed.slice(0, colon).trim().toLowerCase();
            const value = trimmed.slice(colon + 1).trim();

            if (key === "vpn") {
                connected = value.toUpperCase().indexOf("CONNECTED") === 0;
            } else if (connected && detail.length === 0
                    && (key === "server" || key === "location")) {
                detail = value;
            }
        }

        popover.ivpnConnected = connected;
        popover.ivpnDetail = detail;
    }

    function runAction(command, target, desiredOn) {
        if (popover.actionRunning)
            return;
        popover.lastError = "";
        popover.actionRunning = true;
        popover.actionTarget = target || "";
        popover.actionDesiredOn = desiredOn === true;
        actionProcess.command = command;
        actionProcess.running = true;
    }

    function toggleInterface(device) {
        if (!device)
            return;

        if (device.type === DeviceType.Wifi) {
            Networking.wifiEnabled = !Networking.wifiEnabled;
            return;
        }

        if (device.connected)
            popover.runAction(["nmcli", "device", "disconnect", device.name], device.name, false);
        else
            popover.runAction(["nmcli", "device", "connect", device.name], device.name, true);
    }

    function toggleVpn(vpn) {
        if (!vpn)
            return;

        if (vpn.manager === "ivpn") {
            popover.runAction(vpn.connected
                ? ["ivpn", "disconnect"]
                : ["ivpn", "connect", "-last"], "ivpn", !vpn.connected);
            return;
        }

        popover.runAction(vpn.connected
            ? ["nmcli", "connection", "down", vpn.name]
            : ["nmcli", "connection", "up", vpn.name], vpn.name, !vpn.connected);
    }

    function refreshVpnDevices() {
        if (popover.actionRunning)
            return;
        if (!popover.ivpnAvailable && !vpnProcess.running)
            vpnProcess.running = true;
        if (popover.ivpnAvailable && !ivpnStatusProcess.running)
            ivpnStatusProcess.running = true;
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
            value: "NetworkManager"
            eyebrow: true
            size: 8
            color: Theme.dim
            opacityValue: 0.7
        }

        Label {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.topMargin: 12
            value: "Network"
            strong: true
            size: 17
            color: Theme.fg
        }

        Row {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 2
            spacing: 6

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
            height: 56
            radius: Theme.radiusPanel
            color: Theme.primaryContainer
            border.width: 1
            border.color: Theme.alpha(Theme.primary, 0.16)

            Rectangle {
                x: 11
                anchors.verticalCenter: parent.verticalCenter
                width: 32
                height: 32
                radius: Theme.radiusCard
                color: Theme.alpha(Theme.primaryContainerText, 0.14)

                Icon {
                    anchors.centerIn: parent
                    name: popover.connectedDevice ? popover.deviceIcon(popover.connectedDevice) : Glyphs.networkUnknown
                    size: 18
                    filled: popover.connectedDevice !== null
                    color: Theme.primaryContainerText
                }
            }

            Column {
                anchors.left: parent.left
                anchors.leftMargin: 54
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Label {
                    width: parent.width
                    value: popover.currentTitle
                    strong: true
                    size: 11
                    color: Theme.primaryContainerText
                }

                Label {
                    width: parent.width
                    value: popover.currentSubtitle
                    size: 8
                    color: Theme.primaryContainerText
                    opacityValue: 0.7
                }
            }
        }

        Item {
            width: parent.width
            height: 15

            Label {
                anchors.left: parent.left
                value: "Network devices"
                strong: true
                size: 11
                color: Theme.fg
            }

            Label {
                anchors.right: parent.right
                value: "LAN · Wi-Fi · VPN"
                size: 8
                color: Theme.dim
                opacityValue: 0.55
            }
        }

        Column {
            width: parent.width
            spacing: 2

            Repeater {
                model: popover.devices

                delegate: Item {
                    id: deviceRow
                    required property var modelData

                    width: parent.width
                    height: 42

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.radiusCard
                        color: deviceMouse.containsMouse ? Theme.hover : "transparent"
                    }

                    Icon {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        name: popover.deviceIcon(deviceRow.modelData)
                        size: 17
                        color: deviceRow.modelData.connected ? Theme.primary : Theme.dim
                    }

                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: 35
                        anchors.right: statusLabel.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 0

                        Label {
                            width: parent.width
                            value: popover.deviceLabel(deviceRow.modelData) + " · " + (deviceRow.modelData.name || "")
                            size: 10
                            color: Theme.alpha(Theme.fg, 0.82)
                        }

                        Label {
                            width: parent.width
                            value: deviceRow.modelData.address && deviceRow.modelData.address.length > 0
                                ? deviceRow.modelData.address
                                : "No address"
                            size: 8
                            color: Theme.dim
                            opacityValue: 0.55
                        }
                    }

                    MouseArea {
                        id: deviceMouse
                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton
                        hoverEnabled: true
                    }

                    Label {
                        id: statusLabel
                        anchors.right: deviceToggle.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        value: popover.deviceStatusText(deviceRow.modelData)
                        size: 8
                        color: deviceRow.modelData.connected ? Theme.primary : Theme.dim
                        opacityValue: deviceRow.modelData.connected ? 1 : 0.55
                    }

                    ToggleSwitch {
                        id: deviceToggle
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        checked: popover.deviceToggleChecked(deviceRow.modelData)
                        interactive: !popover.actionRunning
                        onToggled: popover.toggleInterface(deviceRow.modelData)
                    }
                }
            }

            Repeater {
                model: popover.vpnDevices

                delegate: Item {
                    id: vpnRow
                    required property var modelData

                    width: parent.width
                    height: 42

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.radiusCard
                        color: vpnMouse.containsMouse ? Theme.hover : "transparent"
                    }

                    Icon {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        name: Glyphs.vpn
                        size: 17
                        color: vpnRow.modelData.connected ? Theme.secondary : Theme.dim
                    }

                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: 35
                        anchors.right: vpnState.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 0

                        Label {
                            width: parent.width
                            value: "VPN · " + (vpnRow.modelData.connection || vpnRow.modelData.name)
                            size: 10
                            color: Theme.alpha(Theme.fg, 0.82)
                        }

                        Label {
                            width: parent.width
                            value: vpnRow.modelData.detail
                                && vpnRow.modelData.detail.length > 0
                                ? vpnRow.modelData.detail
                                : vpnRow.modelData.name + " · "
                                    + popover.vpnTypeLabel(vpnRow.modelData.type)
                            size: 8
                            color: Theme.dim
                            opacityValue: 0.55
                        }
                    }

                    MouseArea {
                        id: vpnMouse
                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton
                        hoverEnabled: true
                    }

                    Label {
                        id: vpnState
                        anchors.right: vpnToggle.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        value: popover.vpnStatusText(vpnRow.modelData)
                        size: 8
                        color: vpnRow.modelData.connected ? Theme.primary : Theme.dim
                        opacityValue: vpnRow.modelData.connected ? 1 : 0.55
                    }

                    ToggleSwitch {
                        id: vpnToggle
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        checked: popover.vpnBusy(vpnRow.modelData)
                            ? popover.actionDesiredOn
                            : vpnRow.modelData.connected
                        interactive: !popover.actionRunning
                        onToggled: popover.toggleVpn(vpnRow.modelData)
                    }
                }
            }

            Label {
                visible: popover.devices.length === 0 && popover.vpnDevices.length === 0
                width: parent.width
                value: "No network devices"
                size: 9
                color: Theme.dim
                opacityValue: 0.5
            }
        }

        Rectangle {
            visible: popover.lastError.length > 0
            width: parent.width
            height: visible ? 30 : 0
            radius: Theme.radiusControl
            color: Theme.alpha(Theme.error, 0.10)
            border.width: 1
            border.color: Theme.alpha(Theme.error, 0.24)

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 9
                anchors.right: parent.right
                anchors.rightMargin: 9
                anchors.verticalCenter: parent.verticalCenter
                spacing: 7

                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: Glyphs.warning
                    size: 14
                    color: Theme.error
                }

                Label {
                    width: parent.width - 21
                    anchors.verticalCenter: parent.verticalCenter
                    value: popover.lastError
                    size: 8
                    color: Theme.error
                }
            }
        }

        Column {
            visible: popover.hasWifi
            width: parent.width
            spacing: 2

            Repeater {
                model: popover.wifiDevice ? popover.wifiDevice.networks.values : []

                delegate: Item {
                    id: networkRow
                    required property var modelData

                    width: parent.width
                    height: 38

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.radiusCard
                        color: networkMouse.containsMouse && networkRow.modelData.known ? Theme.hover : "transparent"
                    }

                    Icon {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        name: Glyphs.wifi
                        size: 16
                        color: networkRow.modelData.connected ? Theme.primary : Theme.dim
                    }

                    Label {
                        anchors.left: parent.left
                        anchors.leftMargin: 34
                        anchors.right: networkState.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        value: networkRow.modelData.name
                        size: 10
                        color: Theme.alpha(Theme.fg, 0.8)
                    }

                    Label {
                        id: networkState
                        anchors.right: parent.right
                        anchors.rightMargin: 9
                        anchors.verticalCenter: parent.verticalCenter
                        value: networkRow.modelData.connected
                            ? "Connected"
                            : (networkRow.modelData.known ? "Saved" : "")
                        size: 8
                        color: networkRow.modelData.connected ? Theme.primary : Theme.dim
                        opacityValue: 0.6
                    }

                    MouseArea {
                        id: networkMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: networkRow.modelData.known && !networkRow.modelData.connected
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: networkRow.modelData.connect()
                    }
                }
            }

            Label {
                visible: popover.wifiDevice && popover.wifiDevice.networks.values.length === 0
                width: parent.width
                value: "No networks found"
                size: 8
                color: Theme.dim
                opacityValue: 0.5
            }
        }

        Rectangle {
            width: parent.width
            height: 30
            radius: Theme.radiusControl
            color: settingsMouse.containsMouse ? Theme.hover : Theme.input
            border.width: 1
            border.color: Theme.border

            Row {
                anchors.centerIn: parent
                spacing: 7

                Icon {
                    name: Glyphs.settings
                    size: 14
                    color: Theme.dim
                }

                Label {
                    value: "Network settings"
                    size: 9
                    color: Theme.dim
                }
            }

            MouseArea {
                id: settingsMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["nm-connection-editor"])
            }
        }
    }

    Process {
        id: vpnProcess
        command: ["nmcli", "-t", "-f", "NAME,TYPE,ACTIVE", "connection", "show"]

        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: popover.applyVpnList(text)
        }
    }

    Process {
        id: ivpnWhichProcess
        command: ["bash", "-c", "command -v ivpn"]
        stdout: StdioCollector {
            id: ivpnWhichOutput
            waitForEnd: true
        }
        onExited: function(code) {
            popover.ivpnAvailable = code === 0
                && ("" + ivpnWhichOutput.text).trim().length > 0;
            popover.refreshVpnDevices();
        }
    }

    Process {
        id: ivpnStatusProcess
        command: ["ivpn", "status"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: popover.applyIvpnStatus(text)
        }
    }

    Process {
        id: actionProcess
        stdout: StdioCollector {
            id: actionOutput
            waitForEnd: true
        }
        stderr: StdioCollector {
            id: actionError
            waitForEnd: true
        }
        onExited: function(code) {
            const message = ("" + actionError.text).trim();
            const output = ("" + actionOutput.text).trim();
            popover.actionRunning = false;
            popover.actionTarget = "";
            if (code !== 0) {
                popover.lastError = message.length > 0
                    ? message.split("\n")[0]
                    : (output.length > 0
                        ? output.split("\n")[0]
                        : "Network action failed");
            }
            popover.refreshVpnDevices();
        }
    }

    Timer {
        interval: 4000
        repeat: true
        running: true
        onTriggered: popover.refreshVpnDevices()
    }

    Component.onCompleted: {
        ivpnWhichProcess.running = true;
        popover.refreshVpnDevices();
    }
}
