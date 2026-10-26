import QtQuick
import ".."
import "../components"
import "../services"

IconButton {
    id: root

    visible: Storage.usbCount > 0 || ShellState.overlay === "devices"
    icon: Glyphs.usb
    iconSize: 18
    size: Settings.bar.iconButton
    active: ShellState.overlay === "devices"
    iconColor: Theme.fg

    onClicked: {
        Storage.refresh();
        ShellState.toggleOverlay("devices");
    }

    onRightClicked: Storage.refresh()
}
