#!/bin/bash
#
# Script for toggling the noise shader in Hyprland
#
# This doesn't work for some reason

# Paths
SHADER_PATH="$HOME/.config/hypr/shaders/noise.frag"
NOTIF_ICON="$HOME/.config/swaync/images/bell.png"

# Check if shader is currently active by looking at the raw value
# This will return empty string ("") when disabled
CURRENT_SHADER=$(hyprctl getoption decoration:screen_shader -j | jq -r '.str')

if [ -n "$CURRENT_SHADER" ]; then
    # Shader is active (string not empty), disable it
    hyprctl keyword decoration:screen_shader \"\"
    notify-send -e -u low -i "$NOTIF_ICON" "Noise shader disabled"
else
    # Shader is inactive (string empty), enable it
    hyprctl keyword decoration:screen_shader "$SHADER_PATH"
    notify-send -e -u low -i "$NOTIF_ICON" "Noise shader enabled"
fi
