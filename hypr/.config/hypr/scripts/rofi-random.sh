#!/usr/bin/env bash
dir="${XDG_DATA_HOME:-$HOME/.local/share}/rofi/images"

img="$(find "$dir" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) | shuf -n1)"

if [ -n "$img" ]; then
    exec rofi -show drun -theme-str "imagebox { background-image: url(\"$img\", height); }" "$@"
else
    exec rofi -show drun "$@"
fi