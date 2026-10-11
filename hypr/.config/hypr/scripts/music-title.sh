#!/usr/bin/env bash
# ~/.config/hypr/scripts/music-title.sh
# gets and sets music title for hyprlock music widget
max=34

text=$(playerctl metadata --format '{{ artist }} - {{ title }}' 2>/dev/null)

if [ "${#text}" -gt "$max" ]; then
    text="${text:0:$((max - 3))}..."
fi

# escape & last, so truncation can't cut an "&amp;" in half
printf '%s\n' "$text" | sed 's/&/\&amp;/g'