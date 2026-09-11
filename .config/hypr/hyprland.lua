-- Ambxst
loadfile(os.getenv("HOME") .. "/.local/share/ambxst/hyprland.lua")()

-- OVERRIDES
-- Down here you can write or source anything that you want to override from Ambxst's settings.
hl.config({ input = { kb_layout = "fr", follow_mouse = 1, sensitivity = 0, touchpad = { natural_scroll = true } } })
hl.monitor({ output = "eDP-1", mode = "1920x1200@60", position = "0x0", scale = 1 })
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@165", position = "1920x0", scale = 1 })

-- Scale is 1 on both monitors (native res, no fractional scaling — see
-- CLAUDE.md's rendering-artifacts note). Ambxst's own bar/dock/notch sizes
-- are plain logical-pixel values with no manual scale math in the QML, so
-- Quickshell's Wayland output-scale handling covers them automatically; no
-- resizing needed. These three just make GTK/Qt/cursor consistent with that,
-- since nothing sets them by default. hl.env(name, value) — verified
-- signature live via hyprctl eval before writing this.
hl.env("GDK_SCALE", "1")
hl.env("QT_SCALE_FACTOR", "1")
hl.env("XCURSOR_SIZE", "24")

-- Startup: default Hyprland logo/splash flash and a laggy startup animation.
hl.config({
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
    },
})
