import QtQuick
import ".."

Item {
    id: root

    property int spacing: 8
    property int lineHeight: 20

    implicitWidth: root.spacing * 2 + 1
    // Match the tallest bar control so the line is vertically centred with
    // buttons and tags instead of sitting at the top of the row.
    implicitHeight: Settings.bar.iconButton

    Rectangle {
        width: 1
        height: root.lineHeight
        anchors.centerIn: parent
        color: Theme.alpha(Theme.fg, 0.10)
    }
}
