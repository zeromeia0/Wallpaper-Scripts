#!/bin/bash
# Thumbnail Wallpaper Selector (poster-style crop) with Ctrl+Alt+Arrow Navigation

WALLPAPER_DIR="$HOME/Downloads/my_wallpapers"
THUMB_DIR="$WALLPAPER_DIR/thumbnails"
mkdir -p "$THUMB_DIR"

# Generate thumbnails with 15% width crop
generate_thumbs() {
    find "$WALLPAPER_DIR" -maxdepth 1 -type f \( \
        -iname '*.jpg' -o -iname '*.jpeg' -o \
        -iname '*.png' -o -iname '*.webp' -o \
        -iname '*.gif' -o -iname '*.mp4' -o -iname '*.mov' \
    \) -exec bash -c '
        file="$1"
        THUMB_DIR="$2"
        name="$(basename "${file%.*}")"
        thumb="$THUMB_DIR/${name}.png"

        # Always regenerate if missing or source newer
        if [[ ! -f "$thumb" || "$file" -nt "$thumb" ]]; then
            echo "Generating thumb for: $file"

            if [[ "$file" =~ \.(mp4|mov|gif)$ ]]; then
                # Video: grab 1st frame, crop center 15%, resize to 300px width
                ffmpeg -y -i "$file" -vframes 1 \
                    -vf "crop=iw*0.30:ih:(iw*0.85)/2:0,scale=300:-1" \
                    "$thumb" 2>/dev/null
            else
                # Image: crop center 30%, resize to 300px width
                convert "$file" \
                    -gravity center -crop 30%x100%+0+0 +repage \
                    -resize 300x "$thumb" 2>/dev/null
            fi
        fi
    ' _ {} "$THUMB_DIR" \;
}

# Show Rofi menu
show_menu() {
    generate_thumbs

    # Build list for Rofi
    items=""
    while IFS= read -r file; do
        thumb="$THUMB_DIR/$(basename "${file%.*}").png"
        items+="$file\x00icon\x1f$(realpath "$thumb")\n"
    done < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( \
        -iname '*.jpg' -o -iname '*.jpeg' -o \
        -iname '*.png' -o -iname '*.webp' -o \
        -iname '*.gif' -o -iname '*.mp4' -o -iname '*.mov' \
    \) | sort)

    # Rofi with navigation
    selected=$(echo -en "$items" | rofi \
        -dmenu \
        -i \
        -p " Select Wallpaper" \
        -show-icons \
        -icon-theme "Papirus" \
        -kb-custom-1 "Ctrl+Alt+Left" \
        -kb-custom-2 "Ctrl+Alt+Right" \
-theme-str '
    window {
        width: 1700px;
        background-color: #5b4259;
        border-radius: 10px;
        color: #ffffff;
    }
    listview {
        layout: horizontal;
        spacing: 25px;
        scrollbar: false;
        dynamic: true;
    }
	element normal.normal {
	    background-color: #5b4259;
	}
	element normal.active {
	    background-color: #3a2c5a;
	}
	element selected.normal {
	    background-color: #755b72;
	}
	element selected.active {
	    background-color: #4a3b6d;
	}
	element urgent.normal {
	    background-color: #1a1633;
	}
	element urgent.active {
	    background-color: #3a2c5a;
	}
	element alternate.normal {
	    background-color: #5b4259;
	}
	element alternate.active {
	    background-color: #5b4259;
	}
    element {
        orientation: vertical;
        border-radius: 5px;
        padding: 10px;
        width: 300px;
        height: 500px;
    }
    element-icon {
        size: 300px;
        width: 300px;
        height: 500px;
        border-radius: 3px;
    }
    element-text {
        horizontal-align: 0.5;
        color: #cdd6f4;
        padding: 5px;
    }'\
        2>/dev/null)

    case $? in
        10) show_menu ;;  # Ctrl+Alt+Left
        11) show_menu ;;  # Ctrl+Alt+Right
        0) [[ -n "$selected" ]] && ~/.scripts/set_wallpaper.sh "$selected" ;;
    esac
}

show_menu

