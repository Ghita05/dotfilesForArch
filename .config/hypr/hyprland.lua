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

-- Ambxst
loadfile(os.getenv("HOME") .. "/.local/share/ambxst/hyprland.lua")()

-- OVERRIDES
-- Down here you can write or source anything that you want to override from Ambxst's settings.

-------------------
---- AUTOSTART ----
-------------------
hl.on("hyprland.start", function()
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
end)

---------------------
---- KEYBINDINGS ----
---------------------
local mainMod = "SUPER"

-- No Ambxst equivalent for these — kept as-is
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + M", hl.dsp.exit())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + B", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + K", hl.dsp.exec_cmd("/home/ghita/.config/hypr/scripts/kbd-backlight-cycle.sh"), { locked = true })

-- Workspaces: hl.bind() does not parse "code:N" physical-keycode syntax
-- (tested live via hyprctl eval — it registers the raw string as an
-- unresolved keysym instead of a keycode; keycode stayed 0). Falling back to
-- AZERTY symbol binds. Ambxst's own generated SUPER+1..0 binds are
-- themselves unreachable as single chords on this layout — French AZERTY
-- only produces digit keysyms with Shift held — so they're dead weight here
-- regardless of what we do.
--
-- Checked ~/.config/ambxst/config/compositor.json: it does not expose
-- workspace binds at all (only visual props — border/shadow/blur/gaps/
-- rounding), so there's no source-level way to disable Ambxst's numeric
-- binds. These hl.unbind() calls are the only lever, and they're fragile:
-- axctl regenerates ~/.local/share/ambxst/hyprland.lua on every theme/gaps/
-- binds change, and if the exact bind strings below ever drift from what
-- axctl emits, these unbinds silently stop matching and the dead numeric
-- binds come back (harmlessly inert on this layout, but not actually
-- removed). If workspace binds misbehave after an Ambxst update, re-check
-- ~/.local/share/ambxst/hyprland.lua for the current SUPER+<n>/SHIFT/ALT
-- strings first.
--
-- Checked Ambxst's generated SUPER+SHIFT+<n> vs SUPER+ALT+<n>: they are
-- byte-identical (both hl.dsp.window.move({workspace=N})) — no silent/
-- follow-focus split exists to mirror. Genuinely redundant in Ambxst's own
-- file; mirrored as-is below for parity, not because there's a distinction.
for _, k in ipairs({
    "SUPER + 1", "SUPER + 2", "SUPER + 3", "SUPER + 4", "SUPER + 5",
    "SUPER + 6", "SUPER + 7", "SUPER + 8", "SUPER + 9", "SUPER + 0",
    "SUPER + SHIFT + 1", "SUPER + SHIFT + 2", "SUPER + SHIFT + 3", "SUPER + SHIFT + 4", "SUPER + SHIFT + 5",
    "SUPER + SHIFT + 6", "SUPER + SHIFT + 7", "SUPER + SHIFT + 8", "SUPER + SHIFT + 9", "SUPER + SHIFT + 0",
    "SUPER + ALT + 1", "SUPER + ALT + 2", "SUPER + ALT + 3", "SUPER + ALT + 4", "SUPER + ALT + 5",
    "SUPER + ALT + 6", "SUPER + ALT + 7", "SUPER + ALT + 8", "SUPER + ALT + 9", "SUPER + ALT + 0",
}) do
    hl.unbind(k)
end

local azerty = { "ampersand", "eacute", "quotedbl", "apostrophe", "parenleft",
                 "minus", "egrave", "underscore", "ccedilla", "agrave" }
for i, key in ipairs(azerty) do
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
    hl.bind(mainMod .. " + ALT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Screenshots: checked ScreenshotTool.qml — open() unconditionally sets
-- GlobalStates.screenshotCaptureMode = "region" and there is exactly one
-- entrypoint ("screenshot" in GlobalShortcuts.qml). The backend IPC
-- (screenshot.capture) does support a mode param per PLAN.md, but `ambxst
-- run screenshot` doesn't expose it — region vs fullscreen is a click inside
-- the overlay (the mode-grid at the bottom), not a separate command. No real
-- split to bind Print vs SHIFT+Print to; both go to the same overlay.
hl.bind("Print", hl.dsp.exec_cmd("ambxst run screenshot"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("ambxst run screenshot"))

-- Brightness: Ambxst's own XF86MonBrightness binds go through an axctl IPC
-- pipe; unbinding those and rebinding on the `ambxst brightness` CLI instead,
-- so axctl's saved/restored brightness baseline (used by idle-dimming) stays
-- coherent — firing both paths on one keypress would double-step it.
hl.unbind("XF86MonBrightnessUp")
hl.unbind("XF86MonBrightnessDown")
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("ambxst brightness +5"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("ambxst brightness -5"), { locked = true, repeating = true })
