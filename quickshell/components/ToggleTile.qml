import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool checked: false
    property string accent: "primary"
    property bool action: false

    signal clicked()

    implicitHeight: 74
    radius: Theme.radiusCard
    color: root.checked ? Theme.alpha(Theme.primary, 0.09) : "transparent"
    border.width: 1
    border.color: root.checked
        ? Theme.alpha(Theme.primary, 0.34)
        : (mouse.containsMouse ? Theme.borderStrong : Theme.border)

    readonly property color accentColor: root.accent === "secondary"
        ? Theme.secondary
        : (root.accent === "tertiary" ? Theme.tertiary : Theme.primary)

    Rectangle {
        id: iconBox
        x: 10
        y: 8
        width: 28
        height: 28
        radius: Theme.radiusControl
        color: root.checked ? Theme.alpha(root.accentColor, 0.14) : "transparent"

        Icon {
            anchors.centerIn: parent
            name: root.icon
            size: 17
            filled: root.checked
            color: root.checked ? root.accentColor : Theme.dim
        }
    }

    Label {
        id: titleLabel
        x: 10
        y: 42
        width: parent.width - 20
        value: root.title
        strong: true
        size: 11
        color: root.checked ? root.accentColor : (root.action ? Theme.dim : Theme.fg)
    }

    Label {
        x: 10
        y: 56
        width: parent.width - 20
        value: root.subtitle
        size: 9
        color: Theme.dim
        opacityValue: 0.72
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
