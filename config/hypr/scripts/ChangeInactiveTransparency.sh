#!/bin/bash

# /* --- https://github.com/mgcvale --- */
#
# Script for changing the amount of blur and dimming
# on inactive windows

notif="$HOME/.config/swaync/images/bell.png"

STATE=$(hyprctl -j getoption decoration:dim_inactive | jq ".int")
echo "${STATE}"

if [ "${STATE}" == 1 ]; then
	hyprctl keyword decoration:dim_inactive 0
	hykeyword decoration:inactive_opacity 1.5
	notify-send -e -u low -i "$notif" "More transparency"
else
	hyprctl keyword decoration:dim_inactive 1
	hyprctl keyword decoration:inactive_opacity 1.05
	notify-send -e -u low -i "$notif" "Less Transparency"
fi
