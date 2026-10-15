#!/bin/bash
set -euo pipefail

if ! awww query >/dev/null 2>&1; then
    awww-daemon &
fi

for _ in {1..50}; do
    if awww query >/dev/null 2>&1; then
        break
    fi
    sleep 0.1
done

awww query >/dev/null

wallpaper="$HOME/.config/rofi/.current_wallpaper"
if [[ -f "$wallpaper" ]]; then
    awww img "$(readlink -f "$wallpaper")" --transition-type none
else
    awww restore
fi
