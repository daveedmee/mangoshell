import QtQuick
import Quickshell.Bluetooth
import ".."
import "../components"

IconButton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    property int connectedCount: 0
    readonly property bool enabled: root.adapter !== null && root.adapter.enabled

    function refreshConnectedCount() {
        if (!root.adapter) {
            root.connectedCount = 0;
            return;
        }
        const devices = root.adapter.devices.values;
        let count = 0;
        for (let i = 0; i < devices.length; i++) {
            if (devices[i].connected)
                count += 1;
        }
        root.connectedCount = count;
    }

    visible: root.adapter !== null
    icon: !root.enabled
        ? Glyphs.bluetoothOff
        : (root.connectedCount > 0 ? Glyphs.bluetoothConnected : Glyphs.bluetooth)
    iconSize: 18
    size: Settings.bar.iconButton
    active: ShellState.overlay === "bluetooth"
    iconColor: !root.enabled
        ? Theme.alpha(Theme.fg, 0.32)
        : (root.connectedCount > 0 ? Theme.tertiary : Theme.fg)
    filled: root.enabled && root.connectedCount > 0
    badgeVisible: root.enabled && root.connectedCount > 0
    badgeText: root.connectedCount > 9 ? "9+" : ("" + root.connectedCount)

    onClicked: ShellState.toggleOverlay("bluetooth")

    onRightClicked: {
        if (root.adapter)
            root.adapter.enabled = !root.adapter.enabled;
    }

    Component.onCompleted: root.refreshConnectedCount()

    // BluetoothDevice.connected changes do not invalidate the adapter's device
    // list binding, so keep the compact bar state in sync explicitly.
    Timer {
        interval: 1000
        repeat: true
        running: root.adapter !== null
        onTriggered: root.refreshConnectedCount()
    }
}
