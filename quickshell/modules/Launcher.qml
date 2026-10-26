import QtQuick
import Quickshell
import ".."
import "../components"

IconButton {
    icon: Glyphs.overview
    iconSize: 18
    size: 30
    iconColor: Theme.dim
    tip: "Quick launcher"

    onClicked: Quickshell.execDetached(["rofi", "-show", "drun"])
}
