import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../components"
import "../services"

Rectangle {
    id: popover

    implicitWidth: Settings.overlay.mediaWidth
    implicitHeight: 440
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
        anchors.topMargin: 16
        height: 44

        Label {
            anchors.left: parent.left
            anchors.top: parent.top
            value: "Now playing"
            eyebrow: true
            size: 8
            color: Theme.dim
            opacityValue: 0.7
        }

        Label {
            anchors.left: parent.left
            anchors.right: closeButton.left
            anchors.rightMargin: 12
            anchors.top: parent.top
            anchors.topMargin: 12
            value: Media.available && Media.identity.length > 0 ? Media.identity : "Media"
            strong: true
            size: 17
            color: Theme.fg
        }

        IconButton {
            id: closeButton
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
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 14

        Row {
            width: parent.width
            spacing: 14

            Rectangle {
                width: 118
                height: 118
                radius: Theme.radiusPanel
                color: Theme.primaryContainer
                clip: true

                Image {
                    id: heroArt
                    anchors.fill: parent
                    source: Media.sourceFor(Media.artUrl)
                    sourceSize.width: 236
                    sourceSize.height: 236
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: status === Image.Ready
                }

                Icon {
                    anchors.centerIn: parent
                    visible: heroArt.status !== Image.Ready
                    name: Glyphs.music
                    size: 40
                    color: Theme.primaryContainerText
                }
            }

            Column {
                width: parent.width - 118 - 14
                spacing: 3
                anchors.verticalCenter: parent.verticalCenter

                Label {
                    width: parent.width
                    value: Media.available ? (Media.title || "Unknown track") : "Nothing playing"
                    strong: true
                    size: 18
                    color: Theme.fg
                }

                Label {
                    width: parent.width
                    value: Media.available ? (Media.artist || "Unknown artist") : "No active player"
                    size: 11
                    color: Theme.dim
                }

                Label {
                    width: parent.width
                    value: Media.available
                        ? (Media.album + (Media.length > 0 ? " · " + Media.formatTime(Media.length) : ""))
                        : "Start a media player to use these controls."
                    size: 9
                    color: Theme.dim
                    opacityValue: 0.55
                }
            }
        }

        Item {
            width: parent.width
            height: 30

            ThinSlider {
                anchors.left: parent.left
                anchors.right: parent.right
                y: 7
                height: 14
                trackHeight: 4
                knobWidth: 4
                knobHeight: 13
                value: Media.length > 0 ? Math.min(100, Math.max(0, 100 * Media.position / Media.length)) : 0
                interactive: Media.available && Media.canSeek && Media.length > 0
                onReleased: function(value) {
                    if (Media.length > 0)
                        Media.seek(Media.length * value / 100);
                }
            }

            Label {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                value: Media.available ? Media.formatTime(Media.position) : ""
                size: 8
                color: Theme.dim
                opacityValue: 0.52
            }

            Label {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                value: Media.available ? Media.formatTime(Media.length) : ""
                size: 8
                color: Theme.dim
                opacityValue: 0.52
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 9

            IconButton {
                icon: Glyphs.shuffle
                size: 32
                iconSize: 18
                interactive: Media.available && Media.shuffleSupported
                active: Media.available && Media.player && Media.player.shuffle
                iconColor: Media.shuffleSupported ? Theme.dim : Theme.alpha(Theme.dim, 0.28)
                onClicked: Media.toggleShuffle()
            }

            IconButton {
                icon: Glyphs.previous
                size: 32
                iconSize: 20
                interactive: Media.available && Media.canPrevious
                iconColor: Media.canPrevious ? Theme.dim : Theme.alpha(Theme.dim, 0.28)
                onClicked: Media.previous()
            }

            Rectangle {
                width: 42
                height: 42
                radius: Theme.radiusCard
                color: Media.available ? Theme.primary : Theme.primaryContainer

                Icon {
                    anchors.centerIn: parent
                    name: Media.isPlaying ? Glyphs.pause : Glyphs.play
                    size: 24
                    filled: true
                    color: Theme.primaryText
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: Media.available && Media.canToggle
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Media.toggle()
                }
            }

            IconButton {
                icon: Glyphs.next
                size: 32
                iconSize: 20
                interactive: Media.available && Media.canNext
                iconColor: Media.canNext ? Theme.dim : Theme.alpha(Theme.dim, 0.28)
                onClicked: Media.next()
            }
        }

        Item {
            width: parent.width
            height: 1

            Rectangle {
                anchors.fill: parent
                color: Theme.alpha(Theme.fg, 0.06)
            }
        }

        Row {
            width: parent.width
            spacing: 6

            Rectangle {
                height: 28
                width: outputChip.implicitWidth + 22
                radius: Theme.radiusControl
                color: Theme.input
                border.width: 1
                border.color: Theme.border

                Row {
                    id: outputChip
                    anchors.centerIn: parent
                    spacing: 6

                    Icon {
                        name: Glyphs.speaker
                        size: 14
                        color: Theme.dim
                    }

                    Label {
                        value: Audio.nodeLabel(Audio.sink) || "No output"
                        size: 8
                        color: Theme.dim
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ShellState.openOverlay("volume")
                }
            }

            Rectangle {
                visible: Media.available
                height: 28
                width: playerChip.implicitWidth + 22
                radius: Theme.radiusControl
                color: Theme.input
                border.width: 1
                border.color: Theme.border

                Row {
                    id: playerChip
                    anchors.centerIn: parent
                    spacing: 6

                    Icon {
                        name: Glyphs.music
                        size: 14
                        color: Theme.dim
                    }

                    Label {
                        value: Media.identity.length > 0 ? Media.identity : "Player"
                        size: 8
                        color: Theme.dim
                    }
                }
            }
        }
    }
}
