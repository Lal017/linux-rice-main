#!/usr/bin/env bash
# Lock wrapper: single instance, scales the lock screen to this display,
# starts the lock-screen cava, cleans up after unlock.

# Don't start a second lock screen
pidof hyprlock >/dev/null && exit 0

# Scale factor, same formula as the SDDM theme (reference: 2560x1440)
s=$(hyprctl monitors -j 2>/dev/null | jq -r '
    ([.[] | select(.focused)][0] // .[0])
    | [(.width / .scale / 2560), (.height / .scale / 1440)] | min' 2>/dev/null)
[ -n "$s" ] && [ "$s" != "null" ] || s=1

# Copy the real config to /tmp, scaling the pixel-based values
conf="$HOME/.config/hypr/hyprlock.conf"
gen=/tmp/hyprlock-generated.conf
S="$s" perl -pe '
  if (/^\s*(font_size|size|rounding|outline_thickness)\s*=/) {
    s/(?<![\w.%-])(\d+)(?![\d%])/int($1 * $ENV{S} + 0.5)/ge
  }' "$conf" > "$gen"

# Start the lock-screen visualizer in the background
"$HOME/.config/hypr/scripts/cava-lock.sh" &

# Blocks until you unlock
hyprlock -c "$gen"

# Stop only the lock-screen cava (not waybar's)
pkill -f "cava -p /tmp/hyprlock-cava.conf"
pkill -f cava-lock.sh
rm -f /tmp/cava-bars "$gen"