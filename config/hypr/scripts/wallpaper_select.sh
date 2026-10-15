#!/bin/bash
# This script for selecting wallpapers (SUPER W)

SCRIPTSDIR="$HOME/.config/hypr/scripts"

# WALLPAPERS PATH
wallDIR="$HOME/Pictures/wallpapers"

# Transition config
FPS=30
TYPE="wipe"
DURATION=1
BEZIER=".43,1.19,1,.4"
AWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION"

# Check if swaybg is running
if pidof swaybg >/dev/null; then
	pkill swaybg
fi

# Retrieve image files
PICS=($(ls "${wallDIR}" | grep -E ".jpg$|.jpeg$|.png$|.gif$"))
RANDOM_PIC="${PICS[$((RANDOM % ${#PICS[@]}))]}"
RANDOM_PIC_NAME="${#PICS[@]}. random"

# Rofi command
rofi_command="rofi -show -dmenu -config ~/.config/rofi/config_wallpaper.rasi"

menu() {
	for i in "${!PICS[@]}"; do
		# Displaying .gif to indicate animated images
		if [[ -z $(echo "${PICS[$i]}" | grep .gif$) ]]; then
			printf "$(echo "${PICS[$i]}" | cut -d. -f1)\x00icon\x1f${wallDIR}/${PICS[$i]}\n"
		else
			printf "${PICS[$i]}\n"
		fi
	done

	printf "$RANDOM_PIC_NAME\n"
}

"${SCRIPTSDIR}/start_wallpaper.sh"

main() {
	choice=$(menu | ${rofi_command})

	# No choice case
	if [[ -z $choice ]]; then
		exit 0
	fi

	# Random choice case
	if [ "$choice" = "$RANDOM_PIC_NAME" ]; then
		awww img "${wallDIR}/${RANDOM_PIC}" $AWWW_PARAMS
		wal -i "${wallDIR}/${RANDOM_PIC}"
		python3 "$HOME/.config/waybar/scripts/portfolio_surface.py"
		exit 0
	fi

	# Find the index of the selected file
	pic_index=-1
	for i in "${!PICS[@]}"; do
		filename=$(basename "${PICS[$i]}")
		if [[ "$filename" == "$choice"* ]]; then
			pic_index=$i
			break
		fi
	done

	if [[ $pic_index -ne -1 ]]; then
        selected_pic="${PICS[$pic_index]}"
		awww img "${wallDIR}/$selected_pic" $AWWW_PARAMS
        # hard code ceirtain palletes for specific black and white wallpapers
        if [[ "$selected_pic" == *"black.png" ]]; then
            wal -f "$HOME/.config/wal/palettes/dark.json"
        elif [[ "$selected_pic" == *"white.png" ]]; then
            wal -f "$HOME/.config/wal/palettes/light.json"
        else
            wal -i "${wallDIR}/$selected_pic"
        fi
	else
		echo "Image not found."
		exit 1
	fi
}

# Check if rofi is already running
if pidof rofi >/dev/null; then
	pkill rofi
	exit 0
fi

main

sleep 0.5
${SCRIPTSDIR}/pywal_awww.sh
sleep 0.2
${SCRIPTSDIR}/refresh.sh
