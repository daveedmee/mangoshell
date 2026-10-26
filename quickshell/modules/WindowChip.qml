import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../components"
import "../services"

Item {
    id: root

    readonly property var client: Mango.focusedClient
    readonly property string title: Mango.focusedTitle.length > 0 ? Mango.focusedTitle : "Desktop"
    readonly property string appId: Mango.focusedAppId.length > 0 ? Mango.focusedAppId : "MangoWM"
    readonly property string appIcon: {
        if (!root.client)
            return "";
        const entry = DesktopEntries.heuristicLookup(root.appId);
        return entry && entry.icon ? entry.icon : "";
    }

    implicitWidth: 286
    implicitHeight: 32

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusControl
        color: chipMouse.containsMouse ? Theme.hover : "transparent"
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 5
        anchors.rightMargin: 9
        spacing: 8

        Rectangle {
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
            radius: Theme.radiusControl
            color: Theme.primaryContainer
            border.width: 1
            border.color: Theme.alpha(Theme.fg, 0.08)

            Image {
                id: appImage
                anchors.centerIn: parent
                width: 16
                height: 16
                source: root.appIcon.length > 0 ? Quickshell.iconPath(root.appIcon, true) : ""
                sourceSize.width: 32
                sourceSize.height: 32
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                smooth: true
                visible: status === Image.Ready
            }

            Icon {
                anchors.centerIn: parent
                visible: appImage.status !== Image.Ready
                name: Glyphs.desktop
                size: 14
                color: Theme.primaryContainerText
            }
        }

        Column {
            Layout.fillWidth: true
            spacing: 0

            Label {
                width: parent.width
                value: root.title
                strong: true
                size: 11
                color: Theme.alpha(Theme.fg, 0.82)
            }

            Label {
                width: parent.width
                value: root.appId
                size: 8
                color: Theme.dim
                opacityValue: 0.52
            }
        }

        Icon {
            name: Glyphs.chevronDown
            size: 15
            color: Theme.alpha(Theme.dim, 0.55)
        }
    }

    MouseArea {
        id: chipMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: function(event) {
            if (event.button === Qt.RightButton)
                Mango.toggleOverview();
            else
                Overview.capture();
        }
    }
}
