# Dotfiles

Personal Arch Linux + Hyprland dotfiles, managed with GNU Stow.

# Steps to setup on a new machine

1. Clone this repo: `git clone https://github.com/lal017/linux-rice-main.git ~/dotfiles`
2. `cd ~/dotfiles`
3. Install packages: `sudo pacman -S --needed - < pacman-packages.txt`
4. Install AUR packages: `yay -S --needed - < aur-packages.txt`
5. Check for stow conflicts first: `stow -n -v cava dolphin fastfetch hypr kitty mimeapps starship waybar wlogout wofi wofi-hidden youtube-music zsh` — remove any real files/folders sitting at the target paths before proceeding
6. Run stow for real: `stow cava dolphin fastfetch hypr kitty mimeapps starship waybar wlogout wofi wofi-hidden youtube-music zsh`

# System-level config NOT covered by dotfiles/stow

These live outside `~/.config` or require root, so they need to be manually reapplied on each new machine:

- **NVIDIA suspend/resume fix** (if machine has NVIDIA GPU):
    - `/etc/modprobe.d/nvidia-power-management.conf` -> `options nvidia NVreg_PreserveVideoMemoryAllocations=1`
    - `sudo systemctl enable nvidia-suspend.service nvidia-resume.service`
    - `sudo mkinitcpio -P` after adding the modprobe option

# Notes

- wofi-hidden hides my unwanted apps from wofi. If you want some of these hidden apps to show on wofi:
    1. go into `~/.local/share/applications`
    2. find the .desktop file of the app you want to show
    3. change `NoDisplay=true` to `NoDisplay=false` or remove the line completely
    4. Run `update-desktop-database ~/.local/share/applications` to refresh

# ToDo

- Configure and style dolphin
- Configure and style SDDM
- configure and style notifications
- Add dropdown and popup menus to waybar
- update install script to get a transparent window in zen browser