#!/bin/bash
# Universal Wallpaper Setter with Thumbnail-Based Pywal for Videos

file="$1"
ext="${file##*.}"
WALLPAPER_DIR="$HOME/Downloads/my_wallpapers"
THUMB_DIR="$WALLPAPER_DIR/thumbnails"

# Verify file exists
if [[ ! -f "$file" ]]; then
    notify-send "Error" "File not found: $file"
    exit 1
fi

# Kill existing wallpaper processes
pkill -f "mpvpaper" || true
pkill -f "hyprpaper" || true
sleep 0.2

case "$ext" in
    mp4|mov|gif)
        # Set video wallpaper (unchanged)
        if ! command -v mpvpaper &>/dev/null; then
            notify-send "Error" "mpvpaper not installed!\nInstall with: yay -S mpvpaper"
            exit 1
        fi
        mpvpaper -o "--loop --no-audio" "*" "$file" &
        
        # ===== KEY CHANGE: Use thumbnail for Pywal =====
        thumb="$THUMB_DIR/$(basename "${file%.*}").png"
        if [[ -f "$thumb" ]]; then
            wal -i "$thumb" -n -q  # Extract colors from thumbnail
        else
            notify-send "Pywal Error" "Thumbnail not found: $thumb"
        fi
        ;;

    png|jpg|jpeg|webp)
        # Set image wallpaper (unchanged)
        if ! command -v hyprpaper &>/dev/null; then
            notify-send "Error" "hyprpaper not installed!\nInstall with: yay -S hyprpaper"
            exit 1
        fi
        TMP_CONFIG="/tmp/hyprpaper.conf"
        echo "preload = $file" > "$TMP_CONFIG"
        while read -r mon; do
            echo "wallpaper = $mon,$file" >> "$TMP_CONFIG"
        done < <(hyprctl monitors | grep "Monitor" | awk '{print $2}')
        hyprpaper -c "$TMP_CONFIG" &
        
        # Run Pywal on the wallpaper itself
        wal -i "$file" -n -q
        ;;
esac

# Update PywalFox (if installed)
if command -v pywalfox &>/dev/null; then
    pywalfox update
else
    notify-send "PywalFox Warning" "pywalfox not installed (Firefox theming disabled)"
fi

notify-send "Wallpaper Set" "Applied: $(basename "$file")"
exit 0
