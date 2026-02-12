#!/bin/bash

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
CACHE_DIR="$HOME/.cache/wallpaper-thumbnails"
THUMBNAIL_DIR="$HOME/Pictures/Thumbnails"
mkdir -p "$CACHE_DIR"
mkdir -p "$THUMBNAIL_DIR"

# generate thumbnails and cache them
generate_thumbnails() {
    find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.webp" -o -iname "*.webm" \) | while read -r img; do
        filename=$(basename "$img")
        thumbnail="$CACHE_DIR/${filename%.*}.png"
        if [ ! -f "$thumbnail" ] || [ "$img" -nt "$thumbnail" ]; then
            magick "$img[0]" -resize 200x200^ -gravity center -extent 200x200 +adjoin "$thumbnail" 2>/dev/null
        fi
    done
}

# generate thumbnails for mp4
generate_video_thumbnails() {
    find "$WALLPAPER_DIR" -type f -iname "*.mp4" | while read -r video; do
        filename=$(basename "$video")
        full_thumbnail="$THUMBNAIL_DIR/${filename%.*}.jpg"
        small_thumbnail="$CACHE_DIR/${filename%.*}.png"
        if [ ! -f "$full_thumbnail" ] || [ "$video" -nt "$full_thumbnail" ]; then
            ffmpeg -i "$video" -vframes 1 -q:v 2 "$full_thumbnail" -y 2>/dev/null
        fi
        if [ -f "$full_thumbnail" ]; then
            if [ ! -f "$small_thumbnail" ] || [ "$full_thumbnail" -nt "$small_thumbnail" ]; then
                magick "$full_thumbnail" -resize 200x200^ -gravity center -extent 200x200 "$small_thumbnail" 2>/dev/null
            fi
        fi
    done
}

if command -v magick &> /dev/null; then
    generate_thumbnails &
fi
if command -v ffmpeg &> /dev/null; then
    generate_video_thumbnails &
fi

# build rofi entries
build_menu() {
    find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.webp" -o -iname "*.mp4" \) -printf "%f\n" | sort | while read -r wallpaper; do
        thumbnail="$CACHE_DIR/${wallpaper%.*}.png"
        if [ -f "$thumbnail" ]; then
            printf "%s\0icon\x1f%s\n" "$wallpaper" "$thumbnail"
        else
            echo "$wallpaper"
        fi
    done
}

# get all wallpapers
get_wallpapers() {
    find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.webp" -o -iname "*.mp4" \) -printf "%f\n"
}

# random wallpaper selection
if [ "$1" = "random" ]; then
    wallpapers=($(get_wallpapers))
    if [ ${#wallpapers[@]} -eq 0 ]; then
        notify-send "Error" "No wallpapers found in $WALLPAPER_DIR"
        exit 1
    fi
    selected="${wallpapers[$RANDOM % ${#wallpapers[@]}]}"
else
    selected=$(build_menu | rofi -dmenu -i -p "Wallpaper" -show-icons -theme ~/.config/rofi/grid.rasi -theme-str 'element-icon { size: 6em; }' -me-select-entry '' -me-accept-entry MousePrimary)
fi

# set wallpaper
if [ -n "$selected" ]; then
    selected=$(echo "$selected" | tr -d '\0')
    wallpaper_path="$WALLPAPER_DIR/$selected"
    if [ -f "$wallpaper_path" ]; then
        echo "$wallpaper_path" > "$HOME/.cache/last_wallpaper"
        extension="${selected##*.}"

        if [ "${extension,,}" = "mp4" ]; then
            killall gslapper 2>/dev/null
            filename=$(basename "$selected")
            thumbnail_path="$THUMBNAIL_DIR/${filename%.*}.jpg"
            cp "$thumbnail_path" "$HOME/.cache/last_wallpaper_static.jpg"
            sleep 0.5
            notify-send -a "Wallpaper" "Applying Animated Wallpaper & Theme" "$selected" -i "$thumbnail_path"
            gslapper -o "loop full" "*" "$wallpaper_path" &
        else
            magick "$wallpaper_path[0]" +adjoin "$HOME/.cache/last_wallpaper_static.jpg"
            sleep 0.5
            notify-send -a "Wallpaper" "Applying Wallpaper & Theme" "$selected" -i "$wallpaper_path"
            awww img "$wallpaper_path"
        fi
    else
        notify-send -a "Wallpaper" "Error" "Wallpaper file not found: $wallpaper_path"
    fi
fi
