import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../components"
import "../services"

Rectangle {
    id: popover

    implicitWidth: Settings.overlay.popoverWidth
    implicitHeight: 80 + body.implicitHeight + 16
    radius: Theme.radiusPanel
    color: Theme.panel
    border.width: 1
    border.color: Theme.border
    clip: true

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
            value: "PipeWire"
            eyebrow: true
            size: 8
            color: Theme.dim
            opacityValue: 0.7
        }

        Label {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.topMargin: 12
            value: "Audio"
            strong: true
            size: 17
            color: Theme.fg
        }

        IconButton {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: -2
            icon: Glyphs.close
            iconSize: 17
            size: 28
            iconColor: Theme.dim
            onClicked: ShellState.closeOverlay()
        }
    }

    Column {
        id: body
        x: 16
        y: 62
        width: parent.width - 32
        spacing: 12

        Column {
            width: parent.width
            spacing: 5

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

            DeviceSelector {
                width: parent.width
                devices: Audio.sinks
                current: Audio.sink
                icon: Glyphs.speaker
                emptyText: "No output device"
                onSelected: function(device) { Audio.setSink(device); }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.alpha(Theme.fg, 0.065)
        }

        Column {
            width: parent.width
            spacing: 5

            SliderRow {
                width: parent.width
                icon: Audio.sourceMuted ? Glyphs.microphoneMuted : Glyphs.microphone
                label: "Microphone"
                valueText: Audio.sources.length === 0 ? "Unavailable" : (Audio.sourceMuted ? "Muted" : Audio.sourcePercent + "%")
                value: Audio.sourceMuted ? 0 : Audio.sourcePercent
                muted: Audio.sourceMuted
                accent: Theme.primary
                interactive: Audio.sources.length > 0
                onMoved: function(value) { Audio.setSourceVolume(value); }
                onReleased: function(value) {
                    ShellState.showOsd("mic", "Microphone", Audio.sourceMuted ? 0 : Audio.sourcePercent,
                        Audio.sourceMuted ? "Muted" : Audio.sourcePercent + "%", Audio.sourceMuted);
                }
            }

            DeviceSelector {
                width: parent.width
                devices: Audio.sources
                current: Audio.source
                icon: Glyphs.microphone
                emptyText: "No microphone"
                onSelected: function(device) { Audio.setSource(device); }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.alpha(Theme.fg, 0.065)
        }

        Item {
            width: parent.width
            height: 14

            Label {
                anchors.left: parent.left
                value: "Applications"
                strong: true
                size: 11
                color: Theme.fg
            }

            Label {
                anchors.right: parent.right
                value: Audio.streams.length > 0 ? Audio.streams.length + " active" : "None"
                size: 8
                color: Theme.dim
                opacityValue: 0.55
            }
        }

        Column {
            width: parent.width
            spacing: 1

            Repeater {
                model: Audio.streams

                delegate: Item {
                    required property var modelData

                    width: parent.width
                    height: 32

                    Row {
                        anchors.fill: parent
                        spacing: 7

                        AppIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            size: 22
                            source: Audio.streamIcon(modelData)
                            fallbackIcon: Audio.streamIsInput(modelData) ? Glyphs.microphone : Glyphs.music
                            background: Theme.alpha(Theme.fg, 0.06)
                            foreground: Theme.dim
                        }

                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 78
                            value: Audio.streamName(modelData)
                            size: 9
                            color: Theme.alpha(Theme.fg, 0.76)
                        }

                        ThinSlider {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 22 - 78 - 30 - 22 - 28
                            height: 14
                            trackHeight: 3
                            knobWidth: 3
                            knobHeight: 10
                            value: Audio.streamPercent(modelData)
                            muted: Audio.streamMuted(modelData)
                            fillColor: Theme.primary
                            onMoved: function(value) { Audio.setStreamVolume(modelData, value); }
                        }

                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 30
                            value: Audio.streamPercent(modelData) + "%"
                            size: 10
                            color: Theme.alpha(Theme.fg, 0.76)
                            horizontalAlignment: Text.AlignRight
                        }

                        IconButton {
                            anchors.verticalCenter: parent.verticalCenter
                            size: 22
                            icon: Audio.streamMuted(modelData) ? Glyphs.volumeMuted : Glyphs.volumeHigh
                            iconSize: 14
                            iconColor: Theme.dim
                            onClicked: Audio.toggleStreamMute(modelData)
                        }
                    }
                }
            }

            Label {
                visible: Audio.streams.length === 0
                width: parent.width
                value: "No active playback streams"
                size: 8
                color: Theme.dim
                opacityValue: 0.5
            }
        }
    }
}
