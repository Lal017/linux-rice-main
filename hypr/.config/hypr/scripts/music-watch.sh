#!/usr/bin/env bash
# Keeps the lock-screen music files up to date in the background,
# so hyprlock only has to read files that are already correct.

# Single instance only
exec 9>/tmp/music-watch.lock
flock -n 9 || exit 0

s="$HOME/.config/hypr/scripts"

while true; do
    "$s/albumart.sh" >/dev/null 2>&1
    "$s/music-bg.sh" >/dev/null 2>&1
    sleep 1
done