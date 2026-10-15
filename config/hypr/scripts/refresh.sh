#!/bin/bash
# Scripts for refreshing waybar, rofi, swaync, pywal colors
set -euo pipefail

# Finish palette generation before restarting apps; do not block in xrdb.
if [[ -f "$HOME/.cache/wal/colors.json" ]]; then
    wal -n -e -t -R
    python3 "$HOME/.config/hypr/scripts/sync_theme.py" --restore
    python3 "$HOME/.config/waybar/scripts/portfolio_surface.py"
    if [[ -f "$HOME/.config/rofi/scripts/sync_palette.py" ]]; then
        python3 "$HOME/.config/rofi/scripts/sync_palette.py"
    fi
fi
# Kill already running processes
_ps=(waybar rofi swaync)
for _prs in "${_ps[@]}"; do
    if pidof "${_prs}" >/dev/null; then
        pkill -x "${_prs}" || true
    fi
done

sleep 0.3
# Relaunch waybar
waybar &

# relaunch swaync
sleep 0.5
swaync > /dev/null 2>&1 &

exit 0
