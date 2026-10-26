import QtQuick
import ".."
import "../components"
import "../services"

Item {
    id: root

    readonly property bool muted: Audio.sinkMuted || Audio.sinkPercent <= 0
    readonly property bool micActive: Audio.micInUse
    readonly property bool micMuted: Audio.allSourcesMuted

    // Both indicators live in one master element. The icon slots are sized to
    // the glyph advance so the number can sit right next to the ink; the mic
    // and output gaps then match visually instead of relying on button padding.
    readonly property int masterPadding: 4
    readonly property int outputIconSlot: 19
    readonly property real outputGap: 3.5
    readonly property int clusterGap: 6

    implicitWidth: content.implicitWidth + root.masterPadding * 2
    implicitHeight: 32

    function announce() {
        ShellState.showOsd(
            "volume",
            "Output",
            root.muted ? 0 : Audio.sinkPercent,
            root.muted ? "Muted" : Audio.sinkPercent + "%",
            root.muted
        );
    }

    function announceMic() {
        ShellState.showOsd(
            "mic",
            "Microphone",
            root.micMuted ? 0 : Audio.sourcePercent,
            root.micMuted ? "Muted" : Audio.sourcePercent + "%",
            root.micMuted
        );
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusControl
        color: ShellState.overlay === "volume"
            ? Theme.selected
            : (masterMouse.containsMouse ? Theme.hover : "transparent")
    }

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 0

        Item {
            width: root.outputIconSlot
            height: 22

            Icon {
                anchors.centerIn: parent
                name: root.muted
                    ? Glyphs.volumeMuted
                    : (Audio.sinkPercent < 34
                        ? Glyphs.volumeLow
                        : (Audio.sinkPercent < 67 ? Glyphs.volumeMedium : Glyphs.volumeHigh))
                // volume_off has more vertical ink than the speaker glyphs; a
                // slightly smaller size keeps it optically the same as before.
                size: root.muted ? 17 : 19
                color: root.muted ? Theme.alpha(Theme.fg, 0.55) : Theme.fg
            }
        }

        Item {
            width: root.outputGap
            height: 1
        }

        Label {
            id: level
            anchors.verticalCenter: parent.verticalCenter
            value: root.muted ? "—" : ("" + Audio.sinkPercent)
            size: 12
            strong: false
            color: root.muted
                ? Theme.alpha(Theme.dim, 0.55)
                : Theme.alpha(Theme.fg, 0.78)
        }

        Item {
            width: root.clusterGap
            height: 1
            visible: root.micActive
        }

        Row {
            id: micCluster
            anchors.verticalCenter: parent.verticalCenter
            visible: root.micActive
            spacing: 1

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: root.micMuted ? Glyphs.microphoneMuted : Glyphs.microphone
                size: 19
                color: root.micMuted
                    ? Theme.alpha(Theme.fg, 0.42)
                    : Theme.secondary
            }

            Label {
                anchors.verticalCenter: parent.verticalCenter
                value: root.micMuted ? "—" : ("" + Audio.sourcePercent)
                size: 12
                strong: false
                color: root.micMuted
                    ? Theme.alpha(Theme.dim, 0.55)
                    : Theme.alpha(Theme.fg, 0.78)
            }
        }
    }

    MouseArea {
        id: masterMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        // The mic cluster keeps its own wheel/right-click actions, but the
        // highlight and left-click target span the whole master element.
        readonly property bool overMic: root.micActive
            && mouseX >= content.x + micCluster.x

        onClicked: function(event) {
            if (event.button === Qt.RightButton) {
                if (overMic) {
                    Audio.toggleAllSourceMutes();
                    root.announceMic();
                } else {
                    Audio.toggleSinkMute();
                    root.announce();
                }
                return;
            }
            ShellState.toggleOverlay("volume");
        }

        onWheel: function(event) {
            if (event.angleDelta.y === 0)
                return;
            const step = event.angleDelta.y > 0
                ? Settings.volume.scrollStep
                : -Settings.volume.scrollStep;
            if (overMic) {
                Audio.changeSourceVolumeBy(step);
                root.announceMic();
            } else {
                Audio.changeSinkVolumeBy(step);
                root.announce();
            }
        }
    }
}
