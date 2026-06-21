#!/usr/bin/env python3

from pathlib import Path

import _common as c

OUT_PATH = Path.home() / ".config" / "mako" / "colors.conf"


def write():
    data = c.load_theme()
    colors = data["colors"]
    mode = c.get_mode(data)
    color = c.color_accessor(colors, mode)

    output = f"""
background-color={color["background"]}cc
text-color={color["on_background"]}
border-color={color["primary"]}
progress-color={color["secondary"]}
""".strip() + "\n"

    c.atomic_write(OUT_PATH, output)
    c.log(f"Wrote: {OUT_PATH}")


if __name__ == "__main__":
    write()
