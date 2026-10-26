#!/usr/bin/env python3
"""Apply the active Matugen palette to KDE/Qt, Konsole, and GTK applications.

The shell's Matugen palette is the source of truth.  This script keeps the
existing KDE Material You scheme names, so Konsole/Dolphin and the GTK Breeze
theme can be updated without replacing the user's profile or theme choices.
"""

from __future__ import annotations

import json
import os
import re
import shutil
import stat
import sys
from pathlib import Path
from typing import Iterable


CONFIG_HOME = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
CACHE_HOME = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache"))
DATA_HOME = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share"))
THEME_JSON = CACHE_HOME / "quickshell" / "theme.json"
SETTINGS_JSON = CONFIG_HOME / "quickshell" / "matugen.json"

KDE_COLOR_DIR = DATA_HOME / "color-schemes"
KONSOLE_DIR = DATA_HOME / "konsole"
KDE_GLOBALS = CONFIG_HOME / "kdeglobals"
GTK_DIRS = (CONFIG_HOME / "gtk-3.0", CONFIG_HOME / "gtk-4.0")

HEX_RE = re.compile(r"^#[0-9a-fA-F]{6}$")

# Breeze's GTK stylesheet uses these private colour names.  Keep this fallback
# list in sync with the generated colours.css in the user's config directories.
GTK_FALLBACK_KEYS = (
    "borders_breeze", "content_view_bg_breeze", "error_color_backdrop_breeze",
    "error_color_breeze", "error_color_insensitive_backdrop_breeze",
    "error_color_insensitive_breeze", "insensitive_base_color_breeze",
    "insensitive_base_fg_color_breeze", "insensitive_bg_color_breeze",
    "insensitive_borders_breeze", "insensitive_fg_color_breeze",
    "insensitive_selected_bg_color_breeze", "insensitive_selected_fg_color_breeze",
    "insensitive_unfocused_bg_color_breeze",
    "insensitive_unfocused_fg_color_breeze",
    "insensitive_unfocused_selected_bg_color_breeze",
    "insensitive_unfocused_selected_fg_color_breeze", "link_color_breeze",
    "link_visited_color_breeze", "success_color_backdrop_breeze",
    "success_color_breeze", "success_color_insensitive_backdrop_breeze",
    "success_color_insensitive_breeze", "theme_base_color_breeze",
    "theme_bg_color_breeze", "theme_button_background_backdrop_breeze",
    "theme_button_background_backdrop_insensitive_breeze",
    "theme_button_background_insensitive_breeze",
    "theme_button_background_normal_breeze",
    "theme_button_decoration_focus_backdrop_breeze",
    "theme_button_decoration_focus_backdrop_insensitive_breeze",
    "theme_button_decoration_focus_breeze",
    "theme_button_decoration_focus_insensitive_breeze",
    "theme_button_decoration_hover_backdrop_breeze",
    "theme_button_decoration_hover_backdrop_insensitive_breeze",
    "theme_button_decoration_hover_breeze",
    "theme_button_decoration_hover_insensitive_breeze",
    "theme_button_foreground_active_backdrop_breeze",
    "theme_button_foreground_active_backdrop_insensitive_breeze",
    "theme_button_foreground_active_breeze",
    "theme_button_foreground_active_insensitive_breeze",
    "theme_button_foreground_backdrop_breeze",
    "theme_button_foreground_backdrop_insensitive_breeze",
    "theme_button_foreground_insensitive_breeze",
    "theme_button_foreground_normal_breeze", "theme_fg_color_breeze",
    "theme_header_background_backdrop_breeze",
    "theme_header_background_breeze", "theme_header_background_light_breeze",
    "theme_header_foreground_backdrop_breeze",
    "theme_header_foreground_breeze",
    "theme_header_foreground_insensitive_backdrop_breeze",
    "theme_header_foreground_insensitive_breeze",
    "theme_hovering_selected_bg_color_breeze", "theme_selected_bg_color_breeze",
    "theme_selected_fg_color_breeze", "theme_text_color_breeze",
    "theme_titlebar_background_backdrop_breeze",
    "theme_titlebar_background_breeze", "theme_titlebar_background_light_breeze",
    "theme_titlebar_foreground_backdrop_breeze",
    "theme_titlebar_foreground_breeze",
    "theme_titlebar_foreground_insensitive_backdrop_breeze",
    "theme_titlebar_foreground_insensitive_breeze",
    "theme_unfocused_base_color_breeze", "theme_unfocused_bg_color_breeze",
    "theme_unfocused_fg_color_breeze", "theme_unfocused_selected_bg_color_alt_breeze",
    "theme_unfocused_selected_bg_color_breeze",
    "theme_unfocused_selected_fg_color_breeze", "theme_unfocused_text_color_breeze",
    "theme_unfocused_view_bg_color_breeze",
    "theme_unfocused_view_text_color_breeze",
    "theme_view_active_decoration_color_breeze",
    "theme_view_hover_decoration_color_breeze", "tooltip_background_breeze",
    "tooltip_border_breeze", "tooltip_text_breeze", "unfocused_borders_breeze",
    "unfocused_insensitive_borders_breeze", "warning_color_backdrop_breeze",
    "warning_color_breeze", "warning_color_insensitive_backdrop_breeze",
    "warning_color_insensitive_breeze",
)

DEFAULT_ROLES = {
    "surface": "#101418",
    "surface_dim": "#101418",
    "surface_bright": "#32363a",
    "surface_container_lowest": "#0b0e12",
    "surface_container_low": "#181c20",
    "surface_container": "#1c2024",
    "surface_container_high": "#262a2e",
    "surface_container_highest": "#31353a",
    "on_surface": "#e2e2e6",
    "on_surface_variant": "#c5c6d0",
    "outline": "#8f9099",
    "outline_variant": "#45464f",
    "primary": "#adc6ff",
    "on_primary": "#002e69",
    "primary_container": "#284777",
    "on_primary_container": "#d7e3ff",
    "primary_fixed": "#d7e3ff",
    "primary_fixed_dim": "#adc6ff",
    "on_primary_fixed": "#001b3e",
    "on_primary_fixed_variant": "#284777",
    "secondary": "#bfc6dc",
    "on_secondary": "#293041",
    "secondary_container": "#3f4759",
    "on_secondary_container": "#dbe2f9",
    "secondary_fixed": "#dbe2f9",
    "secondary_fixed_dim": "#bfc6dc",
    "on_secondary_fixed": "#141b2c",
    "on_secondary_fixed_variant": "#3f4759",
    "tertiary": "#ddbce0",
    "on_tertiary": "#3f2844",
    "tertiary_container": "#573e5c",
    "on_tertiary_container": "#fad8fd",
    "error": "#ffb4ab",
    "on_error": "#690005",
    "error_container": "#93000a",
    "on_error_container": "#ffdad6",
    "background": "#101418",
    "on_background": "#e2e2e6",
    "scrim": "#000000",
    "shadow": "#000000",
}


def atomic_write(path: Path, text: str, mode: int = 0o644) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(path.name + ".matugen-tmp")
    tmp.write_text(text, encoding="utf-8")
    os.chmod(tmp, mode)
    os.replace(tmp, path)


def backup_once(path: Path) -> None:
    if not path.exists():
        return
    backup = path.with_name(path.name + ".bak-matugen")
    if not backup.exists():
        shutil.copy2(path, backup)


def valid_hex(value) -> bool:
    return isinstance(value, str) and bool(HEX_RE.match(value))


def mix_color(base: str, tint: str, amount: float) -> str:
    amount = max(0.0, min(1.0, amount))
    base_rgb = rgb(base)
    tint_rgb = rgb(tint)
    channels = [
        round(base_rgb[index] * (1.0 - amount) + tint_rgb[index] * amount)
        for index in range(3)
    ]
    return "#" + "".join(f"{channel:02x}" for channel in channels)


def shade_color(color: str, amount: float) -> str:
    """Approximate Qt.lighter/Qt.darker used by the shell's Theme.qml."""
    if amount >= 0:
        return mix_color(color, "#ffffff", amount)
    return mix_color(color, "#000000", -amount)


def contrast_color(color: str) -> str:
    red, green, blue = rgb(color)
    luma = (0.2126 * red + 0.7152 * green + 0.0722 * blue) / 255.0
    return "#14100f" if luma > 0.48 else "#fff8f6"


def load_overrides() -> dict[str, str]:
    if not SETTINGS_JSON.exists():
        return {"text": "", "active": "", "background": ""}
    try:
        settings = json.loads(SETTINGS_JSON.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return {"text": "", "active": "", "background": ""}

    def field(name: str) -> str:
        value = settings.get(name, "")
        return value.lower() if valid_hex(value) else ""

    return {
        "text": field("textColor"),
        "active": field("activeColor"),
        "background": field("backgroundColor"),
    }


def apply_overrides(palette: dict, overrides: dict[str, str], dark: bool) -> None:
    """Match the colour overrides applied at runtime by quickshell/Theme.qml."""
    background = overrides.get("background", "")
    if background:
        palette["surface"] = background
        palette["background"] = background
        palette["surface_dim"] = shade_color(background, -0.04 if dark else 0.08)
        palette["surface_bright"] = shade_color(background, 0.105 if dark else -0.08)
        palette["surface_container_lowest"] = shade_color(
            background, -0.04 if dark else 0.08)
        palette["surface_container_low"] = shade_color(
            background, 0.025 if dark else -0.02)
        palette["surface_container"] = shade_color(
            background, 0.05 if dark else -0.04)
        palette["surface_container_high"] = shade_color(
            background, 0.075 if dark else -0.06)
        palette["surface_container_highest"] = shade_color(
            background, 0.105 if dark else -0.08)

    text = overrides.get("text", "")
    if text:
        palette["on_surface"] = text
        palette["on_background"] = text
        # Theme.dim is the override text at 72% opacity over the surface.
        palette["on_surface_variant"] = mix_color(palette["surface"], text, 0.72)

    active = overrides.get("active", "")
    if active:
        on_active = contrast_color(active)
        palette["primary"] = active
        palette["on_primary"] = on_active
        palette["primary_container"] = mix_color(
            palette["surface"], active, 0.18 if dark else 0.12)
        palette["on_primary_container"] = palette["on_surface"]
        palette["primary_fixed"] = active
        palette["primary_fixed_dim"] = active
        palette["on_primary_fixed"] = on_active
        palette["on_primary_fixed_variant"] = palette["on_primary_container"]


def normalize_palette(roles: dict) -> dict:
    out = dict(DEFAULT_ROLES)
    for key, value in roles.items():
        if valid_hex(value):
            out[key] = value.lower()
    return out


def rgb(hex_color: str) -> tuple[int, int, int]:
    value = hex_color.lstrip("#")
    return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4))


def csv_color(hex_color: str) -> str:
    return ",".join(str(channel) for channel in rgb(hex_color))


def argb_color(hex_color: str) -> str:
    return "#ff" + hex_color.lstrip("#").lower()


def section_entry(p: dict) -> dict:
    fg = p["on_surface"]
    dim = p["on_surface_variant"]
    surface = p["surface"]
    surface_low = p["surface_container_low"]
    surface_container = p["surface_container"]
    surface_high = p["surface_container_high"]
    surface_highest = p["surface_container_highest"]
    base = p["surface_container_lowest"]
    primary = p["primary"]
    on_primary = p["on_primary"]
    primary_container = p["primary_container"]
    on_primary_container = p["on_primary_container"]
    secondary = p["secondary"]
    tertiary = p["tertiary"]
    error = p["error"]
    outline = p["outline"]
    outline_variant = p["outline_variant"]

    def normal(bg: str, fg_value: str = fg) -> dict:
        return {
            "BackgroundAlternate": bg,
            "BackgroundNormal": bg,
            "DecorationFocus": primary,
            "DecorationHover": primary,
            "ForegroundActive": primary,
            "ForegroundInactive": dim,
            "ForegroundLink": primary,
            "ForegroundNegative": error,
            "ForegroundNeutral": tertiary,
            "ForegroundNormal": fg_value,
            "ForegroundPositive": secondary,
            "ForegroundVisited": tertiary,
        }

    window = normal(surface)
    window["BackgroundAlternate"] = surface_container
    window["ForegroundActive"] = primary

    view = normal(base)
    view["BackgroundAlternate"] = surface_low
    view["DecorationHover"] = primary_container

    button = normal(surface_container)
    button["BackgroundAlternate"] = surface_high

    selection = normal(primary, on_primary)
    selection["BackgroundAlternate"] = primary_container
    selection["DecorationHover"] = on_primary
    selection["ForegroundActive"] = on_primary
    selection["ForegroundInactive"] = on_primary
    selection["ForegroundLink"] = on_primary
    selection["ForegroundNegative"] = on_primary
    selection["ForegroundNeutral"] = on_primary
    selection["ForegroundPositive"] = on_primary
    selection["ForegroundVisited"] = on_primary

    tooltip = normal(surface_high)
    tooltip["BackgroundAlternate"] = surface_highest

    header = normal(surface_container)
    header["BackgroundAlternate"] = surface_low
    header_inactive = normal(surface_low, dim)
    header_inactive["BackgroundAlternate"] = base
    header_inactive["ForegroundActive"] = primary_container

    complementary = normal(surface_highest)
    complementary["BackgroundAlternate"] = surface_high

    return {
        "ColorEffects:Disabled": {
            "Color": surface,
            "ColorAmount": "0.5",
            "ColorEffect": "3",
            "ContrastAmount": "0",
            "ContrastEffect": "0",
            "IntensityAmount": "0",
            "IntensityEffect": "0",
        },
        "ColorEffects:Inactive": {
            "ChangeSelectionColor": "true",
            "Color": "#000000",
            "ColorAmount": "0.025",
            "ColorEffect": "0",
            "ContrastAmount": "0.1",
            "ContrastEffect": "0",
            "Enable": "true",
            "IntensityAmount": "0",
            "IntensityEffect": "0",
        },
        "Colors:Button": button,
        "Colors:Complementary": complementary,
        "Colors:Header": header,
        "Colors:Header][Inactive": header_inactive,
        "Colors:Selection": selection,
        "Colors:Tooltip": tooltip,
        "Colors:View": view,
        "Colors:Window": window,
        "WM": {
            "activeBackground": argb_color(surface_container),
            "activeBlend": csv_color(p["on_surface"]),
            "activeForeground": argb_color(fg),
            "inactiveBackground": argb_color(surface_low),
            "inactiveBlend": csv_color(dim),
            "inactiveForeground": argb_color(dim),
        },
    }


def render_ini(groups: dict[str, dict[str, str]]) -> str:
    chunks: list[str] = []
    for section, entries in groups.items():
        chunks.append(f"[{section}]")
        chunks.extend(f"{key}={value}" for key, value in entries.items())
        chunks.append("")
    return "\n".join(chunks)


def scheme_groups(p: dict, scheme_name: str, label: str) -> dict[str, dict[str, str]]:
    groups = section_entry(p)
    groups["General"] = {
        "ColorScheme": scheme_name,
        "Name": label,
        "shadeSortColumn": "true",
    }
    groups["KDE"] = {"contrast": "4", "frameContrast": "0.2"}
    return groups


def parse_sections(text: str) -> tuple[list[str], list[tuple[str, list[str]]]]:
    preamble: list[str] = []
    sections: list[tuple[str, list[str]]] = []
    current: list[str] | None = None
    for line in text.splitlines():
        match = re.match(r"^\[(.+)\]\s*$", line)
        if match:
            current = []
            sections.append((match.group(1), current))
        elif current is None:
            preamble.append(line)
        else:
            current.append(line)
    return preamble, sections


def update_kdeglobals(path: Path, groups: dict[str, dict[str, str]], scheme_name: str) -> None:
    original = path.read_text(encoding="utf-8") if path.exists() else ""
    backup_once(path)
    preamble, sections = parse_sections(original)
    replace_sections = {name for name in groups if name != "General" and name != "KDE"}
    seen: set[str] = set()
    out: list[str] = list(preamble)

    for name, lines in sections:
        while lines and not lines[-1].strip():
            lines.pop()

        if name in replace_sections:
            out.append(f"[{name}]")
            out.extend(f"{key}={value}" for key, value in groups[name].items())
            out.append("")
            seen.add(name)
            continue

        if name == "General":
            out.append(f"[{name}]")
            for line in lines:
                if line.startswith("ColorScheme=") or line.startswith("ColorSchemeHash="):
                    continue
                out.append(line)
            out.append(f"ColorScheme={scheme_name}")
            out.append("")
            seen.add(name)
            continue

        out.append(f"[{name}]")
        out.extend(lines)
        out.append("")
        seen.add(name)

    for name, entries in groups.items():
        if name in seen or name in {"General", "KDE"}:
            continue
        out.append(f"[{name}]")
        out.extend(f"{key}={value}" for key, value in entries.items())
        out.append("")

    mode = stat.S_IMODE(path.stat().st_mode) if path.exists() else 0o600
    atomic_write(path, "\n".join(out).rstrip() + "\n", mode)


def gtk_color_for(key: str, p: dict) -> str:
    k = key.lower()
    fg = p["on_surface"]
    dim = p["on_surface_variant"]
    bg = p["surface"]
    base = p["surface_container_lowest"]
    low = p["surface_container_low"]
    container = p["surface_container"]
    high = p["surface_container_high"]
    highest = p["surface_container_highest"]
    primary = p["primary"]
    on_primary = p["on_primary"]
    primary_container = p["primary_container"]
    secondary = p["secondary"]
    on_secondary = p["on_secondary"]
    tertiary = p["tertiary"]
    on_tertiary = p["on_tertiary"]
    error = p["error"]
    error_container = p["error_container"]
    on_error = p["on_error"]
    outline = p["outline"]
    outline_variant = p["outline_variant"]

    if "error_color" in k:
        return error_container if "insensitive" in k else error
    if "success_color" in k:
        return secondary
    if "warning_color" in k:
        return tertiary
    if "link_visited" in k:
        return tertiary
    if "link_color" in k:
        return primary
    if "hovering_selected_bg" in k:
        return primary_container
    if "view_hover_decoration" in k or "view_active_decoration" in k:
        return primary
    if "selected" in k:
        if "fg" in k:
            return dim if ("insensitive" in k or "unfocused" in k) else on_primary
        if "insensitive" in k:
            return container
        if "unfocused" in k or "backdrop" in k:
            return high
        return primary
    if "tooltip" in k:
        if "background" in k:
            return high
        if "border" in k:
            return outline_variant
        return fg
    if "button" in k:
        if "background" in k:
            return low if ("insensitive" in k or "backdrop" in k) else container
        if "decoration" in k:
            return primary_container if ("insensitive" in k or "backdrop" in k) else primary
        if "foreground" in k:
            if "active" in k:
                return on_primary
            return dim if ("insensitive" in k or "backdrop" in k) else fg
    if "header" in k or "titlebar" in k:
        if "background" in k:
            return low if ("backdrop" in k or "light" in k) else container
        if "foreground" in k:
            return dim if ("insensitive" in k or "backdrop" in k) else fg
    if "borders" in k:
        return high if "insensitive" in k else outline_variant
    if "insensitive" in k:
        # Foregrounds must stay foregrounds: an insensitive base foreground
        # that inherits the base surface makes disabled labels disappear.
        if "fg" in k or "text" in k:
            return dim
        if "base" in k:
            return base
        if "bg" in k:
            return low
        if "border" in k:
            return high
        return dim
    if "unfocused" in k:
        if "base" in k or "bg" in k:
            return base
        if "border" in k:
            return outline_variant
        return dim
    if "theme_fg" in k or "theme_text" in k:
        return fg
    if "theme_bg" in k:
        return bg
    if "theme_base" in k or "content_view_bg" in k:
        return base
    if "theme_selected_bg" in k:
        return primary
    if "theme_selected_fg" in k:
        return on_primary
    if "foreground" in k or "fg" in k or "text" in k:
        return fg
    if "background" in k or "bg" in k:
        return container
    if "border" in k:
        return outline_variant
    return fg


def gtk_keys() -> tuple[str, ...]:
    keys: list[str] = list(GTK_FALLBACK_KEYS)
    for directory in GTK_DIRS:
        path = directory / "colors.css"
        if not path.exists():
            continue
        for line in path.read_text(encoding="utf-8").splitlines():
            match = re.match(r"^@define-color\s+(\S+)\s+", line)
            name = match.group(1) if match else ""
            # Only Breeze's private names belong in this section; the common
            # aliases are appended explicitly with fixed values below.
            if name.endswith("_breeze") and name not in keys:
                keys.append(name)
    return tuple(keys)


def build_gtk_css(p: dict) -> str:
    fg = p["on_surface"]
    bg = p["surface"]
    base = p["surface_container_lowest"]
    container = p["surface_container"]
    high = p["surface_container_high"]
    highest = p["surface_container_highest"]
    primary = p["primary"]
    on_primary = p["on_primary"]
    secondary = p["secondary"]
    on_secondary = p["on_secondary"]
    tertiary = p["tertiary"]
    on_tertiary = p["on_tertiary"]
    error = p["error"]
    on_error = p["on_error"]
    outline_variant = p["outline_variant"]

    lines = ["/* Generated by theme-refresh.sh from the active Matugen palette. */"]
    for key in gtk_keys():
        lines.append(f"@define-color {key} {gtk_color_for(key, p)};")

    aliases = {
        "theme_bg_color": bg,
        "theme_fg_color": fg,
        "theme_base_color": base,
        "theme_text_color": fg,
        "theme_selected_bg_color": primary,
        "theme_selected_fg_color": on_primary,
        "insensitive_bg_color": p["surface_container_low"],
        "insensitive_fg_color": p["on_surface_variant"],
        "insensitive_base_color": base,
        "borders": outline_variant,
        "unfocused_borders": outline_variant,
        "link_color": primary,
        "link_visited_color": tertiary,
        "tooltip_bg_color": high,
        "tooltip_fg_color": fg,
        "window_bg_color": bg,
        "window_fg_color": fg,
        "view_bg_color": base,
        "view_fg_color": fg,
        "headerbar_bg_color": container,
        "headerbar_fg_color": fg,
        "headerbar_border_color": outline_variant,
        "headerbar_backdrop_color": p["surface_container_low"],
        "headerbar_shade_color": outline_variant,
        "card_bg_color": container,
        "card_fg_color": fg,
        "card_shade_color": outline_variant,
        "popover_bg_color": high,
        "popover_fg_color": fg,
        "dialog_bg_color": container,
        "dialog_fg_color": fg,
        "sidebar_bg_color": container,
        "sidebar_fg_color": fg,
        "secondary_sidebar_bg_color": p["surface_container_low"],
        "secondary_sidebar_fg_color": fg,
        "accent_bg_color": primary,
        "accent_fg_color": on_primary,
        "accent_color": primary,
        "destructive_bg_color": error,
        "destructive_fg_color": on_error,
        "destructive_color": error,
        "success_bg_color": secondary,
        "success_fg_color": on_secondary,
        "success_color": secondary,
        "warning_bg_color": tertiary,
        "warning_fg_color": on_tertiary,
        "warning_color": tertiary,
        "error_bg_color": error,
        "error_fg_color": on_error,
        "error_color": error,
        "shade_color": outline_variant,
        "scrollbar_outline_color": outline_variant,
        "thumbnail_bg_color": high,
        "thumbnail_fg_color": fg,
    }
    lines.append("")
    lines.append("/* Common GTK and libadwaita aliases. */")
    for key, value in aliases.items():
        lines.append(f"@define-color {key} {value};")
    return "\n".join(lines) + "\n"


def konsole_entries(p: dict) -> dict[str, dict[str, str]]:
    def color(role: str) -> str:
        return csv_color(p[role])

    byte_colors = [
        ("Color0", "surface_container_lowest", "surface_container_low", "surface_container_high"),
        ("Color1", "error", "error_container", "on_error_container"),
        ("Color2", "primary", "primary_container", "on_primary_container"),
        ("Color3", "tertiary", "tertiary_container", "on_tertiary_container"),
        ("Color4", "secondary", "secondary_container", "on_secondary_container"),
        ("Color5", "primary_fixed_dim", "primary_fixed", "on_primary_fixed"),
        ("Color6", "secondary_fixed_dim", "secondary_fixed", "on_secondary_fixed"),
        ("Color7", "on_surface_variant", "outline", "on_surface"),
        ("Color8", "outline", "outline_variant", "on_surface_variant"),
        ("Color9", "on_error", "error_container", "on_error_container"),
        ("Color10", "on_primary", "primary_container", "on_primary_container"),
        ("Color11", "on_tertiary", "tertiary_container", "on_tertiary_container"),
        ("Color12", "on_secondary", "secondary_container", "on_secondary_container"),
        ("Color13", "primary_fixed", "primary_container", "on_primary_fixed"),
        ("Color14", "secondary_fixed", "secondary_container", "on_secondary_fixed"),
        ("Color15", "on_surface", "on_surface_variant", "on_surface"),
    ]

    out: dict[str, dict[str, str]] = {
        "Background": {"Color": color("surface")},
        "BackgroundFaint": {"Color": color("surface_container_low")},
        "BackgroundIntense": {"Color": color("surface_container")},
    }
    for name, normal, faint, intense in byte_colors:
        out[name] = {"Color": color(normal)}
        out[name + "Faint"] = {"Color": color(faint)}
        out[name + "Intense"] = {"Color": color(intense)}
    out["Foreground"] = {"Color": color("on_surface")}
    out["ForegroundFaint"] = {"Color": color("on_surface_variant")}
    out["ForegroundIntense"] = {"Color": color("on_surface")}
    out["General"] = {
        "Anchor": "0.5,0.5",
        "Blur": "true",
        "ColorRandomization": "false",
        "Description": "Matugen",
        "FillStyle": "Tile",
        "Opacity": "1.0",
        "Wallpaper": "",
        "WallpaperFlipType": "NoFlip",
        "WallpaperOpacity": "1",
    }
    return out


def write_gtk(p: dict) -> None:
    css = build_gtk_css(p)
    for directory in GTK_DIRS:
        colors = directory / "colors.css"
        import_file = directory / "gtk.css"
        backup_once(colors)
        backup_once(import_file)
        atomic_write(colors, css, 0o644)
        atomic_write(import_file, "@import 'colors.css';\n", 0o644)


def main() -> int:
    if not THEME_JSON.exists():
        print(f"theme-sync-apps: missing {THEME_JSON}", file=sys.stderr)
        return 1

    try:
        data = json.loads(THEME_JSON.read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:
        print(f"theme-sync-apps: cannot read theme JSON: {exc}", file=sys.stderr)
        return 1

    dark = normalize_palette(data.get("dark") or {})
    light = normalize_palette(data.get("light") or {})
    overrides = load_overrides()
    apply_overrides(dark, overrides, True)
    apply_overrides(light, overrides, False)
    mode = "light" if data.get("mode") == "light" else "dark"
    active = light if mode == "light" else dark
    scheme_name = "MaterialYouLight" if mode == "light" else "MaterialYouDark"
    label = "Material You light" if mode == "light" else "Material You dark"

    KDE_COLOR_DIR.mkdir(parents=True, exist_ok=True)
    dark_groups = scheme_groups(dark, "MaterialYouDark", "Material You dark")
    light_groups = scheme_groups(light, "MaterialYouLight", "Material You light")

    for filename, groups in (
        ("MaterialYouDark.colors", dark_groups),
        ("MaterialYouLight.colors", light_groups),
    ):
        path = KDE_COLOR_DIR / filename
        backup_once(path)
        atomic_write(path, render_ini(groups), 0o644)

    update_kdeglobals(KDE_GLOBALS, groups=scheme_groups(active, scheme_name, label),
                      scheme_name=scheme_name)

    KONSOLE_DIR.mkdir(parents=True, exist_ok=True)
    konsole_path = KONSOLE_DIR / "MaterialYou.colorscheme"
    backup_once(konsole_path)
    atomic_write(konsole_path, render_ini(konsole_entries(active)), 0o644)

    write_gtk(active)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
