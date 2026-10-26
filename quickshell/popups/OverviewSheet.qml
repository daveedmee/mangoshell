import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import ".."
import "../components"
import "../services"

Item {
    id: root

    property string query: ""
    property int tagFilter: 0
    property int confirmCloseId: 0

    readonly property var filteredClients: {
        const list = Overview.clients || [];
        const q = root.query.toLowerCase().trim();
        const tag = root.tagFilter;
        const out = [];

        for (let i = 0; i < list.length; i++) {
            const client = list[i];
            const tags = client.tags || [];
            if (tag > 0 && !tags.some(function(value) { return Number(value) === tag; }))
                continue;

            if (q.length > 0) {
                const hay = ((client.title || "") + " " + (client.appid || "")).toLowerCase();
                if (!hay.includes(q))
                    continue;
            }
            out.push(client);
        }
        return out;
    }

    readonly property string monitorName: {
        if (Overview.clients.length > 0 && Overview.clients[0].monitor)
            return Overview.clients[0].monitor;
        if (ShellState.barWindow && ShellState.barWindow.monitorName)
            return ShellState.barWindow.monitorName;
        return "display";
    }

    function appMark(appid) {
        const known = {
            "firefox": "F",
            "org.mozilla.firefox": "F",
            "org.kde.dolphin": "D",
            "org.kde.kate": "K",
            "org.kde.konsole": ">",
            "ai.opencode.desktop": "O",
            "code": "V",
            "code-oss": "V",
            "org.telegram.desktop": "T",
            "discord": "D",
            "spotify": "S",
            "thunderbird": "M",
            "org.gnome.Nautilus": "N"
        };
        if (known[appid])
            return known[appid];
        const tail = ("" + (appid || "")).split(".").pop() || appid || "?";
        return tail.slice(0, 1).toUpperCase();
    }

    function appColor(appid) {
        const value = "" + (appid || "");
        let hash = 0;
        for (let i = 0; i < value.length; i++)
            hash = (hash * 31 + value.charCodeAt(i)) % 997;
        if (hash % 3 === 0)
            return Theme.primary;
        if (hash % 3 === 1)
            return Theme.secondary;
        return Theme.tertiary;
    }

    function distinctTags() {
        const seen = {};
        const list = Overview.clients || [];
        for (let i = 0; i < list.length; i++) {
            const tags = list[i].tags || [];
            for (let j = 0; j < tags.length; j++)
                seen[tags[j]] = true;
        }
        return Object.keys(seen).length;
    }

    function countForTag(tag) {
        if (tag === 0)
            return (Overview.clients || []).length;
        const list = Overview.clients || [];
        let count = 0;
        for (let i = 0; i < list.length; i++) {
            const tags = list[i].tags || [];
            if (tags.some(function(value) { return Number(value) === tag; }))
                count += 1;
        }
        return count;
    }

    function tagLabel(tags) {
        if (!tags || tags.length === 0)
            return "—";
        return tags.join(" · ");
    }

    function requestForceClose(id) {
        const target = Number(id);
        if (target <= 0)
            return;

        if (root.confirmCloseId === target) {
            root.confirmCloseId = 0;
            Overview.forceCloseClient(target);
        } else {
            root.confirmCloseId = target;
            confirmCloseTimer.restart();
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.surface
    }

    Image {
        id: background
        anchors.fill: parent
        anchors.margins: -28
        source: Theme.wallpaperPath.length > 0 ? Theme.wallpaperPath : Overview.shot
        sourceSize.width: root.width
        sourceSize.height: root.height
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        opacity: 0.72

        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: 0.55
            blurMax: 56
            saturation: 0.88
            brightness: -0.08
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.overviewScrim
    }

    Shortcut {
        sequence: "/"
        onActivated: searchField.forceFocus()
    }

    Timer {
        id: confirmCloseTimer
        interval: 3000
        repeat: false
        onTriggered: root.confirmCloseId = 0
    }

    Item {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: Settings.overview.paddingSide
        anchors.rightMargin: Settings.overview.paddingSide
        anchors.topMargin: Settings.overview.paddingTop
        height: 92

        Label {
            anchors.left: parent.left
            anchors.top: parent.top
            value: "Overview"
            strong: true
            size: 31
            color: Theme.fg
        }

        Column {
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: 9

            SearchField {
                id: searchField
                width: 230
                height: 34
                placeholder: "Search windows"
                text: root.query
                onEdited: root.query = searchField.text
            }

            Row {
                anchors.right: parent.right
                spacing: 3

                Repeater {
                    model: 10

                    delegate: Rectangle {
                        id: tagFilterButton

                        required property int index

                        readonly property int tag: index
                        readonly property bool active: root.tagFilter === tag
                        readonly property int count: root.countForTag(tag)

                        width: tag === 0 ? 43 : 30
                        height: 27
                        radius: Theme.radiusControl
                        color: active
                            ? Theme.alpha(Theme.primary, 0.14)
                            : (filterMouse.containsMouse ? Theme.alpha(Theme.fg, 0.06) : Theme.alpha(Theme.surfaceLowest, 0.55))
                        border.width: 1
                        border.color: active ? Theme.alpha(Theme.primary, 0.30) : Theme.alpha(Theme.fg, 0.06)

                        Row {
                            anchors.centerIn: parent
                            spacing: 3

                            Label {
                                value: tagFilterButton.tag === 0 ? "All" : "" + tagFilterButton.tag
                                size: 9
                                color: tagFilterButton.active ? Theme.primary : Theme.alpha(Theme.fg, 0.55)
                            }

                            Label {
                                visible: tagFilterButton.count > 0
                                value: "" + tagFilterButton.count
                                size: 7
                                color: tagFilterButton.active ? Theme.primary : Theme.alpha(Theme.dim, 0.55)
                            }
                        }

                        MouseArea {
                            id: filterMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.tagFilter = tagFilterButton.tag
                        }
                    }
                }
            }
        }
    }

    GridView {
        id: grid
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.bottom: footer.top
        anchors.leftMargin: Settings.overview.paddingSide
        anchors.rightMargin: Settings.overview.paddingSide
        anchors.topMargin: 18
        anchors.bottomMargin: 8
        cellWidth: width / 3
        cellHeight: (width / 3 - Settings.overview.cardGap) * 9 / 16 + Settings.overview.cardGap
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: root.filteredClients

        delegate: Item {
            id: card
            required property var modelData

            readonly property string iconName: {
                const entry = DesktopEntries.heuristicLookup(card.modelData.appid || "");
                return entry && entry.icon ? entry.icon : "";
            }
            readonly property bool confirmingClose: root.confirmCloseId === Number(card.modelData.id)

            width: grid.cellWidth - Settings.overview.cardGap
            height: width * 9 / 16

            Rectangle {
                anchors.fill: parent
                radius: Theme.radiusPanel
                color: Theme.surfaceContainer
                border.width: 1
                border.color: cardHover.hovered
                    ? Theme.alpha(Theme.fg, 0.18)
                    : (card.modelData.is_focused
                        ? Theme.alpha(Theme.primary, 0.58)
                        : Theme.alpha(Theme.fg, 0.09))
                clip: true

                // HoverHandler stays hovered while the pointer is over the
                // close button. A MouseArea-based check flickers because the
                // button's own MouseArea takes over the hover.
                HoverHandler {
                    id: cardHover
                }

                Image {
                    anchors.fill: parent
                    source: (card.modelData.preview || "").length > 0
                        ? "file://" + card.modelData.preview + "?v=" + Overview.previewVersion
                        : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                    visible: (card.modelData.preview || "").length > 0
                }

                Rectangle {
                    anchors.fill: parent
                    visible: (card.modelData.preview || "").length === 0
                    color: Theme.surfaceLow
                }

                Icon {
                    anchors.centerIn: parent
                    visible: (card.modelData.preview || "").length === 0
                    name: Glyphs.desktop
                    size: 38
                    color: Theme.alpha(Theme.dim, 0.35)
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 56
                    color: Theme.alpha(Theme.surfaceLowest, 0.82)
                }

                Rectangle {
                    x: 11
                    y: 11
                    width: tagText.implicitWidth + 12
                    height: 21
                    radius: Theme.radiusControl
                    color: Theme.alpha(Theme.surfaceLowest, 0.64)
                    border.width: 1
                    border.color: Theme.alpha(Theme.fg, 0.13)

                    Label {
                        id: tagText
                        anchors.centerIn: parent
                        value: root.tagLabel(card.modelData.tags)
                        strong: true
                        size: 8
                        color: Theme.fg
                    }
                }

                AppIcon {
                    x: 13
                    y: parent.height - 40
                    size: 27
                    source: card.iconName
                    fallbackIcon: Glyphs.desktop
                    background: Theme.alpha(root.appColor(card.modelData.appid), 0.18)
                    foreground: root.appColor(card.modelData.appid)
                }

                Label {
                    anchors.left: parent.left
                    anchors.leftMargin: 49
                    anchors.right: parent.right
                    anchors.rightMargin: 13
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 20
                    value: card.modelData.title || card.modelData.appid || "Window"
                    strong: true
                    size: 10
                    color: Theme.fg
                    elide: Text.ElideRight
                }

                MouseArea {
                    id: cardMouse
                    z: 1
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Overview.focusClient(card.modelData.id)
                }

                Rectangle {
                    id: closeButton
                    z: 2
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.rightMargin: 8
                    anchors.topMargin: 8
                    width: card.confirmingClose ? 92 : 24
                    height: 24
                    radius: Theme.radiusControl
                    visible: cardHover.hovered || card.confirmingClose
                    // Keep an opaque base so the control stays readable over
                    // bright window previews; the tint below supplies hover.
                    color: Theme.surfaceLowest
                    border.width: 1
                    border.color: card.confirmingClose
                        ? Theme.alpha(Theme.error, closeMouse.containsMouse ? 0.85 : 0.65)
                        : (closeMouse.containsMouse
                            ? Theme.alpha(Theme.primary, 0.45)
                            : Theme.alpha(Theme.fg, 0.22))

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: card.confirmingClose
                            ? Theme.alpha(Theme.error, closeMouse.containsMouse ? 0.32 : 0.24)
                            : (closeMouse.containsMouse ? Theme.hover : "transparent")
                    }

                    Row {
                        anchors.centerIn: parent
                        spacing: 4

                        Icon {
                            visible: card.confirmingClose
                            name: Glyphs.warning
                            size: 11
                            color: Theme.error
                        }

                        Label {
                            visible: card.confirmingClose
                            value: "Force close"
                            strong: true
                            size: 8
                            color: Theme.error
                        }

                        Icon {
                            visible: !card.confirmingClose
                            name: Glyphs.close
                            size: 13
                            color: closeMouse.containsMouse ? Theme.fg : Theme.alpha(Theme.fg, 0.9)
                        }
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        // Left click mirrors SUPER+W (killclient). Right click
                        // starts the force-close confirmation; a second click
                        // on the expanded button confirms it.
                        onClicked: function(mouse) {
                            if (mouse.button === Qt.RightButton) {
                                root.requestForceClose(card.modelData.id);
                            } else if (card.confirmingClose) {
                                root.confirmCloseId = 0;
                                Overview.forceCloseClient(card.modelData.id);
                            } else {
                                Overview.closeClient(card.modelData.id);
                            }
                        }
                    }
                }
            }
        }
    }

    DraggableScrollBar {
        target: grid
        x: grid.x + grid.width - width
        y: grid.y
        z: 20
    }

    Item {
        id: footer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: Settings.overview.paddingSide
        anchors.rightMargin: Settings.overview.paddingSide
        anchors.bottomMargin: Settings.overview.paddingBottom
        height: 26

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 1
            color: Theme.alpha(Theme.fg, 0.08)
        }

        Label {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            value: (root.filteredClients.length) + ((root.filteredClients.length === 1) ? " window" : " windows")
                + " · " + root.monitorName
            size: 8
            color: Theme.alpha(Theme.dim, 0.44)
        }
    }

    Column {
        visible: root.filteredClients.length === 0
        anchors.centerIn: parent
        spacing: 8

        Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            name: Glyphs.desktop
            size: 36
            color: Theme.alpha(Theme.dim, 0.4)
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            value: Overview.loading ? "Capturing windows…" : "No windows match"
            strong: true
            size: 13
            color: Theme.dim
        }
    }
}
