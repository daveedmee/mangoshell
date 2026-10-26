import QtQuick
import Quickshell
import Quickshell.Wayland
import "."
import "popups"
import "services"

PanelWindow {
    id: host

    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    visible: ShellState.overlayOpen && ShellState.overlay !== "layouts"

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    focusable: visible

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-overlay"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    readonly property string overlay: ShellState.overlay
    readonly property bool modal: overlay === "session" || overlay === "gallery"
        || overlay === "clipboard" || overlay === "overview"
    readonly property bool sidebar: overlay === "controls" || overlay === "notifications"

    function componentFor(name) {
        switch (name) {
        case "controls": return controlsComponent;
        case "notifications": return notificationsComponent;
        case "media": return mediaComponent;
        case "calendar": return calendarComponent;
        case "volume": return volumeComponent;
        case "network": return networkComponent;
        case "bluetooth": return bluetoothComponent;
        case "devices": return devicesComponent;
        case "tray": return trayMenuComponent;
        case "session": return sessionComponent;
        case "gallery": return galleryComponent;
        case "clipboard": return clipboardComponent;
        case "overview": return overviewComponent;
        default: return null;
        }
    }

    function calendarWidth() {
        return ShellState.centerBarWidth > 0
            ? ShellState.centerBarWidth
            : Settings.overlay.calendarWidth;
    }

    function viewX() {
        const margin = Settings.overlay.sideMargin;
        if (host.sidebar || host.overlay === "media"
                || host.overlay === "volume" || host.overlay === "network"
                || host.overlay === "bluetooth" || host.overlay === "devices")
            return host.width - host.viewWidth() - margin;
        if (host.overlay === "tray")
            return Math.max(8, Math.min(ShellState.trayMenuX,
                host.width - Settings.overlay.trayMenuWidth - 8));
        if (host.overlay === "calendar")
            return (host.width - host.calendarWidth()) / 2;
        if (host.overlay === "session")
            return (host.width - Settings.overlay.sessionWidth) / 2;
        if (host.overlay === "gallery")
            return (host.width - Settings.overlay.galleryWidth) / 2;
        if (host.overlay === "clipboard")
            return (host.width - Settings.overlay.clipboardWidth) / 2;
        return 0;
    }

    function viewY() {
        if (host.overlay === "overview")
            return 0;
        if (host.overlay === "session")
            return (host.height - view.height) / 2;
        if (host.overlay === "gallery")
            return (host.height - Settings.overlay.galleryHeight) / 2;
        if (host.overlay === "clipboard")
            return (host.height - Settings.overlay.clipboardHeight) / 2;
        return Settings.overlay.topGap;
    }

    function viewWidth() {
        if (host.sidebar)
            return Settings.overlay.sidebarWidth;
        if (host.overlay === "media")
            return Settings.overlay.mediaWidth;
        if (host.overlay === "calendar")
            return host.calendarWidth();
        if (host.overlay === "volume" || host.overlay === "network")
            return Settings.overlay.popoverWidth;
        if (host.overlay === "bluetooth")
            return Settings.overlay.bluetoothWidth;
        if (host.overlay === "devices")
            return Settings.overlay.devicesWidth;
        if (host.overlay === "tray")
            return Settings.overlay.trayMenuWidth;
        if (host.overlay === "session")
            return Settings.overlay.sessionWidth;
        if (host.overlay === "gallery")
            return Settings.overlay.galleryWidth;
        if (host.overlay === "clipboard")
            return Settings.overlay.clipboardWidth;
        if (host.overlay === "overview")
            return host.width;
        return 0;
    }

    function viewHeight() {
        if (host.sidebar)
            return host.height - Settings.overlay.topGap - Settings.overlay.sidebarBottom;
        if (host.overlay === "overview")
            return host.height;
        if (host.overlay === "session")
            return view.item ? view.item.implicitHeight : 0;
        if (host.overlay === "gallery")
            return Settings.overlay.galleryHeight;
        if (host.overlay === "clipboard")
            return Settings.overlay.clipboardHeight;
        if (host.overlay === "media" || host.overlay === "calendar"
                || host.overlay === "volume" || host.overlay === "network"
                || host.overlay === "bluetooth" || host.overlay === "devices"
                || host.overlay === "tray")
            return view.item ? view.item.implicitHeight : 0;
        return 0;
    }

    onOverlayChanged: {
        ShellState.hideOsd();
        NotificationService.clearPopups();
    }

    Shortcut {
        sequence: "Escape"
        enabled: host.visible
        onActivated: ShellState.closeOverlay()
    }

    Rectangle {
        anchors.fill: parent
        visible: host.modal
        color: Theme.scrim
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: ShellState.closeOverlay()
    }

    Loader {
        id: view
        active: host.overlay.length > 0 && host.overlay !== "layouts"
        sourceComponent: host.componentFor(host.overlay)
        x: host.viewX()
        y: host.viewY()
        width: host.viewWidth()
        height: host.viewHeight()

        Binding {
            target: view.item
            property: "width"
            value: view.width
            when: view.item !== null
        }

        Binding {
            target: view.item
            property: "height"
            value: view.height
            when: view.item !== null
        }
    }

    Component { id: controlsComponent; ControlsPanel {} }
    Component { id: notificationsComponent; NotificationsPanel {} }
    Component { id: mediaComponent; MediaPopover {} }
    Component { id: calendarComponent; CalendarPopover {} }
    Component { id: volumeComponent; VolumePopover {} }
    Component { id: networkComponent; NetworkPopover {} }
    Component { id: bluetoothComponent; BluetoothPopover {} }
    Component { id: devicesComponent; DevicesPopover {} }
    Component { id: trayMenuComponent; TrayMenu {} }
    Component { id: sessionComponent; SessionSheet {} }
    Component { id: galleryComponent; WallpaperSheet {} }
    Component { id: clipboardComponent; ClipboardSheet {} }
    Component { id: overviewComponent; OverviewSheet {} }
}
