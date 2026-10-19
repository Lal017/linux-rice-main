#!/usr/bin/env bash
# wallpaper-apply.sh <file> — images and videos, all through one persistent mpvpaper
set -u

file=$(realpath -- "${1:-}" 2>/dev/null) || exit 1
[ -f "$file" ] || { echo "wallpaper-apply: no such file: ${1:-}" >&2; exit 1; }

case "${file,,}" in
    *.jpg|*.jpeg|*.png|*.webp|*.bmp|*.mp4|*.webm|*.mkv|*.mov|*.gif) ;;
    *) echo "wallpaper-apply: unsupported file type" >&2; exit 1 ;;
esac

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/wallpaper"
mpv_opts="${MPVPAPER_OPTS:-no-audio loop hwdec=auto image-display-duration=inf panscan=1.0 load-scripts=no}"
sock="${XDG_RUNTIME_DIR:-/tmp}/mpvpaper.sock"
mkdir -p "$state_dir"

swapped=0
if pgrep -x mpvpaper >/dev/null && [ -S "$sock" ]; then
    # already running: swap the file inside the player, no new surface
    reply=$(jq -nc --arg f "$file" '{command:["loadfile",$f,"replace"]}' \
            | socat - "$sock" 2>/dev/null)
    [[ $reply == *'"error":"success"'* ]] && swapped=1
fi

if [ "$swapped" = 0 ]; then
    pkill -x mpvpaper
    rm -f "$sock"
    setsid -f mpvpaper -o "$mpv_opts input-ipc-server=$sock" '*' "$file" >/dev/null 2>&1
fi

printf '%s\n' "$file" > "$state_dir/current"