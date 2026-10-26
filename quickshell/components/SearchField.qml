import QtQuick
import ".."

Rectangle {
    id: root

    property alias text: input.text
    property string placeholder: "Search"
    property int textSize: 10
    property bool showKeyHint: true
    property string keyHint: "/"

    signal accepted()
    signal edited()

    implicitHeight: 36
    radius: Theme.radiusControl
    color: Theme.surfaceLowest
    border.width: 0

    function forceFocus() {
        input.forceActiveFocus();
    }

    Icon {
        id: searchIcon
        x: 10
        anchors.verticalCenter: parent.verticalCenter
        name: Glyphs.search
        size: 16
        color: Theme.dim
        opacityValue: 0.55
    }

    TextInput {
        id: input
        x: 34
        width: parent.width - 34 - (root.showKeyHint ? 34 : 12)
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height
        verticalAlignment: TextInput.AlignVCenter
        color: Theme.fg
        font.family: Theme.fontText
        font.pixelSize: root.textSize
        selectionColor: Theme.primary
        selectedTextColor: Theme.primaryText
        clip: true
        onAccepted: root.accepted()
        onTextChanged: root.edited()
    }

    Label {
        x: 34
        width: parent.width - 34 - 34
        anchors.verticalCenter: parent.verticalCenter
        visible: input.text.length === 0
        value: root.placeholder
        size: root.textSize
        color: Theme.dim
        opacityValue: 0.45
    }

    Rectangle {
        visible: root.showKeyHint
        anchors.right: parent.right
        anchors.rightMargin: 9
        anchors.verticalCenter: parent.verticalCenter
        width: 18
        height: 18
        radius: 2
        color: "transparent"
        border.width: 1
        border.color: Theme.alpha(Theme.fg, 0.10)

        Label {
            anchors.centerIn: parent
            value: root.keyHint
            size: 8
            color: Theme.dim
            opacityValue: 0.45
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: input.forceActiveFocus()
    }
}
