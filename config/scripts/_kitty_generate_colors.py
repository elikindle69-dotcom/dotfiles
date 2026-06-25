#!/usr/bin/env python3

from pathlib import Path

import _common as c

DEFAULT_OUTPUT = Path.home() / ".config" / "kitty" / "current-theme.conf"

BASE16_TO_KITTY = {
    "color0": "base00",
    "color1": "base08",
    "color2": "base0B",
    "color3": "base0A",
    "color4": "base0D",
    "color5": "base0E",
    "color6": "base0C",
    "color7": "base05",
    "color8": "base03",
    "color9": "base08",
    "color10": "base0B",
    "color11": "base0A",
    "color12": "base0D",
    "color13": "base0E",
    "color14": "base0C",
    "color15": "base07",
}


def generate_kitty(theme: c.ThemeData) -> str:
    colors = theme["colors"]
    mode = c.get_mode(theme)
    base16 = theme.get("base16", {})

    def _get(name: str) -> str:
        return c.get_color(colors, name, mode)

    def _get_base16(base_name: str) -> str:
        node = base16[base_name.lower()]
        return node["default"]["color"]

    lines = [
        "# Generated automatically from ~/.theme.json",
        "",
        f"foreground {_get('on_surface')}",
        f"background {_get('background')}",
        "",
        f"cursor {_get('primary')}",
        f"cursor_text_color {_get('on_primary')}",
        "",
        f"selection_background {_get('secondary_container')}",
        f"selection_foreground {_get('on_secondary_container')}",
        "",
        f"url_color {_get('tertiary')}",
        "",
        f"active_border_color {_get('primary')}",
        f"inactive_border_color {_get('outline_variant')}",
        "",
        f"active_tab_foreground {_get('on_primary')}",
        f"active_tab_background {_get('primary')}",
        "",
        f"inactive_tab_foreground {_get('on_surface_variant')}",
        f"inactive_tab_background {_get('surface_container')}",
        "",
    ]

    for kitty_color, base_name in BASE16_TO_KITTY.items():
        lines.append(f"{kitty_color} {_get_base16(base_name)}")

    return "\n".join(lines) + "\n"


def write():
    theme = c.load_theme()
    output = generate_kitty(theme)
    c.atomic_write(DEFAULT_OUTPUT, output)
    c.log(f"Wrote: {DEFAULT_OUTPUT}")


if __name__ == "__main__":
    write()
