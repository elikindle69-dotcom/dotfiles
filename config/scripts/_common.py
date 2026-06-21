#!/usr/bin/env python3

import json
import logging
import os
import shutil
import subprocess
import sys
import tempfile
from enum import Enum
from pathlib import Path
from typing import Any, TypedDict

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------

_LOG = logging.getLogger("theme")

_STATUS_MAP = {
    0: logging.DEBUG,
    1: logging.INFO,
    2: logging.WARNING,
    3: logging.ERROR,
}


def setup_logging(*, debug: bool = False) -> None:
    level = logging.DEBUG if debug else logging.INFO
    handler = logging.StreamHandler(sys.stderr)
    handler.setFormatter(logging.Formatter("[%(levelname)s] %(message)s"))
    _LOG.handlers.clear()
    _LOG.addHandler(handler)
    _LOG.setLevel(level)


def log(msg: str, status: int = 1) -> None:
    """Log a message.  status: 0=debug, 1=info, 2=warn, 3=error."""
    level = _STATUS_MAP.get(status, logging.INFO)
    _LOG.log(level, msg)


# ---------------------------------------------------------------------------
# Exceptions
# ---------------------------------------------------------------------------

class ThemeError(Exception):
    """Base exception for theme generation errors."""


class ThemeLoadError(ThemeError):
    """Raised when ~/.theme.json cannot be loaded or is invalid."""


class ThemeValidationError(ThemeError):
    """Raised when theme data is missing expected keys or has bad values."""


class MissingDependencyError(ThemeError):
    """Raised when a required external tool is not installed."""

    def __init__(self, tools: list[str]) -> None:
        self.tools = tools
        super().__init__(f"Missing required tools: {', '.join(tools)}")


# ---------------------------------------------------------------------------
# Mode type
# ---------------------------------------------------------------------------

class Mode(str, Enum):
    DARK = "dark"
    LIGHT = "light"


# ---------------------------------------------------------------------------
# Theme TypedDicts
# ---------------------------------------------------------------------------

class ColorEntry(TypedDict):
    color: str


class ThemeColors(TypedDict, total=False):
    background: dict[str, ColorEntry]
    on_background: dict[str, ColorEntry]
    surface: dict[str, ColorEntry]
    on_surface: dict[str, ColorEntry]
    surface_variant: dict[str, ColorEntry]
    surface_bright: dict[str, ColorEntry]
    surface_container_low: dict[str, ColorEntry]
    surface_container: dict[str, ColorEntry]
    surface_container_high: dict[str, ColorEntry]
    surface_container_highest: dict[str, ColorEntry]
    primary: dict[str, ColorEntry]
    on_primary: dict[str, ColorEntry]
    primary_fixed_dim: dict[str, ColorEntry]
    secondary: dict[str, ColorEntry]
    secondary_container: dict[str, ColorEntry]
    on_secondary_container: dict[str, ColorEntry]
    tertiary: dict[str, ColorEntry]
    tertiary_container: dict[str, ColorEntry]
    error: dict[str, ColorEntry]
    on_error: dict[str, ColorEntry]
    outline: dict[str, ColorEntry]
    outline_variant: dict[str, ColorEntry]
    shadow: dict[str, ColorEntry]
    scrim: dict[str, ColorEntry]
    on_surface_variant: dict[str, ColorEntry]


class Base16Colors(TypedDict, total=False):
    base00: dict[str, ColorEntry]
    base01: dict[str, ColorEntry]
    base02: dict[str, ColorEntry]
    base03: dict[str, ColorEntry]
    base04: dict[str, ColorEntry]
    base05: dict[str, ColorEntry]
    base06: dict[str, ColorEntry]
    base07: dict[str, ColorEntry]
    base08: dict[str, ColorEntry]
    base09: dict[str, ColorEntry]
    base0A: dict[str, ColorEntry]
    base0B: dict[str, ColorEntry]
    base0C: dict[str, ColorEntry]
    base0D: dict[str, ColorEntry]
    base0E: dict[str, ColorEntry]
    base0F: dict[str, ColorEntry]


class ThemeData(TypedDict, total=False):
    is_dark_mode: bool
    colors: ThemeColors
    base16: Base16Colors


# ---------------------------------------------------------------------------
# Opacity scale (0–255 byte values)
# ---------------------------------------------------------------------------

OPACITY_HOVER = 15
OPACITY_SUBTLE = 38
OPACITY_BORDER = 51
OPACITY_MEDIUM = 77
OPACITY_INACTIVE = 97
OPACITY_BORDER_FOCUS = 102
OPACITY_DEFAULT = 128
OPACITY_DIM = 153
OPACITY_OPAQUE = 255

# Qt-specific alpha values for inactive/disabled states
QT_ALPHA_INACTIVE = 0xb3
QT_ALPHA_DISABLED = 0x80

# ---------------------------------------------------------------------------
# Subprocess helpers
# ---------------------------------------------------------------------------

CMD_TIMEOUT = 5  # seconds


def run_cmd(
    cmd: list[str],
    *,
    capture: bool = False,
    check: bool = False,
    timeout: float = CMD_TIMEOUT,
    feed_stdin: str | None = None,
) -> subprocess.CompletedProcess:
    """Run an external command with consistent error handling and timeout.

    Args:
        cmd: Command and arguments as a list.
        capture: If True, capture stdout and stderr.
        check: If True, raise CalledProcessError on non-zero exit.
        timeout: Maximum seconds to wait before TimeoutExpired.
        feed_stdin: String to write to the process's stdin, if any.
    """
    log(f"Running: {' '.join(cmd)}", 0)
    try:
        return subprocess.run(
            cmd,
            input=feed_stdin,
            capture_output=capture,
            text=True,
            check=check,
            timeout=timeout,
        )
    except FileNotFoundError:
        log(f"Command not found: {cmd[0]}", 3)
        raise
    except subprocess.TimeoutExpired:
        log(f"Command timed out ({timeout}s): {' '.join(cmd)}", 2)
        raise
    except subprocess.CalledProcessError as exc:
        log(f"Command failed (exit {exc.returncode}): {' '.join(cmd)}", 3)
        raise


# ---------------------------------------------------------------------------
# Dependency checks
# ---------------------------------------------------------------------------

def check_deps(names: list[str]) -> None:
    """Verify required binaries exist.  Raises MissingDependencyError."""
    missing = [n for n in names if shutil.which(n) is None]
    if missing:
        for name in missing:
            log(f"Missing required tool: {name}", 3)
        raise MissingDependencyError(missing)


# ---------------------------------------------------------------------------
# File I/O
# ---------------------------------------------------------------------------

def atomic_write(path: Path, content: str) -> None:
    """Write *content* to *path* atomically via temp-file + os.replace().

    The temp file is created in the same directory as *path* to ensure
    they are on the same filesystem (required for atomic rename).
    """
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp_path = tempfile.mkstemp(
        dir=str(path.parent), prefix=".atomic_", suffix=".tmp"
    )
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            f.write(content)
            f.flush()
            os.fsync(f.fileno())
        os.replace(tmp_path, str(path))
    except Exception:
        try:
            os.unlink(tmp_path)
        except OSError:
            pass
        raise


# ---------------------------------------------------------------------------
# Theme helpers
# ---------------------------------------------------------------------------

THEME_PATH = Path.home() / ".theme.json"

# Material Design 3 color roles that must be present for valid theme generation.
REQUIRED_COLOR_ROLES = [
    "background",
    "on_background",
    "surface",
    "on_surface",
    "primary",
    "on_primary",
    "secondary",
    "tertiary",
    "error",
    "on_error",
    "outline",
    "outline_variant",
    "surface_variant",
    "surface_bright",
    "surface_container_low",
    "surface_container",
    "surface_container_high",
    "surface_container_highest",
    "secondary_container",
    "on_secondary_container",
    "tertiary_container",
    "primary_fixed_dim",
    "shadow",
    "scrim",
    "on_surface_variant",
]


def load_theme(path: Path = THEME_PATH) -> ThemeData:
    """Load and validate ~/.theme.json.

    Returns:
        Parsed theme data as a TypedDict.

    Raises:
        ThemeLoadError: If the file is missing, not valid JSON, or missing 'colors'.
        ThemeValidationError: If required color roles are missing.
    """
    if not path.exists():
        raise ThemeLoadError(f"Theme file not found: {path}")
    try:
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
    except json.JSONDecodeError as exc:
        raise ThemeLoadError(f"Invalid JSON in {path}: {exc}") from exc

    if "colors" not in data:
        raise ThemeLoadError(f"Theme JSON missing 'colors' key: {path}")

    validate_theme(data)
    return data


def validate_theme(data: ThemeData) -> None:
    """Validate that theme data has all required color roles.

    Raises:
        ThemeValidationError: If required roles are missing.
    """
    colors = data.get("colors", {})
    mode = "dark" if data.get("is_dark_mode", False) else "light"
    missing = []
    for role in REQUIRED_COLOR_ROLES:
        if role not in colors:
            missing.append(role)
        elif mode not in colors[role]:
            missing.append(f"{role} ({mode})")
        elif "color" not in colors[role][mode]:
            missing.append(f"{role}.{mode}.color")
    if missing:
        raise ThemeValidationError(
            f"Theme missing required color roles: {', '.join(missing)}"
        )


def get_mode(data: ThemeData) -> Mode:
    """Extract the mode from theme data."""
    return Mode.DARK if data.get("is_dark_mode", False) else Mode.LIGHT


def get_color(
    colors: ThemeColors,
    name: str,
    mode: Mode,
    *,
    default: str | None = None,
) -> str:
    """Safely fetch a hex color from the theme.

    Args:
        colors: The colors dict from theme data.
        name: Material Design 3 color role (e.g. "primary").
        mode: Dark or light mode.
        default: Fallback value if the key is missing.  If None, raises.

    Returns:
        Hex color string like "#bb86fc".

    Raises:
        ThemeValidationError: If the key is missing and no default provided.
    """
    try:
        return colors[name][mode.value]["color"]
    except KeyError:
        if default is not None:
            log(f"Missing color '{name}' for mode '{mode.value}', using default", 2)
            return default
        raise ThemeValidationError(
            f"Missing color '{name}' for mode '{mode.value}' in theme data"
        )


def color_accessor(
    colors: ThemeColors,
    mode: Mode,
    *,
    default: str | None = None,
) -> dict[str, str]:
    """Return a lazy dict-like accessor for theme colors.

    Colors are resolved on first access (not eagerly computed).
    Missing keys fall back to *default* if provided, otherwise raise
    ThemeValidationError.

    Usage::

        color = color_accessor(colors, mode, default="#808080")
        color["primary"]   # → "#bb86fc"
        color["missing"]   # → "#808080" (logged warning)
    """
    _colors = colors
    _mode = mode
    _default = default

    class ColorMap(dict):
        def __missing__(self, key: str) -> str:
            val = get_color(_colors, key, _mode, default=_default)
            self[key] = val
            return val

    return ColorMap()


# ---------------------------------------------------------------------------
# Opacity helpers
# ---------------------------------------------------------------------------

def hex_to_rgba(hex_color: str, opacity_byte: int) -> str:
    """Convert #rrggbb to rgba(r, g, b, opacity/255).

    Args:
        hex_color: 6-digit hex color like "#bb86fc".
        opacity_byte: Opacity as 0-255 byte value (0=transparent, 255=opaque).

    Returns:
        CSS rgba() string.
    """
    r = int(hex_color[1:3], 16)
    g = int(hex_color[3:5], 16)
    b = int(hex_color[5:7], 16)
    return f"rgba({r}, {g}, {b}, {opacity_byte / 255:.2f})"
