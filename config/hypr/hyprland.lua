-------------------
---- FUNCTIONS ----
-------------------

local function switch_layout() 
    local layouts     = { "master", "dwindle", "scrolling" }
    local workspace   = hl.get_active_workspace()
    if hl.get_active_special_workspace() then
		workspace = hl.get_active_special_workspace()
    end

    local next_layout = "dwindle"

    if not workspace then
        return
    end

    for i = 1, #layouts do
        if layouts[i] == workspace.tiled_layout then
            local next_layout_idx = (i % #layouts) + 1
            next_layout = layouts[next_layout_idx]
            break
        end
    end

	if workspace.special then
		hl.workspace_rule({ workspace = tostring(workspace.name), layout = next_layout })
	else
		hl.workspace_rule({ workspace = tostring(workspace.id), layout = next_layout })
    end
end

------------------
---- MONITORS ----
------------------

hl.monitor({
    output   = "eDP-1",
    mode     = "1920x1080@60",
    position = "0x0",
    scale    = "1",
})

---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "kitty"
local fileManager = "dolphin"
local screenshot  = "sh -c '$HOME/.local/bin/screenshot'"
local menu        = "qs ipc call launcher toggle"
local sidebar     = "qs ipc call sidebar toggle"
local powermenu   = "qs ipc call powermenu toggle"

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function () 
  hl.exec_cmd("quickshell")
  hl.exec_cmd("awww-daemon")
  hl.exec_cmd("hyprpolkitagent")
  hl.exec_cmd("protonvpn-app")
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME","Bibata-Modern-Classic")
hl.env("HYPRCURSOR_THEME","Bibata-Modern-Classic")
hl.env("QT_QPA_PLATFORMTHEME","qt6ct")

-----------------------
----- PERMISSIONS -----
-----------------------

-- https://wiki.hypr.land/Configuring/Advanced-and-Cool/Permissions/
-- not implemented

-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 10,

        border_size = 2,

        col = {
            active_border   = { colors = {"rgba(33ccffee)", "rgba(00ff99ee)"}, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },

        resize_on_border = false,
        allow_tearing = false,
        layout = "master",
    },

    decoration = {
        rounding       = 12,
        rounding_power = 4,

        active_opacity   = 0.97,
        inactive_opacity = 0.83,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a,
        },

        blur = {
            enabled   = true,
            size      = 3,
            passes    = 4,
            vibrancy  = 0.8576
        },
    },

    animations = {
        enabled = true,
    },
})

hl.curve("standard", { type = "bezier", points = { {0.25, 0.1}, {0.25, 1} } })
hl.curve("emphasis", { type = "bezier", points = { {0.22, 1},   {0.36, 1} } })
hl.curve("subtle",   { type = "bezier", points = { {0.2, 0},    {0.2, 1}  } })
hl.curve("linear",   { type = "bezier", points = { {.5, 0},     {.5, 1}   } })
hl.curve("express",  { type = "bezier", points = { {.2, .8},    {.2, 1}   } })

hl.animation({ leaf = "global",        enabled = true, speed = 5,   bezier = "standard"  })
hl.animation({ leaf = "border",        enabled = true, speed = 3,   bezier = "linear"    })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.2, bezier = "express",  style = "popin 85%" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 5,   bezier = "express",  style = "popin 60%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 5,   bezier = "express",  style = "gnomed"    })
hl.animation({ leaf = "windowsMove",   enabled = true, speed = 4.2, bezier = "subtle",   style = "slide" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 3.6, bezier = "subtle"    })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 3.6, bezier = "subtle"    })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.0, bezier = "subtle"    })
hl.animation({ leaf = "fadeSwitch",    enabled = true, speed = 4.0, bezier = "linear"    })
hl.animation({ leaf = "fadeDpms",      enabled = true, speed = 6.0, bezier = "emphasis"  })
hl.animation({ leaf = "layers",        enabled = true, speed = 4.3, bezier = "standard"  })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 3.8, bezier = "subtle",   style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 3.8, bezier = "subtle",   style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.8, bezier = "subtle"    })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.8, bezier = "subtle"    })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 2.0, bezier = "emphasis", style = "slidefade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 3.2, bezier = "emphasis", style = "slidefade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 3.2, bezier = "standard", style = "slidefade" })
hl.animation({ leaf = "specialWorkspace",    enabled = true, speed = 3.0, bezier = "emphasis", style = "slidefadevert" })
hl.animation({ leaf = "specialWorkspaceIn",  enabled = true, speed = 4.2, bezier = "express",  style = "slidefadevert" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 3.7, bezier = "subtle",   style = "slidefadevert" })
hl.animation({ leaf = "zoomFactor",    enabled = true, speed = 6.5, bezier = "express"   })

hl.config({
    dwindle = {
        preserve_split = true,
    },
    master = {
        new_status = "slave",
        mfact = 0.65,
        orientation = "center",
        slave_count_for_center_master = 4,
        center_master_fallback = "left",
    },
    scrolling = {
        fullscreen_on_one_column = true,
    },
})

----------------
----  MISC  ----
----------------

hl.config({
    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo   = false,
    },
})

---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "caps:super",
        kb_rules   = "",

        follow_mouse = 1,
        sensitivity = 0.3,

        touchpad = {
            natural_scroll = false,
        },
    },
})

---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"

hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q",      hl.dsp.window.close())
hl.bind(mainMod .. " + M",      hl.dsp.exec_cmd(powermenu))
hl.bind(mainMod .. " + E",      hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V",      hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + D",      hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + A",      hl.dsp.exec_cmd(sidebar))
hl.bind(mainMod .. " + P",      hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J",      hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + tab",    switch_layout)

hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))

for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i}))
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end

hl.workspace_rule({ workspace = "special:magic", layout = "dwindle" })
hl.workspace_rule({ workspace = "10", layout = "dwindle" })

hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),  { locked = true, repeating = true })
hl.bind("Print",                hl.dsp.exec_cmd(screenshot),                                        { locked = true })
hl.bind("XF86AudioNext",        hl.dsp.exec_cmd("playerctl -p mpd next"),                                 { locked = true })
hl.bind("XF86AudioPause",       hl.dsp.exec_cmd("playerctl -p mpd play-pause"),                           { locked = true })
hl.bind("XF86AudioPlay",        hl.dsp.exec_cmd("playerctl -p mpd play-pause"),                           { locked = true })
hl.bind("XF86AudioPrev",        hl.dsp.exec_cmd("playerctl -p mpd previous"),                             { locked = true })

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

local suppressMaximizeRule = hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

hl.window_rule({
    match = {
        class = "proton.vpn.app.gtk",
    },
    workspace = "10"
})

hl.workspace_rule({
    workspace = "10",
    default_name = "󰖂"
})

hl.layer_rule({ match = { namespace = "notifications" }, "blur"})
hl.layer_rule({ match = { namespace = "notifications" }, "ignorezero"})
hl.layer_rule({ match = { namespace = "notifications" }, "ignorealpha 0.5"})
