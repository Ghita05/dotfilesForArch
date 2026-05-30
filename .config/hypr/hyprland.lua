-- hyprland.lua — charcoal-glass, migrated from hyprland.conf
-- Refer to https://wiki.hypr.land/Configuring/Start/

------------------
---- MONITORS ----
------------------
hl.monitor({
    output = "eDP-1",
    mode = "1920x1200@60",
    position = "0x0",
    scale = 1,
})

---------------------
---- MY PROGRAMS ----
---------------------
local terminal    = "kitty"
local fileManager = "thunar"
local menu        = "wofi --show drun"

---------------
---- INPUT ----
---------------
hl.config({
    input = {
        kb_layout = "fr",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = true,
        },
    },
})

-----------------------
---- LOOK AND FEEL ----
-----------------------
hl.config({
    general = {
        gaps_in = 6,
        gaps_out = 14,
        border_size = 2,
        col = {
            active_border = { colors = {"rgba(7d9bc4cc)", "rgba(9db4d8cc)"}, angle = 45 },
            inactive_border = "rgba(16181f88)",
        },
        resize_on_border = true,
        layout = "dwindle",
    },
    decoration = {
        rounding = 18,
        active_opacity = 0.92,
        inactive_opacity = 0.85,
        dim_inactive = true,
        dim_strength = 0.1,
        shadow = {
            enabled = true,
            range = 30,
            render_power = 3,
            color = 0x66000000,
        },
        blur = {
            enabled = true,
            size = 8,
            passes = 3,
            new_optimizations = true,
            ignore_opacity = false,
            xray = false,
            noise = 0.015,
            contrast = 1.1,
            brightness = 0.9,
            vibrancy = 0.2,
            vibrancy_darkness = 0.5,
        },
    },
    animations = {
        enabled = true,
    },
    dwindle = {
        preserve_split = true,
    },
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
    },
})

hl.layer_rule({ match = { namespace = "quickshell" }, blur = true, ignore_alpha = 0.6 })

-- Animation curves + animations
hl.curve("liquid", { type = "bezier", points = { {0.23, 1}, {0.32, 1} } })
hl.curve("ease",   { type = "bezier", points = { {0.25, 0.1}, {0.25, 1.0} } })

hl.animation({ leaf = "windows",    enabled = true, speed = 6, bezier = "liquid", style = "popin 80%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 6, bezier = "liquid", style = "popin 80%" })
hl.animation({ leaf = "fade",       enabled = true, speed = 6, bezier = "liquid" })
hl.animation({ leaf = "border",     enabled = true, speed = 8, bezier = "liquid" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "liquid", style = "slide" })

-------------------
---- AUTOSTART ----
-------------------
hl.on("hyprland.start", function()
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("sleep 1 && awww img ~/.config/wallpapers/mountfuji.jpg --transition-type fade")
    hl.exec_cmd("mako")
    hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("/usr/lib/polkit-gnome-authentication-agent-1")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("waybar")
    hl.exec_cmd("quickshell")
end)

---------------------
---- KEYBINDINGS ----
---------------------
local mainMod = "SUPER"

hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exit())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + B", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + X", hl.dsp.exec_cmd("wlogout --buttons-per-row 2"))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("cliphist list | wofi --dmenu | cliphist decode | wl-copy"))

-- Move focus
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- AZERTY workspace keys (switch + move)
local azerty = { "ampersand", "eacute", "quotedbl", "apostrophe", "parenleft",
                 "minus", "egrave", "underscore", "ccedilla", "agrave" }
for i, key in ipairs(azerty) do
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Move/resize with mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Screenshots
hl.bind("Print", hl.dsp.exec_cmd("grim - | swappy -f -"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | swappy -f -"))

-- Media & brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })

hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("qs ipc call controlCenter toggle"))