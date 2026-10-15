#!/bin/bash

# https://github.mgcvale
# Script for changing mouse sensitivity

notif="$HOME/.config/swaync/images/bell.png"
STATE=$(hyprctl -j getoption input:sensitivity | jq ".float")
echo "${STATE}"
if [ "${STATE}" != -0.500000 ]; then
	hyprctl keyword input:sensitivity -0.5
	notify-send -e -u low -i "$notif" "Low sensitivity"
else
	hyprctl keyword input:sensitivity 0
	notify-send -e -u low -i "$notif" "High sensitivity"
fi
