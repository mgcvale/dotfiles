### Screenshots
<img src="shots/hypr4.png" width="660px">
<img src="shots/hypr1.jpg" width="660px">
<img src="shots/hypr3.png" width="660px">

### KDE

<img src="shots/kde.png" width="660px">

## Installation

- Install the desktop dependencies listed in `packages.txt`. Building the Waybar underline also needs a C compiler, `pkg-config`, and GTK 3 development headers/libraries (`gtk3-devel` on openSUSE).
- Copy the contents of `config/` into `~/.config`, preserving symlinks and executable permissions. The current Hyprland config lives in `config/hypr/`; there is no separate top-level Hyprland config to install.
- Run `systemctl --user daemon-reload` after copying the included Hyprland session target. Hyprland's startup commands start it after publishing the display environment, which lets the desktop portal expose the system theme preference.
- Install the bundled Bricolage Grotesque font and build the underline module:

```sh
mkdir -p ~/.local/share/fonts/BricolageGrotesque
cp font/BricolageGrotesque/* ~/.local/share/fonts/BricolageGrotesque/
fc-cache -f ~/.local/share/fonts/BricolageGrotesque
sh ~/.config/waybar/cffi/build.sh
```

- Before the first Hyprland start, initialize pywal's generated colors and the bar's surface tint:

```sh
wal -n -e -t -f ~/.config/wal/palettes/dark.json
python3 ~/.config/waybar/scripts/portfolio_surface.py
python3 ~/.config/hypr/scripts/sync_theme.py --restore
```

- Copy `firefox/chrome` into your Firefox profile and set `toolkit.legacyUserProfileCustomizations.stylesheets` to `true` in `about:config`.

These are personal dotfiles; some paths target `/home/mgcv`. Adjust those paths when installing under another account. The wallpaper scripts use `~/Pictures/wallpapers`; the images are in `wallpaper/` in this repository.

### Waybar and themes

The default `portfolio` theme uses pywal colors, translucent glass, Bricolage Grotesque, and a shared sliding workspace underline. Workspace numbers and battery text are 14px; the clock is 16px. The black and white palettes have their own subtle surface tints. `crystal_pywal` remains available through **Super + Ctrl + B**.

**Super + W** opens the wallpaper picker without restoring or changing the current image. Selecting an image saves that exact path and starts one background pywal job, including the custom black/white palettes. The menu can reopen while colors are generating; a new selection cancels the previous worker and its child processes so an old palette cannot apply later. Waybar reloads its colors in place; wallpaper changes do not restart it. **Super + Alt + R** remains the explicit desktop refresh. The scripts skip pywal's X11 reload helpers so `xrdb` cannot leave delayed refresh jobs behind in the Wayland session.

The pywal-only ImageMagick adapter in `config/hypr/scripts/pywal-bin/magick` uses INFO output instead of the restricted TXT encoder and fills sparse palettes without repeated quantization attempts. It preserves normal pywal color adjustment and caching, and does not change the system ImageMagick policy. The most recent worker log is `~/.cache/theme/wallpaper-worker.log`.

### Shared light/dark mode

`config/hypr/scripts/sync_theme.py` chooses light/dark mode before pywal runs, then synchronizes the standard desktop preference, Adwaita's GTK theme variant, and Breeze icons. Waybar, Rofi, terminals, and notifications use the matching pywal palette. Apps configured to follow the system receive the preference through the GTK desktop portal. Qt-specific palette configuration is separate and can use this same mode later.

`~/.config/theme/config.json` controls automatic brightness detection and per-wallpaper overrides. A wallpaper's average grayscale brightness of 0.5 or higher selects light mode; lower brightness selects dark. `black.png`, `white.png`, `mantra.png` (dark), and `japan-street-Light.png` (light) have explicit overrides. Add another filename or an absolute image path to `wallpapers` with `light`, `dark`, or `auto` to override detection. The same file configures the light/dark GTK and icon theme pairs. Optional `palette_backgrounds` entries map filenames or absolute paths to `#RRGGBB` colors; Japan Street Light uses a muted blue-gray (`#b7c0c7`) rather than pywal’s near-white light background, while retaining its generated accent colors. Apps following the system still use their own light appearance.

The current mode and wallpaper are saved in `~/.cache/theme/state.json` and restored once on login. Preferences and settings files are updated only when their values change. There is no theme polling service, and wallpaper changes do not restart Waybar. To inspect a wallpaper's mode without changing settings, run:

```sh
python3 ~/.config/hypr/scripts/sync_theme.py --detect /path/to/wallpaper.png
```

The underline's source, and rebuild instructions are in [config/waybar/cffi](config/waybar/cffi/README.md). Its shared library and Python bytecode are generated locally and are not tracked. Rebuild and restart Waybar after changing its C source.

Hyprland configs and scripts use the flat `configs/` and `scripts/` layout with snake_case filenames. The obsolete duplicate config tree, extra Waybar layouts and themes, Rofi resolution variants, unused icons, and old Qt/Kvantum themes have been removed. Desktop animations remain disabled; the Waybar underline animates independently.

### Keybinds

I have custom keybinds setup in hyprland (capslk + j for left arrow, capslk + m for delete, etc).
For them to run properly, you must install keyd, and apply the propper configs (see /etc/keyd/default.conf)
