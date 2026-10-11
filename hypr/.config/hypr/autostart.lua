---------------------------------------
---- Autostart necessary processes ----
---------------------------------------
-- See https://wiki.hypr.land/Configuring/Basics/Autostart/


hl.on("hyprland.start", function ()
    hl.exec_cmd("waybar")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("/usr/lib/hyprpolkitagent/hyprpolkitagent")
    hl.exec_cmd("/home/lalo/.config/hypr/scripts/music-watch.sh")
end)