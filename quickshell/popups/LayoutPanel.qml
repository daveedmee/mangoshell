import QtQuick
import ".."
import "../components"
import "../services"

Rectangle {
    id: root

    implicitHeight: 238
    radius: Theme.radiusPanel
    color: Theme.panel
    border.width: 1
    border.color: Theme.border
    clip: true

    readonly property var layouts: Mango.layouts.length > 0 ? Mango.layouts : [
        { symbol: "T", name: "tile" },
        { symbol: "S", name: "scroller" },
        { symbol: "G", name: "grid" },
        { symbol: "M", name: "monocle" },
        { symbol: "K", name: "deck" },
        { symbol: "CT", name: "center_tile" },
        { symbol: "RT", name: "right_tile" },
        { symbol: "VS", name: "vertical_scroller" },
        { symbol: "VT", name: "vertical_tile" },
        { symbol: "VG", name: "vertical_grid" },
        { symbol: "VK", name: "vertical_deck" },
        { symbol: "DW", name: "dwindle" },
        { symbol: "F", name: "fair" },
        { symbol: "VF", name: "vertical_fair" }
    ]

    readonly property string currentCode: Mango.layoutCodeFor(
        ShellState.barWindow ? ShellState.barWindow.monitorName : "")

    function displayName(name) {
        const parts = (name || "").split("_");
        for (let i = 0; i < parts.length; i++) {
            if (parts[i].length > 0)
                parts[i] = parts[i].charAt(0).toUpperCase() + parts[i].slice(1);
        }
        return parts.join(" ");
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
    }

    Item {
        id: header
        x: 14
        y: 10
        width: parent.width - 28
        height: 24

        Label {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            value: "Window layout"
            strong: true
            size: 11
            color: Theme.fg
        }

        Label {
            anchors.right: closeButton.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            value: Mango.layoutNameFor(ShellState.barWindow ? ShellState.barWindow.monitorName : "")
            size: 8
            color: Theme.dim
            opacityValue: 0.7
        }

        IconButton {
            id: closeButton
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            icon: Glyphs.close
            iconSize: 13
            size: 24
            iconColor: Theme.dim
            onClicked: ShellState.closeOverlay()
        }
    }

    Grid {
        id: grid
        x: 14
        y: 42
        width: parent.width - 28
        columns: 5
        columnSpacing: 6
        rowSpacing: 6

        Repeater {
            model: root.layouts

            delegate: Rectangle {
                id: tile
                required property var modelData

                readonly property bool current: modelData.symbol === root.currentCode

                width: (grid.width - 24) / 5
                height: 52
                radius: Theme.radiusControl
                color: tile.current
                    ? Theme.alpha(Theme.primary, 0.12)
                    : (tileMouse.containsMouse ? Theme.hover : Theme.alpha(Theme.fg, 0.025))
                border.width: 1
                border.color: tile.current
                    ? Theme.alpha(Theme.primary, 0.42)
                    : Theme.alpha(Theme.fg, 0.065)

                Column {
                    anchors.centerIn: parent
                    width: parent.width - 8
                    spacing: 2

                    Icon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        name: Glyphs.layoutIcon(tile.modelData.name)
                        rotation: Glyphs.layoutRotation(tile.modelData.name)
                        size: 20
                        color: tile.current ? Theme.primary : Theme.alpha(Theme.fg, 0.82)
                    }

                    Label {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        value: root.displayName(tile.modelData.name)
                        size: 7
                        color: tile.current ? Theme.primary : Theme.dim
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: tileMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Mango.setLayout(tile.modelData.name);
                        ShellState.closeOverlay();
                    }
                }
            }
        }
    }
}
