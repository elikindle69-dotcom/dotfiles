#!/usr/bin/env python3

from pathlib import Path

import jinja2

import _common as c

TEMPLATES_DIR = Path(__file__).parent / "templates"
THEME_DIR = Path.home() / ".themes" / "MaterialTheme"

SUCCESS_COLOR = "#2e7d32"

INDEX_THEME = """\
[Desktop Entry]
Type=X-GNOME-Metatheme
Name=MaterialTheme
Comment=Material Design 3 theme generated from ~/.theme.json
Encoding=UTF-8

[X-GNOME-Metatheme]
GtkTheme=MaterialTheme
ButtonLayout=close,minimize,maximize:
"""

GTK3_SETTINGS = """\
[Settings]
gtk-button-images=false
gtk-menu-images=false
"""

_jinja_env = jinja2.Environment(
    loader=jinja2.FileSystemLoader(str(TEMPLATES_DIR)),
    keep_trailing_newline=True,
    undefined=jinja2.StrictUndefined,
)


def _render(template_name: str, theme: c.ThemeData) -> str:
    colors = theme["colors"]
    mode = c.get_mode(theme)
    color = c.color_accessor(colors, mode)

    try:
        template = _jinja_env.get_template(template_name)
    except jinja2.TemplateNotFound:
        raise c.ThemeError(f"GTK template not found: {template_name}")

    bg = color["surface"]
    fg = color["on_surface"]
    base = color["surface_container_low"]
    sel_bg = color["primary"]
    sel_fg = color["on_primary"]
    border = color["outline_variant"]
    headerbar_bg = color["surface_container"]
    menu_bg = color["surface_container"]
    tooltip_bg = color["surface_container_high"]

    return template.render(
        bg=bg,
        fg=fg,
        base=base,
        sel_bg=sel_bg,
        sel_fg=sel_fg,
        border=border,
        headerbar_bg=headerbar_bg,
        menu_bg=menu_bg,
        tooltip_bg=tooltip_bg,
        color=color,
        rgba=c.hex_to_rgba,
        success_color=SUCCESS_COLOR,
        OP_HOVER=c.OPACITY_HOVER,
        OP_SUBTLE=c.OPACITY_SUBTLE,
        OP_BORDER=c.OPACITY_BORDER,
        OP_MEDIUM=c.OPACITY_MEDIUM,
        OP_INACTIVE=c.OPACITY_INACTIVE,
        OP_BORDER_FOCUS=c.OPACITY_BORDER_FOCUS,
        OP_DEFAULT=c.OPACITY_DEFAULT,
        OP_DIM=c.OPACITY_DIM,
    )


def write():
    theme = c.load_theme()

    gtk3_dir = THEME_DIR / "gtk-3.0"
    gtk4_dir = THEME_DIR / "gtk-4.0"

    THEME_DIR.mkdir(parents=True, exist_ok=True)
    c.atomic_write(THEME_DIR / "index.theme", INDEX_THEME)
    c.log(f"Wrote: {THEME_DIR / 'index.theme'}")

    gtk3_dir.mkdir(parents=True, exist_ok=True)
    c.atomic_write(gtk3_dir / "gtk.css", _render("gtk3.css.j2", theme))
    c.log(f"Wrote: {gtk3_dir / 'gtk.css'}")
    c.atomic_write(gtk3_dir / "gtk-dark.css", _render("gtk3.css.j2", theme))
    c.log(f"Wrote: {gtk3_dir / 'gtk-dark.css'}")
    c.atomic_write(gtk3_dir / "settings.ini", GTK3_SETTINGS)
    c.log(f"Wrote: {gtk3_dir / 'settings.ini'}")

    gtk4_dir.mkdir(parents=True, exist_ok=True)
    c.atomic_write(gtk4_dir / "gtk.css", _render("gtk4.css.j2", theme))
    c.log(f"Wrote: {gtk4_dir / 'gtk.css'}")

    try:
        result = c.run_cmd(
            ["gsettings", "set", "org.gnome.desktop.interface", "gtk-theme", "MaterialTheme"],
            capture=True,
        )
        if result.returncode != 0:
            c.log(
                f"Failed to set gtk-theme: {result.stderr.strip() or 'unknown error'}",
                2,
            )
        else:
            c.log("Set gtk-theme to MaterialTheme")
    except FileNotFoundError:
        c.log("gsettings not found, skipping gtk-theme apply", 2)
    except Exception as exc:
        c.log(f"gtk-theme apply failed: {exc}", 2)


if __name__ == "__main__":
    write()
