# AwesomeWM Config Notes

## (Currently) Unused Functions
```lua
awful.tag.history.restore, { description = "go back", group = "tag" }
function () mymainmenu:show() end, { description = "show main menu", group = "awesome" }
awful.screen.focus_relative
awful.client.urgent.jumpto
+++ goto to prev window in workspace +++
function ()
    awful.client.focus.history.previous()
    if client.focus then
        client.focus:raise()
    end
end,
{description = "go back", group = "client"}),
++++++


+++ layout stuff
awful.tag.incmwfact(number) : increase master width factor
awful.tag.innmaster : increase number of master windows
awful.tag.inncol(int,nil??,bool) : increase number of columns

function (c) c:swap(awful.client.getmaster()) end, { description = "move to master", group = "client" }
function (client) client.ontop = not client.ontop end,
client.minimized = true
client.maximized
client.maximized_vertical
client.maximized_horizontal
client:raise()
++++++

+++ screen stuff +++
client:move_to_screen()
++++++



function () awful.screen.focused().mypromptbox:run() end -- awesome app launcher
```


## Unused Layouts
```lua
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.spiral,
    awful.layout.suit.max,
    awful.layout.suit.magnifier,
    awful.layout.suit.corner.nw,
    awful.layout.suit.corner.ne,
    awful.layout.suit.corner.sw,
    awful.layout.suit.corner.se,
```


## Unused Widgets/Panel Stuff
```lua
awful.widget.keyboardlayout()
```

# Misc
```lua
awful.key(
    { super, "Control" }, "n",
    function()
        local c = awful.client.restore()
        -- Focus restored client
        if c then
          c:emit_signal(
              "request::activate", "key.unminimize", {raise = true}
          )
        end
    end,
    {description = "restore minimized", group = "client"}
),


awful.key({ super }, "x",
    function()
        awful.prompt.run {
            prompt       = "Run Lua code: ",
            textbox      = awful.screen.focused().mypromptbox.widget,
            exe_callback = awful.util.eval,
            history_path = awful.util.get_cache_dir() .. "/history_eval"
        }
    end,
    {description = "lua execute prompt", group = "awesome"}
),
```
