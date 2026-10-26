import QtQuick
import ".."

Item {
    id: root

    property string icon: ""
    property string label: ""
    property bool danger: false

    signal clicked()

    implicitHeight: 49

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusControl
        color: mouse.containsMouse
            ? (root.danger ? Theme.alpha(Theme.error, 0.10) : Theme.hover)
            : "transparent"
    }

    Column {
        anchors.centerIn: parent
        spacing: 4

        Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            name: root.icon
            size: 18
            color: mouse.containsMouse
                ? (root.danger ? Theme.error : Theme.fg)
                : (root.danger ? Theme.error : Theme.dim)
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            value: root.label
            size: 8
            color: mouse.containsMouse
                ? (root.danger ? Theme.error : Theme.fg)
                : (root.danger ? Theme.alpha(Theme.error, 0.8) : Theme.dim)
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
