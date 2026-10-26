import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import ".."
import "../components"
import "../services"

Rectangle {
    id: sheet

    property string selectedPath: Theme.wallpaperPath
    property string folder: "All"
    property string browserTab: "library"
    property string fileFolder: Settings.paths.home
    property string colorTarget: "source"
    property bool eyedropperActive: false
    property string eyedropperReturnHex: "#000000"
    property string eyedropperStatus: ""

    implicitWidth: Settings.overlay.galleryWidth
    implicitHeight: Settings.overlay.galleryHeight
    radius: Theme.radiusPanel
    color: Theme.panel
    border.width: 1
    border.color: Theme.border
    clip: true

    readonly property var currentInfo: Wallpapers.info && Wallpapers.info.path === sheet.selectedPath
        ? Wallpapers.info
        : null
    readonly property var filteredItems: Wallpapers.filtered(searchField.text, sheet.folder)
    readonly property var palette: {
        if (sheet.currentInfo && sheet.currentInfo.palette && sheet.currentInfo.palette.length >= 5)
            return sheet.currentInfo.palette;
        return [Theme.surfaceLowest, Theme.primaryContainer, Theme.primary, Theme.secondary, Theme.tertiary];
    }
    readonly property var sourceColors: {
        if (sheet.currentInfo && sheet.currentInfo.sourceColors && sheet.currentInfo.sourceColors.length > 0)
            return sheet.currentInfo.sourceColors;
        return sheet.palette;
    }
    readonly property var schemes: [
        { code: "scheme-tonal-spot", label: "Tonal" },
        { code: "scheme-content", label: "Content" },
        { code: "scheme-expressive", label: "Expressive" },
        { code: "scheme-fidelity", label: "Fidelity" },
        { code: "scheme-fruit-salad", label: "Fruit" },
        { code: "scheme-neutral", label: "Neutral" },
        { code: "scheme-monochrome", label: "Mono" },
        { code: "scheme-rainbow", label: "Rainbow" },
        { code: "scheme-vibrant", label: "Vibrant" },
        { code: "scheme-smart", label: "Smart" }
    ]

    function hexColor(color) {
        function part(value) {
            const hex = Math.round(Math.max(0, Math.min(255, value * 255))).toString(16);
            return hex.length < 2 ? "0" + hex : hex;
        }
        return "#" + part(color.r) + part(color.g) + part(color.b);
    }

    function colorString(value) {
        if (value === null || value === undefined)
            return "";
        return typeof value === "string" ? value : sheet.hexColor(value);
    }

    function applySettings() {
        MatugenSettings.scheduleApply();
    }

    function themeColorFor(target) {
        if (target === "textColor")
            return sheet.hexColor(Theme.fg);
        if (target === "activeColor")
            return sheet.hexColor(Theme.primary);
        if (target === "backgroundColor")
            return sheet.hexColor(Theme.surface);
        return sheet.hexColor(Theme.primary);
    }

    function colorTitleFor(target) {
        if (target === "textColor")
            return "Text colour";
        if (target === "activeColor")
            return "Active colour";
        if (target === "backgroundColor")
            return "Background colour";
        if (target === "wallpaperColor")
            return "Base colour";
        return "Source colour";
    }

    function openThemeColor(target, start) {
        sheet.colorTarget = target;
        colorPicker.title = sheet.colorTitleFor(target);
        colorPicker.openWith(
            start && start.length > 0 ? start : sheet.themeColorFor(target),
            sheet.sourceColors);
    }

    function resetThemeColors() {
        MatugenSettings.textColor = "";
        MatugenSettings.activeColor = "";
        MatugenSettings.backgroundColor = "";
        sheet.applySettings();
    }

    function startEyedropper() {
        if (sheet.selectedPath.length === 0)
            return;
        sheet.eyedropperReturnHex = colorPicker.hex;
        sheet.eyedropperStatus = "";
        sheet.eyedropperActive = true;
        colorPicker.visible = false;
    }

    function cancelEyedropper() {
        if (!sheet.eyedropperActive)
            return;
        sheet.eyedropperActive = false;
        colorPicker.title = sheet.colorTitleFor(sheet.colorTarget);
        colorPicker.openWith(sheet.eyedropperReturnHex, sheet.sourceColors);
    }

    function sampleEyedropperAt(px, py) {
        if (!sheet.eyedropperActive)
            return;
        if (eyedropperProcess.running)
            return;

        const image = eyedropperImage;
        if (image.paintedWidth <= 0 || image.paintedHeight <= 0) {
            sheet.eyedropperStatus = "Wallpaper is still loading";
            return;
        }

        const offsetX = (image.width - image.paintedWidth) / 2;
        const offsetY = (image.height - image.paintedHeight) / 2;
        if (px < offsetX || px > offsetX + image.paintedWidth
                || py < offsetY || py > offsetY + image.paintedHeight) {
            sheet.eyedropperStatus = "Click inside the wallpaper";
            return;
        }

        const fx = (px - offsetX) / image.paintedWidth;
        const fy = (py - offsetY) / image.paintedHeight;
        sheet.eyedropperStatus = "Sampling…";
        eyedropperProcess.command = [
            "bash", Settings.paths.shellScripts + "/wallpaper-sample-color.sh",
            sheet.selectedPath, "" + fx, "" + fy
        ];
        eyedropperProcess.running = true;
    }

    function selectPath(path) {
        if (!path)
            return;
        sheet.selectedPath = path;
        Wallpapers.inspect(path);
    }

    function goToFolder(path) {
        let next = ("" + (path || "")).trim();
        if (next.length === 0)
            return;
        if (next.charAt(0) !== "/")
            next = "/" + next;
        next = next.replace(/\/+$/, "");
        if (next.length === 0)
            next = "/";
        sheet.fileFolder = next;
        filePathInput.text = next;
    }

    function parentFolder(path) {
        const clean = ("" + (path || "")).replace(/\/+$/, "");
        const index = clean.lastIndexOf("/");
        return index <= 0 ? "/" : clean.slice(0, index);
    }

    function formatBytes(value) {
        if (!value)
            return "unknown";
        const raw = "" + value;
        let size = typeof value === "number" ? value : NaN;
        if (isNaN(size)) {
            const unit = raw.toUpperCase().match(/([KMGT]?)I?B$/);
            const numeric = parseFloat(raw.replace(/[^0-9.]/g, ""));
            if (!isNaN(numeric) && unit) {
                const power = ({ "": 0, "K": 1, "M": 2, "G": 3, "T": 4 })[unit[1]] || 0;
                size = numeric * Math.pow(1024, power);
            } else {
                size = parseInt(raw.replace(/[^0-9]/g, ""));
            }
        }
        if (isNaN(size))
            return raw;
        if (size >= 1024 * 1024)
            return (size / (1024 * 1024)).toFixed(1) + " MB";
        if (size >= 1024)
            return Math.round(size / 1024) + " KB";
        return size + " B";
    }

    function resolutionText(info) {
        if (!info || !info.width || !info.height)
            return "Unknown";
        return info.width + " × " + info.height;
    }

    Component.onCompleted: {
        Wallpapers.refresh();
        if (sheet.selectedPath.length > 0)
            Wallpapers.inspect(sheet.selectedPath);
    }

    Connections {
        target: Wallpapers
        function onItemsChanged() {
            if (sheet.selectedPath.length === 0 && Wallpapers.items.length > 0)
                sheet.selectPath(Wallpapers.items[0].path);
        }
    }

    Shortcut {
        sequence: "/"
        onActivated: searchField.forceFocus()
    }

    Shortcut {
        sequence: "Escape"
        enabled: sheet.eyedropperActive
        onActivated: sheet.cancelEyedropper()
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
        anchors.leftMargin: 24
        anchors.rightMargin: 22
        anchors.topMargin: 21
        height: 55

        Label {
            anchors.left: parent.left
            anchors.top: parent.top
            value: "Library · Wallpaper"
            eyebrow: true
            size: 8
            color: Theme.dim
            opacityValue: 0.7
        }

        Label {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.topMargin: 11
            value: "Wallpaper"
            strong: true
            size: 22
            color: Theme.fg
        }

        Label {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.topMargin: 38
            value: "Search, preview, and apply. Pywal and Matugen regenerate together."
            size: 9
            color: Theme.dim
            opacityValue: 0.7
        }

        IconButton {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: -3
            icon: Glyphs.close
            iconSize: 18
            size: 28
            iconColor: Theme.dim
            onClicked: ShellState.closeOverlay()
        }
    }

    Item {
        id: body
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.bottom: footer.top
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        anchors.topMargin: 2
        anchors.bottomMargin: 8

        Column {
            id: previewPane
            width: 520
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            spacing: 11

            Rectangle {
                width: parent.width
                height: 214
                radius: Theme.radiusCard
                color: Theme.surfaceLowest
                border.width: 1
                border.color: Theme.alpha(Theme.fg, 0.09)
                clip: true

                Image {
                    anchors.fill: parent
                    source: sheet.selectedPath
                    sourceSize.width: 1040
                    sourceSize.height: 585
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                }

                Icon {
                    anchors.centerIn: parent
                    visible: sheet.selectedPath.length === 0
                    name: Glyphs.wallpaper
                    size: 40
                    color: Theme.alpha(Theme.dim, 0.4)
                }
            }

            Rectangle {
                width: parent.width
                height: 376
                radius: Theme.radiusCard
                color: Theme.card
                border.width: 1
                border.color: Theme.alpha(Theme.fg, 0.06)

                Column {
                    x: 14
                    y: 16
                    width: parent.width - 28
                    spacing: 18

                    Item {
                        width: parent.width
                        height: 28

                        Label {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            value: "Matugen"
                            strong: true
                            size: 13
                            color: Theme.fg
                        }

                        Label {
                            id: resetLabel
                            anchors.right: modeRow.left
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            value: "Reset"
                            size: 9
                            color: Theme.primary

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: MatugenSettings.setDefaults()
                            }
                        }

                        Row {
                            id: modeRow
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3

                            Repeater {
                                model: [
                                    { code: "auto", label: "Auto" },
                                    { code: "dark", label: "Dark" },
                                    { code: "light", label: "Light" }
                                ]

                                delegate: Rectangle {
                                    required property var modelData

                                    width: 40
                                    height: 22
                                    radius: Theme.radiusControl
                                    color: MatugenSettings.mode === modelData.code
                                        ? Theme.primaryContainer
                                        : (modeMouse.containsMouse ? Theme.hover : "transparent")
                                    border.width: 1
                                    border.color: MatugenSettings.mode === modelData.code
                                        ? Theme.alpha(Theme.primary, 0.32)
                                        : Theme.alpha(Theme.fg, 0.07)

                                    Label {
                                        anchors.centerIn: parent
                                        value: modelData.label
                                        size: 8
                                        color: MatugenSettings.mode === modelData.code
                                            ? Theme.primaryContainerText
                                            : Theme.dim
                                    }

                                    MouseArea {
                                        id: modeMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            MatugenSettings.mode = modelData.code;
                                            sheet.applySettings();
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        width: parent.width
                        height: 62

                        Label {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.topMargin: 2
                            value: "Scheme"
                            size: 9
                            color: Theme.dim
                            opacityValue: 0.7
                        }

                        Grid {
                            id: schemeGrid
                            x: 60
                            width: parent.width - 60
                            columns: 5
                            columnSpacing: 4
                            rowSpacing: 4

                            Repeater {
                                model: sheet.schemes

                                delegate: Rectangle {
                                    required property var modelData

                                    width: (schemeGrid.width - 16) / 5
                                    height: 24
                                    radius: Theme.radiusControl
                                    color: MatugenSettings.scheme === modelData.code
                                        ? Theme.alpha(Theme.primary, 0.14)
                                        : (schemeMouse.containsMouse ? Theme.hover : Theme.alpha(Theme.fg, 0.035))
                                    border.width: 1
                                    border.color: MatugenSettings.scheme === modelData.code
                                        ? Theme.alpha(Theme.primary, 0.32)
                                        : Theme.alpha(Theme.fg, 0.06)

                                    Label {
                                        anchors.centerIn: parent
                                        width: parent.width - 4
                                        horizontalAlignment: Text.AlignHCenter
                                        value: modelData.label
                                        size: 8
                                        color: MatugenSettings.scheme === modelData.code
                                            ? Theme.primary
                                            : Theme.dim
                                        elide: Text.ElideRight
                                    }

                                    MouseArea {
                                        id: schemeMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            MatugenSettings.scheme = modelData.code;
                                            sheet.applySettings();
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: 10

                        Item {
                            width: (parent.width - 10) / 2
                            height: 40

                            Label {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                value: "Contrast"
                                size: 9
                                color: Theme.dim
                            }

                            Label {
                                anchors.right: parent.right
                                anchors.top: parent.top
                                value: (MatugenSettings.contrast >= 0 ? "+" : "")
                                    + Math.round(MatugenSettings.contrast * 100) + "%"
                                size: 9
                                color: Theme.alpha(Theme.fg, 0.7)
                            }

                            ThinSlider {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: 18
                                from: -1
                                to: 1
                                value: MatugenSettings.contrast
                                interactive: MatugenSettings.loaded
                                trackHeight: 3
                                knobWidth: 4
                                knobHeight: 12
                                onMoved: function(value) { MatugenSettings.contrast = value; }
                                onReleased: sheet.applySettings()
                            }
                        }

                        Item {
                            width: (parent.width - 10) / 2
                            height: 40

                            Label {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                value: "Brightness"
                                size: 9
                                color: Theme.dim
                            }

                            Label {
                                anchors.right: parent.right
                                anchors.top: parent.top
                                value: (MatugenSettings.lightness >= 0 ? "+" : "")
                                    + Math.round(MatugenSettings.lightness * 100) + "%"
                                size: 9
                                color: Theme.alpha(Theme.fg, 0.7)
                            }

                            ThinSlider {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: 18
                                from: -0.08
                                to: 0.4
                                value: MatugenSettings.lightness
                                interactive: MatugenSettings.loaded
                                trackHeight: 3
                                knobWidth: 4
                                knobHeight: 12
                                onMoved: function(value) { MatugenSettings.lightness = value; }
                                onReleased: sheet.applySettings()
                            }
                        }
                    }

                    Item {
                        width: parent.width
                        height: 28

                        Label {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            value: "Source"
                            size: 9
                            color: Theme.dim
                            opacityValue: 0.7
                        }

                        Row {
                            x: 60
                            spacing: 4

                            Rectangle {
                                width: 38
                                height: 26
                                radius: Theme.radiusControl
                                color: MatugenSettings.sourceColor.length === 0
                                    ? Theme.alpha(Theme.primary, 0.14)
                                    : (autoMouse.containsMouse ? Theme.hover : "transparent")
                                border.width: 1
                                border.color: MatugenSettings.sourceColor.length === 0
                                    ? Theme.alpha(Theme.primary, 0.32)
                                    : Theme.alpha(Theme.fg, 0.08)

                                Label {
                                    anchors.centerIn: parent
                                    value: "Auto"
                                    size: 8
                                    color: MatugenSettings.sourceColor.length === 0 ? Theme.primary : Theme.dim
                                }

                                MouseArea {
                                    id: autoMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        MatugenSettings.sourceColor = "";
                                        sheet.applySettings();
                                    }
                                }
                            }

                            Repeater {
                                model: sheet.sourceColors

                                delegate: Rectangle {
                                    required property var modelData

                                    readonly property bool selected: sheet.colorString(MatugenSettings.sourceColor).toLowerCase()
                                        === sheet.colorString(modelData).toLowerCase()

                                    width: 26
                                    height: 26
                                    radius: Theme.radiusControl
                                    color: modelData
                                    border.width: selected ? 2 : 1
                                    border.color: selected ? Theme.fg : Theme.alpha(Theme.fg, 0.15)

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            MatugenSettings.sourceColor = sheet.colorString(modelData);
                                            sheet.applySettings();
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                width: 68
                                height: 26
                                radius: Theme.radiusControl
                                color: customMouse.containsMouse ? Theme.hover : Theme.alpha(Theme.fg, 0.04)
                                border.width: 1
                                border.color: Theme.alpha(Theme.fg, 0.09)

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Icon {
                                        name: Glyphs.palette
                                        size: 13
                                        color: Theme.dim
                                    }

                                    Label {
                                        value: "Custom"
                                        size: 8
                                        color: Theme.dim
                                    }
                                }

                                MouseArea {
                                    id: customMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: colorPicker.openWith(
                                        MatugenSettings.sourceColor.length > 0
                                            ? MatugenSettings.sourceColor
                                            : sheet.hexColor(Theme.primary),
                                        sheet.sourceColors)
                                }
                            }
                        }

                        Label {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            visible: MatugenSettings.applying
                            value: "Applying…"
                            size: 7
                            color: Theme.alpha(Theme.primary, 0.8)
                        }
                    }

                    Item {
                        width: parent.width
                        height: 34

                        Label {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            value: "Tune"
                            size: 9
                            color: Theme.dim
                            opacityValue: 0.7
                        }

                        Row {
                            x: 60
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            Repeater {
                                model: [
                                    { key: "textColor", label: "Text", width: 74 },
                                    { key: "activeColor", label: "Active", width: 78 },
                                    { key: "backgroundColor", label: "Background", width: 102 }
                                ]

                                delegate: Rectangle {
                                    required property var modelData

                                    readonly property string current: MatugenSettings[modelData.key] || ""

                                    width: modelData.width
                                    height: 26
                                    radius: Theme.radiusControl
                                    color: current.length > 0
                                        ? Theme.alpha(Theme.primary, 0.10)
                                        : (tuneMouse.containsMouse ? Theme.hover : Theme.alpha(Theme.fg, 0.035))
                                    border.width: 1
                                    border.color: current.length > 0
                                        ? Theme.alpha(Theme.primary, 0.34)
                                        : Theme.alpha(Theme.fg, 0.06)

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 5

                                        Rectangle {
                                            width: 10
                                            height: 10
                                            radius: 2
                                            color: current.length > 0
                                                ? current
                                                : sheet.themeColorFor(modelData.key)
                                            border.width: 1
                                            border.color: Theme.alpha(Theme.fg, 0.20)
                                        }

                                        Label {
                                            value: modelData.label
                                            size: 8
                                            color: current.length > 0 ? Theme.fg : Theme.dim
                                        }
                                    }

                                    MouseArea {
                                        id: tuneMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: sheet.openThemeColor(modelData.key, current)
                                    }
                                }
                            }

                            Rectangle {
                                width: 38
                                height: 26
                                radius: Theme.radiusControl
                                color: tuneResetMouse.containsMouse ? Theme.hover : "transparent"
                                border.width: 1
                                border.color: Theme.alpha(Theme.fg, 0.08)

                                Label {
                                    anchors.centerIn: parent
                                    value: "Auto"
                                    size: 8
                                    color: Theme.dim
                                }

                                MouseArea {
                                    id: tuneResetMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: sheet.resetThemeColors()
                                }
                            }
                        }
                    }

                    Item {
                        width: parent.width
                        height: 34

                        Label {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            value: "Placement"
                            size: 9
                            color: Theme.dim
                            opacityValue: 0.7
                        }

                        Row {
                            x: 60
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            Repeater {
                                model: [
                                    { code: "fill", label: "Crop" },
                                    { code: "fit", label: "Fit" },
                                    { code: "stretch", label: "Stretch" },
                                    { code: "tile", label: "Tile" },
                                    { code: "center", label: "Center" }
                                ]

                                delegate: Rectangle {
                                    required property var modelData

                                    readonly property bool selected: Wallpapers.displayMode === modelData.code

                                    width: 52
                                    height: 26
                                    radius: Theme.radiusControl
                                    color: selected
                                        ? Theme.alpha(Theme.primary, 0.14)
                                        : (placementMouse.containsMouse ? Theme.hover : Theme.alpha(Theme.fg, 0.035))
                                    border.width: 1
                                    border.color: selected
                                        ? Theme.alpha(Theme.primary, 0.34)
                                        : Theme.alpha(Theme.fg, 0.06)

                                    Label {
                                        anchors.centerIn: parent
                                        value: modelData.label
                                        size: 8
                                        color: selected ? Theme.primary : Theme.dim
                                    }

                                    MouseArea {
                                        id: placementMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Wallpapers.setDisplayMode(modelData.code)
                                    }
                                }
                            }

                            Rectangle {
                                width: 68
                                height: 26
                                radius: Theme.radiusControl
                                color: baseColorMouse.containsMouse
                                    ? Theme.hover
                                    : Theme.alpha(Theme.fg, 0.035)
                                border.width: 1
                                border.color: Theme.alpha(Theme.fg, 0.07)

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 5

                                    Rectangle {
                                        width: 10
                                        height: 10
                                        radius: 2
                                        color: Wallpapers.displayColor
                                        border.width: 1
                                        border.color: Theme.alpha(Theme.fg, 0.22)
                                    }

                                    Label {
                                        value: "Base"
                                        size: 8
                                        color: Theme.dim
                                    }
                                }

                                MouseArea {
                                    id: baseColorMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        sheet.colorTarget = "wallpaperColor";
                                        colorPicker.title = "Base colour";
                                        colorPicker.openWith(Wallpapers.displayColor, sheet.sourceColors);
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Row {
                width: parent.width
                spacing: 8

                Rectangle {
                    width: applyRow.implicitWidth + 32
                    height: 38
                    radius: Theme.radiusControl
                    color: sheet.selectedPath.length > 0 && !Wallpapers.applying
                        ? Theme.primary
                        : Theme.alpha(Theme.primary, 0.45)

                    Row {
                        id: applyRow
                        anchors.centerIn: parent
                        spacing: 7

                        Icon {
                            name: Glyphs.check
                            size: 17
                            color: Theme.primaryText
                        }

                        Label {
                            y: 2
                            value: Wallpapers.applying ? "Applying…" : "Apply wallpaper"
                            strong: true
                            size: 10
                            color: Theme.primaryText
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: sheet.selectedPath.length > 0 && !Wallpapers.applying
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: Wallpapers.apply(sheet.selectedPath)
                    }
                }

                Rectangle {
                    width: 103
                    height: 38
                    radius: Theme.radiusControl
                    color: randomMouse.containsMouse ? Theme.alpha(Theme.fg, 0.09) : Theme.alpha(Theme.fg, 0.06)
                    border.width: 1
                    border.color: Theme.alpha(Theme.fg, 0.08)

                    Row {
                        anchors.centerIn: parent
                        spacing: 6

                        Icon {
                            name: Glyphs.shuffle
                            size: 16
                            color: Theme.fg
                        }

                        Label {
                            y: 2
                            value: "Random"
                            size: 9
                            color: Theme.fg
                        }
                    }

                    MouseArea {
                        id: randomMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const picked = Wallpapers.pickRandom(sheet.filteredItems);
                            if (picked)
                                sheet.selectPath(picked.path);
                        }
                    }
                }

                Rectangle {
                    width: 82
                    height: 38
                    radius: Theme.radiusControl
                    color: cancelMouse.containsMouse ? Theme.hover : "transparent"
                    border.width: 1
                    border.color: Theme.alpha(Theme.fg, 0.10)

                    Label {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: 2
                        value: "Cancel"
                        size: 9
                        color: Theme.alpha(Theme.fg, 0.7)
                    }

                    MouseArea {
                        id: cancelMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ShellState.closeOverlay()
                    }
                }
            }
        }

        Item {
            id: browser
            anchors.left: previewPane.right
            anchors.leftMargin: 22
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            Row {
                id: tabs
                width: parent.width
                height: 26
                spacing: 4

                Repeater {
                    model: [
                        { code: "library", label: "Library" },
                        { code: "files", label: "Files" }
                    ]

                    delegate: Rectangle {
                        required property var modelData

                        width: 74
                        height: 26
                        radius: Theme.radiusControl
                        color: sheet.browserTab === modelData.code
                            ? Theme.primaryContainer
                            : (tabMouse.containsMouse ? Theme.hover : Theme.alpha(Theme.fg, 0.035))
                        border.width: 1
                        border.color: sheet.browserTab === modelData.code
                            ? Theme.alpha(Theme.primary, 0.28)
                            : Theme.alpha(Theme.fg, 0.06)

                        Label {
                            anchors.centerIn: parent
                            value: modelData.label
                            size: 8
                            color: sheet.browserTab === modelData.code
                                ? Theme.primaryContainerText
                                : Theme.alpha(Theme.fg, 0.65)
                        }

                        MouseArea {
                            id: tabMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                sheet.browserTab = modelData.code;
                                if (modelData.code === "files")
                                    sheet.goToFolder(sheet.fileFolder);
                            }
                        }
                    }
                }
            }

            SearchField {
                id: searchField
                y: 37
                width: parent.width
                height: 36
                visible: sheet.browserTab === "library"
                placeholder: "Search " + Wallpapers.items.length + " wallpapers"
                onAccepted: {
                    if (sheet.selectedPath.length > 0)
                        Wallpapers.apply(sheet.selectedPath);
                }
            }

            Flickable {
                id: folderScroller
                y: 84
                width: parent.width
                height: 25
                visible: sheet.browserTab === "library"
                contentWidth: folderRow.width
                contentHeight: height
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Row {
                    id: folderRow
                    spacing: 5

                    Repeater {
                        model: ["All"].concat(Wallpapers.folders)

                        delegate: Rectangle {
                            id: folderChip
                            required property string modelData

                            width: folderLabel.implicitWidth + 20
                            height: 24
                            radius: Theme.radiusControl
                            color: sheet.folder === folderChip.modelData
                                ? Theme.primaryContainer
                                : (folderMouse.containsMouse ? Theme.hover : Theme.alpha(Theme.fg, 0.035))

                            Label {
                                id: folderLabel
                                anchors.centerIn: parent
                                value: folderChip.modelData
                                size: 8
                                color: sheet.folder === folderChip.modelData ? Theme.primaryContainerText : Theme.alpha(Theme.fg, 0.6)
                            }

                            MouseArea {
                                id: folderMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: sheet.folder = folderChip.modelData
                            }
                        }
                    }
                }
            }

            Row {
                id: fileNavigation
                y: 37
                width: parent.width
                height: 32
                visible: sheet.browserTab === "files"
                spacing: 5

                IconButton {
                    icon: Glyphs.arrowUp
                    iconSize: 16
                    size: 30
                    iconColor: Theme.dim
                    onClicked: sheet.goToFolder(sheet.parentFolder(sheet.fileFolder))
                }

                IconButton {
                    icon: Glyphs.home
                    iconSize: 16
                    size: 30
                    iconColor: Theme.dim
                    onClicked: sheet.goToFolder(Settings.paths.home)
                }

                Rectangle {
                    width: parent.width - 70
                    height: 32
                    radius: Theme.radiusControl
                    color: Theme.surfaceLowest
                    border.width: 1
                    border.color: filePathInput.activeFocus
                        ? Theme.alpha(Theme.primary, 0.42)
                        : Theme.alpha(Theme.fg, 0.07)

                    TextInput {
                        id: filePathInput
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 9
                        anchors.rightMargin: 7
                        height: parent.height
                        verticalAlignment: TextInput.AlignVCenter
                        text: sheet.fileFolder
                        color: Theme.fg
                        font.family: Theme.fontText
                        font.pixelSize: 10
                        selectionColor: Theme.primary
                        selectedTextColor: Theme.primaryText
                        clip: true
                        activeFocusOnPress: true
                        onAccepted: sheet.goToFolder(text)
                    }

                    Icon {
                        anchors.right: parent.right
                        anchors.rightMargin: 9
                        anchors.verticalCenter: parent.verticalCenter
                        name: Glyphs.folder
                        size: 13
                        color: Theme.dim
                        opacityValue: 0.6
                    }
                }
            }

            FolderListModel {
                id: fileModel
                folder: "file://" + sheet.fileFolder
                nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.avif", "*.bmp", "*.gif"]
                showDirs: true
                showFiles: true
                showHidden: false
                sortField: FolderListModel.Name
                caseSensitive: false
            }

            GridView {
                id: libraryGrid
                y: 120
                width: parent.width
                height: parent.height - 120
                visible: sheet.browserTab === "library"
                cellWidth: width / 3
                cellHeight: ((width / 3 - 9) * 9 / 16) + 9
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: sheet.filteredItems

                delegate: Rectangle {
                    id: wallCard
                    required property var modelData

                    width: libraryGrid.cellWidth - 9
                    height: width * 9 / 16
                    radius: Theme.radiusControl
                    color: Theme.surfaceLow
                    border.width: 1
                    border.color: sheet.selectedPath === wallCard.modelData.path
                        ? Theme.primary
                        : (wallMouse.containsMouse ? Theme.primary : Theme.alpha(Theme.fg, 0.07))
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: wallCard.modelData.path
                        sourceSize.width: wallCard.width
                        sourceSize.height: wallCard.height
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                    }

                    Rectangle {
                        visible: sheet.selectedPath === wallCard.modelData.path
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.rightMargin: 6
                        anchors.topMargin: 6
                        width: 18
                        height: 18
                        radius: Theme.radiusControl
                        color: Theme.primary

                        Icon {
                            anchors.centerIn: parent
                            name: Glyphs.check
                            size: 12
                            color: Theme.primaryText
                        }
                    }

                    MouseArea {
                        id: wallMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: sheet.selectPath(wallCard.modelData.path)
                        onDoubleClicked: Wallpapers.apply(wallCard.modelData.path)
                    }
                }
            }

            GridView {
                id: fileGrid
                y: 78
                width: parent.width
                height: parent.height - 78
                visible: sheet.browserTab === "files"
                cellWidth: width / 3
                cellHeight: 96
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: fileModel

                delegate: Rectangle {
                    id: fileCard
                    required property string fileName
                    required property string filePath
                    required property url fileUrl
                    required property bool fileIsDir

                    width: fileGrid.cellWidth - 9
                    height: 88
                    radius: Theme.radiusControl
                    color: Theme.surfaceLow
                    border.width: 1
                    border.color: !fileCard.fileIsDir && sheet.selectedPath === fileCard.filePath
                        ? Theme.primary
                        : (fileMouse.containsMouse ? Theme.primary : Theme.alpha(Theme.fg, 0.07))
                    clip: true

                    Image {
                        anchors.fill: parent
                        visible: !fileCard.fileIsDir
                        source: fileCard.fileIsDir ? "" : fileCard.fileUrl
                        sourceSize.width: fileCard.width
                        sourceSize.height: fileCard.height
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                    }

                    Rectangle {
                        anchors.fill: parent
                        visible: fileCard.fileIsDir
                        color: Theme.alpha(Theme.primary, 0.06)

                        Icon {
                            anchors.centerIn: parent
                            name: Glyphs.folder
                            size: 28
                            color: Theme.alpha(Theme.primary, 0.72)
                        }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 21
                        color: Theme.alpha(Theme.surfaceLowest, 0.86)

                        Label {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 7
                            anchors.rightMargin: 7
                            anchors.verticalCenter: parent.verticalCenter
                            value: fileCard.fileName
                            size: 8
                            color: Theme.alpha(Theme.fg, 0.82)
                            elide: Text.ElideMiddle
                        }
                    }

                    Rectangle {
                        visible: !fileCard.fileIsDir && sheet.selectedPath === fileCard.filePath
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.rightMargin: 6
                        anchors.topMargin: 6
                        width: 18
                        height: 18
                        radius: Theme.radiusControl
                        color: Theme.primary

                        Icon {
                            anchors.centerIn: parent
                            name: Glyphs.check
                            size: 12
                            color: Theme.primaryText
                        }
                    }

                    MouseArea {
                        id: fileMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (fileCard.fileIsDir)
                                sheet.goToFolder(fileCard.filePath);
                            else
                                sheet.selectPath(fileCard.filePath);
                        }
                        onDoubleClicked: {
                            if (!fileCard.fileIsDir)
                                Wallpapers.apply(fileCard.filePath);
                        }
                    }
                }
            }
        }

        DraggableScrollBar {
            id: browserScrollbar
            target: sheet.browserTab === "library" ? libraryGrid : fileGrid
            x: browser.x + browser.width - width
            y: browser.y + target.y
            z: 20
        }

        Column {
            visible: sheet.browserTab === "library"
                && (Wallpapers.loading || sheet.filteredItems.length === 0)
            anchors.centerIn: browser
            spacing: 6

            Icon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: Wallpapers.loading ? Glyphs.refresh : Glyphs.image
                size: 30
                color: Theme.alpha(Theme.dim, 0.4)
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                value: Wallpapers.loading ? "Indexing wallpapers…" : "No wallpapers found"
                size: 10
                color: Theme.dim
            }
        }

        Column {
            visible: sheet.browserTab === "files" && fileGrid.count === 0
            anchors.centerIn: browser
            spacing: 6

            Icon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: Glyphs.folder
                size: 30
                color: Theme.alpha(Theme.dim, 0.4)
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                value: "No images in this folder"
                size: 10
                color: Theme.dim
            }
        }
    }

    Item {
        id: footer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        height: 37

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 1
            color: Theme.alpha(Theme.fg, 0.06)
        }

        Label {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            value: "Thumbnails are generated lazily · hidden folders and Photos libraries are skipped"
            size: 8
            color: Theme.alpha(Theme.dim, 0.55)
        }

        Label {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            value: "Double-click apply · Esc close"
            size: 8
            color: Theme.alpha(Theme.dim, 0.45)
        }
    }

    Process {
        id: eyedropperProcess
        command: []
        stdout: StdioCollector {
            onStreamFinished: {
                if (!sheet.eyedropperActive)
                    return;
                const value = (text || "").trim();
                if (!/^#[0-9a-fA-F]{6}$/.test(value)) {
                    sheet.eyedropperStatus = "Could not read that pixel";
                    return;
                }
                sheet.eyedropperActive = false;
                colorPicker.title = sheet.colorTitleFor(sheet.colorTarget);
                colorPicker.openWith(value, sheet.sourceColors);
            }
        }
        onExited: {
            if (sheet.eyedropperActive && sheet.eyedropperStatus === "Sampling…")
                sheet.eyedropperStatus = "Could not read that pixel";
        }
    }

    Rectangle {
        id: eyedropperOverlay
        anchors.fill: parent
        z: 110
        visible: sheet.eyedropperActive
        color: Theme.alpha(Theme.scrim, 0.97)
        radius: Theme.radiusPanel
        clip: true

        Item {
            id: eyedropperHeader
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: 24
            anchors.rightMargin: 24
            anchors.topMargin: 18
            height: 52

            Label {
                anchors.left: parent.left
                anchors.top: parent.top
                value: "Eyedropper"
                eyebrow: true
                size: 10
                color: Theme.dim
                opacityValue: 0.72
            }

            Label {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.topMargin: 16
                value: "Pick a colour from the wallpaper"
                strong: true
                size: 17
                color: Theme.fg
            }

            Label {
                anchors.right: eyedropperClose.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                value: sheet.eyedropperStatus.length > 0
                    ? sheet.eyedropperStatus
                    : "Click the image · Esc to cancel"
                size: 10
                color: sheet.eyedropperStatus === "Could not read that pixel"
                    ? Theme.error
                    : Theme.dim
                opacityValue: 0.78
            }

            IconButton {
                id: eyedropperClose
                anchors.right: parent.right
                anchors.top: parent.top
                icon: Glyphs.close
                iconSize: 18
                size: 28
                iconColor: Theme.dim
                onClicked: sheet.cancelEyedropper()
            }
        }

        Rectangle {
            id: eyedropperStage
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: eyedropperHeader.bottom
            anchors.topMargin: 10
            anchors.bottom: parent.bottom
            anchors.leftMargin: 24
            anchors.rightMargin: 24
            anchors.bottomMargin: 24
            radius: Theme.radiusCard
            color: Theme.surfaceLowest
            border.width: 1
            border.color: Theme.alpha(Theme.fg, 0.08)
            clip: true

            Image {
                id: eyedropperImage
                anchors.fill: parent
                source: sheet.selectedPath
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                cache: true
            }

            Label {
                anchors.centerIn: parent
                visible: eyedropperImage.status === Image.Loading
                value: "Loading wallpaper…"
                size: 10
                color: Theme.dim
                opacityValue: 0.6
            }

            Label {
                anchors.centerIn: parent
                visible: eyedropperImage.status === Image.Error
                value: "Could not load this wallpaper"
                size: 10
                color: Theme.error
            }

            Rectangle {
                visible: pickMouse.containsMouse
                x: Math.round(pickMouse.mouseX)
                y: 0
                width: 1
                height: eyedropperStage.height
                color: Theme.alpha(Theme.primary, 0.42)
            }

            Rectangle {
                visible: pickMouse.containsMouse
                x: 0
                y: Math.round(pickMouse.mouseY)
                width: eyedropperStage.width
                height: 1
                color: Theme.alpha(Theme.primary, 0.42)
            }

            Rectangle {
                visible: pickMouse.containsMouse
                x: Math.round(pickMouse.mouseX) - 7
                y: Math.round(pickMouse.mouseY) - 7
                width: 14
                height: 14
                radius: 7
                color: "transparent"
                border.width: 1
                border.color: Theme.primary
            }

            MouseArea {
                id: pickMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.CrossCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: function(event) {
                    if (event.button === Qt.RightButton)
                        sheet.cancelEyedropper();
                    else
                        sheet.sampleEyedropperAt(event.x, event.y);
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        z: 99
        visible: colorPicker.visible
        color: Theme.alpha(Theme.scrim, 0.72)

        MouseArea {
            anchors.fill: parent
            onClicked: colorPicker.visible = false
        }
    }

    ColorPickerPanel {
        id: colorPicker
        anchors.centerIn: parent
        z: 100
        visible: false
        onEyedropperRequested: sheet.startEyedropper()
        onApplied: function(color) {
            if (sheet.colorTarget === "textColor")
                MatugenSettings.textColor = color;
            else if (sheet.colorTarget === "activeColor")
                MatugenSettings.activeColor = color;
            else if (sheet.colorTarget === "backgroundColor")
                MatugenSettings.backgroundColor = color;
            else if (sheet.colorTarget === "wallpaperColor") {
                Wallpapers.setDisplayColor(color);
                return;
            } else
                MatugenSettings.sourceColor = color;
            sheet.applySettings();
        }
    }
}
