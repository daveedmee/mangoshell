import QtQuick
import ".."
import "../components"

IconButton {
    id: root

    icon: Glyphs.tune
    iconSize: 19
    size: Settings.bar.iconButton
    outlined: true
    active: ShellState.overlay === "controls"

    onClicked: ShellState.toggleOverlay("controls")
}
