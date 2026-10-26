import QtQuick
import Quickshell.Networking
import ".."
import "../components"

IconButton {
    id: root

    readonly property var connectedDevice: {
        const devices = Networking.devices.values;
        for (let i = 0; i < devices.length; i++) {
            if (devices[i].connected)
                return devices[i];
        }
        return null;
    }

    readonly property bool hasWifi: {
        const devices = Networking.devices.values;
        for (let i = 0; i < devices.length; i++) {
            if (devices[i].type === DeviceType.Wifi)
                return true;
        }
        return false;
    }

    readonly property bool wired: root.connectedDevice !== null && root.connectedDevice.type === DeviceType.Wired
    readonly property bool wifi: root.connectedDevice !== null && root.connectedDevice.type === DeviceType.Wifi

    icon: root.wifi
        ? Glyphs.wifi
        : (root.wired ? Glyphs.ethernet : (root.hasWifi ? Glyphs.wifiOff : Glyphs.networkUnknown))
    iconSize: 19
    size: Settings.bar.iconButton
    active: ShellState.overlay === "network"
    iconColor: root.connectedDevice !== null ? Theme.fg : Theme.alpha(Theme.fg, 0.55)

    onClicked: ShellState.toggleOverlay("network")
}
