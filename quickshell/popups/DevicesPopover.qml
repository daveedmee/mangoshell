import QtQuick
import Quickshell
import ".."
import "../components"
import "../services"

Rectangle {
    id: popover

    implicitWidth: Settings.overlay.devicesWidth
    implicitHeight: 64 + body.implicitHeight + 16
    radius: Theme.radiusPanel
    color: Theme.panel
    border.width: 1
    border.color: Theme.border
    clip: true

    readonly property var items: Storage.usbItems
    readonly property int count: popover.items.length

    function kindLabel(item) {
        if (!item)
            return "";
        return item.kind === "usb-stick" ? "USB stick" : "External drive";
    }

    function statusText(item) {
        if (!item)
            return "";
        if (Storage.actionRunning && Storage.actionDevice === item.device) {
            return Storage.actionKind === "mount" ? "Mounting…" : "Unmounting…";
        }
        if (item.mounted)
            return "Mounted · " + (item.mountpoint || "");
        return "Not mounted";
    }

    function usageText(item) {
        if (!item)
            return "";
        if (item.mounted) {
            return Storage.formatBytes(item.used) + " used · "
                + Storage.formatBytes(item.avail) + " free";
        }
        return Storage.formatBytes(item.size) + " · " + (item.fstype || "");
    }

    function usagePercent(item) {
        if (!item || !item.mounted || item.percent === null || item.percent === undefined)
            return 0;
        const value = Number(item.percent);
        return isFinite(value) ? Math.max(0, Math.min(100, value)) : 0;
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
    }

    Item {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 14
        height: 44

        Label {
            anchors.left: parent.left
            anchors.top: parent.top
            value: "Removable storage"
            eyebrow: true
            size: 8
            color: Theme.dim
            opacityValue: 0.7
        }

        Label {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.topMargin: 12
            value: "Devices"
            strong: true
            size: 17
            color: Theme.fg
        }

        Row {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 2
            spacing: 4

            IconButton {
                icon: Glyphs.refresh
                iconSize: 15
                size: 28
                iconColor: Theme.dim
                onClicked: Storage.refresh()
            }

            IconButton {
                icon: Glyphs.close
                iconSize: 17
                size: 28
                iconColor: Theme.dim
                onClicked: ShellState.closeOverlay()
            }
        }
    }

    Column {
        id: body
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 6
        spacing: 10

        Item {
            width: parent.width
            height: 18

            Label {
                anchors.left: parent.left
                value: "Attached devices"
                strong: true
                size: 11
                color: Theme.fg
            }

            Label {
                anchors.right: parent.right
                value: popover.count
                size: 8
                color: Theme.dim
                opacityValue: 0.55
            }
        }

        Repeater {
            model: popover.items

            delegate: Rectangle {
                id: deviceRow
                required property var modelData

                readonly property var item: modelData
                readonly property bool mounted: item && item.mounted === true
                readonly property bool busy: Storage.actionRunning
                    && Storage.actionDevice === (item ? item.device : "")
                readonly property real usage: popover.usagePercent(item)

                width: parent.width
                height: 84
                radius: Theme.radiusCard
                color: Theme.card
                border.width: 1
                border.color: Theme.alpha(Theme.fg, 0.055)
                clip: true

                Rectangle {
                    x: 10
                    y: 11
                    width: 30
                    height: 30
                    radius: Theme.radiusCard
                    color: deviceRow.mounted
                        ? Theme.alpha(Theme.tertiary, 0.14)
                        : Theme.alpha(Theme.fg, 0.045)

                    Icon {
                        anchors.centerIn: parent
                        name: deviceRow.item && deviceRow.item.kind === "usb-stick"
                            ? Glyphs.usb
                            : Glyphs.storage
                        size: 17
                        filled: deviceRow.mounted
                        color: deviceRow.mounted ? Theme.tertiary : Theme.alpha(Theme.dim, 0.6)
                    }
                }

                Row {
                    id: rowActions
                    anchors.right: parent.right
                    anchors.rightMargin: 9
                    anchors.top: parent.top
                    anchors.topMargin: 11
                    spacing: 5

                    SmallAction {
                        visible: deviceRow.mounted
                        label: "Open"
                        symbol: Glyphs.folder
                        interactive: !Storage.actionRunning
                        onClicked: {
                            Storage.open(deviceRow.item);
                            ShellState.closeOverlay();
                        }
                    }

                    SmallAction {
                        visible: deviceRow.mounted
                        label: deviceRow.busy && Storage.actionKind === "unmount"
                            ? "…" : "Unmount"
                        symbol: Glyphs.eject
                        interactive: !Storage.actionRunning
                        onClicked: Storage.unmount(deviceRow.item)
                    }

                    SmallAction {
                        visible: !deviceRow.mounted
                        label: deviceRow.busy && Storage.actionKind === "mount"
                            ? "Mounting…" : "Mount"
                        symbol: Glyphs.play
                        primary: true
                        interactive: !Storage.actionRunning
                        onClicked: Storage.mount(deviceRow.item)
                    }
                }

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 50
                    anchors.right: rowActions.left
                    anchors.rightMargin: 8
                    anchors.top: parent.top
                    anchors.topMargin: 9
                    spacing: 2

                    Label {
                        width: parent.width
                        value: deviceRow.item
                            ? (deviceRow.item.name || deviceRow.item.device)
                            : "USB device"
                        strong: true
                        size: 10
                        color: Theme.alpha(Theme.fg, 0.88)
                        elide: Text.ElideRight
                    }

                    Label {
                        width: parent.width
                        value: popover.kindLabel(deviceRow.item) + " · "
                            + popover.statusText(deviceRow.item)
                        size: 8
                        color: deviceRow.mounted
                            ? Theme.tertiary
                            : Theme.alpha(Theme.dim, 0.62)
                        elide: Text.ElideMiddle
                    }

                    Label {
                        width: parent.width
                        value: popover.usageText(deviceRow.item)
                        size: 8
                        color: Theme.dim
                        opacityValue: 0.62
                        elide: Text.ElideRight
                    }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.leftMargin: 50
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 9
                    height: 3
                    radius: 1.5
                    color: Theme.alpha(Theme.fg, 0.08)
                    visible: deviceRow.mounted

                    Rectangle {
                        width: parent.width * (deviceRow.usage / 100)
                        height: parent.height
                        radius: parent.radius
                        color: deviceRow.usage >= 90 ? Theme.error : Theme.tertiary
                    }
                }
            }
        }

        Rectangle {
            visible: popover.count === 0
            width: parent.width
            height: 82
            radius: Theme.radiusCard
            color: Theme.alpha(Theme.fg, 0.025)
            border.width: 1
            border.color: Theme.alpha(Theme.fg, 0.055)

            Column {
                anchors.centerIn: parent
                spacing: 5

                Icon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    name: Glyphs.usb
                    size: 25
                    color: Theme.alpha(Theme.primary, 0.72)
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    value: Storage.loading ? "Reading USB devices…" : "No USB devices attached"
                    strong: true
                    size: 10
                    color: Theme.fg
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    value: "Connect a USB stick or external drive."
                    size: 8
                    color: Theme.dim
                    opacityValue: 0.6
                }
            }
        }

        Rectangle {
            visible: Storage.lastError.length > 0
            width: parent.width
            height: errorLabel.implicitHeight + 16
            radius: Theme.radiusCard
            color: Theme.alpha(Theme.error, 0.08)
            border.width: 1
            border.color: Theme.alpha(Theme.error, 0.22)

            Label {
                id: errorLabel
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                value: Storage.lastError
                size: 8
                color: Theme.error
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
        }

    }

    Component.onCompleted: Storage.refresh()

    component SmallAction: Rectangle {
        id: action

        property string label: ""
        property string symbol: ""
        property bool primary: false
        property bool interactive: true

        signal clicked()

        implicitWidth: Math.max(36, actionLabel.implicitWidth + (symbol.length > 0 ? 24 : 14))
        implicitHeight: 26
        radius: Theme.radiusControl
        color: !action.interactive
            ? Theme.alpha(Theme.fg, 0.035)
            : (action.primary
                ? Theme.alpha(Theme.primary, 0.14)
                : (actionMouse.containsMouse ? Theme.hover : Theme.input))
        border.width: 1
        border.color: action.primary
            ? Theme.alpha(Theme.primary, 0.28)
            : Theme.border
        opacity: action.interactive ? 1 : 0.55

        Row {
            anchors.centerIn: parent
            spacing: 4

            Icon {
                visible: action.symbol.length > 0
                name: action.symbol
                size: 12
                color: action.primary ? Theme.primary : Theme.dim
            }

            Label {
                id: actionLabel
                value: action.label
                size: 8
                color: action.primary ? Theme.primary : Theme.fg
            }
        }

        MouseArea {
            id: actionMouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: action.interactive
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: action.clicked()
        }
    }
}
