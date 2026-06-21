#!/usr/bin/env python3

import argparse
import sys
from pathlib import Path

import _common as c
from generate_colors import write as generate_theme


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("image", type=Path, help="Path to wallpaper image")
    parser.add_argument("mode", choices=[m.value for m in c.Mode], help="Theme mode")
    parser.add_argument("-v", "--debug", action="store_true", help="Enable debug output")
    args = parser.parse_args()

    c.setup_logging(debug=args.debug)

    image = args.image.resolve()
    if not image.is_file():
        c.log(f"Invalid image path: {args.image}", 3)
        sys.exit(1)

    try:
        c.check_deps(["awww"])
    except c.MissingDependencyError:
        sys.exit(1)

    c.run_cmd([
        "awww", "img", str(image),
        "-t", "any",
        "--transition-duration", "2",
        "--transition-bezier", "0.2,0.0,0.0,1.0",
    ], check=True)

    generate_theme(c.Mode(args.mode))


if __name__ == "__main__":
    main()
