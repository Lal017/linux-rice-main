#!/bin/bash

for player in $(playerctl -l 2>/dev/null); do
    status=$(playerctl -p "$player" status 2>/dev/null)

    [ "$status" != "Playing" ] && continue

    album=$(playerctl -p "$player" metadata xesam:album 2>/dev/null)
    url=$(playerctl -p "$player" metadata xesam:url 2>/dev/null)

    # If there is an album, assume it's music
    if [ -n "$album" ]; then
        continue
    fi

    # No album + a URL means browser/web media
    if [ -n "$url" ]; then
        exit 1
    fi
done

exit 0