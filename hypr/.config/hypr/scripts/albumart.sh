#!/usr/bin/env bash
# gets and sets album art for hyprlock
url=$(playerctl metadata mpris:artUrl 2>/dev/null)
raw=/tmp/hyprlock-art-raw
out=/tmp/hyprlock-art.png
last=/tmp/hyprlock-art.url

blank() { [ "$(cat "$last" 2>/dev/null)" = "blank" ] || { magick -size 300x300 xc:none "$out"; echo blank > "$last"; }; }

if [ -z "$url" ]; then blank; echo "$out"; exit 0; fi

if [ "$(cat "$last" 2>/dev/null)" = "$url" ]; then echo "$out"; exit 0; fi

case "$url" in
    file://*) cp "${url#file://}" "$raw" ;;
    http*)    curl -sL "$url" -o "$raw" ;;
    *)        blank; echo "$out"; exit 0 ;;
esac

magick "$raw" -gravity center -crop 1:1+0+0 +repage -resize 300x300 "$out" 2>/dev/null || cp "$raw" "$out"
echo "$url" > "$last"
echo "$out"