# Scripts and IPC

Scripts are split by ownership:

- `quickshell/scripts/` — helpers used by the shell UI and its services.
- `mango/scripts/` — wallpaper/theme/session helpers used by Mango keybinds,
  autostart, and the shell when it needs Mango-owned state.

`Settings.paths.shellScripts` and `Settings.paths.mangoScripts` expose the two
directories. QML never hardcodes an absolute config path, so
`XDG_CONFIG_HOME` overrides work.

## Quickshell scripts

| Script | Commands | Purpose |
| --- | --- | --- |
| `brightness.sh` | `get`, `up`, `down`, `set <0-100>` | DDC/CI brightness for the external display; no-op without `ddcutil`. Drives the OSD. |
| `calendar-events.sh` | `list`, `add <YYYY-MM-DD> <HH:MM|""> <title>`, `remove <id>` | Atomic JSON storage for `calendar.json`. |
| `clipboard-clear.sh` | — | `cliphist wipe`. |
| `clipboard-copy.sh` | `<id>` | Decode one entry into `wl-copy`. |
| `clipboard-delete.sh` | `<id>` | Delete one cliphist entry. |
| `clipboard-list.sh` | `[limit]` | JSON index of the last 80 entries; decodes images into `$XDG_CACHE_HOME/quickshell/clipboard`. |
| `kdeconnect-battery.sh` | — | JSON battery/charging array from KDE Connect over D-Bus. |
| `lock.sh` | — | `swaylock` with the current wallpaper; black fallback; error notification without swaylock. |
| `matugen-settings.sh` | `get`, `apply …`, `reset` | Read/validate/persist Matugen settings and regenerate the theme. |
| `notification-open.sh` | `<desktop-entry> <app-name> <body>` | Focus an existing Mango client, or launch the notification's desktop entry/file. |
| `overview-capture.sh` | — | Mango client list as JSON for the overview; does not enter the native overview. |
| `overview-previews.sh` | — | One `grim -T <toplevel>` preview per client in the overview cache. |
| `storage-list.sh` | — | JSON block-device list with mount/usage/transport/removable metadata. |
| `system-stats.sh` | — | Two-second JSON stream: CPU, RAM, swap, GPU, temperature, RX/TX, network label. |
| `wallpaper-display.sh` | `get`, `apply --mode … --color #RRGGBB` | Persist placement and restart `swaybg` without touching the palette. |
| `wallpaper-info.sh` | `<image>` | JSON metadata, Matugen preview palette, and source colours. |
| `wallpaper-sample-color.sh` | `<image> <x 0..1> <y 0..1>` | Read one pixel as `#rrggbb` for the eyedropper. |
| `wallpapers-list.sh` | `[root]` | Recursive image index (four levels, hidden folders skipped) as JSON. |

### Examples

```bash
# Current external-monitor brightness
bash ~/.config/quickshell/scripts/brightness.sh get

# Add a calendar entry
bash ~/.config/quickshell/scripts/calendar-events.sh add 2026-10-26 09:30 "Standup"

# Inspect a wallpaper and sample its centre pixel
bash ~/.config/quickshell/scripts/wallpaper-info.sh ~/Bilder/wall.png
bash ~/.config/quickshell/scripts/wallpaper-sample-color.sh ~/Bilder/wall.png 0.5 0.5

# Change placement without changing colours
bash ~/.config/quickshell/scripts/wallpaper-display.sh apply --mode fit --color '#1e2021'
```

## Mango scripts

| Script | Commands | Purpose |
| --- | --- | --- |
| `restore-wallpaper.sh` | — | Start `swaybg` on Mango's recorded wallpaper and placement; base colour fallback. |
| `screenshot.sh` | `region`, `fullscreen`, `window` | grim/slurp screenshots, copied to the clipboard and announced; delegates to Spectacle under Plasma. |
| `scroller-resize.sh` | `up`, `down` | Grow/shrink the focused scroller column by 5%, clamped to 20–100%. |
| `set-wallpaper.sh` | `<image>` | Normalise the image, record the path, run pywal + theme refresh, reload Mango, restart swaybg. |
| `theme-refresh.sh` | `[image]` | Generate light/dark Matugen palettes, rofi colours, surface mode/outline flags, and application themes. |
| `theme-sync-apps.py` | — | Write KDE colour schemes, kdeglobals, Konsole scheme, and GTK colours. |
| `volume.sh` | `up`, `down` | Change the default sink by 5%, clamp 0–100, unmute, drive the OSD. |
| `wallpaper-path.sh` | — | Print the readable Mango wallpaper path from state or the canonical copy. |

### Why theme scripts live in Mango

Mango owns session startup and wallpaper restore. Its `exec_once` runs
`restore-wallpaper.sh` and `theme-refresh.sh`; the Quickshell gallery calls
`set-wallpaper.sh` and `matugen-settings.sh`, which call back into
`mango/scripts/theme-refresh.sh`. Keeping the pipeline in one tree avoids two
competing wallpaper/theme owners.

## Quickshell IPC

List targets and functions:

```bash
qs ipc show
```

### `mangoflow` — overlays

```bash
qs ipc call mangoflow toggle controls
qs ipc call mangoflow open gallery
qs ipc call mangoflow close
qs ipc call mangoflow controls
qs ipc call mangoflow notifications
qs ipc call mangoflow media
qs ipc call mangoflow calendar
qs ipc call mangoflow volume
qs ipc call mangoflow network
qs ipc call mangoflow bluetooth
qs ipc call mangoflow devices
qs ipc call mangoflow session
qs ipc call mangoflow overview
qs ipc call mangoflow gallery
qs ipc call mangoflow clipboard
```

`toggle <name>` toggles any overlay name; `open <name>` forces it open;
`close` closes the current overlay. The named helpers are shorthands for
`toggle`. `mangoflow overview` only toggles the overlay; use
`qs ipc call overview capture` when you want a freshly captured client list.

### `notifications`

```bash
qs ipc call notifications toggle
qs ipc call notifications dnd
qs ipc call notifications clear
qs ipc call notifications count
qs ipc call notifications dndState
```

`dnd` toggles Do Not Disturb and persists it in
`~/.config/quickshell/dnd`. `count` and `dndState` are useful in scripts/polybar
replacements.

### `overview`

```bash
qs ipc call overview capture
qs ipc call overview focus 12345
qs ipc call overview forceClose 12345
qs ipc call overview close
```

`capture` collects clients and opens the overview. `focus` closes the overlay
and focuses the client after a short delay. `forceClose` sends `SIGKILL` when a
PID is known and falls back to `killclient`.

### `osd`

```bash
qs ipc call osd volume 42
qs ipc call osd mic 65
qs ipc call osd brightness 80
qs ipc call osd mute volume true
qs ipc call osd show custom "Custom label" 50 "50%"
```

The OSD hides itself after `Settings.osd.timeout`. It is suppressed while an
overlay is open.

## Mango IPC examples

```bash
mmsg get all-clients
mmsg get all-monitors
mmsg get focusing-client
mmsg dispatch view,2,0
mmsg dispatch focusid client,12345
mmsg dispatch setlayout,scroller
mmsg dispatch reload_config
```

`services/Mango.qml` watches the Mango socket and keeps tags, layouts, focused
client, and client list in sync. It falls back to the newest
`$XDG_RUNTIME_DIR/mango-*.sock` when `MANGO_INSTANCE_SIGNATURE` is unset.
