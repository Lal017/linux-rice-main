#!/usr/bin/env bash
# Restarts the wallpaper whenever a real monitor is (re)added.
set -u

# single instance only
exec 9>"$XDG_RUNTIME_DIR/wallpaper-watch.lock"
flock -n 9 || exit 0

script_dir="$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")"
state_file="${XDG_STATE_HOME:-$HOME/.local/state}/wallpaper/current"
sock="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
last=0

socat -u "UNIX-CONNECT:$sock" - | while IFS= read -r line; do
    [[ $line == monitoraddedv2\>\>* ]] || continue

    # line format: monitoraddedv2>>ID,NAME,DESCRIPTION
    IFS=, read -r _id name _rest <<< "${line#monitoraddedv2>>}"
    [[ $name == FALLBACK ]] && continue       # Hyprland's placeholder output

    now=$(date +%s)
    (( now - last < 5 )) && continue          # ignore bursts
    last=$now

    sleep 3                                   # let FALLBACK get removed and DP-2 settle
    IFS= read -r file < "$state_file" 2>/dev/null || continue
    [[ -f $file ]] || continue

    pkill -x mpvpaper
    for _ in $(seq 20); do pgrep -x mpvpaper >/dev/null || break; sleep 0.05; done
    rm -f "$XDG_RUNTIME_DIR/mpvpaper.sock"
    "$script_dir/wallpaper-apply.sh" "$file" 9>&-
done