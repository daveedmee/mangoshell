import QtQuick
import ".."
import "../components"
import "../services"

IconButton {
    id: root

    property string monitor: ""

    readonly property string layoutName: Mango.layoutNameFor(monitor)
    readonly property string layoutCode: Mango.layoutCodeFor(monitor)
    property double lastToggle: 0

    visible: root.layoutCode.length > 0
    icon: Glyphs.layoutIcon(layoutName)
    iconRotation: Glyphs.layoutRotation(layoutName)
    iconSize: 18
    size: Settings.bar.iconButton
    active: ShellState.overlay === "layouts"
    iconColor: Theme.alpha(Theme.fg, 0.72)

    onClicked: {
        const now = Date.now();
        if (now - root.lastToggle < 300)
            return;
        root.lastToggle = now;
        if (ShellState.overlay === "layouts") {
            ShellState.closeOverlay();
            return;
        }

        const point = root.mapToItem(null, 0, root.height);
        ShellState.layoutAnchorX = point.x;
        ShellState.layoutAnchorY = point.y;
        ShellState.openOverlay("layouts");
    }

    Icon {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 4
        anchors.bottomMargin: 3
        name: Glyphs.chevronDown
        size: 10
        color: Theme.alpha(Theme.dim, 0.7)
    }
}
