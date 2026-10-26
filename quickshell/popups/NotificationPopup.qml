import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../components"
import "../services"

PanelWindow {
    id: root

    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    visible: NotificationService.popupNotifications.length > 0
        && !NotificationService.dnd && !ShellState.overlayOpen

    anchors {
        top: true
        right: true
    }
    margins {
        // Mango places overlay surfaces inside the bar's exclusive zone.
        top: Settings.notifications.popupGap
        right: Settings.notifications.popupMarginRight
    }

    implicitWidth: Settings.notifications.popupWidth
    implicitHeight: content.implicitHeight + Settings.notifications.popupPadding * 2
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    focusable: false

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notification-popup"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    ColumnLayout {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: Settings.notifications.popupPadding
        anchors.rightMargin: Settings.notifications.popupPadding
        anchors.topMargin: Settings.notifications.popupPadding
        spacing: 8

        Repeater {
            model: NotificationService.popupNotifications.slice(0, Settings.notifications.maxPopups)

            delegate: NotificationCard {
                id: card

                required property var modelData

                Layout.fillWidth: true
                notification: modelData
                popupMode: true

                onCloseRequested: NotificationService.dismissNotification(modelData)
                onActivated: {
                    if (!NotificationService.activate(modelData))
                        NotificationService.openCenter();
                }
                onHoveredChanged: NotificationService.setPopupHovered(modelData.id, hovered)
                Component.onDestruction: NotificationService.setPopupHovered(modelData.id, false)
            }
        }
    }
}
