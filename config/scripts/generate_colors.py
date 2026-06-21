#!/usr/bin/env python3

import argparse
import re
import sys
from pathlib import Path

import _common as c
import _kitty_generate_colors as kitty
import _mako_generate_colors as mako
import _qt6ct_generate_colors as qt6ct
import _gtk_generate_colors as gtk

THEME_PATH = Path.home() / ".theme.json"


def _get_wallpaper_from_awww() -> str:
    result = c.run_cmd(["awww", "query"], capture=True, check=True)

    match = re.search(
        r"currently displaying:\s*image:\s*(.+)",
        result.stdout,
    )

    if not match:
        raise c.ThemeError("Could not extract wallpaper path from aww output")

    return match.group(1).strip()


def _run_matugen(image_path: str, mode: c.Mode) -> None:
    prefer = "darkness" if mode == c.Mode.DARK else "lightness"

    result = c.run_cmd(
        [
            "matugen",
            "image",
            image_path,
            "--mode",
            mode.value,
            "--prefer",
            prefer,
            "--json",
            "hex",
        ],
        capture=True,
        check=True,
    )

    if not result.stdout.strip():
        raise c.ThemeError("matugen produced no output")

    c.atomic_write(THEME_PATH, result.stdout)

    # Validate immediately so we fail fast before any backend runs.
    try:
        data = c.load_theme(THEME_PATH)
    except c.ThemeError:
        # Load failed — clean up so downstream doesn't operate on bad data.
        THEME_PATH.unlink(missing_ok=True)
        raise


def _reload(name: str, cmd: list[str]) -> None:
    """Try to reload a service.  Never raises."""
    try:
        result = c.run_cmd(cmd, capture=True)
        if result.returncode != 0:
            stderr = (result.stderr or "").strip()
            c.log(f"Failed to reload {name}: {stderr or 'exit ' + str(result.returncode)}", 2)
        else:
            c.log(f"Reloaded {name}")
    except FileNotFoundError:
        c.log(f"{cmd[0]} not found, skipping {name} reload", 2)
    except Exception as exc:
        c.log(f"{name} reload failed: {exc}", 2)


# Backend generators and their reload commands.
# Each entry: (name, write_fn, reload_cmd)
_BACKENDS: list[tuple[str, callable, list[str] | None]] = [
    ("kitty", kitty.write, ["kitten", "@", "load-config"]),
    ("mako", mako.write, ["makoctl", "reload"]),
    ("qt6ct", qt6ct.write, None),
    ("gtk", gtk.write, None),
]


def write(mode: c.Mode) -> str:
    """
    Full theme generation pipeline.

    Returns:
        str: wallpaper path used

    Raises:
        ThemeError: If matugen fails (critical path).
        Backend errors are logged and collected, not raised.
    """
    image_path = _get_wallpaper_from_awww()

    c.log(f"Wallpaper: {image_path}")
    c.log(f"Mode: {mode.value}")

    _run_matugen(image_path, mode)

    c.log(f"Wrote theme: {THEME_PATH}")

    errors: list[str] = []

    for name, write_fn, reload_cmd in _BACKENDS:
        try:
            write_fn()
        except Exception as exc:
            c.log(f"{name} generation failed: {type(exc).__name__}: {exc}", 2)
            errors.append(name)
            continue

        if reload_cmd is not None:
            _reload(name, reload_cmd)

    if errors:
        c.log(f"Completed with errors in: {', '.join(errors)}", 2)

    return image_path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("mode", choices=[m.value for m in c.Mode])
    parser.add_argument("-v", "--debug", action="store_true", help="Enable debug output")
    args = parser.parse_args()

    c.setup_logging(debug=args.debug)

    try:
        c.check_deps(["awww", "matugen"])
    except c.MissingDependencyError:
        sys.exit(1)

    try:
        write(c.Mode(args.mode))
    except c.ThemeError as exc:
        c.log(f"{exc}", 3)
        sys.exit(1)


if __name__ == "__main__":
    main()
