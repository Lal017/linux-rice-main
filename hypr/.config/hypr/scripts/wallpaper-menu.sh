#!/usr/bin/env bash
set -u

wallpaper_dir="${XDG_DATA_HOME:-$HOME/.local/share}/wallpapers"
script_dir="$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")"
apply_script="$script_dir/wallpaper-apply.sh"
rofi_theme="$HOME/.config/rofi/wallpaper.rasi"

if [[ ! -d "$wallpaper_dir" ]]; then
    echo "wallpaper-menu: directory not found: $wallpaper_dir" >&2
    exit 1
fi

if [[ ! -x "$apply_script" ]]; then
    echo "wallpaper-menu: apply script missing or not executable: $apply_script" >&2
    exit 1
fi

mapfile -d '' -t files < <(find "$wallpaper_dir" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.bmp' -o -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' -o -iname '*.mov' -o -iname '*.gif' \) -print0 | sort -z)

((${#files[@]})) || { echo "wallpaper-menu: no wallpapers found" >&2; exit 1; }



entries=()
previews=()
preview_dir="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper-menu"
mkdir -p "$preview_dir"

for i in "${!files[@]}"; do
    file="${files[$i]}"
    entries+=("${file#"$wallpaper_dir"/}")

    key=$(printf '%s' "$file" | sha1sum | cut -c1-16)
    thumbnail="$preview_dir/$key.jpg"

    if [[ ! -s "$thumbnail" || "$file" -nt "$thumbnail" ]]; then
        case "${file,,}" in
            *.mp4|*.webm|*.mkv|*.mov)
                ffmpeg -loglevel error -y -ss 1 -i "$file" -frames:v 1 -vf "scale=1080:1080:force_original_aspect_ratio=increase,crop=1080:1080" "$thumbnail" </dev/null
                ;;
            *)
                ffmpeg -loglevel error -y -i "$file" -frames:v 1 -vf "scale=1080:1080:force_original_aspect_ratio=increase,crop=1080:1080" "$thumbnail" </dev/null
                ;;
        esac
    fi

    if [[ -s "$thumbnail" ]]; then
        previews+=("$thumbnail")
    else
        previews+=("$file")
    fi
done


selected=$(for i in "${!entries[@]}"; do
    printf '%s\0icon\x1f%s\n' "${entries[$i]}" "${previews[$i]}"
done | rofi -dmenu -i -show-icons -p "󰸉 Wallpaper" -theme "$rofi_theme" -format i) || exit 0

[[ "$selected" =~ ^[0-9]+$ ]] || exit 0
((selected < ${#files[@]})) || exit 1

file="${files[$selected]}"
printf 'Applying wallpaper: %s\n' "$file" >&2
"$apply_script" "$file"
