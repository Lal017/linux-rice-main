#!/usr/bin/env bash
#
# install.sh — set up this rice on a new Arch Linux machine
#
# Usage: run from inside the cloned dotfiles repo:
#   cd ~/dotfiles && ./install.sh            # run the real install
#   cd ~/dotfiles && ./install.sh --check    # read-only: report problems, change nothing
#
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

STOW_PACKAGES=(
    cava dolphin fastfetch hypr kitty mimeapps starship waybar
    wlogout wofi wofi-hidden youtube-music zsh
)

CHECK_ONLY=false
if [ "${1:-}" = "--check" ]; then
    CHECK_ONLY=true
fi

cd "$DOTFILES_DIR"
problems_found=false

echo "==> Checking network connectivity..."
if ping -c1 -W3 archlinux.org >/dev/null 2>&1; then
    echo "    OK"
else
    echo "    NO NETWORK — package installs will fail."
    problems_found=true
fi

echo "==> Checking disk space..."
avail_kb="$(df --output=avail / | tail -1)"
if [ "$avail_kb" -lt 2097152 ]; then
    echo "    LOW DISK SPACE — less than 2GB free on /."
    problems_found=true
else
    echo "    OK"
fi

echo "==> Validating official package names..."
if [ -f pacman-packages.txt ]; then
    while read -r pkg; do
        [ -z "$pkg" ] && continue
        [ "$pkg" = "yay" ] && continue
        if ! pacman -Si "$pkg" >/dev/null 2>&1; then
            echo "    MISSING (official repo): $pkg"
            problems_found=true
        fi
    done < pacman-packages.txt
    echo "    Done checking pacman-packages.txt."
else
    echo "    pacman-packages.txt not found, skipping."
fi

echo "==> Validating AUR package names..."
if [ -f aur-packages.txt ]; then
    if command -v yay >/dev/null 2>&1; then
        while read -r pkg; do
            [ -z "$pkg" ] && continue
            if ! yay -Si "$pkg" >/dev/null 2>&1; then
                echo "    MISSING (AUR): $pkg"
                problems_found=true
            fi
        done < aur-packages.txt
        echo "    Done checking aur-packages.txt."
    else
        echo "    yay not installed yet, skipping AUR name validation (will be checked at install time)."
    fi
else
    echo "    aur-packages.txt not found, skipping."
fi

echo "==> Previewing stow conflicts (no changes made)..."
preview_output="$(stow -n -v "${STOW_PACKAGES[@]}" 2>&1 || true)"
if echo "$preview_output" | grep -q "cannot stow"; then
    echo "$preview_output" | grep "cannot stow" | sed 's/^/    /'
    echo "    These will be backed up automatically (renamed to <name>_backup) during the real install."
else
    echo "    No conflicts found."
fi

echo
if [ "$problems_found" = true ]; then
    echo "==> Check complete: problems found above. Fix them before running the real install."
else
    echo "==> Check complete: no problems found. Safe to run ./install.sh without --check."
fi

if [ "$CHECK_ONLY" = true ]; then
    exit 0
fi

if [ "$problems_found" = true ]; then
    echo
    read -rp "Problems were found above. Continue anyway? [y/N] " reply
    if [[ ! "$reply" =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

echo "==> Installing official packages..."
if [ -f pacman-packages.txt ]; then
    # yay itself can't come from pacman -S (it's an AUR package), so skip it here
    grep -vx 'yay' pacman-packages.txt | sudo pacman -S --needed --noconfirm -
else
    echo "    pacman-packages.txt not found, skipping."
fi

echo "==> Checking for yay..."
if ! command -v yay >/dev/null 2>&1; then
    echo "    yay not found, building from AUR..."
    tmpdir="$(mktemp -d)"
    git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
    (cd "$tmpdir/yay" && makepkg -si --noconfirm)
    rm -rf "$tmpdir"
else
    echo "    yay already installed."
fi

echo "==> Installing AUR packages..."
if [ -f aur-packages.txt ]; then
    yay -S --needed --noconfirm - < aur-packages.txt
else
    echo "    aur-packages.txt not found, skipping."
fi

echo "==> Checking for NVIDIA GPU..."
nvidia_fix_applied=false
if lspci | grep -Ei 'vga|3d controller' | grep -qi nvidia; then
    echo "    NVIDIA GPU detected — applying suspend/resume fix..."

    nvidia_conf="/etc/modprobe.d/nvidia-power-management.conf"
    if [ -f "$nvidia_conf" ] && grep -q "NVreg_PreserveVideoMemoryAllocations=1" "$nvidia_conf"; then
        echo "    $nvidia_conf already configured, skipping."
    else
        echo "options nvidia NVreg_PreserveVideoMemoryAllocations=1" | sudo tee "$nvidia_conf" >/dev/null
        echo "    Wrote $nvidia_conf"
        nvidia_fix_applied=true
    fi

    if systemctl list-unit-files nvidia-suspend.service >/dev/null 2>&1 && \
       systemctl list-unit-files nvidia-resume.service >/dev/null 2>&1; then
        if ! systemctl is-enabled --quiet nvidia-suspend.service || ! systemctl is-enabled --quiet nvidia-resume.service; then
            sudo systemctl enable nvidia-suspend.service nvidia-resume.service
            echo "    Enabled nvidia-suspend.service and nvidia-resume.service"
            nvidia_fix_applied=true
        else
            echo "    nvidia-suspend/resume services already enabled, skipping."
        fi
    else
        echo "    nvidia-suspend.service/nvidia-resume.service not found on this system — skipping."
        echo "    (These ship with some NVIDIA driver packages but not others; the modprobe.d fix above still applies.)"
    fi
else
    echo "    No NVIDIA GPU detected, skipping suspend/resume fix."
fi

echo "==> Checking for stow conflicts..."
conflict_found=false

dry_run_output="$(stow -n -v "${STOW_PACKAGES[@]}" 2>&1 || true)"

while IFS= read -r line; do
    if [[ "$line" == *"cannot stow"* ]]; then
        # Extract the path after "existing target "
        target="${line#*existing target }"
        target="${target% since*}"
        full_path="$HOME/$target"

        if [ -e "$full_path" ] && [ ! -L "$full_path" ]; then
            conflict_found=true

            # Pick a backup name that doesn't clobber an existing one
            backup_path="${full_path}_backup"
            n=2
            while [ -e "$backup_path" ]; do
                backup_path="${full_path}_backup${n}"
                n=$((n + 1))
            done

            mv "$full_path" "$backup_path"
            echo "    Conflict: $full_path -> $backup_path"
        fi
    fi
done <<< "$dry_run_output"

if [ "$conflict_found" = false ]; then
    echo "    No conflicts found."
fi

echo "==> Running stow..."
stow "${STOW_PACKAGES[@]}"

echo "==> Done."
if [ "$conflict_found" = true ]; then
    echo "    Original conflicting files were renamed to <name>_backup next to their original location."
    echo "    A future uninstall script can restore them by unstowing, then renaming <name>_backup back."
fi
if [ "$nvidia_fix_applied" = true ]; then
    echo "    NVIDIA suspend/resume fix applied — reboot for it to take effect."
fi