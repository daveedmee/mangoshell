import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import ".."
import "../components"
import "../services"

Rectangle {
    id: sheet

    property string typeFilter: "all"
    property bool confirmClear: false

    implicitWidth: Settings.overlay.clipboardWidth
    implicitHeight: Settings.overlay.clipboardHeight
    radius: Theme.radiusPanel
    color: Theme.panel
    border.width: 1
    border.color: Theme.border
    clip: true

    readonly property var filteredItems: Clipboard.filtered(searchField.text, sheet.typeFilter)

    function firstLine(text) {
        const value = "" + (text || "");
        const line = value.split(/\r?\n/)[0] || "";
        return line.length > 0 ? line : "(empty)";
    }

    function charCount(value) {
        return ("" + (value || "")).length;
    }

    function typeCount(type) {
        const list = Clipboard.items || [];
        if (type === "all")
            return list.length;
        let count = 0;
        for (let i = 0; i < list.length; i++) {
            if (list[i].type === type)
                count += 1;
        }
        return count;
    }

    function formatBytes(value) {
        let size = typeof value === "number" ? value : parseInt(("" + (value || "0")).replace(/[^0-9]/g, ""));
        if (isNaN(size))
            return "unknown size";
        if (size >= 1024 * 1024)
            return (size / (1024 * 1024)).toFixed(1) + " MB";
        if (size >= 1024)
            return Math.round(size / 1024) + " KB";
        return size + " B";
    }

    function iconFor(item) {
        if (!item)
            return Glyphs.clipboard;
        if (item.type === "image")
            return Glyphs.image;
        const text = ("" + (item.preview || "")).trim();
        if (text.startsWith("http://") || text.startsWith("https://"))
            return Glyphs.link;
        if (text.startsWith("mmsg ") || text.startsWith("$ ") || text.startsWith("sudo "))
            return Glyphs.terminal;
        if (text.includes("function ") || text.includes("{") || text.includes("</"))
            return Glyphs.code;
        if (text.length > 0)
            return Glyphs.notes;
        return Glyphs.clipboard;
    }

    Timer {
        id: confirmTimer
        interval: 3000
        repeat: false
        onTriggered: sheet.confirmClear = false
    }

    Component.onCompleted: Clipboard.refresh()

    Shortcut {
        sequence: "/"
        onActivated: searchField.forceFocus()
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
        anchors.leftMargin: 22
        anchors.rightMargin: 20
        anchors.topMargin: 21
        height: 55

        Label {
            anchors.left: parent.left
            anchors.top: parent.top
            value: "History · Clipboard"
            eyebrow: true
            size: 8
            color: Theme.dim
            opacityValue: 0.7
        }

        Label {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.topMargin: 11
            value: "Clipboard"
            strong: true
            size: 22
            color: Theme.fg
        }

        Label {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.topMargin: 38
            value: "cliphist history · click or Enter to copy."
            size: 9
            color: Theme.dim
            opacityValue: 0.7
        }

        IconButton {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: -3
            icon: Glyphs.close
            iconSize: 18
            size: 28
            iconColor: Theme.dim
            onClicked: ShellState.closeOverlay()
        }
    }

    Column {
        id: tools
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.leftMargin: 22
        anchors.rightMargin: 22
        anchors.topMargin: 2
        spacing: 10

        SearchField {
            id: searchField
            width: parent.width
            height: 36
            placeholder: "Search clipboard"
            onAccepted: {
                if (sheet.filteredItems.length > 0)
                    Clipboard.copy(sheet.filteredItems[0].id);
            }
        }

        Rectangle {
            width: parent.width
            height: 35
            radius: Theme.radiusCard
            color: Theme.surfaceLowest
            border.width: 1
            border.color: Theme.alpha(Theme.fg, 0.055)

            Row {
                x: 3
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Repeater {
                    model: [
                        { value: "all", label: "All" },
                        { value: "text", label: "Text" },
                        { value: "image", label: "Images" }
                    ]

                    delegate: Rectangle {
                        id: tab
                        required property var modelData

                        width: tabLabel.implicitWidth + (tabCount.visible ? 28 : 22)
                        height: 29
                        radius: Theme.radiusControl
                        color: sheet.typeFilter === tab.modelData.value
                            ? Theme.surfaceHigh
                            : (tabMouse.containsMouse ? Theme.hover : "transparent")

                        Row {
                            anchors.centerIn: parent
                            spacing: 4

                            Label {
                                id: tabLabel
                                value: tab.modelData.label
                                size: 9
                                color: sheet.typeFilter === tab.modelData.value ? Theme.fg : Theme.alpha(Theme.fg, 0.55)
                            }

                            Label {
                                id: tabCount
                                visible: sheet.typeCount(tab.modelData.value) > 0
                                value: "" + sheet.typeCount(tab.modelData.value)
                                size: 7
                                color: sheet.typeFilter === tab.modelData.value ? Theme.primary : Theme.alpha(Theme.dim, 0.55)
                            }
                        }

                        MouseArea {
                            id: tabMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: sheet.typeFilter = tab.modelData.value
                        }
                    }
                }
            }
        }
    }

    ListView {
        id: list
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: tools.bottom
        anchors.bottom: footer.top
        anchors.leftMargin: 22
        anchors.rightMargin: 22
        anchors.topMargin: 12
        anchors.bottomMargin: 8
        clip: true
        spacing: 6
        boundsBehavior: Flickable.StopAtBounds
        model: sheet.filteredItems

        delegate: Rectangle {
            id: item
            required property var modelData

            width: list.width
            height: 61
            radius: Theme.radiusCard
            color: itemMouse.containsMouse ? Theme.surfaceContainer : Theme.surfaceLow
            border.width: 1
            border.color: Clipboard.pendingId === item.modelData.id
                ? Theme.alpha(Theme.primary, 0.45)
                : Theme.alpha(Theme.fg, 0.05)

            Rectangle {
                x: 11
                anchors.verticalCenter: parent.verticalCenter
                width: 35
                height: 35
                radius: Theme.radiusControl
                color: Theme.alpha(Theme.fg, 0.055)
                clip: true

                Image {
                    anchors.fill: parent
                    visible: item.modelData.type === "image" && item.modelData.image.length > 0
                    source: item.modelData.image
                    sourceSize.width: 70
                    sourceSize.height: 70
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                }

                Icon {
                    anchors.centerIn: parent
                    visible: item.modelData.type !== "image" || !item.modelData.image
                    name: sheet.iconFor(item.modelData)
                    size: 18
                    color: Theme.dim
                }
            }

            Column {
                anchors.left: parent.left
                anchors.leftMargin: 56
                anchors.right: itemMeta.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Label {
                    width: parent.width
                    value: item.modelData.type === "image"
                        ? "Image · " + item.modelData.mime
                        : sheet.firstLine(item.modelData.preview)
                    size: 10
                    color: Theme.alpha(Theme.fg, 0.80)
                }

                Label {
                    width: parent.width
                    value: item.modelData.type === "image"
                        ? sheet.formatBytes(item.modelData.length)
                        : "Text · " + sheet.charCount(item.modelData.preview) + " characters · " + item.modelData.mime
                    size: 8
                    color: Theme.dim
                    opacityValue: 0.5
                }
            }

            Label {
                id: itemMeta
                anchors.right: deleteButton.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                value: item.modelData.type === "image" ? "image" : "text"
                size: 7
                color: Theme.dim
                opacityValue: 0.38
            }

            IconButton {
                id: deleteButton
                z: 2
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                icon: Glyphs.trash
                iconSize: 14
                size: 26
                iconColor: Theme.dim
                opacity: itemMouse.containsMouse ? 1 : 0
                onClicked: Clipboard.remove(item.modelData.id)
            }

            MouseArea {
                id: itemMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Clipboard.copy(item.modelData.id)
            }
        }
    }

    Rectangle {
        width: 3
        height: Math.max(20, list.height * list.height / Math.max(list.contentHeight, 1))
        x: list.x + list.width + 4
        y: list.y + list.contentY / Math.max(1, list.contentHeight - list.height) * (list.height - height)
        radius: 1
        color: Theme.alpha(Theme.fg, 0.14)
        visible: list.contentHeight > list.height
    }

    Column {
        visible: Clipboard.loading || sheet.filteredItems.length === 0
        anchors.centerIn: parent
        spacing: 7

        Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            name: Clipboard.loading ? Glyphs.refresh : Glyphs.clipboard
            size: 30
            color: Theme.alpha(Theme.dim, 0.4)
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            value: Clipboard.loading ? "Reading clipboard…" : "Clipboard is empty"
            size: 10
            color: Theme.dim
        }
    }

    Item {
        id: footer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 22
        anchors.rightMargin: 22
        height: 37

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 1
            color: Theme.alpha(Theme.fg, 0.06)
        }

        Label {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            value: "Click to copy · Esc close"
            size: 8
            color: Theme.alpha(Theme.dim, 0.5)
        }

        Label {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            value: sheet.confirmClear ? "Confirm clear" : "Clear all…"
            size: 9
            color: sheet.confirmClear ? Theme.error : Theme.alpha(Theme.error, 0.72)

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (sheet.confirmClear) {
                        sheet.confirmClear = false;
                        Clipboard.clear();
                    } else {
                        sheet.confirmClear = true;
                        confirmTimer.restart();
                    }
                }
            }
        }
    }
}
