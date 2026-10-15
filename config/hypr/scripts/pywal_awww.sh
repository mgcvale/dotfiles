#!/bin/bash
wallpaper_path=$(awww query | sed -n 's/^.*image: //p' | head -n 1)
if [[ -f "$wallpaper_path" ]]; then
    ln -sfn "$wallpaper_path" "$HOME/.config/rofi/.current_wallpaper"
    wal -i "$wallpaper_path" -s -t
    python3 "$HOME/.config/waybar/scripts/portfolio_surface.py"
fi
