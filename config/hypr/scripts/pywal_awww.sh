#!/bin/bash
# Update colors without restarting the bar or notification daemon.
set -euo pipefail

wallpaper_path="${1:-}"
if [[ -z "$wallpaper_path" ]]; then
    wallpaper_path=$(awww query | sed -n 's/^.*image: //p' | head -n 1)
fi
[[ -f "$wallpaper_path" ]] || exit 1
wallpaper_path=$(readlink -f -- "$wallpaper_path")
ln -sfn -- "$wallpaper_path" "$HOME/.config/rofi/.current_wallpaper"

theme_sync="$HOME/.config/hypr/scripts/sync_theme.py"
mode=$(python3 "$theme_sync" --detect "$wallpaper_path")

run_wal() {
    local magick_real
    magick_real=$(command -v magick || true)
    if [[ -n "$magick_real" ]]; then
        PYWAL_MAGICK_REAL="$magick_real" PATH="$HOME/.config/hypr/scripts/pywal-bin:$PATH" wal "$@"
    else
        wal "$@"
    fi
}

# awww owns the wallpaper. Skip X11 reload helpers: xrdb can block on Wayland.
case "${wallpaper_path##*/}" in
    black.png|white.png) run_wal -n -e -t -f "$HOME/.config/wal/palettes/$mode.json" ;;
    *)
        light_args=()
        [[ "$mode" == light ]] && light_args=(-l)
        background_args=()
        background=$(python3 "$theme_sync" --palette-background "$wallpaper_path")
        [[ -n "$background" ]] && background_args=(-b "$background")
        run_wal -n -e -t "${light_args[@]}" "${background_args[@]}" -i "$wallpaper_path"
        ;;
esac

python3 "$theme_sync" --mode "$mode" --wallpaper "$wallpaper_path"
python3 "$HOME/.config/waybar/scripts/portfolio_surface.py"
if [[ -f "$HOME/.config/rofi/scripts/sync_palette.py" ]]; then
    python3 "$HOME/.config/rofi/scripts/sync_palette.py"
fi
# Waybar watches its CSS. SwayNC needs a style refresh, not a process restart.
if command -v swaync-client >/dev/null; then
    timeout 3 swaync-client -rs >/dev/null 2>&1 || true
fi
