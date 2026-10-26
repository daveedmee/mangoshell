import QtQuick
import Quickshell
import ".."
import "../components"

Item {
    id: root

    implicitWidth: 90
    implicitHeight: 34

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusControl
        color: clockMouse.containsMouse ? Theme.hover : "transparent"
    }

    Column {
        anchors.centerIn: parent
        spacing: 0

        Label {
            width: root.width
            value: Qt.formatDateTime(clock.date, "HH:mm")
            strong: true
            size: 18
            color: Theme.fg
            horizontalAlignment: Text.AlignHCenter
        }

        Label {
            width: root.width
            value: clock.date.toLocaleDateString(Qt.locale(), "ddd · dd MMM")
            eyebrow: true
            size: 8
            color: Theme.dim
            opacityValue: 0.72
            horizontalAlignment: Text.AlignHCenter
        }
    }

    MouseArea {
        id: clockMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: ShellState.toggleOverlay("calendar")
    }
}
