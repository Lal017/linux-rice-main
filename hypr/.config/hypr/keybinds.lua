---------------------
---- KEYBINDINGS ----
---------------------

local programs = require("programs")
local mainMod = "SUPER" -- Sets "Cmd" key as main modifier

-- Example binds, see https://wiki.hypr.land/Configuring/Basics/Binds/ for more
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(programs.terminal))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(programs.browser))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(programs.fileManager))
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd(programs.menu))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd(programs.code))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(programs.wallpaper_switcher))

local closeWindowBind = hl.bind(mainMod .. " + Q", hl.dsp.window.close())
-- closeWindowBind:set_enabled(false)
hl.bind(mainMod .. " + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + S", hl.dsp.layout("togglesplit"))    -- dwindle only

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Move Windows around with mainMod + CONTROL + SHIFT + arrow keys
hl.bind(mainMod .. " + SHIFT + CONTROL + left", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + CONTROL + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + CONTROL + up", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + CONTROL + down", hl.dsp.window.move({ direction = "down" }))

-- Resize Windows with mainMod + SHIFT + arrowKeys
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.resize({ x = -10, y = 0, relative = true }, {description = "Resize window" .. "left", repeating = true}))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.resize({ x = 10, y = 0, relative = true }, {description = "Resize window" .. "right", repeating = true}))
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.resize({ x = 0, y = -10, relative = true }, {description = "Resize window" .. "up", repeating = true}))
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.resize({ x = 0, y = 10, relative = true }, {description = "Resize window" .. "down", repeating = true}))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i}))
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Multimedia keys for volume
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })

-- Monitor brightness controls
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { locked = true, repeating = true })

-- Mute mic
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })

-- Keyboard backlight
hl.bind("XF86kbdBrightnessUp", hl.dsp.exec_cmd("brightnessctl -d '*kbd_backlight' set 10%+"), { locked = true, repeating = true })
hl.bind("XF86kbdBrightnessDown", hl.dsp.exec_cmd("brightnessctl -d '*kbd_backlight' set 10%-"), { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true})
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl prev"), { locked = true })
