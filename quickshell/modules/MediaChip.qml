import QtQuick
import ".."
import "../components"
import "../services"

Item {
    id: root

    visible: Media.available && Media.title.length > 0
    implicitWidth: visible ? 256 : 0
    implicitHeight: 34

    HoverHandler {
        id: chipHover
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusControl
        color: chipHover.hovered ? Theme.hover : "transparent"
    }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: 3
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Rectangle {
            width: 28
            height: 28
            radius: Theme.radiusControl
            color: Theme.primaryContainer
            clip: true

            Image {
                id: art
                anchors.fill: parent
                source: Media.sourceFor(Media.artUrl)
                sourceSize.width: 56
                sourceSize.height: 56
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                visible: status === Image.Ready
            }

            Icon {
                anchors.centerIn: parent
                visible: art.status !== Image.Ready
                name: Glyphs.music
                size: 17
                color: Theme.primaryContainerText
            }
        }

        Label {
            width: root.width - 48 - 72
            anchors.verticalCenter: parent.verticalCenter
            value: Media.title.length > 0 ? Media.title : "Nothing playing"
            size: 10
            color: Theme.alpha(Theme.fg, 0.70)
        }
    }

    MouseArea {
        id: mediaMouse
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: Math.max(0, root.width - controls.width - 7)
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: function(event) {
            if (event.button === Qt.RightButton)
                Media.toggle();
            else
                ShellState.toggleOverlay("media");
        }
        onWheel: function(event) {
            if (event.angleDelta.y > 0)
                Media.previous();
            else if (event.angleDelta.y < 0)
                Media.next();
        }
    }

    Row {
        id: controls
        anchors.right: parent.right
        anchors.rightMargin: 3
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0
        z: 3

        IconButton {
            icon: Glyphs.previous
            iconSize: 14
            size: 22
            iconColor: Theme.alpha(Theme.fg, 0.72)
            interactive: Media.canPrevious
            onClicked: Media.previous()
        }

        IconButton {
            icon: Media.isPlaying ? Glyphs.pause : Glyphs.play
            iconSize: 15
            size: 22
            filled: Media.isPlaying
            iconColor: Theme.fg
            interactive: Media.canToggle
            onClicked: Media.toggle()
        }

        IconButton {
            icon: Glyphs.next
            iconSize: 14
            size: 22
            iconColor: Theme.alpha(Theme.fg, 0.72)
            interactive: Media.canNext
            onClicked: Media.next()
        }
    }
}
