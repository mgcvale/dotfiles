#!/bin/bash
#
# /* --- https://github.com/mgcvale --- */
#
# Script for changing the refresh rate for the ThinkPad T480,
# from 48hz to 60hz.
#

notif="$HOME/.config/swaync/images/bell.png"

STATE=$(xrandr | grep -c "47.98")

if [ "${STATE}" == "1" ]; then
	hyprctl keyword monitor eDP-1,1920x1080@60.01,0x0,1
	notify-send -e -u low -i "$notif" "Refresh rate set to 60Hz"
else
	hyprctl keyword monitor eDP-1,1920x1080@48.01,0x0,1
	notify-send -e -u low -i "$notif" "Refresh rate set to 48Hz"
fi
