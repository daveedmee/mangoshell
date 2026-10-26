import QtQuick
import ".."

Item {
    id: root

    property string name: ""
    property string value: ""
    property real fraction: 0
    property color barColor: Theme.primary

    implicitHeight: 18

    Label {
        id: nameLabel
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 34
        value: root.name
        size: 9
        color: Theme.alpha(Theme.fg, 0.62)
    }

    Rectangle {
        id: track
        anchors.left: nameLabel.right
        anchors.leftMargin: 7
        anchors.right: valueLabel.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        height: 4
        radius: 1
        color: Theme.alpha(Theme.fg, 0.10)

        Rectangle {
            width: Math.max(0, Math.min(1, root.fraction)) * parent.width
            height: parent.height
            radius: 1
            color: root.barColor
        }
    }

    Label {
        id: valueLabel
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 46
        value: root.value
        strong: true
        size: 9
        color: Theme.alpha(Theme.fg, 0.78)
        horizontalAlignment: Text.AlignRight
    }
}
