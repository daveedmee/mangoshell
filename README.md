# Mangoshell

A compact, wallpaper-adaptive desktop shell for [MangoWM](https://github.com/mangowm/mango)
built with [Quickshell](https://quickshell.org/). The top bar, control center,
notification daemon, window overview, clipboard browser, and wallpaper/theme
gallery are one QML process; Mango owns the compositor, wallpaper state, and
global keybinds.

![Screenshot of mangoshell, featuring three top bars and a gruvbox-inspired dark theme](/screenshot.png?raw=true)

## Features

- Three-island top bar on every monitor: session, tags, layout, launcher,
  clock, focused window, media, tray, network, Bluetooth, USB, volume,
  notifications, and controls.
- Control center with Wi-Fi/Bluetooth/DND/microphone tiles, audio and
  brightness sliders, media controls, live system stats, drives, and session
  actions.
- Notification daemon with popup queue, Do Not Disturb, history, actions, and
  click-to-open source applications.
- Full-screen window overview with live previews, tag filters, search, and a secondary force-close confirmation.
- Wallpaper gallery with folder search, placement (crop/fit/stretch/tile/
  center), Matugen palettes, source-colour picking, and light/dark/auto mode.
- Pywal + Matugen pipeline that recolours Quickshell, rofi, KDE/Qt, Konsole,
  and GTK from the current wallpaper.
- Cliphist clipboard history with text/image filters, copy, delete, and clear.
- rofi launcher, tray menus, session sheet, OSD, and a small IPC surface.

## Requirements

### Core

| Component | Needed for |
| --- | --- |
| MangoWM 0.18+ | Compositor, tags, layouts, IPC (`mmsg`). |
| Quickshell 0.3.2+ | The shell itself. Tested with Qt 6.12. |
| PipeWire + WirePlumber | Audio devices, volume, microphone state. |
| NetworkManager | Network popover and Wi-Fi/ethernet toggles. |
| BlueZ | Bluetooth popover and bar indicator. |
| systemd + a polkit agent | Suspend/reboot/shutdown and privileged actions. |
| udisks2 | Mounting/unmounting USB storage. |
| D-Bus session bus | Notifications, tray, Mango, and Quickshell IPC. |

### Tools

| Component | Needed for |
| --- | --- |
| `rofi` | Launcher and run dialog. |
| `wal` (pywal) | Base wallpaper palette and Mango border colours. |
| `matugen` | Material You palettes for the shell and applications. |
| `swaybg` | Wallpaper rendering and placement. |
| `jq` | JSON state and IPC parsing in scripts. |
| ImageMagick (`magick`/`convert`/`identify`) | Wallpaper metadata, previews, colour sampling, luminance. |
| `cliphist` + `wl-clipboard` (`wl-copy`, `wl-paste`) | Clipboard history. |
| `grim` + `slurp` | Screenshots and overview previews. |
| `playerctl` | Media keys (play/pause, next, previous). |
| `pactl` (libpulse) | Volume keys and mute toggles. |
| `python3` | Wallpaper indexer and application theme sync. |
| `xdg-utils` (`xdg-open`), `gtk-launch` or `gio` | Opening notification sources, drives, and screenshots. |
| `libnotify` (`notify-send`) | Lock/screenshot fallback messages. |
| `nm-connection-editor` | Network settings button. |

### Optional

- `ddcutil` for external-monitor brightness.
- `kdeconnect-cli` + `busctl` for connected device battery readings.
- `swaylock` for locking; without it the lock action reports an error.
- `iw` for the Wi-Fi band label in system stats.
- `nvidia-smi` for NVIDIA GPU utilisation.
- `xdg-user-dir` for the Pictures directory; otherwise `~/Pictures` is tried.
- A polkit agent such as `polkit-kde-authentication-agent-1`.
- `breeze` icons/cursors (`breeze` for Quickshell, `breeze-dark` for rofi).

### Fonts

The theme expects these families:

- `Futura PT Web Book`
- `Futura PT Demi`
- `Material Symbols Rounded`

Futura PT is commercial. If it is unavailable, change `Theme.fontText` and
`Theme.fontDemi` in `quickshell/Theme.qml` to an installed family. Material
Symbols Rounded is available as a variable font in most distributions.

## Install

Back up an existing configuration first. The commands below merge the four
configuration trees into `~/.config` and preserve executable bits.

```bash
git clone <repository-url> ./mangoshell
cd mangoshell

mkdir -p ~/.config
rsync -a quickshell/ ~/.config/quickshell/
rsync -a mango/ ~/.config/mango/
rsync -a rofi/ ~/.config/rofi/
rsync -a wal/ ~/.config/wal/

chmod +x ~/.config/quickshell/scripts/*.sh \
         ~/.config/mango/scripts/*.sh \
         ~/.config/mango/scripts/*.py
```

Mango reads `~/.config/mango/config.toml` by default. Start it directly:

```bash
mango
```

or select Mango in your display manager. Its `exec_once` block restores the
recorded wallpaper (starting `swaybg`), refreshes the theme, starts the polkit
agent, launches Quickshell (`qs`), and starts the cliphist watchers.

### First run

1. Log in to Mango. Until a wallpaper is selected, the shell uses its built-in
   fallback palette and `swaybg` uses the recorded base colour.
2. Press `SUPER+SHIFT+W` to open the wallpaper gallery.
3. Pick an image, choose a Matugen mode (Auto/Dark/Light), and press **Apply
   wallpaper**. This creates `~/.config/mango/wallpaper.png`, records its path
   under `$XDG_STATE_HOME/mango/wallpaper`, and generates the pywal/Matugen
   caches.
4. Press `SUPER+SHIFT+C` for the control center, `SUPER+SHIFT+Tab` for the
   overview, and `SUPER+V` for the clipboard.

### Reloading

- `SUPER+R` reloads `mango/config.toml`.
- `qs kill && qs` restarts the Quickshell process (or log out and back in).
- `SUPER+SHIFT+Q` quits Mango.

## Default keybinds

| Key | Action |
| --- | --- |
| `SUPER+Return` | Terminal (`konsole`). |
| `SUPER+Space` | rofi application launcher. |
| `SUPER+ALT+Space` | rofi run dialog. |
| `SUPER+D` | File manager (`dolphin`). |
| `SUPER+1..9` | Switch tag. |
| `SUPER+SHIFT+1..9` | Send window to tag without following. |
| `SUPER+W` | Close focused window (`killclient`). |
| `SUPER+F` | Toggle fullscreen. |
| `SUPER+S` | Toggle floating. |
| `SUPER+M` | Cycle layout. |
| `SUPER+O` | Toggle Mango's native overlay. |
| `SUPER+N` | Toggle notification center. |
| `SUPER+SHIFT+N` | Toggle Do Not Disturb. |
| `SUPER+SHIFT+C` | Control center. |
| `SUPER+SHIFT+W` | Wallpaper gallery. |
| `SUPER+V` | Clipboard history. |
| `SUPER+SHIFT+Tab` | Window overview. |
| `Print` | Full-screen screenshot. |
| `SUPER+SHIFT+S` | Region screenshot. |
| `SUPER+Print` | Window screenshot. |

The complete table, including mouse and gesture bindings, is in
[docs/keybinds.md](docs/keybinds.md).

## Documentation

- [Bar modules](docs/bar.md) — every module in the top bar and its actions.
- [Popovers and overlays](docs/popovers.md) — every panel, sheet, menu, popup,
  and OSD.
- [Theming](docs/theming.md) — pywal/Matugen pipeline, auto light/dark,
  overrides, and application sync.
- [Configuration](docs/configuration.md) — `Settings.qml`, layout tokens,
  paths, Mango options, fonts, and portability notes.
- [Scripts and IPC](docs/scripts-and-ipc.md) — script ownership, commands, and
  `qs ipc` examples.
- [Keybinds](docs/keybinds.md) — keyboard, mouse, and gesture bindings.

## Repository layout

```text
quickshell/     Quickshell shell, services, modules, popups, and UI scripts
mango/          MangoWM config and Mango-owned wallpaper/theme/keybind scripts
rofi/           rofi config, theme, and generated palette fallback
wal/            pywal template for Mango border colours
docs/           Configuration manual
```

## State and generated files

These runtime files are intentionally **not** shipped and are recreated on
first use:

| Path | Purpose |
| --- | --- |
| `quickshell/matugen.json` | Matugen settings chosen in the gallery. |
| `quickshell/wallpaper.json` | Placement mode and base colour. |
| `quickshell/calendar.json` | Local calendar notes and appointments. |
| `quickshell/dnd` | Do Not Disturb flag. |
| `mango/wallpaper.png` | Normalised copy of the selected wallpaper. |
| `$XDG_STATE_HOME/mango/wallpaper` | Absolute path of Mango's wallpaper. |
| `$XDG_CACHE_HOME/wal/*` | pywal palette and surface mode/outline flags. |
| `$XDG_CACHE_HOME/quickshell/theme.json` | Dark/light Matugen palettes for the shell. |

`rofi/colors.rasi` is shipped only as a neutral fallback; `theme-refresh.sh`
replaces it with the active wallpaper palette.

## Verification notes

The configuration was exercised on Arch Linux with MangoWM 0.18.3,
Quickshell 0.3.2, Qt 6.12, PipeWire, NetworkManager, and BlueZ. Wi-Fi toggling
could not be tested because the test machine has no Wi-Fi adapter. Bluetooth
reconnection of known devices was tested; pairing a new device was not. VPN
entries are managed by IVPN and depend on its CLI/daemon. A full reboot-based
wallpaper restore was not performed.

## Credits

MangoWM and Quickshell provide the compositor and shell runtime. pywal and
Matugen provide the palette pipeline. The configuration is a curated personal
setup published as a starting point; adapt paths, fonts, terminal, file
manager, and keybinds to your system.
