import QtQuick
import QtQuick.Layouts
import ".."

Item {
    id: root

    default property alias content: layout.data

    property int paddingH: 0
    property int paddingV: 0
    property int maxHeight: Settings.bar.height
    property bool interactive: true
    property bool active: false

    readonly property bool hovered: mouseArea.containsMouse
    readonly property bool hoverActive: Settings.bar.hover && interactive

    signal clicked(int button)
    signal clickedAt(int button, real x, real y)
    signal wheeled(int delta)
    signal wheeledAt(int delta, real x, real y)

    implicitWidth: layout.implicitWidth + paddingH * 2
    implicitHeight: Math.min(layout.implicitHeight + paddingV * 2, maxHeight)

    Rectangle {
        anchors.fill: parent
        radius: Settings.bar.hoverRadius
        color: Theme.hover
        opacity: root.hoverActive && (root.hovered || root.active) ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 90
                easing.type: Easing.OutCubic
            }
        }
    }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 0
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: root.hoverActive
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor

        onClicked: function(mouse) {
            root.clicked(mouse.button);
            root.clickedAt(mouse.button, mouse.x, mouse.y);
        }
        onWheel: function(wheel) {
            root.wheeled(wheel.angleDelta.y);
            root.wheeledAt(wheel.angleDelta.y, wheel.x, wheel.y);
        }
    }
}
