import QtQuick
import Quickshell
import Quickshell.Wayland
import "."
import "components"
import "modules"
import "services"

PanelWindow {
    id: bar

    property var targetScreen: null

    screen: targetScreen || (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)
    visible: !ShellState.overlayBlocksBar
    readonly property string monitorName: screen && screen.name ? screen.name : ""

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: Settings.bar.height
    exclusiveZone: Settings.bar.height
    color: "transparent"
    focusable: false

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-bar"

    Component.onCompleted: {
        ShellState.barWindow = bar;
        if (bar.monitorName.length > 0)
            ShellState.barWindows[bar.monitorName] = bar;
    }

    Item {
        anchors.fill: parent

        // ── left: session, tags, layout ─────────────────────────────────
        Rectangle {
            id: leftIsland
            x: Settings.bar.sideMargin
            y: Settings.bar.islandTop
            height: Settings.bar.islandHeight
            width: leftRow.implicitWidth + Settings.bar.islandPadding * 2
            radius: Theme.radiusBar
            color: Theme.bar
            border.width: 1
            border.color: Theme.border

            Row {
                id: leftRow
                anchors.left: parent.left
                anchors.leftMargin: Settings.bar.islandPadding
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                Power {}

                BarDivider { spacing: 6 }

                Tags {
                    monitor: bar.monitorName
                }

                BarDivider { spacing: 6 }

                Layout {
                    monitor: bar.monitorName
                }
            }
        }

        // ── centre: clock and focused window ───────────────────────────
        Rectangle {
            id: centerIsland
            anchors.horizontalCenter: parent.horizontalCenter
            y: Settings.bar.islandTop
            height: Settings.bar.islandHeight
            width: centerRow.implicitWidth + Settings.bar.islandPadding * 2
            Binding {
                target: ShellState
                property: "centerBarWidth"
                value: centerIsland.width
            }
            radius: Theme.radiusBar
            color: Theme.bar
            border.width: 1
            border.color: Theme.border

            Row {
                id: centerRow
                anchors.centerIn: parent
                spacing: 0

                Launcher {}

                BarDivider { spacing: 6 }

                Clock {}

                BarDivider { spacing: 6 }

                WindowChip {}
            }
        }

        // ── right: media, tray, system, notifications, controls ─────────
        Rectangle {
            id: rightIsland
            anchors.right: parent.right
            anchors.rightMargin: Settings.bar.sideMargin
            y: Settings.bar.islandTop
            height: Settings.bar.islandHeight
            width: rightRow.implicitWidth + Settings.bar.islandPadding * 2
            radius: Theme.radiusBar
            color: Theme.bar
            border.width: 1
            border.color: Theme.border

            Row {
                id: rightRow
                anchors.right: parent.right
                anchors.rightMargin: Settings.bar.islandPadding
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                MediaChip { id: mediaChip }

                BarDivider {
                    visible: mediaChip.visible
                    spacing: 6
                }

                Tray { id: tray }

                BarDivider {
                    visible: tray.visible
                    spacing: 6
                }

                BluetoothStatus {}
                Network {}
                DevicesStatus {}
                Volume {}
                Notifications {}
                ControlsButton {}
            }
        }
    }
}
