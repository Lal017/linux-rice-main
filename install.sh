#!/usr/bin/env bash
#
# install.sh — set up this rice on a new Arch Linux machine
#
# Usage: run from inside the cloned dotfiles repo:
#   cd ~/dotfiles && ./install.sh            # run the real install
#   cd ~/dotfiles && ./install.sh --check    # read-only: report problems, change nothing
#
set -euo pipefail

if [ "$EUID" -eq 0 ]; then
    echo "Don't run this as root or with sudo. It calls sudo itself where needed."
    exit 1
fi

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

STOW=(stow --no-folding)

STOW_PACKAGES=(
    cava dolphin hypr terminal waybar wofi youtube-music style
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

echo "==> Checking for Poiret One font..."
font_dir="$HOME/.local/share/fonts"
font_file="$font_dir/PoiretOne-Regular.ttf"
if [ -f "$font_file" ]; then
    echo "    Already installed."
else
    mkdir -p "$font_dir"
    if curl -fL --retry 3 -o "$font_file" \
        "https://github.com/google/fonts/raw/main/ofl/poiretone/PoiretOne-Regular.ttf"; then
        fc-cache -f "$font_dir"
        echo "    Installed Poiret One."
    else
        rm -f "$font_file"
        echo "    WARNING: couldn't download Poiret One. hyprlock will fall back to a default font."
    fi
fi

echo "==> Previewing stow conflicts (no changes made)..."
preview_output="$("${STOW[@]}" -R -n -v "${STOW_PACKAGES[@]}" 2>&1 || true)"
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

echo "==> Updating system (refresh package database and upgrade)..."
sudo pacman -Syu --noconfirm

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

    echo "    Ensuring build dependencies are installed..."
    sudo pacman -S --needed --noconfirm base-devel debugedit

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

echo "==> Checking login shell..."
zsh_path="$(command -v zsh)"
if [ "$SHELL" != "$zsh_path" ]; then
    chsh -s "$zsh_path"
    echo "    Login shell set to zsh — log out and back in for it to take effect."
else
    echo "    Already using zsh."
fi

echo "==> Checking for stow conflicts..."
conflict_found=false

dry_run_output="$("${STOW[@]}" -R -n -v "${STOW_PACKAGES[@]}" 2>&1 || true)"

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

mkdir -p "$HOME/.config"

echo "==> Running stow..."
"${STOW[@]}" -R "${STOW_PACKAGES[@]}"

echo "==> Setting dark mode preference..."
if command -v gsettings >/dev/null 2>&1; then
    dark_cmd=(gsettings set org.gnome.desktop.interface color-scheme prefer-dark)
    if [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
        "${dark_cmd[@]}" || echo "    WARNING: gsettings failed."
    else
        # Running from a TTY with no session bus, so start a temporary one
        dbus-run-session -- "${dark_cmd[@]}" || echo "    WARNING: gsettings failed."
    fi
    echo "    Set color-scheme to prefer-dark."
else
    echo "    gsettings not found, skipping."
fi

echo "==> Installing icon theme (Breeze-Round-Chameleon Dark Icons)..."
icon_name="Breeze-Round-Chameleon Dark Icons"
icon_dir="$HOME/.local/share/icons"
icon_api="https://api.kde-look.org/ocs/v1/content/data/1608771"

if [ -f "$icon_dir/$icon_name/index.theme" ]; then
    echo "    Already installed."
else
    mkdir -p "$icon_dir"
    icon_tmp="$(mktemp -d)"

    # Ask the store API for a fresh (short-lived) download link
    icon_url="$(curl -fsSL --retry 3 "$icon_api" \
        | sed -n 's:.*<downloadlink1>\(.*\)</downloadlink1>.*:\1:p' \
        | sed 's/&amp;/\&/g' || true)"

    if [ -n "$icon_url" ] \
        && curl -fL --retry 3 -o "$icon_tmp/icons.tar.xz" "$icon_url" \
        && tar -xJf "$icon_tmp/icons.tar.xz" -C "$icon_tmp"; then
        # Find the extracted theme folder (the one containing index.theme)
        theme_src="$(find "$icon_tmp" -maxdepth 2 -name index.theme -printf '%h\n' | head -n1 || true)"
        if [ -n "$theme_src" ]; then
            rm -rf "$icon_dir/$icon_name"
            cp -a "$theme_src" "$icon_dir/$icon_name"
            echo "    Installed."
        else
            echo "    WARNING: downloaded archive had no icon theme in it. Icons will fall back to the default."
        fi
    else
        echo "    WARNING: couldn't download the icon theme. Icons will fall back to the default."
    fi
    rm -rf "$icon_tmp"
fi

if [ -d "$icon_dir/$icon_name" ]; then
    echo "==> Setting icon theme..."

    # GTK apps (wofi, etc.)
    if command -v gsettings >/dev/null 2>&1; then
        icon_cmd=(gsettings set org.gnome.desktop.interface icon-theme "$icon_name")
        if [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
            "${icon_cmd[@]}" || echo "    WARNING: gsettings failed."
        else
            dbus-run-session -- "${icon_cmd[@]}" || echo "    WARNING: gsettings failed."
        fi
    fi

    # Qt/KDE apps (Dolphin)
    if command -v kwriteconfig6 >/dev/null 2>&1; then
        kwriteconfig6 --file kdeglobals --group Icons --key Theme "$icon_name"
    else
        echo "    kwriteconfig6 not found, skipping Dolphin icon setting."
    fi
fi

echo "==> Syncing wallpapers..."
wall_dir="$HOME/Pictures/wallpapers"
wall_state="$HOME/.local/state/dotfiles-wallpapers.txt"
wall_added=false

if [ -f wallpaper-urls.txt ]; then
    mkdir -p "$wall_dir" "$(dirname "$wall_state")"
    touch "$wall_state"

    while read -r url || [ -n "$url" ]; do
        [ -z "$url" ] && continue
        [[ "$url" == \#* ]] && continue

        url="${url%/}"
        [[ "$url" == */download ]] || url="$url/download"

        if grep -qxF "$url" "$wall_state"; then
            echo "    Already downloaded: $url"
            continue
        fi

        wall_tmp="$(mktemp -d)"
        if curl -fL --retry 3 -o "$wall_tmp/w.zip" "$url" \
            && unzip -q -j -n "$wall_tmp/w.zip" -d "$wall_dir"; then
            echo "$url" >> "$wall_state"
            wall_added=true
            echo "    Downloaded: $url"
        else
            echo "    WARNING: couldn't download $url"
        fi
        rm -rf "$wall_tmp"
    done < wallpaper-urls.txt

    # Restart hyprpaper so it picks up the new images
    if [ "$wall_added" = true ] && pgrep -x hyprpaper >/dev/null; then
        pkill -x hyprpaper
        nohup hyprpaper >/dev/null 2>&1 &
    fi
else
    echo "    wallpaper-urls.txt not found, skipping."
fi

echo "==> Configuring NetworkManager (iwd backend)..."
nm_conf="/etc/NetworkManager/conf.d/wifi_backend.conf"
nm_conf_desired=$'[device]\nwifi.backend=iwd'

if [ -f "$nm_conf" ] && [ "$(cat "$nm_conf")" = "$nm_conf_desired" ]; then
    echo "    $nm_conf already configured, skipping."
else
    sudo mkdir -p /etc/NetworkManager/conf.d
    printf '%s\n' "$nm_conf_desired" | sudo tee "$nm_conf" >/dev/null
    echo "    Wrote $nm_conf"
    network_switch_pending=true
fi

for svc in iwd.service NetworkManager.service; do
    if systemctl is-enabled --quiet "$svc"; then
        echo "    $svc already enabled, skipping."
    else
        sudo systemctl enable "$svc"
        echo "    Enabled $svc"
        network_switch_pending=true
    fi
done

for svc in systemd-networkd.service systemd-networkd.socket; do
    if systemctl is-enabled --quiet "$svc" 2>/dev/null; then
        sudo systemctl disable "$svc"
        echo "    Disabled $svc"
        network_switch_pending=true
    else
        echo "    $svc already disabled, skipping."
    fi
done

echo "==> Done."
if [ "$conflict_found" = true ]; then
    echo "    Original conflicting files were renamed to <name>_backup next to their original location."
    echo "    A future uninstall script can restore them by unstowing, then renaming <name>_backup back."
fi
if [ "$nvidia_fix_applied" = true ]; then
    echo "    NVIDIA suspend/resume fix applied — reboot for it to take effect."
fi
if [ "${network_switch_pending:-false}" = true ]; then
    echo "    Networking switched to NetworkManager + iwd — reboot to apply (systemd-networkd was disabled)."
fi