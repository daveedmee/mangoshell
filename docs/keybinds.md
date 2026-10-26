# Keybinds

Bindings live in `mango/config.toml` under `[bind.default]`,
`[mousebind.default]`, `[axisbind.default]`, and `[gesturebind.default]`.
`spawn_shell` runs a shell command; `spawn` launches a program directly.

## Applications

| Key | Action |
| --- | --- |
| `SUPER+Return` | `konsole` |
| `SUPER+Space` | `rofi -show drun` |
| `SUPER+ALT+Space` | `rofi -show run` |
| `SUPER+D` | `dolphin` |

## Shell overlays

| Key | Action |
| --- | --- |
| `SUPER+N` | Toggle notification center. |
| `SUPER+SHIFT+N` | Toggle Do Not Disturb. |
| `SUPER+SHIFT+C` | Toggle control center. |
| `SUPER+SHIFT+W` | Toggle wallpaper gallery. |
| `SUPER+V` | Toggle clipboard history. |
| `SUPER+SHIFT+Tab` | Capture and open the window overview. |
| `Escape` | Close the current overlay/popup. |

The overview's per-window close button mirrors `SUPER+W` (`killclient`).
Right-clicking it starts the force-close confirmation.

## Compositor

| Key | Action |
| --- | --- |
| `SUPER+R` | Reload `mango/config.toml`. |
| `SUPER+SHIFT+Q` | Quit Mango. |
| `SUPER+W` | Close focused window (`killclient`). |
| `SUPER+F` | Toggle fullscreen. |
| `SUPER+SHIFT+F` | Toggle fake fullscreen. |
| `SUPER+M` | Switch layout. |
| `SUPER+S` | Toggle floating. |
| `SUPER+G` | Toggle global. |
| `SUPER+I` | Minimize. |
| `SUPER+SHIFT+I` | Restore minimized. |
| `SUPER+O` | Toggle Mango's native overlay. |
| `ALT+Z` | Toggle scratchpad. |

## Focus and movement

| Key | Action |
| --- | --- |
| `SUPER+Left/Down/Up/Right` | Focus in direction. |
| `SUPER+Tab` | Toggle jump. |
| `SUPER+SHIFT+Left/Down/Up/Right` | Swap window with neighbour. |
| `ALT+Left/Right` | Focus previous/next scroller column. |
| `ALT+Up/Down` | Resize the focused scroller column by 5% (20–100%). |
| `ALT+E` | Set the focused column to 100%. |
| `ALT+X` | Cycle proportion presets. |
| `ALT+SUPER+CTRL+Left/Right/Up/Down` | Stack the focused window in that direction. |

## Tags

| Key | Action |
| --- | --- |
| `SUPER+1..9` | View tag. |
| `SUPER+,` / `SUPER+.` | Previous/next tag. |
| `SUPER+SHIFT+1..9` | Send focused window to tag without following. |
| `SUPER+scroll up/down` (axis) | Previous/next tag with a client. |

## Monitors

| Key | Action |
| --- | --- |
| `ALT+SHIFT+Left/Right` | Focus monitor. |
| `SUPER+ALT+Left/Right` | Move tag to monitor. |

## Floating windows

| Key | Action |
| --- | --- |
| `CTRL+SHIFT+Up/Down/Left/Right` | Move floating window by 50 px. |
| `CTRL+ALT+Up/Down/Left/Right` | Resize floating window by 50 px. |
| `SUPER+Left-drag` | Move window. |
| `SUPER+Right-drag` | Resize window. |
| `SUPER+Middle-click` | Toggle maximize screen. |

## Gaps

| Key | Action |
| --- | --- |
| `ALT+SHIFT+X` | Increase gaps. |
| `ALT+SHIFT+Z` | Decrease gaps. |
| `ALT+SHIFT+R` | Toggle gaps. |

## Media and screenshots

| Key | Action |
| --- | --- |
| `XF86AudioRaiseVolume` | Volume +5% via `mango/scripts/volume.sh up`. |
| `XF86AudioLowerVolume` | Volume −5% via `mango/scripts/volume.sh down`. |
| `XF86AudioMute` | Toggle default sink mute. |
| `XF86AudioMicMute` | Toggle default source mute. |
| `XF86AudioPlay` | `playerctl play-pause`. |
| `XF86AudioNext` / `Prev` | `playerctl next` / `previous`. |
| `Print` | Full-screen screenshot. |
| `SUPER+SHIFT+S` | Region screenshot. |
| `SUPER+Print` | Window screenshot. |

## Mouse and touchpad

| Binding | Action |
| --- | --- |
| `SUPER+btn_left` | Move/resize window (`moveresize,curmove`). |
| `SUPER+btn_middle` | Toggle maximize screen. |
| `SUPER+btn_right` | Move/resize window (`moveresize,curresize`). |
| `SUPER+wheel up/down` | Previous/next tag with a client. |

## Gestures

| Gesture | Action |
| --- | --- |
| `none+left+3` | Focus left. |
| `none+right+3` | Focus right. |
| `none+up+3` | Focus up. |
| `none+down+3` | Focus down. |
| `none+right+4` | Previous tag with a client. |
| `none+left+4` | Next tag with a client. |
| `none+up+4` | Enter Mango overview. |
| `none+down+4` | Leave Mango overview. |

## Bar interactions

The bar modules have their own pointer actions, documented in
[bar.md](bar.md). The most important are:

- Right-click a tag → Quickshell overview.
- Left-click the window chip → Quickshell overview; right-click → Mango's
  native overview.
- Right-click the media chip text → play/pause; wheel → previous/next.
- Right-click the volume cluster → mute output/microphone; wheel → adjust.
- Right-click the Bluetooth icon → toggle the adapter.
- Right-click the notification bell → toggle DND.
- Right-click the USB icon → refresh drives.
