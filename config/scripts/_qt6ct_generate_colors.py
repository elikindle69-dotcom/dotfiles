#!/usr/bin/env python3

from pathlib import Path

import _common as c

OUT_PATH = Path.home() / ".config" / "qt6ct" / "colors" / "theme.conf"
CONF_PATH = Path.home() / ".config" / "qt6ct" / "qt6ct.conf"

PALETTE_MAP = [
    "on_surface",              # 0  WindowText
    "surface",                 # 1  Button
    "surface_variant",         # 2  Light
    "surface_bright",          # 3  Midlight
    "background",              # 4  Dark
    "surface_container_high",  # 5  Mid
    "on_surface",              # 6  Text
    None,                      # 7  BrightText (literal)
    "on_surface",              # 8  ButtonText
    "background",              # 9  Base
    "surface",                 # 10 Window
    "shadow",                  # 11 Shadow
    "primary",                 # 12 Highlight
    "on_primary",              # 13 HighlightedText
    "tertiary",                # 14 Link
    "tertiary_container",      # 15 LinkVisited
    "surface_container_low",   # 16 AlternateBase
    "surface",                 # 17 NoRole
    "surface_container_high",  # 18 ToolTipBase
    "on_surface",              # 19 ToolTipText
    "surface_variant",         # 20 PlaceholderText
]

TEXT_ROLES = {0, 6, 8, 13, 15, 19, 20}


def _hex_to_argb(hex_color: str, alpha: int) -> str:
    r, g, b = hex_color[1:3], hex_color[3:5], hex_color[5:7]
    return f"#{alpha:02x}{r}{g}{b}"


def _build_palette(colors: c.ThemeColors, mode: c.Mode) -> list[str]:
    palette = []
    for i, role in enumerate(PALETTE_MAP):
        if role is None:
            palette.append("#ffffffff")
        else:
            palette.append(c.get_color(colors, role, mode))
    return palette


def _apply_alpha(palette: list[str], indices: set[int], alpha: int) -> list[str]:
    result = list(palette)
    for i in indices:
        result[i] = _hex_to_argb(result[i], alpha)
    return result


def generate_palette(theme: c.ThemeData) -> dict[str, list[str]]:
    colors = theme["colors"]
    mode = c.get_mode(theme)

    active = _build_palette(colors, mode)
    inactive = _apply_alpha(active, TEXT_ROLES, c.QT_ALPHA_INACTIVE)
    disabled = _apply_alpha(active, TEXT_ROLES, c.QT_ALPHA_DISABLED)

    return {
        "active": active,
        "inactive": inactive,
        "disabled": disabled,
    }


def _format_line(key: str, palette: list[str]) -> str:
    return f"{key}={', '.join(palette)}"


def write():
    theme = c.load_theme()
    palettes = generate_palette(theme)

    lines = [
        "# Generated automatically from ~/.theme.json",
        "[ColorScheme]",
        _format_line("active_colors", palettes["active"]),
        _format_line("disabled_colors", palettes["disabled"]),
        _format_line("inactive_colors", palettes["inactive"]),
    ]

    c.atomic_write(OUT_PATH, "\n".join(lines) + "\n")
    c.log(f"Wrote: {OUT_PATH}")

    if CONF_PATH.exists():
        conf = CONF_PATH.read_text(encoding="utf-8")
        new_line = f"color_scheme_path={OUT_PATH}"
        updated = []
        replaced = False
        for line in conf.splitlines():
            if line.startswith("color_scheme_path="):
                updated.append(new_line)
                replaced = True
            else:
                updated.append(line)
        if not replaced:
            result = []
            inserted = False
            for line in updated:
                result.append(line)
                if not inserted and line.startswith("custom_palette="):
                    result.append(new_line)
                    inserted = True
            if not inserted:
                result.append(new_line)
            updated = result
        c.atomic_write(CONF_PATH, "\n".join(updated) + "\n")
        c.log(f"Updated: {CONF_PATH}")


if __name__ == "__main__":
    write()
