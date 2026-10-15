#!/usr/bin/env python3
"""Detect a wallpaper's mode, or apply/restore the desktop's shared theme mode."""

import argparse
import configparser
import fcntl
import io
import json
import math
import re
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile


DEFAULTS = {
    "default": "auto",
    "brightness_threshold": 0.5,
    "wallpapers": {"black.png": "dark", "white.png": "light"},
    "palette_backgrounds": {},
    "gtk_themes": {"light": "Adwaita", "dark": "Adwaita-dark"},
    "icon_themes": {"light": "breeze", "dark": "breeze-dark"},
}
MODES = ("light", "dark")
SCHEMA = "org.gnome.desktop.interface"


def load_config(home):
    config = {**DEFAULTS}
    path = home / ".config/theme/config.json"
    if path.exists():
        supplied = json.loads(path.read_text())
        for key, value in supplied.items():
            if key in ("wallpapers", "palette_backgrounds", "gtk_themes", "icon_themes"):
                config[key] = {**DEFAULTS[key], **value}
            else:
                config[key] = value
    if config["default"] not in (*MODES, "auto"):
        raise ValueError("theme default must be auto, light, or dark")
    if not 0 <= float(config["brightness_threshold"]) <= 1:
        raise ValueError("brightness_threshold must be between 0 and 1")
    if any(mode not in (*MODES, "auto") for mode in config["wallpapers"].values()):
        raise ValueError("wallpaper overrides must be auto, light, or dark")
    if any(not isinstance(color, str) or not re.fullmatch(r"#[0-9a-fA-F]{6}", color)
           for color in config["palette_backgrounds"].values()):
        raise ValueError("palette backgrounds must be #RRGGBB colors")
    return config


def detect_mode(wallpaper, config):
    wallpaper = wallpaper.expanduser().resolve(strict=True)
    overrides = config["wallpapers"]
    mode = overrides.get(str(wallpaper), overrides.get(wallpaper.name, config["default"]))
    if mode != "auto":
        return mode
    executable = shutil.which("magick") or shutil.which("convert")
    if not executable:
        raise RuntimeError("ImageMagick is required for automatic wallpaper brightness detection")
    result = subprocess.run(
        [executable, str(wallpaper) + "[0]", "-auto-orient", "-thumbnail", "64x64!",
         "-colorspace", "Gray", "-format", "%[fx:mean]", "info:"],
        capture_output=True, text=True, check=True, timeout=15,
    )
    brightness = float(result.stdout.strip())
    if not math.isfinite(brightness) or not 0 <= brightness <= 1:
        raise ValueError("ImageMagick returned an invalid wallpaper brightness")
    return "light" if brightness >= float(config["brightness_threshold"]) else "dark"


def write_if_changed(path, text):
    if path.exists() and path.read_text() == text:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    mode = path.stat().st_mode & 0o777 if path.exists() else 0o644
    with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, delete=False) as handle:
        temporary = Path(handle.name)
        handle.write(text)
    try:
        temporary.chmod(mode)
        temporary.replace(path)
    finally:
        temporary.unlink(missing_ok=True)


def gtk_settings(path, mode, theme, icons):
    settings = configparser.ConfigParser(interpolation=None)
    settings.optionxform = str
    if path.exists():
        settings.read(path)
    if not settings.has_section("Settings"):
        settings.add_section("Settings")
    desired = {
        "gtk-application-prefer-dark-theme": str(mode == "dark").lower(),
        "gtk-theme-name": theme,
        "gtk-icon-theme-name": icons,
    }
    if all(settings.get("Settings", key, fallback=None) == value for key, value in desired.items()):
        return
    for key, value in desired.items():
        settings.set("Settings", key, value)
    output = io.StringIO()
    settings.write(output, space_around_delimiters=False)
    write_if_changed(path, output.getvalue().rstrip() + "\n")


def set_preference(key, value):
    current = subprocess.run(["gsettings", "get", SCHEMA, key],
                             capture_output=True, text=True, check=True, timeout=5)
    if current.stdout.strip().strip("'\"") == value:
        return
    subprocess.run(["gsettings", "set", SCHEMA, key, value],
                   capture_output=True, text=True, check=True, timeout=5)


def restore_state(home):
    state_path = home / ".cache/theme/state.json"
    if state_path.exists():
        state = json.loads(state_path.read_text())
        if state.get("mode") in MODES:
            return state
    # Bootstrap from the existing palette, keeping the shell and apps aligned.
    palette_path = home / ".cache/wal/colors.json"
    if palette_path.exists():
        palette = json.loads(palette_path.read_text())
        color = palette["special"]["foreground"].lstrip("#")
        red, green, blue = (int(color[i:i + 2], 16) / 255 for i in (0, 2, 4))
        mode = "light" if .2126 * red + .7152 * green + .0722 * blue < .5 else "dark"
    else:
        mode = "dark"
    saved = home / ".config/rofi/.current_wallpaper"
    return {"mode": mode, "wallpaper": str(saved.resolve()) if saved.exists() else None}


def apply_mode(home, mode, wallpaper, config):
    theme = config["gtk_themes"][mode]
    icons = config["icon_themes"][mode]
    # The GTK portal publishes this preference to Follow System applications.
    set_preference("color-scheme", "prefer-" + mode)
    set_preference("gtk-theme", theme)
    set_preference("icon-theme", icons)
    for version in ("3.0", "4.0"):
        gtk_settings(home / f".config/gtk-{version}/settings.ini", mode, theme, icons)
    state = {"mode": mode, "wallpaper": wallpaper}
    write_if_changed(home / ".cache/theme/state.json", json.dumps(state, indent=2) + "\n")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    action = parser.add_mutually_exclusive_group()
    action.add_argument("--detect", type=Path, metavar="WALLPAPER",
                        help="print light/dark before pywal; do not change settings")
    action.add_argument("--palette-background", type=Path, metavar="WALLPAPER",
                        help="print an optional wallpaper palette background override")
    action.add_argument("--mode", choices=MODES, help="apply a previously chosen mode")
    action.add_argument("--restore", action="store_true", help="restore the saved mode (default)")
    parser.add_argument("--wallpaper", type=Path, help="record the selected wallpaper with --mode")
    args = parser.parse_args()
    if args.wallpaper and not args.mode:
        parser.error("--wallpaper requires --mode")
    home = Path.home()
    config = load_config(home)
    if args.palette_background:
        wallpaper = args.palette_background.expanduser().resolve(strict=True)
        backgrounds = config["palette_backgrounds"]
        print(backgrounds.get(str(wallpaper), backgrounds.get(wallpaper.name, "")))
        return
    if args.detect:
        print(detect_mode(args.detect, config))
        return
    cache = home / ".cache/theme"
    cache.mkdir(parents=True, exist_ok=True)
    with (cache / "sync.lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        if args.mode:
            saved = home / ".config/rofi/.current_wallpaper"
            wallpaper = args.wallpaper or (saved.resolve() if saved.exists() else None)
            state = {"mode": args.mode, "wallpaper": str(wallpaper.resolve()) if wallpaper else None}
        else:
            state = restore_state(home)
        apply_mode(home, state["mode"], state.get("wallpaper"), config)
    print(state["mode"])


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, KeyError, TypeError, subprocess.SubprocessError) as error:
        print(f"sync_theme: {error}", file=sys.stderr)
        sys.exit(1)
