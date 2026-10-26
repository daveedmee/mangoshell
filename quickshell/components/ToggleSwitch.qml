import QtQuick
import ".."

Item {
    id: root

    property bool checked: false
    property bool interactive: true

    signal toggled()

    implicitWidth: 34
    implicitHeight: 18
    opacity: root.interactive ? 1 : 0.4

    Rectangle {
        id: track
        anchors.fill: parent
        radius: 2
        color: root.checked
            ? Theme.primary
            : (mouse.containsMouse ? Theme.alpha(Theme.fg, 0.10) : Theme.alpha(Theme.fg, 0.055))
        border.width: 1
        border.color: root.checked
            ? Theme.alpha(Theme.fg, 0.20)
            : Theme.border

        Rectangle {
            width: 12
            height: 12
            radius: 1
            y: 3
            x: root.checked ? parent.width - width - 3 : 3
            color: root.checked ? Theme.fg : "#000000"
            border.width: root.checked ? 0 : 1
            border.color: Theme.alpha(Theme.fg, 0.16)

            Behavior on x {
                NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: true
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.toggled()
    }
}
