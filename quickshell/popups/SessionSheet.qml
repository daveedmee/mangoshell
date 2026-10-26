import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../components"
import "../services"

Rectangle {
    id: sheet

    property string confirmAction: ""

    implicitWidth: Settings.overlay.sessionWidth
    implicitHeight: 96 + content.implicitHeight + 26
    radius: Theme.radiusPanel
    color: Theme.panel
    border.width: 1
    border.color: Theme.border
    clip: true

    readonly property var actions: [
        { icon: Glyphs.lock, label: "Lock", action: "lock", danger: false },
        { icon: Glyphs.logout, label: "Logout", action: "logout", danger: false },
        { icon: Glyphs.suspend, label: "Suspend", action: "suspend", danger: false },
        { icon: Glyphs.restart, label: "Reboot", action: "reboot", danger: false },
        { icon: Glyphs.power, label: "Shut down", action: "shutdown", danger: true }
    ]

    SystemClock {
        id: headerClock
        precision: SystemClock.Minutes
    }

    Timer {
        id: confirmTimer
        interval: 3000
        repeat: false
        onTriggered: sheet.confirmAction = ""
    }

    function closeAndRun(action) {
        ShellState.closeOverlay();
        if (action === "lock") {
            Quickshell.execDetached(["bash", Settings.paths.shellScripts + "/lock.sh"]);
        } else if (action === "logout") {
            Mango.dispatch("quit");
        } else if (action === "suspend") {
            Quickshell.execDetached(["systemctl", "suspend"]);
        } else if (action === "reboot") {
            Quickshell.execDetached(["systemctl", "reboot"]);
        } else if (action === "shutdown") {
            Quickshell.execDetached(["systemctl", "poweroff"]);
        }
    }

    function activate(action) {
        if (action === "reboot" || action === "shutdown") {
            if (sheet.confirmAction === action) {
                sheet.confirmAction = "";
                sheet.closeAndRun(action);
            } else {
                sheet.confirmAction = action;
                confirmTimer.restart();
            }
            return;
        }
        sheet.closeAndRun(action);
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
        anchors.leftMargin: 26
        anchors.rightMargin: 22
        anchors.topMargin: 22
        height: 64

        Label {
            anchors.left: parent.left
            anchors.top: parent.top
            value: headerClock.date.toLocaleDateString(Qt.locale(), "dddd, dd MMMM")
                + " · " + Qt.formatDateTime(headerClock.date, "HH:mm")
            eyebrow: true
            size: 8
            color: Theme.dim
            opacityValue: 0.7
        }

        Label {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.topMargin: 12
            value: "Session"
            strong: true
            size: 24
            color: Theme.fg
        }

        Label {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.topMargin: 42
            value: "Lock the screen, leave the session, or power off."
            size: 9
            color: Theme.dim
            opacityValue: 0.7
        }

        IconButton {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: -4
            icon: Glyphs.close
            iconSize: 18
            size: 28
            iconColor: Theme.dim
            onClicked: ShellState.closeOverlay()
        }
    }

    Column {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.leftMargin: 26
        anchors.rightMargin: 26
        anchors.topMargin: 10
        spacing: 18

        Row {
            width: parent.width
            spacing: 9

            Repeater {
                model: sheet.actions

                delegate: Rectangle {
                    id: actionTile
                    required property var modelData

                    readonly property bool confirming: sheet.confirmAction === actionTile.modelData.action

                    width: (content.width - 36) / 5
                    height: 100
                    radius: Theme.radiusPanel
                    color: actionMouse.containsMouse
                        ? (actionTile.modelData.danger ? Theme.alpha(Theme.error, 0.08) : Theme.alpha(Theme.surfaceHigh, 0.52))
                        : Theme.alpha(Theme.surfaceHigh, 0.42)
                    border.width: 1
                    border.color: actionTile.confirming
                        ? Theme.alpha(Theme.primary, 0.65)
                        : (actionMouse.containsMouse && actionTile.modelData.danger
                            ? Theme.alpha(Theme.error, 0.22)
                            : Theme.alpha(Theme.fg, 0.055))

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 21
                        width: 37
                        height: 37
                        radius: Theme.radiusCard
                        color: actionTile.modelData.danger
                            ? Theme.alpha(Theme.error, 0.09)
                            : Theme.alpha(Theme.fg, 0.055)

                        Icon {
                            anchors.centerIn: parent
                            name: actionTile.modelData.icon
                            size: 21
                            color: actionTile.modelData.danger ? Theme.error : Theme.dim
                        }
                    }

                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 66
                        value: actionTile.confirming ? "Confirm" : actionTile.modelData.label
                        size: 8
                        color: actionTile.confirming
                            ? Theme.primary
                            : (actionTile.modelData.danger ? Theme.alpha(Theme.error, 0.8) : Theme.dim)
                    }

                    MouseArea {
                        id: actionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: sheet.activate(actionTile.modelData.action)
                    }
                }
            }
        }

        Item {
            width: parent.width
            height: 25

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 1
                color: Theme.alpha(Theme.fg, 0.06)
            }

            Label {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                value: "Cancel"
                size: 9
                color: Theme.dim

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ShellState.closeOverlay()
                }
            }

            Label {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                value: sheet.confirmAction.length > 0
                    ? "Click the highlighted action again to confirm"
                    : "Lock and suspend run immediately"
                size: 8
                color: Theme.dim
                opacityValue: 0.5
            }
        }
    }
}
