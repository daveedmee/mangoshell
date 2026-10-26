import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../components"
import "../services"

Rectangle {
    id: panel

    implicitWidth: Settings.overlay.sidebarWidth
    implicitHeight: 900
    radius: Theme.radiusPanel
    color: Theme.panel
    border.width: 1
    border.color: Theme.border
    clip: true

    SystemClock {
        id: headerClock
        precision: SystemClock.Minutes
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
    }

    Item {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 20
        anchors.rightMargin: 16
        anchors.topMargin: 18
        height: 46

        Label {
            anchors.left: parent.left
            anchors.top: parent.top
            value: headerClock.date.toLocaleDateString(Qt.locale(), "dddd, dd MMMM")
            eyebrow: true
            size: 8
            color: Theme.dim
            opacityValue: 0.72
        }

        Label {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.topMargin: 14
            value: "Notifications"
            strong: true
            size: 21
            color: Theme.fg
        }

        IconButton {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: -2
            icon: Glyphs.close
            iconSize: 18
            size: 28
            iconColor: Theme.dim
            onClicked: ShellState.closeOverlay()
        }
    }

    Flickable {
        id: scroll
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.leftMargin: 16
        anchors.rightMargin: 10
        anchors.topMargin: 12
        contentWidth: width
        contentHeight: contentColumn.height + 16
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: contentColumn
            width: scroll.width - 6
            spacing: 10

            Rectangle {
                width: parent.width
                height: 56
                radius: Theme.radiusCard
                color: Theme.card
                border.width: 1
                border.color: Theme.alpha(Theme.fg, 0.065)

                AppIcon {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    size: 30
                    fallbackIcon: Glyphs.dnd
                    background: Theme.alpha(Theme.fg, 0.055)
                }

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 53
                    anchors.right: dndSwitch.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    Label {
                        width: parent.width
                        value: "Do Not Disturb"
                        strong: true
                        size: 11
                        color: Theme.fg
                    }

                    Label {
                        width: parent.width
                        value: "Suppress popups, keep history"
                        size: 8
                        color: Theme.dim
                        opacityValue: 0.58
                    }
                }

                ToggleSwitch {
                    id: dndSwitch
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    checked: NotificationService.dnd
                    onToggled: NotificationService.toggleDnd()
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: NotificationService.toggleDnd()
                    z: -1
                }
            }

            Repeater {
                model: NotificationService.notifications

                delegate: NotificationCard {
                    required property var modelData
                    width: contentColumn.width
                    notification: modelData
                    popupMode: false
                    onCloseRequested: NotificationService.dismissNotification(modelData)
                    onActivated: NotificationService.activate(modelData)
                }
            }

            Item {
                width: parent.width
                height: 170
                visible: NotificationService.count === 0

                Column {
                    anchors.centerIn: parent
                    spacing: 8

                    Icon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        name: NotificationService.dnd ? Glyphs.bellSlash : Glyphs.checkCircle
                        size: 30
                        color: Theme.primary
                        opacityValue: 0.72
                    }

                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        value: NotificationService.dnd ? "Do Not Disturb is on" : "All caught up"
                        strong: true
                        size: 12
                        color: Theme.fg
                    }

                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        value: "New notifications will appear here."
                        size: 9
                        color: Theme.dim
                        opacityValue: 0.55
                    }
                }
            }

            Item {
                width: parent.width
                height: 30
                visible: NotificationService.count > 0

                Label {
                    anchors.left: parent.left
                    value: "Clear all"
                    size: 9
                    color: Theme.primary

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NotificationService.clearAll()
                    }
                }

                Label {
                    anchors.right: parent.right
                    value: NotificationService.count + (NotificationService.count === 1 ? " notification" : " notifications")
                    size: 8
                    color: Theme.dim
                    opacityValue: 0.5
                }
            }
        }

    }

    Rectangle {
        width: 3
        height: Math.max(20, scroll.height * scroll.height / Math.max(scroll.contentHeight, 1))
        x: panel.width - 7
        y: scroll.y + scroll.contentY / Math.max(1, scroll.contentHeight - scroll.height) * (scroll.height - height)
        radius: 1
        color: Theme.alpha(Theme.fg, 0.14)
        visible: scroll.contentHeight > scroll.height
    }
}
