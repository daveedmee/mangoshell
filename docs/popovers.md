# Popovers and overlays

Quickshell uses one overlay at a time. `OverlayHost.qml` creates a full-screen
layer surface, dims it for modal surfaces, closes on `Escape` or a click outside,
and loads the matching component. The bar is hidden for the session sheet,
gallery, clipboard, and overview. The OSD is a separate bottom layer surface.

Overlay names: `controls`, `notifications`, `media`, `calendar`, `volume`,
`network`, `bluetooth`, `devices`, `tray`, `session`, `gallery`, `clipboard`,
`overview`. The layout picker is a separate `PopupWindow` anchored to the bar.

## Controls panel

**Open:** controls button in the bar, `SUPER+SHIFT+C`, or
`qs ipc call mangoflow controls`.

A full-height right sidebar with:

- **Quick tiles** — Wi-Fi (toggle, or open the network popover when no Wi-Fi
  device exists), Bluetooth (open popover), Do Not Disturb, microphone mute,
  KDE Connect (launches `kdeconnect-app`), and wallpaper (opens the gallery).
- **Sliders** — output volume, microphone volume, and external-monitor
  brightness. Brightness uses `ddcutil` and is disabled when unavailable.
- **Media card** — album art, player/title/artist, seek bar, previous/play/
  next. Clicking the card opens the media popover.
- **System** — CPU, RAM, swap, GPU (if available), RX/TX rates, and network
  label. The two-second sampler only runs while the panel is open.
- **Drives** — every block-device filesystem, with usage bars for mounted
  drives.
- **Session** — Lock, Logout, Suspend, Reboot, and Shut down. Lock/logout/
  suspend execute immediately; reboot and shutdown open the session sheet for
  confirmation.

The panel scrolls when its content exceeds the screen height.

## Notifications panel

**Open:** bell button, `SUPER+N`, or `qs ipc call notifications toggle`.

A full-height right sidebar with a Do Not Disturb toggle, notification history,
relative timestamps, per-notification close buttons, and **Clear all**. The
empty state changes between “All caught up” and “Do Not Disturb is on”.
Clicking a notification invokes its default action/source; action buttons invoke
their specific action. Closing a notification dismisses it from the server.

## Notification popups

**Open:** automatically for new notifications, unless DND is on or another
overlay is open.

`NotificationPopup.qml` is a top-right layer surface. It shows at most
`Settings.notifications.maxPopups` (3) cards; the rest wait in a queue of up to
`popupQueueLimit` (12). Normal notifications time out after 10 s, low urgency
after 5 s, and critical notifications stay until dismissed, unless the sender
supplies its own expire timeout. Hovering pauses the timeout. Clicking a card activates it; if no source can be opened, the
notification center opens. Closing a transient notification removes it
entirely.

## Media popover

**Open:** media chip in the bar, or `qs ipc call mangoflow media`.

Shows the active MPRIS player identity, album art, track, artist, album, and
length. The seek slider is enabled when the player supports seeking. Controls:
shuffle (when supported), previous, play/pause, next. The output chip opens the
volume popover; the player chip identifies the current player. With no player,
the controls are disabled and the popover explains how to start one.

## Calendar popover

**Open:** clock in the bar, or `qs ipc call mangoflow calendar`.

A month grid with previous/next month, **Today**, selected-day details, and a
local entry list. Click a day to select it. Entries can have a title and an
optional `HH:MM` time; **Add note or appointment** stores them in
`~/.config/quickshell/calendar.json`. Each entry has a delete button. The
popover width follows the centre bar island so it opens directly under the
clock. `Escape` or clicking outside closes it.

## Volume popover

**Open:** volume module, media popover output chip, or
`qs ipc call mangoflow volume`.

Sections:

- **Output** — volume slider, mute state, and a device selector for every
  PipeWire sink.
- **Microphone** — volume slider, mute state, and a source selector.
- **Applications** — every active playback/recording stream with app icon,
  name, volume slider, percentage, and mute button.

All changes are applied immediately through `Audio.qml`; the OSD follows the
same actions when they originate from the bar or media keys.

## Network popover

**Open:** network icon, or `qs ipc call mangoflow network`.

- **Current connection** — Wi-Fi SSID or Ethernet, interface name, and address.
- **Network devices** — Wi-Fi and wired interfaces with toggles. Wi-Fi uses
  NetworkManager's radio state; wired devices connect/disconnect with `nmcli`.
- **VPN** — when the `ivpn` CLI is available, a single IVPN row is preferred
  and uses `ivpn connect -last` / `ivpn disconnect`. Otherwise NetworkManager
  VPN/WireGuard/tun/tap connections are listed and toggled with `nmcli`.
- **Wi-Fi networks** — available networks with signal/security state; clicking
  one connects.
- **Network settings** — launches `nm-connection-editor`.

Errors from `nmcli`/`ivpn` are shown inline. If the IVPN daemon is stopped, the
popover cannot start it; use the IVPN application or `ivpn connect -last`.

## Bluetooth popover

**Open:** Bluetooth icon, or `qs ipc call mangoflow bluetooth`.

- Adapter power toggle and scan control. Scanning stops when the popover closes.
- **Connected** devices with name, address, battery (BlueZ, or KDE Connect when
  available), charging state, and a Disconnect button.
- **Paired** devices with Connect/Disconnect actions.
- **Add a device** — scan results for pairing. Pairing is provided by BlueZ;
  the popover does not bypass the adapter's normal pairing flow.
- Device icons are derived from the BlueZ icon name, with fallbacks for phones,
  audio, input, and generic devices.

## Devices popover

**Open:** USB icon in the bar, or `qs ipc call mangoflow devices`.

Lists attached USB storage devices larger than 64 MB (tiny boot partitions such
as Ventoy's `VTOYEFI` are hidden). Each row shows label/device, filesystem,
size, mount state, mountpoint, used/free space, and a usage bar. Actions:

- **Open** — `xdg-open` the mountpoint and close the popover.
- **Unmount** / **Mount** — `udisksctl unmount|mount -b <device>`.
- Refresh button re-reads `lsblk`/`findmnt`; the list also refreshes every 10 s.

Errors are shown at the bottom of the popover.

## Tray menu

**Open:** right-click a tray icon, or left-click a menu-only item.

`TrayMenu.qml` renders the StatusNotifierItem menu with separators, checkmarks,
disabled items, and one level of expandable submenus. Selecting a leaf item
triggers it and closes the overlay. The menu is positioned leftwards from the
tray icon and clamped to the output edge. An empty menu shows “No menu items”.

## Session sheet

**Open:** power button, or `qs ipc call mangoflow session`.

A centred modal with Lock, Logout, Suspend, Reboot, and Shut down.

- **Lock** runs `quickshell/scripts/lock.sh` (`swaylock`, with the wallpaper as
  background when available).
- **Logout** dispatches Mango's `quit`.
- **Suspend** runs `systemctl suspend`.
- **Reboot** and **Shut down** require a second click on the highlighted action
  within 3 seconds; the button changes to **Confirm**.
- **Cancel** or `Escape` closes the sheet.

## Wallpaper gallery

**Open:** wallpaper tile in the controls panel, `SUPER+SHIFT+W`, or
`qs ipc call mangoflow gallery`.

A large modal with two browser tabs:

- **Library** — indexed wallpapers under the configured folder (`~/Bilder`;
  if it is missing, `$XDG_PICTURES_DIR`, then `~/Pictures`), with search,
  folder chips, lazy thumbnails, resolution/size metadata, and double-click
  apply.
- **Files** — browse the filesystem, go to home/parent, and open images.

The right side controls the theme and placement:

- **Matugen** — scheme (Tonal, Content, Expressive, Fidelity, Fruit, Neutral,
  Mono, Rainbow, Vibrant, Smart), mode (Auto/Dark/Light), contrast, brightness,
  and source colour (Auto, a sampled palette colour, custom hex, or the
  eyedropper). **Reset** restores defaults.
- **Tune** — optional text, active, and background colour overrides for the
  shell and synced applications. **Auto** clears each override.
- **Placement** — Crop, Fit, Stretch, Tile, or Center, plus a base colour for
  exposed areas. Placement is independent of the Matugen palette.

**Apply wallpaper** runs `mango/scripts/set-wallpaper.sh`: it normalises a copy
to `~/.config/mango/wallpaper.png`, records the path in Mango's state directory,
runs pywal, regenerates Matugen/rofi/application colours, reloads Mango, and
restarts `swaybg`. **Random** picks from the current filtered list; **Cancel**
closes without applying. Matugen setting changes regenerate the theme without
changing the wallpaper.

Auto mode uses Matugen's `smart` mode on the whole image, so a light wallpaper
gets a light palette. When an explicit source colour is configured, smart mode
cannot inspect the image; the script falls back to whole-image luminance. The
top 3% strip is only used to decide whether the bar needs a text halo.

## Clipboard sheet

**Open:** `SUPER+V`, or `qs ipc call mangoflow clipboard`.

A modal browser over the last 80 cliphist entries. It shows text or image
previews, byte size, MIME type, and per-type counts. Controls:

- Search field; `/` focuses it.
- **All / Text / Images** filters.
- Click a row (or press Enter on the first match) to copy it and close.
- Delete button removes one entry from cliphist.
- **Clear all…** requires a second click on **Confirm clear**.
- `Escape` closes.

Images are decoded once into `$XDG_CACHE_HOME/quickshell/clipboard` for
previews; missing `cliphist`/`jq` yields an empty list.

## Overview

**Open:** `SUPER+SHIFT+Tab`, right-click a tag, left-click the window chip, or
`qs ipc call overview capture`.

A full-screen overview with the current wallpaper as background, a search field
(“Search windows”), tag filter buttons (All plus 1–9), and cards showing a live
preview, app icon, title, app ID, and tags. Previews are captured per toplevel
with `grim -T`; if capture fails, cards fall back to the app icon.

- Click a card to focus that client. The overlay closes first, then Mango
  focuses the client after a short delay.
- The close button on each card normally calls `Mango.closeClient(id)` — the
  same result as `SUPER+W`.
- Right-click the close button to start force-close confirmation; the button
  expands to **Force close**. A second left click sends `SIGKILL` to the
  client's PID, falling back to Mango's normal close when no PID is available.
- Clicking the expanded button also confirms force-close.
- `Escape` closes the overview without focusing anything.

## Layout picker

**Open:** layout button in the left island.

A `PopupWindow` anchored below the left bar island, showing the current layout
and every layout Mango reports (falling back to a built-in list). Clicking a
layout dispatches `setlayout` and closes the picker. `Escape` closes it.

## OSD

**Open:** volume/microphone/brightness changes from the bar or IPC.

A small bottom-centre layer surface with an icon, label, value, and progress
bar. It hides after `Settings.osd.timeout` (1.6 s), restarts its timer when the
value changes, and is suppressed while any overlay is open. IPC can drive it
directly with `qs ipc call osd …`; see
[scripts-and-ipc.md](scripts-and-ipc.md).
