pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "."
import "services"

Singleton {
    id: root

    // Matugen writes both palettes in one atomically replaced file.
    readonly property var fallbackDark: ({
        "surface": "#1a110f",
        "surface_container_lowest": "#140c0a",
        "surface_container_low": "#231917",
        "surface_container": "#271d1b",
        "surface_container_high": "#322825",
        "surface_container_highest": "#3d3230",
        "on_surface": "#f1dfdb",
        "on_surface_variant": "#d8c2bd",
        "outline": "#a08c88",
        "outline_variant": "#534340",
        "primary": "#ffb4a4",
        "on_primary": "#561f13",
        "primary_container": "#733427",
        "on_primary_container": "#ffdad3",
        "secondary": "#e7bdb4",
        "on_secondary": "#442a24",
        "secondary_container": "#5d3f39",
        "on_secondary_container": "#ffdad3",
        "tertiary": "#dbc48c",
        "on_tertiary": "#3c2f04",
        "tertiary_container": "#544519",
        "on_tertiary_container": "#f8e0a6",
        "error": "#ffb4ab",
        "on_error": "#690005",
        "error_container": "#93000a",
        "on_error_container": "#ffdad6",
        "inverse_surface": "#f1dfdb",
        "inverse_on_surface": "#392e2c",
        "background": "#1a110f",
        "scrim": "#000000"
    })

    readonly property var fallbackLight: ({
        "surface": "#fff8f6",
        "surface_container_lowest": "#ffffff",
        "surface_container_low": "#fff0ed",
        "surface_container": "#fceae6",
        "surface_container_high": "#f6e4e0",
        "surface_container_highest": "#f1dfdb",
        "on_surface": "#231917",
        "on_surface_variant": "#534340",
        "outline": "#85736f",
        "outline_variant": "#d8c2bd",
        "primary": "#904b3c",
        "on_primary": "#ffffff",
        "primary_container": "#ffdad3",
        "on_primary_container": "#3a0a03",
        "secondary": "#77574f",
        "on_secondary": "#ffffff",
        "secondary_container": "#ffdad3",
        "on_secondary_container": "#2c1510",
        "tertiary": "#6e5d2e",
        "on_tertiary": "#ffffff",
        "tertiary_container": "#f8e0a6",
        "on_tertiary_container": "#241a00",
        "error": "#ba1a1a",
        "on_error": "#ffffff",
        "error_container": "#ffdad6",
        "on_error_container": "#410002",
        "inverse_surface": "#392e2c",
        "inverse_on_surface": "#f1dfdb",
        "background": "#fff8f6",
        "scrim": "#000000"
    })

    property var rolesDark: fallbackDark
    property var rolesLight: fallbackLight
    property string surfaceMode: "dark"
    property string wallpaperPath: Settings.paths.wallpaper
    property string schemeName: "Tonal spot"

    readonly property bool isDark: surfaceMode !== "light"
    readonly property var roles: isDark ? rolesDark : rolesLight

    readonly property string fontText: "Futura PT Web Book"
    readonly property string fontDemi: "Futura PT Demi"
    readonly property string fontIcon: "Material Symbols Rounded"

    readonly property int textSize: 12
    readonly property int iconSize: 18
    readonly property int smallIconSize: 17
    readonly property int sizeBody: 11

    // theme-refresh.sh sets this when the bar's top strip is too busy for a
    // single text colour. The halo uses the surface colour so it sits behind
    // the foreground in both light and dark palettes.
    property bool outlineText: false
    readonly property color textOutline: alpha(surface, 0.72)

    // Radii are deliberately tight. Nothing in the shell is a pill.
    readonly property int radiusBar: 4
    readonly property int radiusPanel: 5
    readonly property int radiusCard: 4
    readonly property int radiusControl: 3

    function colorOf(name, fallback) {
        const value = root.roles ? root.roles[name] : undefined;
        if (value === undefined || value === null || value === "")
            return Qt.color(fallback || "#000000");
        return Qt.color("" + value);
    }

    function alpha(value, a) {
        const c = value === undefined || value === null ? Qt.color("#000000") : value;
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    function shade(value, amount) {
        return amount >= 0 ? Qt.lighter(value, 1 + amount) : Qt.darker(value, 1 - amount);
    }

    function validHexColor(value) {
        return /^#[0-9a-fA-F]{6}$/.test("" + value);
    }

    function contrastColor(value) {
        const c = Qt.color(value);
        const luma = 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b;
        return luma > 0.48 ? "#14100f" : "#fff8f6";
    }

    readonly property bool hasTextOverride: validHexColor(MatugenSettings.textColor)
    readonly property bool hasActiveOverride: validHexColor(MatugenSettings.activeColor)
    readonly property bool hasBackgroundOverride: validHexColor(MatugenSettings.backgroundColor)
    readonly property color overrideText: Qt.color(hasTextOverride ? MatugenSettings.textColor : "#ffffff")
    readonly property color overrideActive: Qt.color(hasActiveOverride ? MatugenSettings.activeColor : "#ffffff")
    readonly property color overrideBackground: Qt.color(hasBackgroundOverride ? MatugenSettings.backgroundColor : "#000000")

    readonly property color surface: hasBackgroundOverride
        ? overrideBackground
        : colorOf("surface", "#1a110f")
    readonly property color surfaceLowest: hasBackgroundOverride
        ? shade(surface, isDark ? -0.04 : 0.08)
        : colorOf("surface_container_lowest", "#140c0a")
    readonly property color surfaceLow: hasBackgroundOverride
        ? shade(surface, isDark ? 0.025 : -0.02)
        : colorOf("surface_container_low", "#231917")
    readonly property color surfaceContainer: hasBackgroundOverride
        ? shade(surface, isDark ? 0.05 : -0.04)
        : colorOf("surface_container", "#271d1b")
    readonly property color surfaceHigh: hasBackgroundOverride
        ? shade(surface, isDark ? 0.075 : -0.06)
        : colorOf("surface_container_high", "#322825")

    readonly property color fg: hasTextOverride
        ? overrideText
        : colorOf("on_surface", "#f1dfdb")
    readonly property color dim: hasTextOverride
        ? alpha(overrideText, 0.72)
        : colorOf("on_surface_variant", "#d8c2bd")
    readonly property color outline: colorOf("outline", "#a08c88")
    readonly property color outlineVariant: colorOf("outline_variant", "#534340")

    readonly property color primary: hasActiveOverride
        ? overrideActive
        : colorOf("primary", "#ffb4a4")
    // Avoid names starting with "on" + an uppercase letter. QML parses those
    // as signal handlers, which silently leaves the property at its default
    // value (black for colors).
    readonly property color primaryText: hasActiveOverride
        ? contrastColor(MatugenSettings.activeColor)
        : colorOf("on_primary", "#561f13")
    readonly property color primaryContainer: hasActiveOverride
        ? alpha(primary, isDark ? 0.18 : 0.12)
        : colorOf("primary_container", "#733427")
    readonly property color primaryContainerText: hasActiveOverride
        ? fg
        : colorOf("on_primary_container", "#ffdad3")
    readonly property color secondary: colorOf("secondary", "#e7bdb4")
    readonly property color tertiary: colorOf("tertiary", "#dbc48c")
    readonly property color error: colorOf("error", "#ffb4ab")

    readonly property color panel: alpha(surfaceContainer, 0.97)
    readonly property color card: alpha(surfaceLow, 0.95)
    readonly property color bar: alpha(surfaceContainer, 0.90)
    readonly property color border: alpha(outlineVariant, isDark ? 0.55 : 0.60)
    readonly property color borderStrong: alpha(outline, 0.45)
    readonly property color hover: alpha(fg, isDark ? 0.07 : 0.06)
    readonly property color press: alpha(fg, isDark ? 0.12 : 0.10)
    readonly property color selected: alpha(primary, 0.12)
    readonly property color input: alpha(fg, isDark ? 0.05 : 0.045)
    readonly property color scrim: Qt.rgba(0, 0, 0, 0.50)
    readonly property color overviewScrim: isDark
        ? Qt.rgba(0, 0, 0, 0.55)
        : Qt.rgba(0, 0, 0, 0.70)

    function loadTheme() {
        const raw = themeFile.text();
        if (!raw || raw.length === 0)
            return;

        try {
            const data = JSON.parse(raw);
            if (data.dark && typeof data.dark === "object") {
                const dark = Object.assign({}, fallbackDark, data.dark);
                root.rolesDark = dark;
            }
            if (data.light && typeof data.light === "object") {
                const light = Object.assign({}, fallbackLight, data.light);
                root.rolesLight = light;
            }
            if (data.wallpaper)
                root.wallpaperPath = data.wallpaper;
            if (data.mode === "light" || data.mode === "dark")
                root.surfaceMode = data.mode;
        } catch (e) {
            console.warn("Theme: could not parse theme.json:", e);
        }
    }

    function loadMode() {
        const raw = (modeFile.text() || "").trim();
        if (raw === "light" || raw === "dark")
            root.surfaceMode = raw;
    }

    function loadOutline() {
        root.outlineText = (outlineFile.text() || "").trim() === "1";
    }

    FileView {
        id: themeFile
        path: Settings.paths.themeJson
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onTextChanged: root.loadTheme()
        onLoaded: root.loadTheme()
    }

    FileView {
        id: modeFile
        path: Settings.paths.walCache + "/surface-mode"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onTextChanged: root.loadMode()
        onLoaded: root.loadMode()
    }

    FileView {
        id: outlineFile
        path: Settings.paths.walCache + "/surface-outline"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onTextChanged: root.loadOutline()
        onLoaded: root.loadOutline()
    }
}
