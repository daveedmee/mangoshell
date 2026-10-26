import QtQuick
import ".."

Item {
    id: root

    property real value: 0
    property real from: 0
    property real to: 100
    property bool muted: false
    property color trackColor: Theme.alpha(Theme.fg, 0.14)
    property color fillColor: Theme.primary
    property color mutedColor: Theme.dim
    property bool interactive: true
    property int trackHeight: 4
    property int knobWidth: 4
    property int knobHeight: 13

    signal moved(real value)
    signal released(real value)

    implicitWidth: 120
    implicitHeight: 20

    readonly property real fraction: {
        if (root.to <= root.from)
            return 0;
        return Math.max(0, Math.min(1, (root.value - root.from) / (root.to - root.from)));
    }

    function moveToX(x) {
        const usable = Math.max(1, root.width - root.knobWidth);
        const f = Math.max(0, Math.min(1, (x - root.knobWidth / 2) / usable));
        const next = root.from + f * (root.to - root.from);
        root.moved(next);
    }

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: root.trackHeight
        radius: 1
        color: root.trackColor
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(root.knobWidth / 2, root.fraction * parent.width)
        height: root.trackHeight
        radius: 1
        color: root.muted ? root.mutedColor : root.fillColor
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(0, Math.min(parent.width - width, root.fraction * (parent.width - root.knobWidth)))
        width: root.knobWidth
        height: root.knobHeight
        radius: 1
        color: root.muted ? root.mutedColor : root.fillColor
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        enabled: root.interactive
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        preventStealing: true

        onPressed: function(mouse) { root.moveToX(mouse.x); }
        onPositionChanged: function(mouse) {
            if (pressed)
                root.moveToX(mouse.x);
        }
        onReleased: root.released(root.value)
        onWheel: function(wheel) {
            if (wheel.angleDelta.y === 0)
                return;
            const step = (root.to - root.from) / 20;
            const next = root.value + (wheel.angleDelta.y > 0 ? step : -step);
            root.moved(Math.max(root.from, Math.min(root.to, next)));
            root.released(root.value);
        }
    }
}
