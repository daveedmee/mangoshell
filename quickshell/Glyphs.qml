pragma Singleton

import Quickshell

Singleton {
    // Material Symbols Rounded ligature names. The Icon component renders these
    // with the variable font's FILL axis for active states.
    readonly property string power: "power_settings_new"
    readonly property string session: "power_settings_new"
    readonly property string wifi: "wifi"
    readonly property string wifiOff: "wifi_off"
    readonly property string wifiFind: "wifi_find"
    readonly property string ethernet: "lan"
    readonly property string networkUnknown: "wifi_find"
    readonly property string vpn: "vpn_lock"
    readonly property string volumeHigh: "volume_up"
    readonly property string volumeMedium: "volume_down"
    readonly property string volumeLow: "volume_mute"
    readonly property string volumeMuted: "volume_off"
    readonly property string microphone: "mic"
    readonly property string microphoneMuted: "mic_off"
    readonly property string bell: "notifications"
    readonly property string bellSlash: "notifications_off"
    readonly property string dnd: "do_not_disturb_on"
    readonly property string tune: "tune"
    readonly property string chevronDown: "keyboard_arrow_down"
    readonly property string chevronUp: "keyboard_arrow_up"
    readonly property string chevronLeft: "chevron_left"
    readonly property string chevronRight: "chevron_right"
    readonly property string check: "check"
    readonly property string close: "close"
    readonly property string trash: "delete"
    readonly property string logout: "logout"
    readonly property string lock: "lock"
    readonly property string suspend: "bedtime"
    readonly property string restart: "restart_alt"
    readonly property string play: "play_arrow"
    readonly property string pause: "pause"
    readonly property string stop: "stop"
    readonly property string previous: "skip_previous"
    readonly property string next: "skip_next"
    readonly property string shuffle: "shuffle"
    readonly property string music: "music_note"
    readonly property string album: "album"
    readonly property string speaker: "speaker"
    readonly property string devices: "devices"
    readonly property string queue: "queue_music"
    readonly property string search: "search"
    readonly property string calendar: "calendar_month"
    readonly property string darkMode: "dark_mode"
    readonly property string lightMode: "light_mode"
    readonly property string desktop: "desktop_windows"
    readonly property string overview: "grid_view"
    readonly property string wallpaper: "wallpaper"
    readonly property string palette: "palette"
    readonly property string eyedropper: "colorize"
    readonly property string clipboard: "content_paste"
    readonly property string screenshot: "screenshot_monitor"
    readonly property string download: "download"
    readonly property string smartphone: "smartphone"
    readonly property string headphones: "headphones"
    readonly property string gamepad: "sports_esports"
    readonly property string mouse: "mouse"
    readonly property string tablet: "tablet"
    readonly property string computer: "computer"
    readonly property string printer: "print"
    readonly property string camera: "photo_camera"
    readonly property string tv: "tv"
    readonly property string router: "router"
    readonly property string scanner: "scanner"
    readonly property string update: "system_update"
    readonly property string cloud: "cloud"
    readonly property string bluetooth: "bluetooth"
    readonly property string bluetoothConnected: "bluetooth_connected"
    readonly property string bluetoothSearching: "bluetooth_searching"
    readonly property string bluetoothOff: "bluetooth_disabled"
    readonly property string battery: "battery_full"
    readonly property string security: "security"
    readonly property string chat: "chat_bubble"
    readonly property string arrowDown: "arrow_downward"
    readonly property string arrowUp: "arrow_upward"
    readonly property string brightness: "brightness_6"
    readonly property string coffee: "coffee"
    readonly property string expand: "expand_more"
    readonly property string layout: "view_carousel"
    readonly property string add: "add"
    readonly property string settings: "settings"
    readonly property string info: "info"
    readonly property string warning: "warning"
    readonly property string error: "error"
    readonly property string refresh: "refresh"
    readonly property string star: "star"
    readonly property string link: "link"
    readonly property string code: "code"
    readonly property string notes: "sticky_note_2"
    readonly property string terminal: "terminal"
    readonly property string image: "image"
    readonly property string folder: "folder"
    readonly property string home: "home"
    readonly property string memory: "memory"
    readonly property string storage: "hard_drive"
    readonly property string usb: "usb"
    readonly property string eject: "eject"
    readonly property string thermostat: "device_thermostat"
    readonly property string speed: "speed"
    readonly property string checkCircle: "check_circle"
    readonly property string circle: "radio_button_unchecked"
    readonly property string keyboard: "keyboard"

    // Window-layout pictograms. These deliberately differ from one another so
    // the layout popout can be understood without learning Mango's two-letter
    // layout codes. Some source glyphs need rotating to match the arrangement.
    readonly property var layoutSpecs: ({
        tile: { icon: "grid_view", rotation: 0 },
        scroller: { icon: "transition_push", rotation: 0 },
        grid: { icon: "dataset", rotation: 0 },
        monocle: { icon: "pageless", rotation: 0 },
        deck: { icon: "devices_fold", rotation: 0 },
        center_tile: { icon: "view_array", rotation: 0 },
        right_tile: { icon: "space_dashboard_2", rotation: 0 },
        vertical_scroller: { icon: "amp_stories", rotation: 90 },
        vertical_tile: { icon: "view_stream", rotation: 0 },
        vertical_grid: { icon: "calendar_view_month", rotation: 90 },
        vertical_deck: { icon: "view_sidebar", rotation: -90 },
        dwindle: { icon: "account_tree", rotation: 0 },
        fair: { icon: "window", rotation: 0 },
        vertical_fair: { icon: "splitscreen", rotation: 0 }
    })

    function layoutSpec(name) {
        return layoutSpecs[("" + (name || "")).toLowerCase()] || layoutSpecs.tile;
    }

    function layoutIcon(name) {
        return layoutSpec(name).icon;
    }

    function layoutRotation(name) {
        return layoutSpec(name).rotation;
    }
}
