import QtQuick
import ".."

// A slim scroll indicator that can be dragged or clicked like a real
// scrollbar. The hit area is wider than the visible thumb so it is easy to
// grab without making the thumb visually heavy.
Item {
    id: root

    property var target: null
    property color thumbColor: Theme.alpha(Theme.fg, 0.16)
    property color activeColor: Theme.alpha(Theme.fg, 0.30)
    property int thickness: 3
    property int hitWidth: 12

    readonly property bool active: root.target !== null
        && root.target.height > 0
        && root.target.contentHeight > root.target.height
    readonly property real thumbHeight: root.active
        ? Math.max(20, root.target.height * root.target.height / Math.max(root.target.contentHeight, 1))
        : 0
    readonly property real travel: root.active ? Math.max(0, root.target.height - root.thumbHeight) : 0
    readonly property real fraction: {
        if (!root.active)
            return 0;
        const max = root.target.contentHeight - root.target.height;
        return max > 0 ? Math.max(0, Math.min(1, root.target.contentY / max)) : 0;
    }

    width: root.hitWidth
    height: root.target ? root.target.height : 0
    visible: root.active

    Rectangle {
        id: thumb
        width: root.thickness
        height: root.thumbHeight
        x: root.width - width
        y: root.fraction * root.travel
        radius: 1
        color: scrollMouse.containsMouse || scrollMouse.pressed
            ? root.activeColor
            : root.thumbColor
    }

    MouseArea {
        id: scrollMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        property real grabOffset: 0

        function scrollTo(y) {
            const max = root.target.contentHeight - root.target.height;
            if (root.travel <= 0 || max <= 0)
                return;
            const position = Math.max(0, Math.min(root.travel, y - grabOffset));
            root.target.contentY = (position / root.travel) * max;
        }

        onPressed: function(mouse) {
            if (mouse.y >= thumb.y && mouse.y <= thumb.y + thumb.height) {
                grabOffset = mouse.y - thumb.y;
            } else {
                grabOffset = thumb.height / 2;
                scrollTo(mouse.y);
            }
        }

        onPositionChanged: function(mouse) {
            if (pressed)
                scrollTo(mouse.y);
        }

        onWheel: function(wheel) {
            const max = root.target.contentHeight - root.target.height;
            if (max <= 0)
                return;
            const step = (wheel.angleDelta.y / 120) * root.target.height * 0.35;
            root.target.contentY = Math.max(0, Math.min(max, root.target.contentY - step));
        }
    }
}
