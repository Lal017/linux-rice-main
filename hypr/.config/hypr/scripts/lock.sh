#!/usr/bin/env bash
# Lock wrapper: single instance, starts the lock-screen cava, cleans up after unlock.

# Don't start a second lock screen
pidof hyprlock >/dev/null && exit 0

# Start the lock-screen visualizer in the background
"$HOME/.config/hypr/scripts/cava-lock.sh" &

# Blocks until you unlock
hyprlock

# Stop only the lock-screen cava (not waybar's)
pkill -f "cava -p /tmp/hyprlock-cava.conf"
pkill -f cava-lock.sh
rm -f /tmp/cava-bars