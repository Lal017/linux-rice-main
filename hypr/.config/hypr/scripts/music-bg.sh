#!/usr/bin/env bash
# background for hyprlock music widget
out=/tmp/hyprlock-musicbg.png
on=/tmp/hyprlock-musicbg-on.png
off=/tmp/hyprlock-musicbg-off.png

[ -f "$on" ]  || magick -size 640x160 xc:none -fill 'rgba(0,0,0,0.35)' -draw 'roundrectangle 0,0 639,159 15,15' "$on"
[ -f "$off" ] || magick -size 640x160 xc:none "$off"

if playerctl status >/dev/null 2>&1; then cp -f "$on" "$out"; else cp -f "$off" "$out"; fi
echo "$out"