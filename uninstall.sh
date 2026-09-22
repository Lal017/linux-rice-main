#!/usr/bin/env bash
#
# uninstall.sh — remove this rice's symlinks and restore original files
#
# Usage: run from inside the cloned dotfiles repo:
#   cd ~/dotfiles && ./uninstall.sh
#
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

STOW_PACKAGES=(
    cava thunar fastfetch hypr kitty mimeapps starship waybar
    wlogout wofi wofi-hidden youtube-music zsh
)

# Directories to search for "_backup" files left behind by install.sh.
# Kept narrow (not a full recursive $HOME scan) to avoid false positives
# in unrelated directories like caches.
SEARCH_DIRS=(
    "$HOME"
    "$HOME/.config"
    "$HOME/.local/share/applications"
)

cd "$DOTFILES_DIR"

echo "==> Unstowing dotfiles..."
stow -D "${STOW_PACKAGES[@]}"
echo "    Done. Symlinks removed."

echo "==> Looking for backed-up original files..."
restored_any=false

for dir in "${SEARCH_DIRS[@]}"; do
    [ -d "$dir" ] || continue
    while IFS= read -r -d '' backup_path; do
        # Strip a trailing _backup, _backup2, _backup3, etc.
        original_path="$(echo "$backup_path" | sed -E 's/_backup[0-9]*$//')"

        if [ -e "$original_path" ]; then
            echo "    Skipping $backup_path — $original_path already exists (not touching it)."
            continue
        fi

        mv "$backup_path" "$original_path"
        echo "    Restored: $backup_path -> $original_path"
        restored_any=true
    done < <(find "$dir" -maxdepth 1 -name "*_backup*" -print0)
done

if [ "$restored_any" = false ]; then
    echo "    No backup files found."
fi

echo "==> Done."
echo
echo "Note: installed packages were left untouched. If you also want to remove them, review:"
echo "    pacman-packages.txt and aur-packages.txt"
echo "and run 'sudo pacman -Rns <package>' manually for anything you no longer want."
