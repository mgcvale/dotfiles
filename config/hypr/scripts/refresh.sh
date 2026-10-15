#!/bin/bash
# Scripts for refreshing waybar, rofi, swaync, pywal colors



# Kill already running processes
_ps=(waybar rofi swaync)
for _prs in "${_ps[@]}"; do
    if pidof "${_prs}" >/dev/null; then
        pkill "${_prs}"
    fi
done

sleep 0.3
# Relaunch waybar
waybar &

# relaunch swaync
sleep 0.5
swaync > /dev/null 2>&1 &

wal -R
python3 "$HOME/.config/waybar/scripts/portfolio_surface.py"
exit 0
