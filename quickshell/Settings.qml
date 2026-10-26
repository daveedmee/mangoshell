pragma Singleton

import QtQml
import Quickshell

Singleton {
    readonly property QtObject bar: QtObject {
        property int height: 44
        property int islandHeight: 44
        property int islandTop: 0
        property int sideMargin: 0
        property int islandPadding: 4
        property int tagCount: 9
        property int tagWidth: 28
        property int tagHeight: 30
        property int iconButton: 32
        property int mediaMaxChars: 18
        property int titleMaxChars: 34
        property int trayIconSize: 18
        property int traySpacing: 8
        property bool hover: true
        property int hoverRadius: 3
    }

    readonly property QtObject overlay: QtObject {
        // Popout surfaces already begin below the bar's exclusive zone; this is
        // the additional visible gap between the bar and a popout.
        property int topGap: 8
        property int sideMargin: 0
        property int sidebarWidth: 420
        property int sidebarBottom: 0
        property int popoverWidth: 380
        property int bluetoothWidth: 400
        property int devicesWidth: 440
        property int mediaWidth: 392
        property int calendarWidth: 338
        property int trayMenuWidth: 264
        property int sessionWidth: 610
        property int galleryWidth: 1280
        property int galleryHeight: 790
        property int clipboardWidth: 650
        property int clipboardHeight: 720
        property int layoutPanelWidth: 548
        property int layoutPanelHeight: 238
    }

    readonly property QtObject notifications: QtObject {
        property int popupWidth: 390
        property int popupPadding: 0
        property int popupGap: 12
        property int popupMarginRight: 14
        property int maxPopups: 3
        property int popupQueueLimit: 12
        property int historyLimit: 100

        property int timeoutNormal: 10000
        property int timeoutLow: 5000
        property int timeoutCritical: 0
    }

    readonly property QtObject osd: QtObject {
        property int width: 318
        property int height: 62
        property int bottom: 48
        property int timeout: 1600
    }

    readonly property QtObject volume: QtObject {
        property int deviceListMaxHeight: 168
        property int scrollStep: 5
    }

    readonly property QtObject overview: QtObject {
        property int paddingTop: 56
        property int paddingSide: 72
        property int paddingBottom: 34
        property int cardGap: 17
    }

    readonly property QtObject paths: QtObject {
        property string home: Quickshell.env("HOME") || ""
        property string configHome: Quickshell.env("XDG_CONFIG_HOME") || (home + "/.config")
        property string cacheHome: Quickshell.env("XDG_CACHE_HOME") || (home + "/.cache")
        property string shellScripts: configHome + "/quickshell/scripts"
        property string mangoScripts: configHome + "/mango/scripts"
        property string walCache: cacheHome + "/wal"
        property string themeCache: cacheHome + "/quickshell"
        property string themeJson: themeCache + "/theme.json"
        property string wallpapers: home + "/Bilder"
        property string wallpaper: configHome + "/mango/wallpaper.png"
    }
}
