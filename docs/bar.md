# Bar modules

`quickshell/Bar.qml` creates one top-layer `PanelWindow` per monitor. The bar
is 44 px tall, reserves that height as an exclusive zone, and hides while a
modal overlay (session, gallery, clipboard, overview) is open. It has three
independent islands: left (session/tags/layout), centre (launcher/clock/window),
and right (media/tray/system/notifications/controls).

Shared sizes and spacing come from `Settings.bar` in
`quickshell/Settings.qml`; individual modules also set their own fixed widths
and heights. Hover feedback is controlled by `Settings.bar.hover` and
`Settings.bar.hoverRadius`.

## Module reference

| Module | Visible when | Left click | Right click | Wheel |
| --- | --- | --- | --- | --- |
| **Power** (`Power.qml`) | Always | Open the session sheet. | — | — |
| **Tags** (`Tags.qml`) | Always | Switch to tag 1–9. | Capture the window overview. | Previous/next tag. |
| **Layout** (`Layout.qml`) | Mango reports a layout for the monitor. | Open the layout picker below the left island. | — | — |
| **Launcher** (`Launcher.qml`) | Always | Open `rofi -show drun`. | — | — |
| **Clock** (`Clock.qml`) | Always | Open the calendar popover. | — | — |
| **WindowChip** (`WindowChip.qml`) | Always | Capture the window overview. | Toggle Mango's native overview. | — |
| **MediaChip** (`MediaChip.qml`) | A player has a title. | Open the media popover. | Toggle play/pause. | Previous/next track. |
| **Tray** (`Tray.qml`) | At least one SNI item exists. | Activate the item, or open its menu when it is menu-only. | Open its menu. | Scroll the item. |
| **BluetoothStatus** (`BluetoothStatus.qml`) | A Bluetooth adapter exists. | Open the Bluetooth popover. | Enable/disable the adapter. | — |
| **Network** (`Network.qml`) | Always | Open the network popover. | — | — |
| **DevicesStatus** (`DevicesStatus.qml`) | USB storage is attached, or the devices popover is open. | Refresh and open the devices popover. | Refresh. | — |
| **Volume** (`Volume.qml`) | Always | Open the audio popover. | Mute output, or mute the microphone when the pointer is over the mic cluster. | Adjust output or microphone by 5%. |
| **Notifications** (`Notifications.qml`) | Always | Toggle the notification center. | Toggle Do Not Disturb. | — |
| **ControlsButton** (`ControlsButton.qml`) | Always | Toggle the control center. | — | — |

## Left island

### Power

A single power glyph. It opens the modal session sheet, which offers Lock,
Logout, Suspend, Reboot, and Shut down; reboot and shutdown require a second
confirmation click there. The button is highlighted while the session sheet is
open.

### Tags

Nine tag buttons, configured by `Settings.bar.tagCount`. Each button reflects
Mango's state for the monitor that owns the bar:

- **Active** — filled with the primary colour.
- **Occupied** — normal foreground at reduced opacity, with a small primary
  dot when clients exist.
- **Urgent** — error-coloured border/text and an error dot.
- **Empty** — dim foreground.

Right-clicking any tag captures the Quickshell overview instead of entering
Mango's native overview. This is the same path as `SUPER+SHIFT+Tab`.

### Layout

Shows the current Mango layout for the monitor using a layout-specific glyph
and rotation. Clicking opens `LayoutPanel` anchored below the left island (not
the generic overlay host). The picker lists every layout reported by Mango and
closes after a selection. A 300 ms guard prevents accidental double toggles.

## Centre island

### Launcher

A grid/overview glyph that launches rofi's `drun` mode. The rofi terminal is
configured in `rofi/config.rasi` (`rofi-sensible-terminal`).

### Clock

Two lines: `HH:mm` and a short localized date (`ddd · dd MMM`). Clicking opens
the calendar popover, whose width follows the centre island width.

### WindowChip

Shows the focused window's application icon, title, and app ID. When no client
is focused it shows `Desktop` / `MangoWM`. Left-click captures the Quickshell
overview; right-click toggles Mango's native overview. The app icon is resolved
through `DesktopEntries.heuristicLookup` with a desktop glyph fallback.

## Right island

### MediaChip

Visible only when an MPRIS player exists and has a track title. The chip shows
album art (or a music glyph), the track title, and compact previous/play/next
buttons. Clicking the text area opens the media popover; right-clicking the
text area toggles playback; the wheel skips tracks. The control buttons stop
at the edge of the chip so they do not open the popover.

### Tray

Renders StatusNotifierItem icons, recoloured to the current foreground. Left
click activates the item (or opens its menu if the item is menu-only); right
click opens the menu; middle click triggers `secondaryActivate`; the wheel
sends scroll events. Menus use `TrayMenu` and are positioned leftwards from the
icon, clamped to the output edge.

### BluetoothStatus

Hidden when no adapter is present. The icon distinguishes off, on, and
connected states; a badge shows the connected-device count (capped at `9+`).
Left click opens the Bluetooth popover, right click toggles the adapter. A
one-second timer keeps the badge in sync because BlueZ device-list bindings do
not always invalidate on `connected` changes.

### Network

Chooses an icon from the active device: Wi-Fi, ethernet, Wi-Fi-off (adapter
present but disconnected), or unknown/offline. Clicking opens the network
popover. The popover, not the bar icon, performs toggles and connections.

### DevicesStatus

Appears when `Storage.usbCount > 0` or while the devices popover is open. It
shows a USB glyph; left click refreshes the drive list and toggles the popover,
right click refreshes in place.

### Volume

A compact output cluster: speaker glyph, percentage, and — only while a
microphone is in use — a microphone glyph and percentage. The whole element is
one hit target:

- Left click opens the volume popover.
- Right click mutes the output, or all microphones when the pointer is over the
  mic cluster.
- Wheel changes output or microphone volume in `Settings.volume.scrollStep`
  (5%) steps.

Volume changes also drive the OSD through `ShellState.showOsd`.

### Notifications

A bell, or a bell-slash while Do Not Disturb is enabled. The badge shows the
number of stored notifications (capped at `9+`) and is hidden in DND. Left click
toggles the notification center; right click toggles DND.

### ControlsButton

The tune glyph with an outlined style. It toggles the control center and stays
highlighted while it is open.

## Reusable bar primitives

`components/BarText.qml` and `components/BarIcon.qml` are small text/icon
primitives for custom bar modules. They use `Theme.textSize` /
`Theme.iconSize` and apply the wallpaper-aware text halo when
`Theme.outlineText` is true. The stock modules use `Label` and `Icon` directly;
the primitives are kept for local extensions.
