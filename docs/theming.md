# Theming

Mangoshell has two palette layers:

1. **pywal** supplies the base wallpaper palette and Mango's border colours.
2. **Matugen** derives Material You light and dark palettes for Quickshell,
   rofi, KDE/Qt, Konsole, and GTK.

The wallpaper pipeline is owned by `mango/scripts`, because Mango starts the
session and restores the wallpaper. Quickshell only consumes the generated
files and provides the gallery UI.

## Pipeline

```text
wallpaper image
   │
   ├─ set-wallpaper.sh
   │    ├─ normalise copy → ~/.config/mango/wallpaper.png
   │    ├─ record path   → $XDG_STATE_HOME/mango/wallpaper
   │    ├─ wal -i … -n -q -s
   │    │    └─ ~/.cache/wal/colors.sh + ~/.cache/wal/mango.toml
   │    ├─ theme-refresh.sh <image>
   │    │    ├─ ~/.cache/wal/surface-mode      (light|dark)
   │    │    ├─ ~/.cache/wal/surface-outline   (1|0)
   │    │    ├─ ~/.config/rofi/colors.rasi
   │    │    ├─ ~/.cache/quickshell/theme.json (dark + light roles)
   │    │    └─ theme-sync-apps.py
   │    │         ├─ KDE colour schemes + kdeglobals
   │    │         ├─ Konsole colour scheme
   │    │         └─ GTK 3/4 colours.css
   │    ├─ mmsg dispatch reload_config
   │    └─ restart restore-wallpaper.sh (swaybg)
   │
   └─ Quickshell watches theme.json, surface-mode, surface-outline
        └─ Theme.qml recolours the bar, panels, and overlays live
```

`set-wallpaper.sh` runs `wal` with `-n` (do not set the wallpaper) and `-s`
(do not emit OSC colour sequences). Mango's own wallpaper is handled by
`swaybg`; pywal only generates colours.

## First application

Until a wallpaper is applied:

- `restore-wallpaper.sh` starts `swaybg` with the recorded base colour (or
  black) if no wallpaper path exists.
- `theme-refresh.sh` exits quietly if `~/.cache/wal/colors.sh` is missing.
- `Theme.qml` uses its built-in fallback dark/light palettes.

Open the gallery (`SUPER+SHIFT+W`), choose an image, and press **Apply
wallpaper**. This creates the runtime files listed above. A fresh install can
therefore log in before the first gallery selection.

## Auto light/dark

The gallery's Matugen mode has three values: `auto`, `dark`, `light`.

- **Auto** calls `matugen image … --mode smart` on the whole wallpaper. If the
  resulting background is light (luma ≥ 128), the smart palette becomes the
  light palette and mode is set to `light`; otherwise it becomes the dark
  palette and mode is `dark`. The other palette is generated explicitly so the
  shell can switch without invoking Matugen at runtime.
- If Matugen's smart mode fails, the fallback compares the whole-image mean:
  above `0.55` is light, otherwise dark.
- **Dark/Light** always generate both palettes, but force the selected mode.
- **Explicit source colour** cannot be combined with smart image inspection.
  In that case the fallback whole-image luminance decides the mode, while the
  source colour drives both palettes.

The top strip is deliberately *not* the light/dark decision. `theme-refresh.sh`
measures the top 3% only to decide whether the bar needs a text halo:

- mean between `0.32` and `0.68`, or standard deviation above `0.20`, sets
  `surface-outline` to `1`;
- `Theme.outlineText` then enables a one-pixel outline on the optional
  `BarText`/`BarIcon` primitives;
- `Theme.textOutline` is the surface colour at 72% alpha.

The stock bar modules use `Label`/`Icon` on the bar's surface islands, so the
halo is opt-in for custom modules that use `BarText`/`BarIcon`. It keeps a busy
or mixed top edge readable without changing the palette.

## Theme roles

`Theme.qml` exposes Material-style roles from `theme.json`:

- surfaces: `surface`, `surfaceLowest`, `surfaceLow`, `surfaceContainer`,
  `surfaceHigh`;
- text: `fg`, `dim`, `outline`, `outlineVariant`;
- accents: `primary`, `primaryText`, `primaryContainer`,
  `primaryContainerText`, `secondary`, `tertiary`, `error`;
- composed surfaces: `panel` (97% container), `card` (95% low), `bar` (90%
  container), `border`, `hover`, `press`, `selected`, `input`, `scrim`,
  `overviewScrim`.

Radii and typography are also in `Theme.qml`: `radiusBar` 4, `radiusPanel` 5,
`radiusCard` 4, `radiusControl` 3; `fontText` = Futura PT Web Book, `fontDemi`
= Futura PT Demi, `fontIcon` = Material Symbols Rounded; `textSize` 12,
`iconSize` 18, `smallIconSize` 17, `sizeBody` 11.

`theme.json` stores both palettes plus metadata:

```json
{
  "wallpaper": "/absolute/path",
  "mode": "dark",
  "scheme": "Tonal spot",
  "matugen": { "scheme": "scheme-tonal-spot", "mode": "auto", "contrast": 0, "sourceColor": "" },
  "dark": { "surface": "#…", "primary": "#…" },
  "light": { "surface": "#…", "primary": "#…" }
}
```

## Matugen settings

Settings are stored in `~/.config/quickshell/matugen.json`:

```json
{
  "scheme": "scheme-tonal-spot",
  "contrast": 0,
  "mode": "auto",
  "prefer": "saturation",
  "sourceColor": "",
  "textColor": "",
  "activeColor": "",
  "backgroundColor": "",
  "lightnessDark": 0,
  "lightnessLight": 0
}
```

The gallery writes these through `quickshell/scripts/matugen-settings.sh`:

```bash
bash ~/.config/quickshell/scripts/matugen-settings.sh get
bash ~/.config/quickshell/scripts/matugen-settings.sh apply \
  --scheme scheme-tonal-spot --mode auto --contrast 0
bash ~/.config/quickshell/scripts/matugen-settings.sh reset
```

`apply` validates values, atomically replaces the JSON file, and calls
`mango/scripts/theme-refresh.sh`. It never changes the wallpaper. The gallery
debounces changes by 320 ms and serialises concurrent applies.

Supported schemes: `scheme-content`, `scheme-expressive`, `scheme-fidelity`,
`scheme-fruit-salad`, `scheme-monochrome`, `scheme-neutral`,
`scheme-rainbow`, `scheme-tonal-spot`, `scheme-vibrant`, `scheme-smart`.
Contrast is clamped to `-1…1`; brightness (`lightnessDark`/`lightnessLight`) is
clamped to `-0.8…0.8`. The gallery's single **Brightness** slider sends the same
value to both light and dark lightness fields.

`prefer` is exposed in the JSON/CLI (`darkness`, `lightness`, `saturation`,
`less-saturation`, `value`, `closest-to-fallback`) but not in the gallery UI.

### Manual colour overrides

The **Tune** section sets three optional overrides:

- `textColor` replaces `on_surface`/`on_background`; `Theme.dim` becomes the
  override at 72% alpha.
- `activeColor` replaces `primary`/`on_primary` and derives the primary
  container; the foreground is chosen by contrast.
- `backgroundColor` replaces `surface` and derives the surface container
  shades.

The same overrides are applied by `theme-sync-apps.py`, so KDE/Qt, Konsole, and
GTK match the shell. **Auto** clears an override.

## rofi

`rofi/theme.rasi` imports `colors.rasi`. `theme-refresh.sh` first writes a
pywal-based palette, then overwrites it with Matugen surface/text/active roles
when Matugen is available. The shipped `rofi/colors.rasi` is a neutral fallback
for a fresh checkout; it is replaced on the first wallpaper apply.

## Application sync

`mango/scripts/theme-sync-apps.py` reads `theme.json` and `matugen.json` and
writes:

- `~/.local/share/color-schemes/MaterialYouDark.colors`
- `~/.local/share/color-schemes/MaterialYouLight.colors`
- `~/.local/share/konsole/MaterialYou.colorscheme`
- `~/.config/kdeglobals` (active `ColorScheme`)
- `~/.config/gtk-3.0/colors.css` + `gtk.css`
- `~/.config/gtk-4.0/colors.css` + `gtk.css`

Existing files get a one-time `.bak-matugen` backup. KDE applications usually
pick up the new scheme immediately; some GTK applications need a restart, and
KDE may need a re-login for every toolkit to reload.

## Wallpaper placement

Placement is intentionally separate from Matugen. `wallpaper.json` stores:

```json
{ "mode": "fill", "color": "#000000" }
```

`wallpaper-display.sh apply --mode … --color …` writes the file and restarts
`swaybg`; `get` prints it. `restore-wallpaper.sh` reads the same file at login.
Modes: `fill` (crop), `fit`, `stretch`, `tile`, `center`. The colour is used
for exposed areas in fit/center/tile modes and when no wallpaper is recorded.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| Bar stays on fallback colours | `wal` and `matugen` installed? `~/.cache/wal/colors.sh` exists? Run `bash ~/.config/mango/scripts/theme-refresh.sh` manually. |
| Auto picks dark for a light image | Is `sourceColor` set? Explicit source colours disable smart mode. Clear it in **Source → Auto**. |
| Top bar text is hard to read | Stock modules sit on the bar's surface islands. If you use `BarText`/`BarIcon`, inspect `~/.cache/wal/surface-outline`; the top-strip heuristic may not set the halo for a very uniform image. Adjust the thresholds in `theme-refresh.sh`. |
| rofi still uses fallback colours | `jq`/`matugen` missing, or `theme-refresh.sh` did not run; check `~/.config/rofi/colors.rasi`. |
| KDE/GTK colours unchanged | `theme-sync-apps.py` must be executable; check `~/.cache/quickshell/theme.json`; re-login for KDE. |
| Wallpaper not restored after login | `wallpaper-path.sh` must find `$XDG_STATE_HOME/mango/wallpaper` or the canonical copy; otherwise `restore-wallpaper.sh` falls back to the base colour. |
| Fonts fall back to something else | Install the three families or edit `Theme.fontText`/`fontDemi`/`fontIcon`. |

## Generated files

Do not edit these by hand unless you are debugging; they are replaced
atomically:

- `~/.cache/wal/colors.sh`, `surface-mode`, `surface-outline`
- `~/.cache/wal/mango.toml` (from `wal/templates/mango.toml`)
- `~/.cache/quickshell/theme.json`
- `~/.config/rofi/colors.rasi`
- `~/.config/mango/wallpaper.png`
- `$XDG_STATE_HOME/mango/wallpaper`
- KDE/Konsole/GTK outputs listed above
