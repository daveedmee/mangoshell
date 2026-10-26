pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import ".."

Singleton {
    id: root

    readonly property var tracked: notificationServer.trackedNotifications
        ? notificationServer.trackedNotifications.values
        : []

    // The center keeps normal notifications. Transient notifications are only
    // tracked while their popup exists.
    readonly property var notifications: {
        const values = root.tracked;
        const list = [];

        for (let i = 0; i < values.length; i++) {
            if (values[i] && !values[i].transient)
                list.push(values[i]);
        }

        list.sort(function(a, b) { return b.id - a.id; });
        return list;
    }

    readonly property int count: root.notifications.length
    property bool dnd: false
    property bool dndReady: false

    readonly property string dndPath: Settings.paths.configHome + "/quickshell/dnd"
    readonly property string configDir: Settings.paths.configHome + "/quickshell"
    readonly property string openScript: Settings.paths.shellScripts + "/notification-open.sh"

    // Newest popup first. The popup window shows the first few entries; the
    // rest wait until a slot is free. Deadlines are absolute so recreating a
    // delegate does not restart a notification's timeout.
    property var popupIds: []
    property var popupDeadlines: ({})
    property var popupPausedAt: ({})
    readonly property var popupNotifications: {
        const all = root.tracked;
        const result = [];

        for (let i = 0; i < root.popupIds.length; i++) {
            const id = root.popupIds[i];
            for (let j = 0; j < all.length; j++) {
                if (all[j] && all[j].id === id) {
                    result.push(all[j]);
                    break;
                }
            }
        }

        return result;
    }

    // Notification objects do not carry a timestamp, so remember when each one
    // arrived for the relative labels in the center.
    property var receivedAt: ({})
    property double nowTick: Date.now()

    NotificationServer {
        id: notificationServer

        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: false
        actionsSupported: true
        actionIconsSupported: false
        imageSupported: true
        inlineReplySupported: false

        onNotification: function(notification) {
            root.handleNotification(notification);
        }
    }

    function handleNotification(notification) {
        if (!notification)
            return;

        const old = notification.lastGeneration;
        const suppressPopup = root.dnd
            || ShellState.overlay !== "";

        if (notification.transient && (suppressPopup || old)) {
            notification.tracked = false;
            return;
        }

        notification.tracked = true;

        const map = Object.assign({}, root.receivedAt);
        if (!map[notification.id])
            map[notification.id] = Date.now();
        root.receivedAt = map;

        if (old) {
            Qt.callLater(root.pruneHistory);
            return;
        }

        if (!suppressPopup)
            root.addPopup(notification);

        Qt.callLater(root.pruneHistory);
    }

    function pruneHistory() {
        const list = root.notifications;
        if (list.length <= Settings.notifications.historyLimit)
            return;

        const excess = list.slice(Settings.notifications.historyLimit);
        for (let i = 0; i < excess.length; i++) {
            if (excess[i])
                excess[i].dismiss();
        }
    }

    function addPopup(notification) {
        if (!notification || root.popupIds.indexOf(notification.id) !== -1)
            return;

        if (root.popupIds.length >= Settings.notifications.popupQueueLimit) {
            const oldest = root.popupIds[root.popupIds.length - 1];
            root.expirePopup(oldest);
        }

        const timeout = root.popupTimeout(notification);
        const deadlines = Object.assign({}, root.popupDeadlines);
        deadlines[notification.id] = timeout > 0 ? Date.now() + timeout : 0;
        root.popupDeadlines = deadlines;

        root.popupIds = [notification.id].concat(root.popupIds);
    }

    function removePopup(id) {
        root.popupIds = root.popupIds.filter(function(value) {
            return value !== id;
        });

        if (root.popupDeadlines[id] !== undefined) {
            const deadlines = Object.assign({}, root.popupDeadlines);
            delete deadlines[id];
            root.popupDeadlines = deadlines;
        }

        if (root.popupPausedAt[id] !== undefined) {
            const paused = Object.assign({}, root.popupPausedAt);
            delete paused[id];
            root.popupPausedAt = paused;
        }
    }

    function setPopupHovered(id, hovered) {
        if (root.popupDeadlines[id] === undefined)
            return;

        const deadlines = Object.assign({}, root.popupDeadlines);
        const paused = Object.assign({}, root.popupPausedAt);

        if (hovered) {
            if (!paused[id] && deadlines[id] > 0)
                paused[id] = Date.now();
        } else if (paused[id]) {
            if (deadlines[id] > 0)
                deadlines[id] += Date.now() - paused[id];
            delete paused[id];
        }

        root.popupDeadlines = deadlines;
        root.popupPausedAt = paused;
    }

    function expireDuePopups() {
        const now = Date.now();
        const ids = root.popupIds.slice();

        for (let i = 0; i < ids.length; i++) {
            const id = ids[i];
            if (!root.findById(id)) {
                root.removePopup(id);
                continue;
            }

            const deadline = root.popupDeadlines[id];
            if (deadline > 0 && !root.popupPausedAt[id] && now >= deadline)
                root.expirePopup(id);
        }
    }

    function expirePopup(id) {
        const notification = root.findById(id);
        root.removePopup(id);

        if (notification && notification.transient)
            notification.dismiss();
    }

    function clearPopups() {
        const ids = root.popupIds;
        root.popupIds = [];
        root.popupDeadlines = ({});
        root.popupPausedAt = ({});

        for (let i = 0; i < ids.length; i++) {
            const notification = root.findById(ids[i]);
            if (notification && notification.transient)
                notification.dismiss();
        }
    }

    function findById(id) {
        const values = root.tracked;
        for (let i = 0; i < values.length; i++) {
            if (values[i] && values[i].id === id)
                return values[i];
        }
        return null;
    }

    // Quickshell exposes the DBus expire-timeout hint in milliseconds.
    function popupTimeout(notification) {
        if (!notification)
            return 0;

        if (notification.expireTimeout > 0)
            return notification.expireTimeout;
        if (notification.expireTimeout === 0)
            return 0;
        if (notification.urgency === NotificationUrgency.Critical)
            return Settings.notifications.timeoutCritical;
        if (notification.urgency === NotificationUrgency.Low)
            return Settings.notifications.timeoutLow;
        return Settings.notifications.timeoutNormal;
    }

    function defaultAction(notification) {
        if (!notification)
            return null;

        const actions = notification.actions || [];
        for (let i = 0; i < actions.length; i++) {
            if (actions[i].identifier === "default")
                return actions[i];
        }
        return null;
    }

    function isSystemNotifier(notification) {
        if (!notification)
            return false;

        const app = ("" + (notification.appName || "")).trim().toLocaleLowerCase();
        const entry = ("" + (notification.desktopEntry || "")).trim().toLocaleLowerCase();
        return app === "notify-send"
            || app === "notify-send (system)"
            || entry === "notify-send.desktop";
    }

    function filePathInBody(body) {
        const text = ("" + (body || "")).trim();
        if (text.length === 0)
            return "";

        const lines = text.split(/\r?\n/);
        for (let i = 0; i < lines.length; i++) {
            const candidate = lines[i].trim();
            if (/^\/.*\.(png|jpe?g|webp|gif|bmp|svg)$/i.test(candidate))
                return candidate;
        }
        return "";
    }

    // A click should take the user to the application that sent the message.
    // System notifiers get the special case of opening an attached image.
    function activate(notification) {
        if (!notification)
            return false;

        const body = "" + (notification.body || "");
        const path = root.filePathInBody(body);
        if (root.isSystemNotifier(notification) && path.length > 0) {
            root.removePopup(notification.id);
            if (ShellState.overlay === "notifications")
                ShellState.closeOverlay();
            Quickshell.execDetached(["xdg-open", path]);
            return true;
        }

        const entry = "" + (notification.desktopEntry || "");
        const app = "" + (notification.appName || "");
        if (entry.length > 0
                || (app.length > 0 && !root.isSystemNotifier(notification))) {
            root.removePopup(notification.id);
            if (ShellState.overlay === "notifications")
                ShellState.closeOverlay();
            Quickshell.execDetached([
                "bash", root.openScript, entry, app, body
            ]);
            return true;
        }

        return root.invokeDefault(notification);
    }

    function invokeDefault(notification) {
        const action = root.defaultAction(notification);
        if (!action)
            return false;

        root.invokeAction(notification, action);
        return true;
    }

    function invokeAction(notification, action) {
        if (!notification || !action)
            return;

        root.removePopup(notification.id);
        action.invoke();
    }

    function dismissNotification(notification) {
        if (!notification)
            return;

        root.removePopup(notification.id);
        notification.dismiss();
    }

    function clearAll() {
        const values = root.tracked.slice();
        root.popupIds = [];
        root.popupDeadlines = ({});
        root.popupPausedAt = ({});
        root.receivedAt = ({});

        for (let i = 0; i < values.length; i++) {
            if (values[i])
                values[i].dismiss();
        }
    }

    function openCenter() {
        root.clearPopups();
        ShellState.openOverlay("notifications");
    }

    function closeCenter() {
        if (ShellState.overlay === "notifications" || ShellState.overlay === "controls")
            ShellState.closeOverlay();
    }

    function toggleCenter() {
        if (ShellState.overlay === "notifications")
            ShellState.closeOverlay();
        else
            root.openCenter();
    }

    function setDnd(value) {
        root.dnd = value;
        if (root.dnd)
            root.clearPopups();
    }

    function toggleDnd() {
        root.setDnd(!root.dnd);
    }

    onDndChanged: {
        if (!root.dndReady)
            return;
        dndSave.command = [
            "bash", "-c",
            "mkdir -p \"" + root.configDir + "\" && printf '%s' "
                + (root.dnd ? "1" : "0") + " > \"" + root.dndPath + "\""
        ];
        dndSave.running = true;
    }

    Component.onCompleted: dndLoad.running = true

    Process {
        id: dndLoad
        command: [
            "bash", "-c",
            "if [ -f \"" + root.dndPath + "\" ]; then cat \"" + root.dndPath + "\"; else echo 0; fi"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                root.dndReady = false;
                root.dnd = (text || "").trim() === "1";
                root.dndReady = true;
            }
        }
    }

    Process {
        id: dndSave
    }

    function relativeTime(id) {
        const timestamp = root.receivedAt[id];
        if (!timestamp)
            return "";

        const seconds = Math.max(0, Math.floor((root.nowTick - timestamp) / 1000));
        if (seconds < 60)
            return "now";
        if (seconds < 3600)
            return Math.floor(seconds / 60) + "m";
        if (seconds < 86400)
            return Math.floor(seconds / 3600) + "h";
        return Math.floor(seconds / 86400) + "d";
    }

    IpcHandler {
        target: "notifications"

        function toggle(): void { root.toggleCenter(); }
        function dnd(): void { root.toggleDnd(); }
        function clear(): void { root.clearAll(); }
        function count(): int { return root.count; }
        function dndState(): bool { return root.dnd; }
    }

    Timer {
        interval: 30000
        repeat: true
        running: true
        onTriggered: root.nowTick = Date.now()
    }

    Timer {
        interval: 500
        repeat: true
        running: root.popupIds.length > 0
        onTriggered: root.expireDuePopups()
    }
}
