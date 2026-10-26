import QtQuick
import ".."

Item {
    id: root

    property string icon: ""
    property int iconSize: 18
    property real iconRotation: 0
    property int size: 28
    property bool filled: false
    property bool active: false
    property bool interactive: true
    property bool outlined: false
    property bool danger: false
    property color iconColor: Theme.fg
    property string tip: ""
    property bool badgeVisible: false
    property string badgeText: ""

    signal clicked()
    signal rightClicked()
    signal wheeled(int delta)

    implicitWidth: root.size
    implicitHeight: root.size

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusControl
        color: {
            if (root.active)
                return Theme.selected;
            if (root.interactive && mouse.containsMouse)
                return root.danger ? Theme.alpha(Theme.error, 0.10) : Theme.hover;
            return "transparent";
        }
        border.width: root.outlined ? 1 : 0
        border.color: root.active || mouse.containsMouse
            ? Theme.alpha(Theme.primary, 0.34)
            : Theme.border
    }

    Icon {
        anchors.centerIn: parent
        name: root.icon
        rotation: root.iconRotation
        size: root.iconSize
        filled: root.filled || root.active
        color: {
            if (root.danger)
                return Theme.error;
            if (root.active || root.outlined)
                return Theme.primary;
            if (root.interactive && mouse.containsMouse)
                return Theme.fg;
            return root.iconColor;
        }
    }

    Rectangle {
        visible: root.badgeVisible
        anchors.right: parent.right
        anchors.rightMargin: 2
        anchors.top: parent.top
        anchors.topMargin: 1
        width: Math.max(14, badgeLabel.implicitWidth + 6)
        height: 14
        radius: Theme.radiusControl
        color: Theme.primary
        border.width: 1
        border.color: Theme.alpha(Theme.surfaceLowest, 0.9)

        Label {
            id: badgeLabel
            anchors.centerIn: parent
            value: root.badgeText
            strong: true
            size: 8
            color: Theme.primaryText
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.interactive
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: function(event) {
            if (event.button === Qt.RightButton)
                root.rightClicked();
            else
                root.clicked();
        }
        onWheel: function(event) {
            root.wheeled(event.angleDelta.y);
        }
    }
}
