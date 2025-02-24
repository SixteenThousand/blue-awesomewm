-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup")
-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
require("awful.hotkeys_popup.keys")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({
        preset = naughty.config.presets.critical,
        title = "Oops, there were errors during startup!",
        text = awesome.startup_errors
    })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({
            preset = naughty.config.presets.critical,
            title = "Oops, an error happened!",
            text = tostring(err)
        })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
beautiful.init(gears.filesystem.get_themes_dir() .. "zenburn/theme.lua")
theme = beautiful.get()
theme.font = "FantasqueSansM Nerd Font 14"
theme.border_width = 0
beautiful.init(theme)

-- This is used later as the default terminal and editor to run.
terminal = os.getenv("TERMINAL") or "wezterm"
editor = os.getenv("EDITOR") or "vi"
editor_cmd = terminal .. " -e " .. editor

-- +++ MOD KEYS +++
super = "Mod4"
alt = "Mod1"

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
    awful.layout.suit.max,
    awful.layout.suit.tile,
    -- awful.layout.suit.floating,
}
-- }}}

-- {{{ Menu
-- Create a launcher widget and a main menu
myawesomemenu = {
   {
       "hotkeys",
       function()
           hotkeys_popup.show_help(nil, awful.screen.focused())
       end
   },
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", function() awesome.quit() end },
}

mymainmenu = awful.menu({
    items = {
        { "awesome", myawesomemenu, beautiful.awesome_icon },
        { "open terminal", terminal }
    }
})

mylauncher = awful.widget.launcher({
    image = beautiful.awesome_icon,
    menu = mymainmenu,
})

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- {{{ Wibar

-- Create a wibox for each screen and add it
local taglist_buttons = gears.table.join(
    awful.button({ }, 1, function(t) t:view_only() end),
    awful.button({ super }, 1,
        function(t)
            if client.focus then
                client.focus:move_to_tag(t)
            end
        end
    ),
    awful.button({ }, 3, awful.tag.viewtoggle),
    awful.button({ super }, 3,
        function(t)
            if client.focus then
                client.focus:toggle_tag(t)
            end
        end
    ),
    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
)

local tasklist_buttons = gears.table.join(
    awful.button({ }, 1, function (c)
        if c == client.focus then
            c.minimized = true
        else
            c:emit_signal(
                "request::activate",
                "tasklist",
                {raise = true}
            )
        end
    end),
    awful.button({ }, 3, function()
        awful.menu.client_list({ theme = { width = 250 } })
    end),
    awful.button({ }, 4, function()
        awful.client.focus.byidx(1)
    end),
    awful.button({ }, 5, function()
        awful.client.focus.byidx(-1)
    end)
)

local function set_wallpaper(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

awful.screen.connect_for_each_screen(function(s)

    -- Each screen has its own tag table.
    awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.layouts[1])

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    -- Create an imagebox widget which will contain an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(
        awful.button({ }, 1, function() awful.layout.inc( 1) end),
        awful.button({ }, 3, function() awful.layout.inc(-1) end),
        awful.button({ }, 4, function() awful.layout.inc( 1) end),
        awful.button({ }, 5, function() awful.layout.inc(-1) end)
    ))
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist {
        screen  = s,
        filter  = awful.widget.taglist.filter.all,
        buttons = taglist_buttons
    }

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist {
        screen  = s,
        filter  = awful.widget.tasklist.filter.currenttags,
        buttons = tasklist_buttons
    }
    
    -- system monitors
    s.myi3bar = wibox.widget{
        widget = wibox.widget.textbox,
        text = "--------",
    }
    awful.spawn.with_line_callback(
        "i3status -c "..gears.filesystem.get_configuration_dir().."i3status.conf",
        {
            stdout = function(line)
                s.myi3bar:set_markup_silently("<b> "..line.." </b>")
            end,
            stderr = function(line)
                naughty.notify("i3status error: "..line)
            end,
        }
    )
                

    -- Create the wibox
    s.mywibox = awful.wibar({ position = "top", screen = s, height = 30, })

    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            mylauncher,
            s.mytaglist,
            s.mypromptbox,
        },
        s.mytasklist, -- Middle widget
        { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            s.myi3bar,
            wibox.widget.systray(),
            s.mylayoutbox,
        },
    }
end)
-- }}}

-- {{{ Mouse bindings
root.buttons(gears.table.join(
    awful.button({ }, 3, function() mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
function tag_next_row()
    local current_ws = tonumber(awful.screen.focused().selected_tag.name) - 1
    local new_ws = ((current_ws + 3) % 9) + 1
    awful.tag.find_by_name(awful.screen.focused(),tostring(new_ws)):view_only()
end
function tag_prev_row()
    local current_ws = tonumber(awful.screen.focused().selected_tag.name) - 1
    local new_ws = ((current_ws - 3) % 9) + 1
    awful.tag.find_by_name(awful.screen.focused(),tostring(new_ws)):view_only()
end

globalkeys = gears.table.join(
    awful.key(
        { super, "Shift" },  "/",
        hotkeys_popup.show_help,
        { description="show help", group="awesome" }
    ),
    -- tag navigation
    awful.key(
        { super, },  "Up",
        awful.tag.viewprev,
        { description = "view previous", group = "tag" }
    ),
    awful.key(
        { super, },  "Down",
        awful.tag.viewnext,
        { description = "view next", group = "tag" }
    ),
    awful.key(
        { super, },  "k",
        awful.tag.viewprev,
        { description = "view previous", group = "tag" }
    ),
    awful.key(
        { super, },  "j",
        awful.tag.viewnext,
        { description = "view next", group = "tag" }
    ),
    awful.key(
        { super, }, "l",
        tag_next_row,
        {}
    ),
    awful.key(
        { super, }, "h",
        tag_prev_row,
        {}
    ),
    awful.key(
        { super, }, "Right",
        tag_next_row,
        {}
    ),
    awful.key(
        { super, }, "Left",
        tag_prev_row,
        {}
    ),
    awful.key(
        { super, }, "space",
        function()
            awful.tag.history.restore(awful.screen.focused(),"previous")
        end,
        { description = "view last viewed", group = "tag" }
    ),
    -- basically copied from a reddit user, link below
    -- https://www.reddit.com/r/awesomewm/comments/kr2fbi/how_to_autohide_statusbar/
    awful.key(
        { super, }, "Escape",
        function()
            myscreen = awful.screen.focused()
            myscreen.mywibox.visible = not myscreen.mywibox.visible
        end,
        {description = "show/hide panel", group = "Awesome"}
    ),

    awful.key({ super,}, "w",
        function()
            awful.client.focus.byidx(1)
        end,
        {description = "focus next by index", group = "client"}
    ),
    awful.key({ alt }, "Tab",
        function()
            awful.client.focus.byidx(1)
        end,
        {description = "focus next by index", group = "client"}
    ),
    awful.key({ super,}, "x",
        function()
            awful.client.focus.byidx(-1)
        end,
        {description = "focus previous by index", group = "client"}
    ),
    awful.key({ alt, "Shift" }, "Tab",
        function()
            awful.client.focus.byidx(-1)
        end,
        {description = "focus previous by index", group = "client"}
    ),

    -- Layout manipulation
    awful.key(
        { super, "Shift" }, "w",
        function() awful.client.swap.byidx(1) end,
        { description = "swap with next client by index", group = "client" }
    ),
    awful.key(
        { super, "Shift" }, "x",
        function() awful.client.swap.byidx(-1) end,
        { description = "swap with previous client by index", group = "client" }
    ),
    awful.key(
        { super, alt }, "Return",
        function() awful.layout.inc(1,awful.screen.focused()) end,
        { description = "switch to next layout", group = "layout" }
    ),

    -- Apps
    awful.key(
        { super, },  "Return",
        function() awful.spawn(terminal) end,
        { description = "open default terminal", group = "launcher" }
    ),
    awful.key(
        { super, "Shift" }, "Return",
        function() awful.spawn("alacritty -e tmux") end,
        { description = "alacritty with tmux", group = "launcher" }
    ),
    awful.key(
        { super, }, "b",
        function() awful.spawn("firefox") end,
        { description = "open a browser", group = "launcher" }
    ),
    awful.key(
        { super, }, "t",
        function() awful.spawn("thunderbird") end,
        { description = "open email client", group = "launcher" }
    ),
    awful.key(
        { super, "Control" }, "r",
        awesome.restart,
        { description = "reload awesome", group = "awesome" }
    ),
    awful.key(
        { super, "Shift" }, "q",
        awesome.quit,
        { description = "quit awesome", group = "awesome" }
    ),
    awful.key(
        { super, "Shift" }, "Delete",
        function() awesome.spawn("systemctl poweroff") end,
        { description = "turn off computer", group = "awesome" }
    ),

    -- Menubar
    awful.key(
        { super, "Shift" }, "a",
        function() menubar.show() end,
        {description = "show the menubar", group = "launcher"}
    ),
    awful.key(
        { super, }, "a",
        function()
            awful.spawn("rofi -show drun")
        end,
        { description = "rofi app launcher", group = "launcher" }
    ),

    -- hardware stuff
    awful.key(
        {}, "XF86MonBrightnessDown",
        function()
            awful.spawn("desktopctl mon - 10")
        end,
        {}
    ),
    awful.key(
        {}, "XF86MonBrightnessUp",
        function()
            awful.spawn("desktopctl mon + 10")
        end,
        {}
    ),
    awful.key(
        {}, "XF86AudioPlay",
        function() awful.spawn("playerctl play-pause") end,
        {}
    ),
    awful.key(
        {}, "XF86AudioMute",
        function()
            awful.spawn("desktopctl mute")
        end,
        {}
    ),
    awful.key(
        {}, "XF86AudioLowerVolume",
        function()
            awful.spawn("desktopctl vol - 2")
        end,
        {}
    ),
    awful.key(
        {}, "XF86AudioRaiseVolume",
        function()
            awful.spawn("desktopctl vol + 2")
        end,
        {}
    ),
    awful.key(
        {}, "Print",
        function() awful.spawn("spectacle -b -f") end,
        { description = "screeenshot whole desktop \"screen\"" }
    ),
    awful.key(
        { alt }, "Print",
        function() awful.spawn("spectacle -b -a") end,
        { description = "screeenshot active window" }
    ),
    
    -- Misc
    awful.key(
        { super, }, "n",
        function()
            naughty.destroy_all_notifications(
                nil,
                naughty.notificationClosedReason.dismissedByUser
            )
        end,
        {}
    )
)

function prev_ws_move(c)
    local current_ws = tonumber(awful.screen.focused().selected_tag.name) - 1
    local new_ws = ((current_ws - 1) % 9) + 1
    local new_tag = awful.tag.find_by_name(
        awful.screen.focused(),
        tostring(new_ws)
    )
    c:move_to_tag(new_tag)
    new_tag:view_only()
end
function next_ws_move(c)
    local current_ws = tonumber(awful.screen.focused().selected_tag.name) - 1
    local new_ws = ((current_ws + 1) % 9) + 1
    local new_tag = awful.tag.find_by_name(
        awful.screen.focused(),
        tostring(new_ws)
    )
    c:move_to_tag(new_tag)
    new_tag:view_only()
end
function prev_row_move(c)
    local current_ws = tonumber(awful.screen.focused().selected_tag.name) - 1
    local new_ws = ((current_ws - 3) % 9) + 1
    local new_tag = awful.tag.find_by_name(
        awful.screen.focused(),
        tostring(new_ws)
    )
    c:move_to_tag(new_tag)
    new_tag:view_only()
end
function next_row_move(c)
    local current_ws = tonumber(awful.screen.focused().selected_tag.name) - 1
    local new_ws = ((current_ws + 3) % 9) + 1
    local new_tag = awful.tag.find_by_name(
        awful.screen.focused(),
        tostring(new_ws)
    )
    c:move_to_tag(new_tag)
    new_tag:view_only()
end
clientkeys = gears.table.join(
    awful.key(
        { super, }, "f",
        function(c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        {description = "toggle fullscreen", group = "client"}
    ),
    awful.key(
        { super, }, "q",
        function(c) c:kill() end,
        { description = "close", group = "client" }
    ),
    awful.key(
        { super, }, "m",
        function(c) c.maximized = not c.maximized end,
        {}
    ),
    awful.key(
        { super, "Control" }, "space",
        awful.client.floating.toggle,
        { description = "toggle floating", group = "client" }
    ),
    
    awful.key(
        { super, "Shift" }, "Left",
        prev_ws_move,
        { description = "move window to prev tag", group = "client" }
    ),
    awful.key(
        { super, "Shift" }, "Down",
        next_row_move,
        { description = "move window down a row", group = "client" }
    ),
    awful.key(
        { super, "Shift" }, "Up",
        prev_row_move,
        { description = "move window down a row", group = "client" }
    ),
    awful.key(
        { super, "Shift" }, "Right",
        next_ws_move,
        { description = "move window to next tag", group = "client" }
    ),
    awful.key(
        { super, "Shift" }, "h",
        prev_ws_move,
        { description = "move window to prev tag", group = "client" }
    ),
    awful.key(
        { super, "Shift" }, "j",
        next_row_move,
        { description = "move window down a row", group = "client" }
    ),
    awful.key(
        { super, "Shift" }, "k",
        prev_row_move,
        { description = "move window down a row", group = "client" }
    ),
    awful.key(
        { super, "Shift" }, "l",
        next_ws_move,
        { description = "move window to next tag", group = "client" }
    )
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = gears.table.join(globalkeys,
        -- View tag only.
        awful.key(
            { super }, "#" .. i + 9,
            function()
                local screen = awful.screen.focused()
                local tag = screen.tags[i]
                if tag then
                   tag:view_only()
                end
            end,
            {description = "view tag #"..i, group = "tag"}
        ),
        -- Toggle tag display.
        awful.key(
            { super, "Control" }, "#" .. i + 9,
            function()
                local screen = awful.screen.focused()
                local tag = screen.tags[i]
                if tag then
                   awful.tag.viewtoggle(tag)
                end
            end,
            {description = "toggle tag #" .. i, group = "tag"}
        ),
        -- Move client to tag.
        awful.key(
            { super, "Shift" }, "#" .. i + 9,
            function()
                if client.focus then
                    local tag = client.focus.screen.tags[i]
                    if tag then
                        client.focus:move_to_tag(tag)
                        tag:view_only()
                    end
               end
            end,
            {description = "move focused client to tag #"..i, group = "tag"}
        ),
        -- Toggle tag on focused client.
        awful.key(
            { super, "Control", "Shift" }, "#" .. i + 9,
            function()
                if client.focus then
                    local tag = client.focus.screen.tags[i]
                    if tag then
                        client.focus:toggle_tag(tag)
                    end
                end
            end,
            {description = "toggle focused client on tag #" .. i, group = "tag"}
        )
    )
end

clientbuttons = gears.table.join(
    awful.button(
        { }, 1,
        function (c)
            c:emit_signal("request::activate", "mouse_click", {raise = true})
        end
    ),
    awful.button(
        { super }, 1,
        function (c)
            c:emit_signal("request::activate", "mouse_click", {raise = true})
            awful.mouse.client.move(c)
        end
    ),
    awful.button(
        { super }, 3,
        function (c)
            c:emit_signal("request::activate", "mouse_click", {raise = true})
            awful.mouse.client.resize(c)
        end
    )
)

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    {
        rule = { },
        properties = {
            border_width = beautiful.border_width,
            border_color = beautiful.border_normal,
            focus = awful.client.focus.filter,
            raise = true,
            keys = clientkeys,
            buttons = clientbuttons,
            screen = awful.screen.preferred,
            placement = awful.placement.no_overlap+awful.placement.no_offscreen,
            callback = awful.client.setslave,
        }
    },
    -- Make dialog windows float
    {
        rule_any = {
            type = { "dialog" }
        },
        properties = { titlebars_enabled = true }
    },
    -- Make sure  most-everything is tiled by default
    {
        rule_any = {
            type = { "normal", },
        },
        properties = {
            maximized = false,
        },
    },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup
        and not c.size_hints.user_position
        and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end

    awful.spawn("xsetroot -xcf /usr/share/icons/Adwaita/cursors/default 48")
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    -- buttons for the titlebar
    local buttons = gears.table.join(
        awful.button({ }, 1, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            awful.mouse.client.move(c)
        end),
        awful.button({ }, 3, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            awful.mouse.client.resize(c)
        end)
    )

    awful.titlebar(c) : setup {
        { -- Left
            awful.titlebar.widget.iconwidget(c),
            buttons = buttons,
            layout  = wibox.layout.fixed.horizontal
        },
        { -- Middle
            { -- Title
                align  = "center",
                widget = awful.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout  = wibox.layout.flex.horizontal
        },
        { -- Right
            awful.titlebar.widget.floatingbutton (c),
            awful.titlebar.widget.maximizedbutton(c),
            awful.titlebar.widget.stickybutton(c),
            awful.titlebar.widget.ontopbutton(c),
            awful.titlebar.widget.closebutton(c),
            layout = wibox.layout.fixed.horizontal()
        },
        layout = wibox.layout.align.horizontal
    }
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
    c:emit_signal("request::activate", "mouse_enter", {raise = false})
end)

client.connect_signal("property::maximized", function(c)
    c.maximized = false
end)
client.connect_signal("property::minimized", function(c)
    c.minimized = false
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

tag.connect_signal("property::layout", function(t)
    local bw = 1
    if t.layout.name == "max" then
        bw = 0
    end
    for _,c in ipairs(t:clients()) do
        c.border_width = bw
    end
end)
-- }}}

-- {{{ Misc.

naughty.config.defaults.position = "bottom_right"
awful.spawn("sh "..gears.filesystem.get_configuration_dir().."/misc_settings.sh")
-- }}}
