import QtQuick
import ".."
import "../components"
import "../services"

IconButton {
    id: root

    icon: NotificationService.dnd
        ? Glyphs.bellSlash
        : Glyphs.bell
    iconSize: 19
    size: Settings.bar.iconButton
    filled: NotificationService.count > 0 && !NotificationService.dnd
    active: ShellState.overlay === "notifications"
    iconColor: NotificationService.dnd ? Theme.alpha(Theme.fg, 0.48) : Theme.fg
    badgeVisible: NotificationService.count > 0 && !NotificationService.dnd
    badgeText: NotificationService.count > 9 ? "9+" : ("" + NotificationService.count)

    onClicked: NotificationService.toggleCenter()
    onRightClicked: NotificationService.toggleDnd()
}
