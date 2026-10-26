import QtQuick
import Quickshell
import ".."
import "../components"

Rectangle {
    id: root

    implicitWidth: Settings.overlay.trayMenuWidth
    implicitHeight: menuColumn.height + 8
    radius: Theme.radiusPanel
    color: Theme.panel
    border.width: 1
    border.color: Theme.border
    clip: true

    property var expandedEntry: null

    readonly property var menuHandle: ShellState.trayMenu

    QsMenuOpener {
        id: opener
        menu: root.menuHandle
    }

    QsMenuOpener {
        id: childOpener
        menu: root.expandedEntry
    }

    Connections {
        target: ShellState

        function onTrayMenuChanged() {
            root.expandedEntry = null;
        }
    }

    function activate(entry) {
        if (!entry || !entry.enabled)
            return;
        if (entry.hasChildren) {
            root.expandedEntry = root.expandedEntry === entry ? null : entry;
            return;
        }
        entry.triggered();
        ShellState.closeOverlay();
    }

    Column {
        id: menuColumn
        width: parent.width
        y: 4

        Repeater {
            model: opener.children

            delegate: Item {
                id: menuItem
                required property var modelData

                readonly property bool separator: modelData.isSeparator
                readonly property bool expandable: modelData.hasChildren
                readonly property bool expanded: root.expandedEntry === modelData
                readonly property bool checked: modelData.checkState === Qt.Checked
                readonly property bool hasIcon: modelData.icon !== undefined
                    && modelData.icon !== null && modelData.icon.length > 0

                width: menuColumn.width
                height: separator ? 9 : 30 + (expanded ? childrenColumn.height : 0)

                Rectangle {
                    visible: menuItem.separator
                    x: 10
                    y: 4
                    width: parent.width - 20
                    height: 1
                    color: Theme.alpha(Theme.fg, 0.08)
                }

                Rectangle {
                    visible: !menuItem.separator
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: 30
                    radius: Theme.radiusControl
                    color: !menuItem.modelData.enabled
                        ? "transparent"
                        : (itemMouse.containsMouse || menuItem.expanded ? Theme.hover : "transparent")
                }

                Icon {
                    visible: !menuItem.separator && menuItem.checked
                    anchors.left: parent.left
                    anchors.leftMargin: 9
                    anchors.top: parent.top
                    anchors.topMargin: 7
                    name: Glyphs.check
                    size: 13
                    color: Theme.primary
                }

                Label {
                    visible: !menuItem.separator
                    anchors.left: parent.left
                    anchors.leftMargin: menuItem.checked ? 27 : 11
                    anchors.right: menuItem.expandable ? chevron.left : parent.right
                    anchors.rightMargin: menuItem.expandable ? 5 : 10
                    anchors.top: parent.top
                    height: 30
                    value: menuItem.modelData.text || ""
                    size: 11
                    color: menuItem.modelData.enabled
                        ? Theme.fg
                        : Theme.alpha(Theme.dim, 0.45)
                    elide: Text.ElideRight
                }

                Icon {
                    id: chevron
                    visible: !menuItem.separator && menuItem.expandable
                    anchors.right: parent.right
                    anchors.rightMargin: 9
                    anchors.top: parent.top
                    anchors.topMargin: 8
                    name: Glyphs.chevronRight
                    size: 13
                    color: Theme.dim
                }

                MouseArea {
                    id: itemMouse
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: 30
                    enabled: !menuItem.separator && menuItem.modelData.enabled
                    hoverEnabled: true
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.activate(menuItem.modelData)
                }

                Column {
                    id: childrenColumn
                    visible: menuItem.expanded
                    x: 18
                    y: 30
                    width: parent.width - 18
                    spacing: 0

                    Repeater {
                        model: menuItem.expanded ? childOpener.children : []

                        delegate: Item {
                            id: childItem
                            required property var modelData

                            readonly property bool separator: modelData.isSeparator
                            readonly property bool checked: modelData.checkState === Qt.Checked

                            width: childrenColumn.width
                            height: separator ? 9 : 28

                            Rectangle {
                                visible: childItem.separator
                                x: 4
                                y: 4
                                width: parent.width - 8
                                height: 1
                                color: Theme.alpha(Theme.fg, 0.08)
                            }

                            Rectangle {
                                visible: !childItem.separator
                                anchors.fill: parent
                                radius: Theme.radiusControl
                                color: childMouse.containsMouse ? Theme.hover : "transparent"
                            }

                            Icon {
                                visible: !childItem.separator && childItem.checked
                                anchors.left: parent.left
                                anchors.leftMargin: 5
                                anchors.verticalCenter: parent.verticalCenter
                                name: Glyphs.check
                                size: 12
                                color: Theme.primary
                            }

                            Label {
                                visible: !childItem.separator
                                anchors.left: parent.left
                                anchors.leftMargin: childItem.checked ? 22 : 7
                                anchors.right: parent.right
                                anchors.rightMargin: 7
                                anchors.verticalCenter: parent.verticalCenter
                                value: childItem.modelData.text || ""
                                size: 10
                                color: childItem.modelData.enabled
                                    ? Theme.alpha(Theme.fg, 0.86)
                                    : Theme.alpha(Theme.dim, 0.45)
                                elide: Text.ElideRight
                            }

                            MouseArea {
                                id: childMouse
                                anchors.fill: parent
                                enabled: !childItem.separator && childItem.modelData.enabled
                                hoverEnabled: true
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: {
                                    childItem.modelData.triggered();
                                    ShellState.closeOverlay();
                                }
                            }
                        }
                    }
                }
            }
        }

        Label {
            visible: opener.children.count === 0
            width: parent.width
            height: 30
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            value: "No menu items"
            size: 10
            color: Theme.dim
            opacityValue: 0.55
        }
    }
}
