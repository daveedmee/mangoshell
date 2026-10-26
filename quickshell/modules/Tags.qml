import QtQuick
import ".."
import "../components"
import "../services"

Row {
    id: root

    property string monitor: ""
    property int count: Settings.bar.tagCount

    spacing: 2

    Repeater {
        model: root.count

        delegate: Item {
            id: tagRoot

            required property int index

            readonly property int tagIndex: index + 1
            readonly property string tagState: Mango.tagState(root.monitor, tagIndex)
            readonly property bool hasClients: Mango.tagHasClients(root.monitor, tagIndex)

            width: Settings.bar.tagWidth
            height: Settings.bar.tagHeight

            Rectangle {
                anchors.fill: parent
                radius: Theme.radiusControl
                color: tagRoot.tagState === "active"
                    ? Theme.primary
                    : (tagMouse.containsMouse ? Theme.hover : "transparent")
                border.width: tagRoot.tagState === "urgent" ? 1 : 0
                border.color: Theme.error

                Label {
                    anchors.centerIn: parent
                    value: "" + tagRoot.tagIndex
                    strong: true
                    size: 11
                    color: tagRoot.tagState === "active"
                        ? Theme.primaryText
                        : tagRoot.tagState === "urgent"
                            ? Theme.error
                            : tagRoot.tagState === "occupied"
                                ? Theme.alpha(Theme.fg, 0.68)
                                : Theme.alpha(Theme.fg, 0.38)
                }

                Rectangle {
                    visible: tagRoot.hasClients && tagRoot.tagState !== "active"
                    width: 3
                    height: 3
                    radius: 1
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 3
                    color: tagRoot.tagState === "urgent" ? Theme.error : Theme.primary
                    opacity: 0.9
                }
            }

            MouseArea {
                id: tagMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: function(event) {
                    if (event.button === Qt.RightButton)
                        Overview.capture();
                    else
                        Mango.viewTag(tagRoot.tagIndex);
                }
                onWheel: function(event) {
                    if (event.angleDelta.y > 0)
                        Mango.viewLeft();
                    else if (event.angleDelta.y < 0)
                        Mango.viewRight();
                }
            }
        }
    }
}
