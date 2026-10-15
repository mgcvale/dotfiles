#!/bin/bash
# Opening/cancelling the picker never changes the current wallpaper.
set -euo pipefail

scripts_dir="$HOME/.config/hypr/scripts"
wallpaper_dir="$HOME/Pictures/wallpapers"

# Keep the hotkey's toggle behavior. The lock covers the menu, not pywal.
if pgrep -x rofi >/dev/null; then
    pkill -x rofi || true
    exit 0
fi
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/wallpaper-select-${UID}.lock"
flock -n 9 || exit 0

mapfile -d '' -t pictures < <(
    find -L "$wallpaper_dir" -maxdepth 1 -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \
           -o -iname '*.gif' -o -iname '*.webp' \) -printf '%f\0' | sort -z
)
if (( ${#pictures[@]} == 0 )); then
    printf 'No wallpapers found in %s\n' "$wallpaper_dir" >&2
    exit 1
fi

menu() {
    local picture
    for picture in "${pictures[@]}"; do
        printf '%s\0icon\x1f%s\n' "${picture%.*}" "$wallpaper_dir/$picture"
    done
    printf '%s. random\n' "${#pictures[@]}"
}

# Indices handle spaces, dots, percent signs, and duplicate display names.
choice=$(menu | rofi -dmenu -format i -config "$HOME/.config/rofi/config_wallpaper.rasi") || exit 0
[[ "$choice" =~ ^[0-9]+$ ]] || exit 0
index=$((10#$choice))
if (( index == ${#pictures[@]} )); then
    index=$((RANDOM % ${#pictures[@]}))
elif (( index >= ${#pictures[@]} )); then
    exit 1
fi

selected="$wallpaper_dir/${pictures[$index]}"
# Let the picker reopen while color extraction runs. A new choice supersedes
# the old worker instead of queuing another palette that may apply much later.
flock -u 9
exec 9>&-
python3 "$scripts_dir/wallpaper_job.py" "$selected"
