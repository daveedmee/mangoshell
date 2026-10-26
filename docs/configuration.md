# Configuration

The configuration is split by ownership:

| Tree | Owns |
| --- | --- |
| `quickshell/` | Shell UI, services, bar modules, popovers, and UI helpers. |
| `mango/` | Compositor config, wallpaper/theme pipeline, screenshots, volume keys, scroller helpers. |
| `rofi/` | Launcher config, visual theme, generated palette fallback. |
| `wal/` | pywal template for Mango's border colours. |

Runtime paths are derived from XDG variables in `quickshell/Settings.qml`, so a
non-standard `XDG_CONFIG_HOME`, `XDG_CACHE_HOME`, `XDG_STATE_HOME`, or
`XDG_DATA_HOME` works without editing absolute paths.

## Quickshell settings

`quickshell/Settings.qml` is a singleton with grouped tokens. Changes require a
Quickshell restart (`qs kill && qs`) or a re-login.

### Bar

| Token | Default | Meaning |
| --- | --- | --- |
| `height` | 44 | Reserved bar height / exclusive zone. |
| `islandHeight` | 44 | Height of the three islands. |
| `islandTop` | 0 | Vertical offset of the islands. |
| `sideMargin` | 0 | Outer left/right margin. |
| `islandPadding` | 4 | Horizontal padding inside an island. |
| `tagCount` | 9 | Number of tag buttons. |
| `tagWidth` / `tagHeight` | 28 / 30 | Tag button size. |
| `iconButton` | 32 | Standard icon-button hit area. |
| `mediaMaxChars` | 18 | Media chip title truncation. |
| `titleMaxChars` | 34 | Window chip title truncation. |
| `trayIconSize` / `traySpacing` | 18 / 8 | Tray icon size and gap. |
| `hover` | true | Enable hover feedback. |
| `hoverRadius` | 3 | Hover rectangle radius. |

The island order is defined in `quickshell/Bar.qml`: left `Power`, `Tags`,
`Layout`; centre `Launcher`, `Clock`, `WindowChip`; right `MediaChip`, `Tray`,
`BluetoothStatus`, `Network`, `DevicesStatus`, `Volume`, `Notifications`,
`ControlsButton`. Move a module by moving its entry in the corresponding `Row`.

### Overlays

| Token | Default | Surface |
| --- | --- | --- |
| `topGap` | 8 | Gap below the bar. |
| `sideMargin` | 0 | Right margin for side panels. |
| `sidebarWidth` | 420 | Controls/notifications width. |
| `sidebarBottom` | 0 | Bottom inset for sidebars. |
| `popoverWidth` | 380 | Volume/network width. |
| `bluetoothWidth` | 400 | Bluetooth popover width. |
| `devicesWidth` | 440 | Devices popover width. |
| `mediaWidth` | 392 | Media popover width. |
| `calendarWidth` | 338 | Calendar fallback width. |
| `trayMenuWidth` | 264 | Tray menu width. |
| `sessionWidth` | 610 | Session sheet width. |
| `galleryWidth` / `galleryHeight` | 1280 / 790 | Wallpaper gallery size. |
| `clipboardWidth` / `clipboardHeight` | 650 / 720 | Clipboard sheet size. |
| `layoutPanelWidth` / `layoutPanelHeight` | 548 / 238 | Layout picker size. |

### Notifications

| Token | Default | Meaning |
| --- | --- | --- |
| `popupWidth` | 390 | Popup card width. |
| `popupPadding` | 0 | Popup surface padding. |
| `popupGap` | 12 | Gap between popups. |
| `popupMarginRight` | 14 | Right screen margin. |
| `maxPopups` | 3 | Visible popup cards. |
| `popupQueueLimit` | 12 | Maximum queued popups. |
| `historyLimit` | 100 | Stored notifications before pruning. |
| `timeoutNormal` | 10000 | Normal popup timeout (ms). |
| `timeoutLow` | 5000 | Low-urgency timeout (ms). |
| `timeoutCritical` | 0 | Critical timeout; 0 means persistent. |

### OSD and volume

| Token | Default | Meaning |
| --- | --- | --- |
| `osd.width` / `osd.height` | 318 / 62 | OSD size. |
| `osd.bottom` | 48 | Distance from the bottom edge. |
| `osd.timeout` | 1600 | Auto-hide delay (ms). |
| `volume.deviceListMaxHeight` | 168 | Device selector scroll height. |
| `volume.scrollStep` | 5 | Wheel volume step. |
| `overview.paddingTop` | 56 | Overview top inset. |
| `overview.paddingSide` | 72 | Overview side inset. |
| `overview.paddingBottom` | 34 | Overview bottom inset. |
| `overview.cardGap` | 17 | Gap between overview cards. |

### Paths

`Settings.paths` derives everything from XDG:

```qml
home:         $HOME
configHome:   $XDG_CONFIG_HOME or $HOME/.config
cacheHome:    $XDG_CACHE_HOME or $HOME/.cache
shellScripts: configHome/quickshell/scripts
mangoScripts: configHome/mango/scripts
walCache:     cacheHome/wal
themeCache:   cacheHome/quickshell
themeJson:    themeCache/theme.json
wallpapers:   $HOME/Bilder
wallpaper:    configHome/mango/wallpaper.png
```

The wallpaper indexer falls back to `$XDG_PICTURES_DIR` and then `~/Pictures`
when `~/Bilder` does not exist. To use a different library root, change
`Settings.paths.wallpapers`; the gallery still searches subfolders up to four
levels deep and skips hidden folders and Photos libraries.

## Mango config

`mango/config.toml` contains the compositor configuration. The most relevant
sections:

### Autostart

```toml
exec_once = [
    "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE",
    'bash "${XDG_CONFIG_HOME:-$HOME/.config}/mango/scripts/restore-wallpaper.sh"',
    'bash "${XDG_CONFIG_HOME:-$HOME/.config}/mango/scripts/theme-refresh.sh"',
    "sh -c 'p=$(command -v polkit-kde-authentication-agent-1 || true); [ -n \"$p\" ] || p=/usr/lib/polkit-kde-authentication-agent-1; [ -x \"$p\" ] && exec \"$p\"'",
    "qs",
    "wl-paste --type text --watch cliphist store",
    "wl-paste --type image --watch cliphist store"
]
```

Add personal applications here. Keep each command quoted as a TOML string.
`restore-wallpaper.sh` runs before `theme-refresh.sh` so the same image drives
both `swaybg` and the palette.

### Appearance

- `blur`, `blur_layer`, `blur_params_*`: frosted-glass layer/window blur.
- `shadows`, `layer_shadows`, `border_radius`, `border_px`: borders and shadows.
- `focused_opacity` / `unfocused_opacity`: window translucency.
- `gap_inner_*`, `gap_outer_*`, `smart_gaps`: tiling gaps.
- `root_color`, `border_color`, etc.: fallback colours used until pywal writes
  `~/.cache/wal/mango.toml`. `source_optional` loads that generated file.

### Layouts

The default tag layout is `scroller` for tags 1–9 via `[[rule.tag_rule]]`.
`scroller_structs`, `scroller_default_proportion`, and the proportion presets
control column sizing. `ALT+Up/Down` calls `scroller-resize.sh`, which clamps
the focused column to 20–100%.

### Window rules

- `[var] opaque_apps` — apps that stay fully opaque and unblurred.
- `[var] floating_apps` — apps forced floating.
- Firefox Picture-in-Picture is matched by app ID and localized title.
- `[[rule.layer_rule]]` gives rofi a zoom animation and disables blur on the
  screenshot selection layer.

Edit the PCRE lists to match your applications. Matching is case-insensitive
substring matching unless anchored with `^...$`.

### Keyboard and pointer

- `xkb_rules_layout = "de"`, `xkb_rules_variant = "nodeadkeys"` — change for
  your keyboard.
- `cursor_theme = "breeze_cursors"`, `cursor_size = 24` — change to an installed
  Xcursor directory name.
- `tap_to_click`, `drag_lock`, `trackpad_natural_scrolling`, `sloppy_focus`,
  `warp_cursor`, etc. are under the pointer/behaviour sections.

### Keybinds

`[bind.default]`, `[mousebind.default]`, `[axisbind.default]`, and
`[gesturebind.default]` contain the bindings documented in
[keybinds.md](keybinds.md). `spawn_shell` is used for commands that must run
through a shell; `spawn` is used for direct executables.

## rofi

`rofi/config.rasi` sets modes, icon theme, terminal, fuzzy matching, and
history. `rofi/theme.rasi` contains the visual layout. `rofi/colors.rasi` is
generated by `theme-refresh.sh`; the shipped copy is a neutral fallback.

Change the terminal with:

```rasi
terminal: "rofi-sensible-terminal";
```

Change the icon theme with `icon-theme: "breeze-dark";` or another installed
theme. The rofi font is set in `theme.rasi` (`Futura PT Demi 11`).

## Fonts and icons

The shell uses three font families:

- `Theme.fontText` — `Futura PT Web Book`
- `Theme.fontDemi` — `Futura PT Demi`
- `Theme.fontIcon` — `Material Symbols Rounded`

If Futura PT is unavailable, change the first two to an installed family (for
example `Inter` or `Noto Sans`). Material Symbols Rounded is required for the
glyph names in `Glyphs.qml`; a different icon font will render missing glyphs.
The Quickshell icon theme is set in `shell.qml` (`IconTheme breeze`) and rofi
uses `breeze-dark`.

## Portability checklist

1. **Keyboard** — change `xkb_rules_layout` / `xkb_rules_variant`.
2. **Cursor** — change `cursor_theme` to an installed Xcursor directory name.
3. **Terminal/file manager** — `SUPER+Return` and `SUPER+D` spawn `konsole` and
   `dolphin`; change them in `config.toml`.
4. **Wallpaper library** — `Settings.paths.wallpapers` or the
   `XDG_PICTURES_DIR` fallback.
5. **Fonts** — install Futura PT/Material Symbols or edit `Theme.qml`.
6. **Optional tools** — `ddcutil`, KDE Connect, `swaylock`, `iw`, `nvidia-smi`,
   and `spectacle` degrade gracefully when missing.
7. **Polkit** — the autostart probes for
   `polkit-kde-authentication-agent-1`; install a different agent and adjust
   the command if needed.
8. **Monitor names** — Mango's monitor-specific tags/layouts use the output
   names reported by the compositor; check `mmsg get all-monitors` if a bar
   shows the wrong tags.
9. **VPN** — the network popover prefers the IVPN CLI when present; otherwise
   it lists NetworkManager VPN connections. Install/configure one of them.
10. **Wallpaper state** — `$XDG_STATE_HOME/mango/wallpaper` is isolated from
    pywal's shared cache, so another desktop environment rewriting
    `~/.cache/wal` does not change Mango's restored wallpaper.

## Runtime state and backups

Runtime files are documented in the [README](../README.md#state-and-generated-files).
They are intentionally excluded from the published tree:

- `quickshell/matugen.json`, `wallpaper.json`, `calendar.json`, `dnd`
- `mango/wallpaper.png`
- caches and `$XDG_STATE_HOME/mango/wallpaper`

`rofi/colors.rasi` ships as a neutral fallback and is replaced by
`theme-refresh.sh` after the first wallpaper is applied.

`theme-sync-apps.py` creates one-time `.bak-matugen` backups next to KDE,
Konsole, and GTK files it modifies. It never overwrites an existing backup.

## Applying changes

- **Mango config**: `SUPER+R` reloads `config.toml`.
- **Quickshell QML/settings**: `qs kill && qs` or log out/in.
- **Theme settings**: use the gallery (debounced apply) or run
  `matugen-settings.sh apply …`; no shell restart is needed.
- **Wallpaper placement**: gallery or `wallpaper-display.sh apply …`; `swaybg`
  restarts immediately.
- **rofi**: new launches read `colors.rasi`/`theme.rasi`; no restart needed.
- **KDE/GTK**: restart the application; some KDE components need a re-login.
