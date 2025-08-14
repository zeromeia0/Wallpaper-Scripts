#!/bin/bash
# Universal Wallpaper Setter - Fixed Version

file="$1"
ext="${file##*.}"

# Verify file exists
if [[ ! -f "$file" ]]; then
    notify-send "Error" "File not found: $file"
    exit 1
fi

# Kill existing wallpaper processes
pkill -f "mpvpaper" || true
pkill -f "feh" || true
sleep 0.2

case "$ext" in
    mp4|mov|gif)
        if ! command -v mpvpaper &>/dev/null; then
            notify-send "Error" "mpvpaper not installed!\nInstall with: yay -S mpvpaper"
            exit 1
        fi
        mpvpaper -o "--loop --no-audio" "*" "$file" &
        ;;

	png|jpg|jpeg|webp)
	    if ! command -v hyprpaper &>/dev/null; then
	        notify-send "Error" "hyprpaper not installed!\nInstall with: yay -S hyprpaper"
	        exit 1
	    fi
	
	    # Kill existing hyprpaper instances
	    pkill -f hyprpaper || true
	    sleep 0.2
	
	    # Create a temporary config
	    TMP_CONFIG="/tmp/hyprpaper.conf"
	    echo "preload = $file" > "$TMP_CONFIG"
	
	    # Add wallpaper line for each monitor
	    while read -r mon; do
	        echo "wallpaper = $mon,$file" >> "$TMP_CONFIG"
	    done < <(hyprctl monitors | grep "Monitor" | awk '{print $2}')
	
	    # Launch hyprpaper with this config
	    hyprpaper -c "$TMP_CONFIG" &
	    ;;

    *)
        notify-send "Error" "Unsupported format: .$ext"
        exit 1
        ;;
esac

notify-send "Wallpaper Set" "Applied: $(basename "$file")"
exit 0
