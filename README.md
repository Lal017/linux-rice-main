# Dotfiles

Personal Arch Linux + Hyprland dotfiles, managed with GNU Stow.

# Steps to setup on a new machine

1. Clone this repo: `git clone https://github.com/lal017/linux-rice-main.git ~/dotfiles`
2. `cd ~/dotfiles`
3. run the install script `./install.sh`

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
- add update script
- switch wofi for rofi?