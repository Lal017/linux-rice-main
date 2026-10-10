# Dotfiles

Personal Arch Linux + Hyprland dotfiles, managed with GNU Stow.

# Install

1. Clone this repo: `git clone https://github.com/lal017/linux-rice-main.git ~/dotfiles`
2. `cd ~/dotfiles`
3. run the install script `./install.sh`

# Update

1. `cd ~/dotfiles`
2. `git fetch origin`
3. `git reset --hard origin/main`
4. ./install.sh

# Notes

- If you want any hidden apps to show on wofi:
    1. go into `~/.local/share/applications`
    2. find the .desktop file of the app you want to show
    3. change `NoDisplay=true` to `NoDisplay=false` or remove the line completely
    4. Run `update-desktop-database ~/.local/share/applications` to refresh

# ToDo

- restyle hyprlock to look simpler
- configure and style notifications and add dotfiles
- Add and style more dropdown and popup menus to waybar
- restyle waybar and colors
- restyle wlogout
- add update script?
- switch wofi for rofi?