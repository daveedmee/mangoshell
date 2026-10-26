import QtQuick
import ".."
import "../components"

IconButton {
    id: root

    icon: Glyphs.power
    iconSize: 19
    size: Settings.bar.iconButton
    active: ShellState.overlay === "session"

    onClicked: ShellState.toggleOverlay("session")
}
