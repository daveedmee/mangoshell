import QtQuick
import Quickshell
import "."
import "popups"
import "services"

PopupWindow {
    id: root

    visible: false
    implicitWidth: Settings.overlay.layoutPanelWidth
    implicitHeight: Settings.overlay.layoutPanelHeight
    color: "transparent"
    grabFocus: true

    anchor.window: ShellState.barWindow
    // The picker belongs to the left bar island, not to the button that
    // happens to open it. The bar is flush with the screen edge, so the
    // picker is too; the y offset preserves the gap to the bar.
    anchor.rect.x: 0
    anchor.rect.y: Settings.bar.islandTop + Settings.bar.islandHeight + Settings.overlay.topGap

    onVisibleChanged: {
        if (!root.visible && ShellState.overlay === "layouts")
            ShellState.closeOverlay();
    }

    Component.onCompleted: root.visible = ShellState.overlay === "layouts"

    Connections {
        target: ShellState

        function onOverlayChanged() {
            root.visible = ShellState.overlay === "layouts";
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        onActivated: ShellState.closeOverlay()
    }

    LayoutPanel {
        anchors.fill: parent
    }
}
