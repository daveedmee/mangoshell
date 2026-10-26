import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import Quickshell.Bluetooth
import ".."
import "../components"
import "../services"

Rectangle {
    id: panel

    implicitWidth: Settings.overlay.sidebarWidth
    implicitHeight: 900
    radius: Theme.radiusPanel
    color: Theme.panel
    border.width: 1
    border.color: Theme.border
    clip: true

    readonly property var netDevices: Networking.devices.values
    readonly property var connectedDevice: {
        const devices = Networking.devices.values;
        for (let i = 0; i < devices.length; i++) {
            if (devices[i].connected)
                return devices[i];
        }
        return null;
    }
    readonly property bool hasWifi: {
        const devices = Networking.devices.values;
        for (let i = 0; i < devices.length; i++) {
            if (devices[i].type === DeviceType.Wifi)
                return true;
        }
        return false;
    }
    readonly property string wifiName: {
        const device = root.connectedDevice;
        if (!device || device.type !== DeviceType.Wifi)
            return "";
        const networks = device.networks.values;
        for (let i = 0; i < networks.length; i++) {
            if (networks[i].connected)
                return networks[i].name;
        }
        return "";
    }

    readonly property var btAdapter: Bluetooth.defaultAdapter
    readonly property bool btEnabled: btAdapter !== null && btAdapter.enabled
    readonly property int btConnected: {
        if (!btAdapter)
            return 0;
        const devices = btAdapter.devices.values;
        let count = 0;
        for (let i = 0; i < devices.length; i++) {
            if (devices[i].connected)
                count += 1;
        }
        return count;
    }

    Component.onCompleted: {
        Brightness.refresh();
        Storage.refresh();
        SystemStats.active = true;
    }

    Component.onDestruction: SystemStats.active = false

    // Hardware brightness keys only report through the OSD. Mirror that value
    // into the slider while the panel is open instead of polling the monitor.
    Connections {
        target: ShellState

        function onOsdValueChanged() {
            if (ShellState.osdKind === "brightness")
                Brightness.value = ShellState.osdValue;
        }
    }

    SystemClock {
        id: headerClock
        precision: SystemClock.Minutes
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
        anchors.leftMargin: 20
        anchors.rightMargin: 16
        anchors.topMargin: 18
        height: 46

        Label {
            anchors.left: parent.left
            anchors.top: parent.top
            value: headerClock.date.toLocaleDateString(Qt.locale(), "dddd, dd MMMM")
            eyebrow: true
            size: 8
            color: Theme.dim
            opacityValue: 0.72
        }

        Label {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.topMargin: 14
            value: "Controls"
            strong: true
            size: 21
            color: Theme.fg
        }

        IconButton {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: -2
            icon: Glyphs.close
            iconSize: 18
            size: 28
            iconColor: Theme.dim
            onClicked: ShellState.closeOverlay()
        }
    }

    Flickable {
        id: scroll
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.leftMargin: 16
        anchors.rightMargin: 10
        anchors.topMargin: 12
        contentWidth: width
        contentHeight: contentColumn.height + 18
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: contentColumn
            width: scroll.width - 6
            spacing: 12

            GridLayout {
                width: parent.width
                columns: 3
                columnSpacing: 8
                rowSpacing: 8

                ToggleTile {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 74

                    icon: panel.hasWifi
                        ? (Networking.wifiEnabled ? Glyphs.wifi : Glyphs.wifiOff)
                        : (panel.connectedDevice !== null ? Glyphs.ethernet : Glyphs.networkUnknown)
                    title: panel.hasWifi ? "Wi-Fi" : "Ethernet"
                    subtitle: panel.hasWifi
                        ? (Networking.wifiEnabled ? (panel.wifiName.length > 0 ? panel.wifiName : "On") : "Off")
                        : (panel.connectedDevice !== null ? "Connected" : "Disconnected")
                    checked: panel.hasWifi ? Networking.wifiEnabled : panel.connectedDevice !== null
                    onClicked: {
                        if (panel.hasWifi)
                            Networking.wifiEnabled = !Networking.wifiEnabled;
                        else
                            ShellState.openOverlay("network");
                    }
                }

                ToggleTile {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 74

                    icon: Glyphs.bluetooth
                    title: "Bluetooth"
                    subtitle: panel.btAdapter === null
                        ? "Unavailable"
                        : (!panel.btEnabled ? "Off" : (panel.btConnected > 0 ? panel.btConnected + " connected" : "On"))
                    checked: panel.btEnabled
                    onClicked: ShellState.openOverlay("bluetooth")
                }

                ToggleTile {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 74

                    icon: Glyphs.dnd
                    title: "DND"
                    subtitle: NotificationService.dnd ? "On" : "Off"
                    checked: NotificationService.dnd
                    accent: "tertiary"
                    onClicked: NotificationService.toggleDnd()
                }

                ToggleTile {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 74

                    icon: Audio.allSourcesMuted ? Glyphs.microphoneMuted : Glyphs.microphone
                    title: "Microphone"
                    subtitle: Audio.sources.length === 0 ? "Unavailable" : (Audio.allSourcesMuted ? "Muted" : "Live")
                    checked: !Audio.allSourcesMuted && Audio.sources.length > 0
                    onClicked: Audio.toggleAllSourceMutes()
                }

                ToggleTile {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 74

                    icon: Glyphs.smartphone
                    title: "KDE Connect"
                    subtitle: "Devices & sync"
                    action: true
                    accent: "secondary"
                    onClicked: Quickshell.execDetached(["kdeconnect-app"])
                }

                ToggleTile {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 74

                    icon: Glyphs.wallpaper
                    title: "Wallpaper"
                    subtitle: "Browse gallery"
                    action: true
                    accent: "secondary"
                    onClicked: ShellState.openOverlay("gallery")
                }
            }

            Rectangle {
                width: parent.width
                height: sliderContent.implicitHeight + 26
                radius: Theme.radiusCard
                color: Theme.card
                border.width: 1
                border.color: Theme.alpha(Theme.fg, 0.065)

                Column {
                    id: sliderContent
                    x: 14
                    y: 13
                    width: parent.width - 28
                    spacing: 10

                    SliderRow {
                        width: parent.width
                        icon: Audio.sinkMuted
                            ? Glyphs.volumeMuted
                            : (Audio.sinkPercent < 34 ? Glyphs.volumeLow : (Audio.sinkPercent < 67 ? Glyphs.volumeMedium : Glyphs.volumeHigh))
                        label: "Output"
                        valueText: Audio.sinkMuted ? "Muted" : Audio.sinkPercent + "%"
                        value: Audio.sinkMuted ? 0 : Audio.sinkPercent
                        muted: Audio.sinkMuted
                        onMoved: function(value) { Audio.setSinkVolume(value); }
                        onReleased: function(value) {
                            ShellState.showOsd("volume", "Output", Audio.sinkMuted ? 0 : Audio.sinkPercent,
                                Audio.sinkMuted ? "Muted" : Audio.sinkPercent + "%", Audio.sinkMuted);
                        }
                    }

                    SliderRow {
                        width: parent.width
                        icon: Audio.sourceMuted ? Glyphs.microphoneMuted : Glyphs.microphone
                        label: "Microphone"
                        valueText: Audio.sources.length === 0 ? "Unavailable" : (Audio.sourceMuted ? "Muted" : Audio.sourcePercent + "%")
                        value: Audio.sourceMuted ? 0 : Audio.sourcePercent
                        muted: Audio.sourceMuted
                        interactive: Audio.sources.length > 0
                        onMoved: function(value) { Audio.setSourceVolume(value); }
                        onReleased: function(value) {
                            ShellState.showOsd("mic", "Microphone", Audio.sourceMuted ? 0 : Audio.sourcePercent,
                                Audio.sourceMuted ? "Muted" : Audio.sourcePercent + "%", Audio.sourceMuted);
                        }
                    }

                    SliderRow {
                        width: parent.width
                        icon: Glyphs.brightness
                        label: "Brightness"
                        valueText: Brightness.available ? Brightness.value + "%" : "Unavailable"
                        value: Brightness.value
                        interactive: Brightness.available
                        onMoved: function(value) { Brightness.setValue(value); }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: Media.available ? 144 : 92
                radius: Theme.radiusCard
                color: Theme.card
                border.width: 1
                border.color: Theme.alpha(Theme.fg, 0.065)
                clip: true

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ShellState.openOverlay("media")
                }

                Row {
                    x: 11
                    y: 11
                    width: parent.width - 22
                    spacing: 11

                    Rectangle {
                        width: 70
                        height: 70
                        radius: Theme.radiusControl
                        color: Theme.primaryContainer
                        clip: true

                        Image {
                            id: mediaArt
                            anchors.fill: parent
                            source: Media.sourceFor(Media.artUrl)
                            sourceSize.width: 140
                            sourceSize.height: 140
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            visible: status === Image.Ready
                        }

                        Icon {
                            anchors.centerIn: parent
                            visible: mediaArt.status !== Image.Ready
                            name: Glyphs.music
                            size: 26
                            color: Theme.primaryContainerText
                        }
                    }

                    Column {
                        width: parent.width - 70 - 11
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Label {
                            width: parent.width
                            value: Media.available && Media.identity.length > 0
                                ? Media.identity
                                : (Media.available ? "Now playing" : "Media")
                            eyebrow: true
                            size: 7
                            color: Theme.alpha(Theme.primary, 0.82)
                        }

                        Label {
                            width: parent.width
                            value: Media.available ? (Media.title || "Unknown track") : "Nothing playing"
                            strong: true
                            size: 12
                            color: Theme.fg
                        }

                        Label {
                            width: parent.width
                            value: Media.available
                                ? (Media.artist + (Media.album.length > 0 ? " · " + Media.album : ""))
                                : "Start a player to see playback"
                            size: 9
                            color: Theme.dim
                            opacityValue: 0.72
                        }
                    }
                }

                Item {
                    visible: Media.available
                    x: 11
                    y: 86
                    width: parent.width - 22
                    height: 23

                    ThinSlider {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        y: 3
                        height: 11
                        value: Media.length > 0 ? Math.min(100, 100 * Media.position / Media.length) : 0
                        trackHeight: 3
                        knobWidth: 3
                        knobHeight: 9
                        interactive: Media.canSeek && Media.length > 0
                        onReleased: function(value) {
                            if (Media.length > 0)
                                Media.seek(Media.length * value / 100);
                        }
                    }

                    Label {
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        value: Media.formatTime(Media.position)
                        size: 7
                        color: Theme.dim
                        opacityValue: 0.55
                    }

                    Label {
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        value: Media.formatTime(Media.length)
                        size: 7
                        color: Theme.dim
                        opacityValue: 0.55
                    }
                }

                Row {
                    visible: Media.available
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 8
                    spacing: 9

                    IconButton {
                        icon: Glyphs.previous
                        size: 28
                        iconSize: 17
                        interactive: Media.canPrevious
                        iconColor: Media.canPrevious ? Theme.dim : Theme.alpha(Theme.dim, 0.28)
                        onClicked: Media.previous()
                    }

                    Rectangle {
                        width: 34
                        height: 34
                        radius: Theme.radiusCard
                        color: Media.canToggle ? Theme.primary : Theme.primaryContainer

                        Icon {
                            anchors.centerIn: parent
                            name: Media.isPlaying ? Glyphs.pause : Glyphs.play
                            size: 19
                            filled: true
                            color: Media.canToggle ? Theme.primaryText : Theme.primaryContainerText
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: Media.canToggle
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: Media.toggle()
                        }
                    }

                    IconButton {
                        icon: Glyphs.next
                        size: 28
                        iconSize: 17
                        interactive: Media.canNext
                        iconColor: Media.canNext ? Theme.dim : Theme.alpha(Theme.dim, 0.28)
                        onClicked: Media.next()
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: statsContent.implicitHeight + 24
                radius: Theme.radiusCard
                color: Theme.card
                border.width: 1
                border.color: Theme.alpha(Theme.fg, 0.065)

                Column {
                    id: statsContent
                    x: 14
                    y: 12
                    width: parent.width - 28
                    spacing: 8

                    Item {
                        width: parent.width
                        height: 14

                        Label {
                            anchors.left: parent.left
                            value: "System"
                            strong: true
                            size: 11
                            color: Theme.fg
                        }

                        Label {
                            anchors.right: parent.right
                            value: "Live · 2s"
                            size: 8
                            color: Theme.dim
                            opacityValue: 0.58
                        }
                    }

                    StatRow {
                        width: parent.width
                        name: "CPU"
                        value: SystemStats.cpu + "%"
                        fraction: SystemStats.cpu / 100
                        barColor: Theme.primary
                    }

                    StatRow {
                        width: parent.width
                        name: "RAM"
                        value: SystemStats.ram + "%"
                        fraction: SystemStats.ram / 100
                        barColor: Theme.secondary
                    }

                    StatRow {
                        width: parent.width
                        name: "Swap"
                        value: SystemStats.swap + "%"
                        fraction: SystemStats.swap / 100
                        barColor: Theme.tertiary
                    }

                    StatRow {
                        width: parent.width
                        name: "GPU"
                        value: SystemStats.gpuAvailable ? SystemStats.gpu + "%" : "—"
                        fraction: SystemStats.gpuAvailable ? SystemStats.gpu / 100 : 0
                        barColor: Theme.primary
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Theme.alpha(Theme.fg, 0.06)
                    }

                    Item {
                        width: parent.width
                        height: 14

                        Row {
                            anchors.left: parent.left
                            spacing: 5

                            Icon {
                                name: Glyphs.arrowDown
                                size: 13
                                color: Theme.tertiary
                            }

                            Label {
                                value: SystemStats.rx
                                size: 8
                                color: Theme.dim
                            }
                        }

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 84
                            spacing: 5

                            Icon {
                                name: Glyphs.arrowUp
                                size: 13
                                color: Theme.secondary
                            }

                            Label {
                                value: SystemStats.tx
                                size: 8
                                color: Theme.dim
                            }
                        }

                        Label {
                            anchors.right: parent.right
                            value: SystemStats.network
                            size: 8
                            color: Theme.dim
                            opacityValue: 0.65
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: storageContent.implicitHeight + 24
                radius: Theme.radiusCard
                color: Theme.card
                border.width: 1
                border.color: Theme.alpha(Theme.fg, 0.065)

                Column {
                    id: storageContent
                    x: 14
                    y: 12
                    width: parent.width - 28
                    spacing: 7

                    Item {
                        width: parent.width
                        height: 15

                        Label {
                            anchors.left: parent.left
                            value: "Drives"
                            strong: true
                            size: 11
                            color: Theme.fg
                        }

                        Label {
                            anchors.right: parent.right
                            value: Storage.items.length + (Storage.items.length === 1 ? " disk" : " disks")
                            size: 8
                            color: Theme.dim
                            opacityValue: 0.58
                        }
                    }

                    Repeater {
                        model: Storage.items

                        delegate: Item {
                            required property var modelData

                            width: parent.width
                            height: 35

                            Icon {
                                id: driveIcon
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.topMargin: 1
                                name: modelData.kind === "usb-stick"
                                    ? Glyphs.usb
                                    : Glyphs.storage
                                size: 14
                                filled: modelData.mounted
                                color: modelData.mounted
                                    ? Theme.tertiary
                                    : Theme.alpha(Theme.dim, 0.6)
                            }

                            Label {
                                anchors.left: driveIcon.right
                                anchors.leftMargin: 7
                                anchors.right: driveUse.left
                                anchors.rightMargin: 8
                                anchors.top: parent.top
                                value: modelData.name || modelData.device
                                strong: true
                                size: 9
                                color: Theme.fg
                                elide: Text.ElideRight
                            }

                            Label {
                                id: driveUse
                                anchors.right: parent.right
                                anchors.top: parent.top
                                value: modelData.mounted
                                    ? (modelData.percent !== null ? modelData.percent + "%" : "—")
                                    : "Not mounted"
                                size: 8
                                color: modelData.mounted ? Theme.dim : Theme.alpha(Theme.dim, 0.5)
                            }

                            Label {
                                anchors.left: driveIcon.right
                                anchors.leftMargin: 7
                                anchors.right: driveUse.left
                                anchors.rightMargin: 8
                                anchors.top: parent.top
                                anchors.topMargin: 15
                                value: modelData.mounted
                                    ? (modelData.mountpoint + " · "
                                        + Storage.formatBytes(modelData.used) + " / " + Storage.formatBytes(modelData.size))
                                    : (Storage.formatBytes(modelData.size) + " · " + modelData.fstype)
                                size: 7
                                color: Theme.dim
                                opacityValue: 0.58
                                elide: Text.ElideMiddle
                            }

                            ThinSlider {
                                visible: modelData.mounted && modelData.percent !== null
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: 8
                                trackHeight: 2
                                knobWidth: 0
                                knobHeight: 0
                                value: modelData.percent || 0
                                interactive: false
                                fillColor: modelData.percent >= 90 ? Theme.error : Theme.tertiary
                            }
                        }
                    }

                    Label {
                        visible: Storage.items.length === 0
                        width: parent.width
                        value: Storage.loading ? "Reading drives…" : "No drives found"
                        size: 9
                        color: Theme.dim
                        opacityValue: 0.55
                    }
                }
            }

            Rectangle {
                id: sessionCard
                width: parent.width
                height: 73
                radius: Theme.radiusCard
                color: Theme.card
                border.width: 1
                border.color: Theme.alpha(Theme.fg, 0.065)

                Row {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 2

                    Repeater {
                        model: [
                            { icon: Glyphs.lock, label: "Lock", danger: false, action: "lock" },
                            { icon: Glyphs.logout, label: "Logout", danger: false, action: "logout" },
                            { icon: Glyphs.suspend, label: "Suspend", danger: false, action: "suspend" },
                            { icon: Glyphs.restart, label: "Reboot", danger: false, action: "reboot" },
                            { icon: Glyphs.power, label: "Shut down", danger: true, action: "shutdown" }
                        ]

                        delegate: SessionButton {
                            required property var modelData
                            width: (sessionCard.width - 22) / 5
                            height: 51
                            icon: modelData.icon
                            label: modelData.label
                            danger: modelData.danger
                            onClicked: {
                                if (modelData.action === "lock") {
                                    ShellState.closeOverlay();
                                    Quickshell.execDetached(["bash", Settings.paths.shellScripts + "/lock.sh"]);
                                } else if (modelData.action === "logout") {
                                    ShellState.closeOverlay();
                                    Mango.dispatch("quit");
                                } else if (modelData.action === "suspend") {
                                    ShellState.closeOverlay();
                                    Quickshell.execDetached(["systemctl", "suspend"]);
                                } else {
                                    ShellState.openOverlay("session");
                                }
                            }
                        }
                    }
                }
            }
        }

    }

    DraggableScrollBar {
        target: scroll
        x: panel.width - width - 1
        y: scroll.y
        z: 20
    }
}
