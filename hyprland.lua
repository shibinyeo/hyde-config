-- Hyprland loads this file when it is started without a config, and it prefers
-- it over hyprland.conf. HyDE loads it too, last, as the override layer below.
-- The block keeps the two apart: hyde.lua sets `hyde` on its first line, so it
-- runs only when this file is the entry point and HyDE has not been loaded.
-- Removing it leaves a session with a cursor and nothing else.
if not hyde then
	local share = os.getenv("XDG_DATA_HOME") or (os.getenv("HOME") .. "/.local/share")
	local entry = share .. "/hypr/hyde.lua"
	local handle = io.open(entry, "r")
	if not handle then
		error("HyDE is not installed at " .. entry .. ". Run install.sh -r, or point Hyprland at your own config.")
	end
	handle:close()
	dofile(entry)
end

-- Your Hyprland configuration. HyDE never overwrites this file.
--
-- It loads after HyDE's own binds, so settings here take precedence. Replacing
-- a bind needs more than that: see below. HyDE's defaults live in
-- ~/.local/share/hypr/lua/ and are overwritten on every update, so edits there
-- do not survive.
--
-- Adding a keybind:
--
--     hl.bind("SUPER + SPACE", hl.dsp.exec_cmd(hyde.sh.gamelauncher()), {
--         description = "[Utilities] game launcher",
--     })
--
-- Replacing one of HyDE's: bind the same combination again and yours takes
-- over, but copy its flags across as well. A bind counts as the same one only
-- when its flags match, and `description` is not a flag — miss one and both
-- binds stay live on that combination. Copy the whole options table from
-- ~/.local/share/hypr/lua/key_binds.lua and change only what you need:
--
--     hl.bind("F9", hl.dsp.exec_cmd(hyde.sh.volumecontrol("-o", "m")), {
--         locked = true,
--         description = "[Hardware Controls|Audio] un/mute output",
--     })
--
-- Press SUPER + / to see what is actually loaded, your own binds included.
-- The full reference is KEYBINDINGS.md in the HyDE repository.
--
-- Other Lua files next to this one can be pulled in with require("name").

-- =====================================================================
-- My personal settings (moved from the old .conf files on 2026-11-09).
-- Backup of the old files: ~/hyde-migration-2026-11-09/
-- Based on machine 1's hyprland.lua, adjusted for this laptop.
-- =====================================================================

local MOD = hyde.config.modifiers.main -- "SUPER"
local app = hyde.config.app
local HOME = os.getenv("HOME")

-- ---------------------------------------------------------------------
-- Input and look (was userprefs.conf)
-- ---------------------------------------------------------------------
hl.config({
    input = {
        sensitivity = 0.5,
        repeat_delay = 200,
        repeat_rate = 50,
        touchpad = {
            natural_scroll = true,
        },
    },
    decoration = {
        active_opacity = 1,
    },
})

-- ---------------------------------------------------------------------
-- Autostart (was exec-once in userprefs.conf)
-- ---------------------------------------------------------------------
hl.on("hyprland.start", function()
    hl.exec_cmd("firefox", { workspace = "1 silent" })
    hl.exec_cmd("obsidian", { workspace = "2 silent" })
    hl.exec_cmd("Telegram", { workspace = "5 silent" })
end)

-- ---------------------------------------------------------------------
-- Monitors: NOT here. hyprdynamicmonitors writes ~/.config/hypr/monitors.lua
-- (HyDE loads it before this file) from the profile templates in
-- ~/.config/hyprdynamicmonitors/hyprconfigs/*.lua.tmpl, then runs
-- `hyprctl reload`. Any hl.monitor() line here would override those profiles.
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- Turn off HyDE default keys I do not use, or that sit on my keys
-- (unbind first, so flags do not matter)
-- ---------------------------------------------------------------------
local unbind_list = {
    MOD .. " + Q", "ALT + F4", MOD .. " + Delete", MOD .. " + W", MOD .. " + G",
    "SHIFT + F11", "CTRL + ALT + DELETE", MOD .. " + CTRL + B",
    MOD .. " + CTRL + H", MOD .. " + CTRL + L",
    MOD .. " + Up", MOD .. " + Down",
    MOD .. " + SHIFT + CONTROL + LEFT", MOD .. " + SHIFT + CONTROL + RIGHT",
    MOD .. " + SHIFT + CONTROL + UP", MOD .. " + SHIFT + CONTROL + DOWN",
    MOD .. " + Z", MOD .. " + X", MOD .. " + J",
    MOD .. " + ALT + T", MOD .. " + E", "CTRL + SHIFT + ESCAPE",
    MOD .. " + A", MOD .. " + TAB", MOD .. " + SHIFT + E",
    "F10", "F11", "F12",
    MOD .. " + K", MOD .. " + ALT + G", MOD .. " + SHIFT + G",
    MOD .. " + P", MOD .. " + CONTROL + P", MOD .. " + ALT + P", "Print",
    MOD .. " + CONTROL + RIGHT", MOD .. " + CONTROL + LEFT", MOD .. " + CONTROL + DOWN",
    MOD .. " + CONTROL + ALT + RIGHT", MOD .. " + CONTROL + ALT + LEFT",
    MOD .. " + mouse_down", MOD .. " + mouse_up",
    MOD .. " + ALT + S",
    MOD .. " + SHIFT + K",                         -- calculator
    MOD .. " + SHIFT + LEFT", MOD .. " + SHIFT + RIGHT", -- resize (repeating)
    MOD .. " + SHIFT + UP", MOD .. " + SHIFT + DOWN",     -- resize (repeating)
    MOD .. " + Left", MOD .. " + Right",           -- focus left/right
    MOD .. " + S", MOD .. " + T", MOD .. " + B", MOD .. " + C",
    MOD .. " + SHIFT + F",                         -- pin
    "ALT+TAB",                                     -- HyDE alt-tab switcher
}
for _, key in ipairs(unbind_list) do
    hl.unbind(hyde.binds.normalize(key))
end

-- ---------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------

-- Run several dispatchers with one key (one Lua bind per key; a second bind
-- with the same flags would replace the first).
local function run(...)
    local steps = { ... }
    return function()
        for _, step in ipairs(steps) do
            hl.dispatch(step)
        end
    end
end

-- Toggle real fullscreen (same pattern HyDE uses for SHIFT + F11).
local function toggle_fullscreen()
    local win = hl.get_active_window()
    if not win then return end
    local next_state = ((tonumber(win.fullscreen) or 0) == 0) and 2 or 0
    hl.dispatch(hl.dsp.window.fullscreen_state({ internal = next_state, client = next_state, window = win }))
end

-- Move a floating window by pixels, or a tiled window by direction.
local function move_window(dir, pix)
    local lut = { l = { -1, 0 }, r = { 1, 0 }, u = { 0, -1 }, d = { 0, 1 } }
    local m = lut[dir]
    return function()
        local win = hl.get_active_window()
        if not win then return end
        local args = win.floating and { x = m[1] * pix, y = m[2] * pix, relative = true } or { direction = dir }
        hl.dispatch(hl.dsp.window.move(args))
    end
end

-- ---------------------------------------------------------------------
-- Window management
-- ---------------------------------------------------------------------
hl.bind(MOD .. " + Escape", hl.dsp.window.close(), { description = "[Window Management] close focused window" })
hl.bind(MOD .. " + SHIFT + F", hl.dsp.window.float({ action = "toggle" }), { description = "[Window Management] toggle floating" })
hl.bind(MOD .. " + M", toggle_fullscreen, { description = "[Window Management] toggle fullscreen" })
hl.bind(MOD .. " + CTRL + ALT + L", hl.dsp.exec_cmd(hyde.sh.session.logout.launcher()), { description = "[Window Management] logout menu" })

hl.bind(MOD .. " + SHIFT + H", move_window("l", 30), { repeating = true, description = "[Window Management|Move active window] left" })
hl.bind(MOD .. " + SHIFT + L", move_window("r", 30), { repeating = true, description = "[Window Management|Move active window] right" })
hl.bind(MOD .. " + SHIFT + K", move_window("u", 30), { repeating = true, description = "[Window Management|Move active window] up" })
hl.bind(MOD .. " + SHIFT + J", move_window("d", 30), { repeating = true, description = "[Window Management|Move active window] down" })

hl.bind(MOD .. " + CTRL + Right", hl.dsp.window.resize({ x = 30, y = 0, relative = true }), { repeating = true, description = "[Window Management|Resize Active Window] resize right" })
hl.bind(MOD .. " + CTRL + Left", hl.dsp.window.resize({ x = -30, y = 0, relative = true }), { repeating = true, description = "[Window Management|Resize Active Window] resize left" })
hl.bind(MOD .. " + CTRL + Up", hl.dsp.window.resize({ x = 0, y = -30, relative = true }), { repeating = true, description = "[Window Management|Resize Active Window] resize up" })
hl.bind(MOD .. " + CTRL + Down", hl.dsp.window.resize({ x = 0, y = 30, relative = true }), { repeating = true, description = "[Window Management|Resize Active Window] resize down" })

hl.bind("ALT + TAB", hl.dsp.window.cycle_next(), { description = "[Window Management] change window in focus" })

-- Move the mouse with ydotool
hl.bind("ALT + SHIFT + CTRL + M", hl.dsp.exec_cmd("ydotool mousemove -x -340 -y 0"), { description = "[Mouse] move mouse left" })
hl.bind("ALT + SHIFT + CTRL + I", hl.dsp.exec_cmd("ydotool mousemove -x 340 -y 0"), { description = "[Mouse] move mouse right" })
hl.bind("ALT + SHIFT + CTRL + E", hl.dsp.exec_cmd("ydotool mousemove -x 0 -y -270"), { description = "[Mouse] move mouse up" })
hl.bind("ALT + SHIFT + CTRL + N", hl.dsp.exec_cmd("ydotool mousemove -x 0 -y 270"), { description = "[Mouse] move mouse down" })

-- ---------------------------------------------------------------------
-- Apps
-- ---------------------------------------------------------------------
hl.bind(MOD .. " + Return", run(hl.dsp.focus({ workspace = 4 }), hl.dsp.exec_cmd(app.terminal)), { description = "[Launcher|Apps] terminal (workspace 4)" })
hl.bind(MOD .. " + F", run(hl.dsp.exec_cmd(app.explorer), hl.dsp.focus({ window = "class:dolphin" })), { description = "[Launcher|Apps] file explorer" })
hl.bind(MOD .. " + B", run(hl.dsp.exec_cmd(app.browser), hl.dsp.focus({ window = "class:firefox" })), { description = "[Launcher|Apps] web browser" })
hl.bind(MOD .. " + O", run(hl.dsp.exec_cmd("obsidian"), hl.dsp.focus({ window = "class:obsidian" })), { description = "[Launcher|Apps] obsidian" })
hl.bind(MOD .. " + C", hl.dsp.exec_cmd("gnome-clocks"), { description = "[Launcher|Apps] gnome-clocks" })
hl.bind(MOD .. " + T", run(hl.dsp.focus({ workspace = 5 }), hl.dsp.exec_cmd("Telegram")), { description = "[Launcher|Apps] telegram (workspace 5)" })
hl.bind(MOD .. " + W", run(hl.dsp.focus({ workspace = 7 }), hl.dsp.exec_cmd("flatpak run com.slack.Slack")), { description = "[Launcher|Apps] slack (workspace 7)" })
hl.bind(MOD .. " + S", hl.dsp.exec_cmd("env LD_PRELOAD=/usr/lib/spotify-adblock.so spotify --disable-gpu --no-zygote"), { description = "[Launcher|Apps] spotify" })
hl.bind(MOD .. " + R", hl.dsp.exec_cmd(hyde.sh.menu.apps()), { description = "[Launcher|Rofi menus] application finder" })

-- ---------------------------------------------------------------------
-- Voice and dictation
-- ---------------------------------------------------------------------
-- OpenWhispr (was ~/.local/share/hypr/openwhispr-binds.conf, which OpenWhispr
-- manages itself; if you change these keys in OpenWhispr, update them here)
hl.bind(MOD .. " + Q", hl.dsp.exec_cmd("dbus-send --session --type=method_call --dest=com.openwhispr.App /com/openwhispr/App com.openwhispr.App.Toggle"), { description = "[Utilities] OpenWhispr toggle" })
hl.bind(MOD .. " + CTRL + P", hl.dsp.exec_cmd("dbus-send --session --type=method_call --dest=com.openwhispr.App /com/openwhispr/App com.openwhispr.App.ToggleVoiceAgent"), { description = "[Utilities] OpenWhispr voice agent" })
hl.bind(MOD .. " + CTRL + Q", hl.dsp.exec_cmd(HOME .. "/.local/bin/voice2text-stream"), { description = "[Utilities] voice2text-stream" })

-- ---------------------------------------------------------------------
-- Audio: SUPER + volume keys switch the default output
-- ---------------------------------------------------------------------
hl.bind(MOD .. " + XF86AudioRaiseVolume", hl.dsp.exec_cmd([[for num in '' .1 .2 .3 .4 .5 .6 .7 .8 .9; do pactl set-default-sink alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__HDMI1__sink"$num"; done]]), { locked = true, description = "[Hardware Controls|Audio] output to HDMI" })
hl.bind(MOD .. " + XF86AudioLowerVolume", hl.dsp.exec_cmd([[for num in '' .1 .2 .3 .4 .5 .6 .7 .8 .9; do pactl set-default-sink alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Headphones__sink"$num"; done]]), { locked = true, description = "[Hardware Controls|Audio] output to headphones" })

-- ---------------------------------------------------------------------
-- Screen
-- ---------------------------------------------------------------------
hl.bind("Print", hl.dsp.exec_cmd(hyde.sh.screenshot.freeze()), { locked = true, description = "[Utilities] freeze and snip screen" })

-- ---------------------------------------------------------------------
-- Workspaces
-- ---------------------------------------------------------------------
hl.bind(MOD .. " + TAB", hl.dsp.focus({ workspace = "previous" }), { description = "[Workspaces|Navigation] previous workspace" })
hl.bind("CTRL + SHIFT + ALT + TAB", hl.dsp.focus({ workspace = "previous" }), { description = "[Workspaces|Navigation] previous workspace" })
for i = 1, 10 do
    local key = (i == 10) and "0" or tostring(i)
    hl.bind("CTRL + SHIFT + ALT + " .. key, hl.dsp.focus({ workspace = i }), { description = "[Workspaces|Navigation] navigate to workspace " .. i })
    hl.bind(MOD .. " + CTRL + SHIFT + ALT + " .. key, hl.dsp.window.move({ workspace = i }), { description = "[Workspaces|Move window to workspace] move to workspace " .. i })
end

-- ---------------------------------------------------------------------
-- Scrolling layout keys (only do something when the layout is "scrolling")
-- ---------------------------------------------------------------------
hl.bind(MOD .. " + SHIFT + B", hl.dsp.layout("fit all"), { description = "[Scrolling] fit all" })
hl.bind(MOD .. " + Left", hl.dsp.layout("move -col"), { description = "[Scrolling] move column left" })
hl.bind(MOD .. " + Right", hl.dsp.layout("move +col"), { description = "[Scrolling] move column right" })
hl.bind(MOD .. " + SHIFT + Left", hl.dsp.layout("swapcol l"), { description = "[Scrolling] swap column left" })
hl.bind(MOD .. " + SHIFT + Right", hl.dsp.layout("swapcol r"), { description = "[Scrolling] swap column right" })

-- ---------------------------------------------------------------------
-- wl-kbptr (keyboard pointer)
-- ---------------------------------------------------------------------
hl.bind(MOD .. " + G", function()
    hl.config({ cursor = { inactive_timeout = 0, hide_on_key_press = false } })
    hl.dispatch(hl.dsp.exec_cmd("wl-kbptr"))
end, { description = "[Utilities] keyboard pointer, move and click (wl-kbptr)" })

-- Same, but only move the pointer: no click
hl.bind(MOD .. " + SHIFT + G", function()
    hl.config({ cursor = { inactive_timeout = 0, hide_on_key_press = false } })
    hl.dispatch(hl.dsp.exec_cmd("wl-kbptr -o general.modes=floating"))
end, { description = "[Utilities] keyboard pointer, move only (wl-kbptr)" })

-- Cursor submap (like Sway's mouse mode). Not used right now: the entry key
-- below is off, same as in the old config.
hl.define_submap("cursor", function()
    -- a: jump the cursor again
    hl.bind("a", hl.dsp.exec_cmd("hyprctl dispatch 'hl.dsp.submap(\"reset\")' && wl-kbptr && hyprctl dispatch 'hl.dsp.submap(\"cursor\")'"))
    -- Escape: restore cursor settings and leave
    hl.bind("Escape", function()
        hl.config({ cursor = { inactive_timeout = 3, hide_on_key_press = true } })
        hl.dispatch(hl.dsp.submap("reset"))
    end)
end)
-- hl.bind(MOD .. " + G", function()
--     hl.config({ cursor = { inactive_timeout = 0, hide_on_key_press = false } })
--     hl.dispatch(hl.dsp.submap("cursor"))
-- end)
