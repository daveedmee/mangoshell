import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import QtQuick.Effects
import ".."
import "../components"

Item {
    id: root

    readonly property int iconSize: Settings.bar.trayIconSize
    readonly property var items: SystemTray.items

    visible: trayRepeater.count > 0
    implicitWidth: visible ? trayRow.width + 8 : 0
    // Match the tallest right-island control so Row does not top-align the
    // tray above the other bar icons.
    implicitHeight: 34

    Row {
        id: trayRow
        anchors.centerIn: parent
        spacing: Settings.bar.traySpacing

        Repeater {
            id: trayRepeater
            model: SystemTray.items

            delegate: Item {
                id: entry

                readonly property var trayItem: modelData

                width: root.iconSize + 4
                height: root.iconSize + 4

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radiusControl
                    color: entryMouse.containsMouse ? Theme.hover : "transparent"
                }

                Item {
                    anchors.centerIn: parent
                    width: root.iconSize
                    height: root.iconSize

                    Image {
                        id: iconImage
                        anchors.fill: parent
                        source: root.iconSource(entry.trayItem ? entry.trayItem.icon : "")
                        sourceSize.width: root.iconSize
                        sourceSize.height: root.iconSize
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        visible: false
                    }

                    MultiEffect {
                        anchors.fill: parent
                        source: iconImage
                        colorization: 1.0
                        colorizationColor: Theme.alpha(Theme.fg, entryMouse.containsMouse ? 0.92 : 0.68)
                    }
                }

                MouseArea {
                    id: entryMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    cursorShape: Qt.PointingHandCursor

                    onClicked: function(event) {
                        if (!entry.trayItem)
                            return;

                        if (event.button === Qt.LeftButton) {
                            if (entry.trayItem.onlyMenu && entry.trayItem.hasMenu)
                                root.openMenu(entry);
                            else
                                entry.trayItem.activate();
                        } else if (event.button === Qt.RightButton && entry.trayItem.hasMenu) {
                            root.openMenu(entry);
                        } else if (event.button === Qt.MiddleButton) {
                            entry.trayItem.secondaryActivate();
                        }
                    }

                    onWheel: function(event) {
                        if (entry.trayItem && event.angleDelta.y !== 0)
                            entry.trayItem.scroll(event.angleDelta.y > 0 ? 1 : -1, false);
                    }
                }

            }
        }
    }

    function openMenu(entry) {
        if (!entry || !entry.trayItem || !entry.trayItem.hasMenu || !entry.trayItem.menu)
            return;
        const point = entry.mapToItem(null, 0, 0);
        ShellState.trayMenu = entry.trayItem.menu;
        // Open the menu leftwards from the tray icon; OverlayHost clamps it
        // against the screen edge.
        ShellState.trayMenuX = point.x + entry.width - Settings.overlay.trayMenuWidth;
        ShellState.openOverlay("tray");
    }

    function iconSource(name) {
        if (!name || name.length === 0)
            return "";
        if (name.indexOf("/") === 0 || name.indexOf("file:") === 0 || name.indexOf("image://") === 0)
            return name;
        return Quickshell.iconPath(name, true);
    }
}
