#!/bin/bash

# https://github.mgcvale
# Script for changing mouse sensitivity

notif="$HOME/.config/swaync/images/bell.png"
STATE=$(hyprctl -j getoption general:sensitivity | jq ".float")
echo "${STATE}"
if [ "${STATE}" == 0.900000 ]; then
	hyprctl keyword general:sensitivity 0.5
	notify-send -e -u low -i "$notif" "Low sensitivity"
else
	hyprctl keyword general:sensitivity 0.90
	notify-send -e -u low -i "$notif" "High sensitivity"
fi
