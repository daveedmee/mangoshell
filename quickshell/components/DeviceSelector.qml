import QtQuick
import QtQuick.Layouts
import ".."

Column {
    id: root

    property var devices: []
    property var current: null
    property string icon: Glyphs.volumeHigh
    property string emptyText: "No device"
    property bool expanded: false

    signal selected(var device)

    spacing: 4

    function deviceLabel(node) {
        if (!node)
            return "";
        const nickname = node.nickname || "";
        const description = node.description || "";
        if (!description)
            return nickname || node.name || "";
        if (!nickname || description.toLowerCase().includes(nickname.toLowerCase()))
            return description;
        return nickname + " · " + description;
    }

    function isCurrent(node) {
        if (!root.current || !node)
            return false;
        return node === root.current || node.id === root.current.id;
    }

    function collapse() {
        root.expanded = false;
    }

    Rectangle {
        id: selector
        width: parent.width
        height: 30
        radius: Theme.radiusControl
        color: root.expanded ? Theme.hover : "transparent"
        border.width: root.expanded ? 1 : 0
        border.color: Theme.border

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 7

            Icon {
                name: root.icon
                size: 14
                color: Theme.dim
            }

            Label {
                Layout.fillWidth: true
                value: root.current ? root.deviceLabel(root.current) : root.emptyText
                size: 10
                color: root.current ? Theme.dim : Theme.dim
                opacityValue: root.current ? 0.82 : 0.5
            }

            Icon {
                name: root.expanded ? Glyphs.chevronUp : Glyphs.chevronDown
                size: 12
                color: Theme.dim
                opacityValue: 0.5
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded = !root.expanded
        }
    }

    Rectangle {
        width: parent.width
        height: root.expanded
            ? Math.min(Math.max(0, list.contentHeight) + 6, Settings.volume.deviceListMaxHeight)
            : 0
        visible: root.expanded
        radius: Theme.radiusControl
        color: Theme.surfaceLowest
        border.width: 1
        border.color: Theme.border
        clip: true

        ListView {
            id: list
            anchors.fill: parent
            anchors.margins: 3
            clip: true
            spacing: 1
            model: root.devices
            boundsBehavior: Flickable.StopAtBounds

            delegate: Item {
                id: entry
                required property var modelData
                width: list.width
                height: 32

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radiusControl
                    color: root.isCurrent(entry.modelData)
                        ? Theme.selected
                        : (entryMouse.containsMouse ? Theme.hover : "transparent")
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 7

                    Icon {
                        name: Glyphs.check
                        size: 12
                        color: root.isCurrent(entry.modelData) ? Theme.primary : Theme.dim
                        opacityValue: root.isCurrent(entry.modelData) ? 1 : 0
                    }

                    Label {
                        Layout.fillWidth: true
                        value: root.deviceLabel(entry.modelData)
                        size: 10
                        color: root.isCurrent(entry.modelData) ? Theme.fg : Theme.dim
                    }
                }

                MouseArea {
                    id: entryMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.selected(entry.modelData);
                        root.expanded = false;
                    }
                }
            }
        }
    }
}
