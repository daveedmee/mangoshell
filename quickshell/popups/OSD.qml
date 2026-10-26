import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../components"

PanelWindow {
    id: root

    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    visible: ShellState.osdVisible && !ShellState.overlayOpen

    anchors.bottom: true
    margins.bottom: Settings.osd.bottom
    implicitWidth: Settings.osd.width
    implicitHeight: Settings.osd.height
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    focusable: false

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-osd"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    readonly property string iconName: {
        if (ShellState.osdKind === "brightness")
            return Glyphs.brightness;
        if (ShellState.osdKind === "mic")
            return ShellState.osdMuted ? Glyphs.microphoneMuted : Glyphs.microphone;
        return ShellState.osdMuted ? Glyphs.volumeMuted : Glyphs.volumeHigh;
    }

    Timer {
        id: hideTimer
        interval: Settings.osd.timeout
        repeat: false
        running: root.visible
        onTriggered: ShellState.hideOsd()
    }

    Connections {
        target: ShellState
        function onOsdValueChanged() { hideTimer.restart(); }
        function onOsdTextChanged() { hideTimer.restart(); }
        function onOsdMutedChanged() { hideTimer.restart(); }
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusPanel
        color: Theme.panel
        border.width: 1
        border.color: Theme.border

        Rectangle {
            x: 13
            anchors.verticalCenter: parent.verticalCenter
            width: 38
            height: 38
            radius: Theme.radiusPanel
            color: Theme.alpha(ShellState.osdMuted ? Theme.error : Theme.primary, 0.12)

            Icon {
                anchors.centerIn: parent
                name: root.iconName
                size: 21
                filled: true
                color: ShellState.osdMuted ? Theme.error : Theme.primary
            }
        }

        Column {
            anchors.left: parent.left
            anchors.leftMargin: 63
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Item {
                width: parent.width
                height: 16

                Label {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    value: ShellState.osdLabel
                    eyebrow: true
                    size: 8
                    color: Theme.dim
                }

                Label {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    value: ShellState.osdText
                    strong: true
                    size: 14
                    color: Theme.fg
                }
            }

            Rectangle {
                width: parent.width
                height: 4
                radius: 1
                color: Theme.alpha(Theme.fg, 0.12)

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, ShellState.osdValue / 100))
                    height: parent.height
                    radius: 1
                    color: ShellState.osdMuted ? Theme.dim : Theme.primary
                }
            }
        }
    }
}
