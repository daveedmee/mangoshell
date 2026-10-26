import QtQuick
import ".."

Item {
    id: root

    property string icon: Glyphs.volumeHigh
    property string label: ""
    property string valueText: ""
    property real value: 0
    property bool muted: false
    property color accent: Theme.primary
    property bool interactive: true

    signal moved(real value)
    signal released(real value)

    implicitHeight: 38

    Icon {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 20
        name: root.icon
        size: 17
        color: root.muted ? Theme.alpha(Theme.dim, 0.55) : Theme.dim
    }

    Column {
        anchors.left: parent.left
        anchors.leftMargin: 28
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3

        Item {
            width: parent.width
            height: 13

            Label {
                anchors.left: parent.left
                value: root.label
                size: 9
                color: Theme.alpha(Theme.fg, 0.72)
            }

            Label {
                anchors.right: parent.right
                value: root.valueText
                size: 9
                color: Theme.alpha(Theme.fg, 0.72)
            }
        }

        ThinSlider {
            width: parent.width
            height: 14
            value: root.value
            muted: root.muted
            fillColor: root.accent
            interactive: root.interactive
            onMoved: function(value) { root.moved(value); }
            onReleased: function(value) { root.released(value); }
        }
    }
}
