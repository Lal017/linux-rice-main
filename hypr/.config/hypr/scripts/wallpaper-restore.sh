#!/usr/bin/env bash
# Restores the last set wallpaper after shutdown
pgrep -x mpvpaper >/dev/null && exit 0

set -u

script_dir="$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")"
state_file="${XDG_STATE_HOME:-$HOME/.local/state}/wallpaper/current"
apply_script="$script_dir/wallpaper-apply.sh"

[[ -r "$state_file" ]] || exit 0

IFS= read -r file < "$state_file"

[[ -n "$file" && -f "$file" ]] || exit 0

"$apply_script" "$file"
