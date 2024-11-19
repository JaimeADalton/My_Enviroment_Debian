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
require("awful.hotkeys_popup.keys")

-- Load Debian menu entries
local debian = require("debian.menu")
local has_fdo, freedesktop = pcall(require, "freedesktop")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, hubo errores durante el inicio!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Asegúrate de no entrar en un bucle infinito de errores
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, ocurrió un error!",
                         text = tostring(err) })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colores, iconos, fuente y fondos de pantalla.
beautiful.init(gears.filesystem.get_themes_dir() .. "default/theme.lua")

-- Este se usa más adelante como el terminal y editor por defecto para ejecutar.
terminal = "alacritty"
editor = os.getenv("EDITOR") or "vim" -- Cambiado a "vim" por defecto
editor_cmd = terminal .. " -e " .. editor

-- Tecla modificadora por defecto.
modkey = "Mod4"

-- Tabla de layouts para cubrir con awful.layout.inc, el orden importa.
awful.layout.layouts = {
    -- Deja solo los layouts de mosaico
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
}
-- }}}

-- {{{ Menu
-- Crea un widget lanzador y un menú principal
myawesomemenu = {
   { "hotkeys", function() hotkeys_popup.show_help(nil, awful.screen.focused()) end },
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", function() awesome.quit() end },
}

local menu_awesome = { "awesome", myawesomemenu, beautiful.awesome_icon }
local menu_terminal = { "abrir terminal", terminal }

if has_fdo then
    mymainmenu = freedesktop.menu.build({
        before = { menu_awesome },
        after =  { menu_terminal }
    })
else
    mymainmenu = awful.menu({
        items = {
                  menu_awesome,
                  { "Debian", debian.menu.Debian_menu.Debian },
                  menu_terminal,
                }
    })
end

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })

-- Configuración de Menubar
menubar.utils.terminal = terminal -- Establece el terminal para aplicaciones que lo requieran
-- }}}

-- Indicador y cambiador de mapa de teclado
mykeyboardlayout = awful.widget.keyboardlayout()

-- {{{ Wibar
-- Crea un widget de reloj de texto
mytextclock = wibox.widget.textclock()

-- Crea una wibox para cada pantalla y la añade
local taglist_buttons = gears.table.join(
                    awful.button({ }, 1, function(t) t:view_only() end),
                    awful.button({ modkey }, 1, function(t)
                                              if client.focus then
                                                  client.focus:move_to_tag(t)
                                              end
                                          end),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, function(t)
                                              if client.focus then
                                                  client.focus:toggle_tag(t)
                                              end
                                          end),
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
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                          end))

local function set_wallpaper(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- Si el wallpaper es una función, la llama con la pantalla
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

-- Reestablece el wallpaper cuando cambia la geometría de una pantalla (p.ej., resolución diferente)
screen.connect_signal("property::geometry", set_wallpaper)

awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper(s)

    -- Cada pantalla tiene su propia tabla de tags.
    awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8" }, s, awful.layout.layouts[1])

    -- Crea un promptbox para cada pantalla
    s.mypromptbox = awful.widget.prompt()
    -- Crea un widget imagebox que contendrá un icono indicando qué layout estamos usando.
    -- Necesitamos un layoutbox por pantalla.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(
                           awful.button({ }, 1, function () awful.layout.inc( 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(-1) end),
                           awful.button({ }, 4, function () awful.layout.inc( 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(-1) end)))
    -- Crea un widget taglist
    s.mytaglist = awful.widget.taglist {
        screen  = s,
        filter  = awful.widget.taglist.filter.all,
        buttons = taglist_buttons
    }

    -- Crea un widget tasklist
    s.mytasklist = awful.widget.tasklist {
        screen  = s,
        filter  = awful.widget.tasklist.filter.currenttags,
        buttons = tasklist_buttons
    }

    -- Crea la wibox
    s.mywibox = awful.wibar({ position = "top", screen = s })

    -- Añade widgets a la wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Widgets de la izquierda
            layout = wibox.layout.fixed.horizontal,
            mylauncher,
            s.mytaglist,
            s.mypromptbox,
        },
        s.mytasklist, -- Widget central
        { -- Widgets de la derecha
            layout = wibox.layout.fixed.horizontal,
            mykeyboardlayout,
            wibox.widget.systray(),
            mytextclock,
            s.mylayoutbox,
        },
    }
end)
-- }}}

-- {{{ Mouse bindings
root.buttons(gears.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end)
))
-- }}}

-- {{{ Key bindings
globalkeys = gears.table.join(
    awful.key({ modkey,           }, "s",      hotkeys_popup.show_help,
              {description="mostrar ayuda", group="awesome"}),
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev,
              {description = "ver tag anterior", group = "tag"}),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext,
              {description = "ver tag siguiente", group = "tag"}),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore,
              {description = "volver al tag anterior", group = "tag"}),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
        end,
        {description = "enfocar siguiente cliente por índice", group = "client"}
    ),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
        end,
        {description = "enfocar cliente anterior por índice", group = "client"}
    ),
    awful.key({ modkey,           }, "w", function () mymainmenu:show() end,
              {description = "mostrar menú principal", group = "awesome"}),

    -- Manipulación de layouts
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end,
              {description = "intercambiar con siguiente cliente por índice", group = "client"}),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end,
              {description = "intercambiar con cliente anterior por índice", group = "client"}),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end,
              {description = "enfocar pantalla siguiente", group = "screen"}),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end,
              {description = "enfocar pantalla anterior", group = "screen"}),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto,
              {description = "saltar a cliente urgente", group = "client"}),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end,
        {description = "volver al cliente anterior", group = "client"}),

    -- Programas estándar
    awful.key({ modkey,           }, "Return", function () awful.spawn(terminal) end,
              {description = "abrir un terminal", group = "launcher"}),
    awful.key({ modkey, "Control" }, "r", awesome.restart,
              {description = "recargar awesome", group = "awesome"}),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit,
              {description = "cerrar awesome", group = "awesome"}),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)          end,
              {description = "aumentar factor de ancho maestro", group = "layout"}),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)          end,
              {description = "disminuir factor de ancho maestro", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1, nil, true) end,
              {description = "aumentar número de clientes maestros", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1, nil, true) end,
              {description = "disminuir número de clientes maestros", group = "layout"}),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1, nil, true)    end,
              {description = "aumentar número de columnas", group = "layout"}),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1, nil, true)    end,
              {description = "disminuir número de columnas", group = "layout"}),
    awful.key({ modkey,           }, "space", function () awful.layout.inc( 1)                end,
              {description = "seleccionar siguiente layout", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(-1)                end,
              {description = "seleccionar layout anterior", group = "layout"}),

    awful.key({ modkey, "Control" }, "n",
              function ()
                  local c = awful.client.restore()
                  -- Enfocar cliente restaurado
                  if c then
                    c:emit_signal(
                        "request::activate", "key.unminimize", {raise = true}
                    )
                  end
              end,
              {description = "restaurar minimizado", group = "client"}),

    -- Pantalla de bloqueo
    awful.key({ "Mod5" }, "l", function ()
        awful.spawn("dm-tool switch-to-greeter") end,
        {description = "Bloquear pantalla", group = "launcher"}),

    -- Lanzador de navegador
     awful.key({ modkey }, "b", function ()
        awful.spawn("/usr/bin/firefox") end,
        {description = "Lanzar navegador", group = "launcher"}),

    -- Dmenu
    awful.key({ modkey }, "r", function ()
            awful.spawn("dmenu_run") end,
              {description = "lanzar dmenu", group = "launcher"}),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run {
                    prompt       = "Run Lua code: ",
                    textbox      = awful.screen.focused().mypromptbox.widget,
                    exe_callback = awful.util.eval,
                    history_path = awful.util.get_cache_dir() .. "/history_eval"
                  }
              end,
              {description = "prompt para ejecutar Lua", group = "awesome"}),
    -- Menubar
    awful.key({ modkey }, "p", function() menubar.show() end,
              {description = "mostrar menubar", group = "launcher"})
)

clientkeys = gears.table.join(
    awful.key({ modkey,           }, "f",
        function (c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        {description = "alternar fullscreen", group = "client"}),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end,
              {description = "cerrar", group = "client"}),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ,
              {description = "alternar flotabilidad", group = "client"}),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end,
              {description = "mover al maestro", group = "client"}),
    awful.key({ modkey,           }, "o",      function (c) c:move_to_screen()               end,
              {description = "mover a pantalla", group = "client"}),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end,
              {description = "alternar mantener encima", group = "client"}),
    awful.key({ modkey,           }, "n",
        function (c)
            -- El cliente actualmente tiene el foco de entrada, por lo que no puede ser
            -- minimizado, ya que los clientes minimizados no pueden tener el foco.
            c.minimized = true
        end ,
        {description = "minimizar", group = "client"}),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized = not c.maximized
            c:raise()
        end ,
        {description = "(des)maximizar", group = "client"}),
    awful.key({ modkey, "Control" }, "m",
        function (c)
            c.maximized_vertical = not c.maximized_vertical
            c:raise()
        end ,
        {description = "(des)maximizar verticalmente", group = "client"}),
    awful.key({ modkey, "Shift"   }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c:raise()
        end ,
        {description = "(des)maximizar horizontalmente", group = "client"})
)

-- Vincula todas las teclas numéricas a tags.
-- Ten cuidado: usamos keycodes para que funcione en cualquier distribución de teclado.
-- Esto debería mapearse en la fila superior de tu teclado, usualmente 1 a 9.
for i = 1, 9 do
    globalkeys = gears.table.join(globalkeys,
        -- Ver tag solo.
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                           tag:view_only()
                        end
                  end,
                  {description = "ver tag #"..i, group = "tag"}),
        -- Alternar la visualización del tag.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = awful.screen.focused()
                      local tag = screen.tags[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end,
                  {description = "alternar tag #" .. i, group = "tag"}),
        -- Mover cliente al tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:move_to_tag(tag)
                          end
                     end
                  end,
                  {description = "mover cliente enfocado al tag #"..i, group = "tag"}),
        -- Alternar el tag en el cliente enfocado.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:toggle_tag(tag)
                          end
                      end
                  end,
                  {description = "alternar cliente enfocado en tag #" .. i, group = "tag"})
    )
end

clientbuttons = gears.table.join(
    awful.button({ }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
    end),
    awful.button({ modkey }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.move(c)
    end),
    awful.button({ modkey }, 3, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.resize(c)
    end)
)

-- Establece las teclas
root.keys(globalkeys)
-- }}}

-- {{{ Reglas
-- Reglas para aplicar a nuevos clientes (a través de la señal "manage").
awful.rules.rules = {
    -- Todas las ventanas coincidirán con esta regla.
    { rule = { },
      properties = {
          border_width = beautiful.border_width,
          border_color = beautiful.border_normal,
          focus = awful.client.focus.filter,
          raise = true,
          keys = clientkeys,
          buttons = clientbuttons,
          screen = awful.screen.preferred,
          placement = awful.placement.no_overlap + awful.placement.no_offscreen,
          -- Asegura que las ventanas no se inicien maximized
          maximized = false,
          maximized_vertical = false,
          maximized_horizontal = false,
          size_hints_honor = false,
      }
    },

    -- Clientes flotantes.
    { rule_any = {
        instance = {
          "DTA",  -- Complemento DownThemAll de Firefox.
          "copyq",  -- Incluye el nombre de la sesión en la clase.
          "pinentry",
        },
        class = {
          "Arandr",
          "Blueman-manager",
          "Gpick",
          "Kruler",
          "MessageWin",  -- kalarm.
          "Sxiv",
          "Tor Browser", -- Necesita un tamaño de ventana fijo para evitar el fingerprinting por tamaño de pantalla.
          "Wpa_gui",
          "veromix",
          "xtightvncviewer",
        },
        name = {
          "Event Tester",  -- xev.
        },
        role = {
          "AlarmWindow",  -- Calendario de Thunderbird.
          "ConfigManager",  -- about:config de Thunderbird.
          "pop-up",       -- p.ej. Herramientas de Desarrollo de Google Chrome (desconectadas).
        }
      }, properties = { floating = true }},

    -- Reglas específicas para aplicaciones que no deseas que sean flotantes
    -- y que no se inicien maximized.
    {
        rule = { class = "Sublime_text" },
        properties = {
            floating = false,
            maximized = false,
            maximized_vertical = false,
            maximized_horizontal = false,
            size_hints_honor = false,
        }
    },
    {
        rule = { class = "org.gnome.Nautilus" },
        properties = {
            floating = false,
            maximized = false,
            maximized_vertical = false,
            maximized_horizontal = false,
            size_hints_honor = false,
	    layout = awful.layout.suit.tile,
        }
    },

    -- Añade titlebars a clientes normales y diálogos (comentado para un aspecto más minimalista)
    -- { rule_any = {type = { "normal", "dialog" }
    --  }, properties = { titlebars_enabled = true }
    -- },

    -- Configuración adicional de reglas puede ir aquí
    -- Ejemplo: Firefox siempre en el tag "2" en pantalla 1
    -- { rule = { class = "Firefox" },
    --   properties = { screen = 1, tag = "2" } },
}
-- }}}

-- {{{ Señales
-- Función de señal para ejecutar cuando aparece un nuevo cliente.
client.connect_signal("manage", function (c)
    -- Configura las ventanas como esclavas,
    -- es decir, ponlas al final de otras en lugar de establecerlas como maestro.
    -- if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup
      and not c.size_hints.user_position
      and not c.size_hints.program_position then
        -- Previene que los clientes sean inaccesibles después de cambios en el número de pantallas.
        awful.placement.no_offscreen(c)
    end
end)

-- Configura las esquinas redondeadas para cada cliente
client.connect_signal("manage", function (c)
    c.shape = function(cr, w, h)
        gears.shape.rounded_rect(cr, w, h, 7)
    end
end)

-- Cambia el color del borde al enfocarse/desenfocarse
client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

-- {{{ Gaps
-- Establece gaps entre ventanas
beautiful.useless_gap = 2
-- }}}

-- {{{ Autostart
-- Ejecuta aplicaciones al inicio
awful.spawn.with_shell("picom") -- Compositor para transparencias y sombras
awful.spawn.with_shell("nitrogen --set-zoom-fill --random /home/jaimedalton/Pictures/Wallpapers") -- Gestor de fondos de pantalla
awful.spawn.with_shell("flameshot") -- Herramienta de capturas de pantalla
awful.spawn.with_shell("barrier") -- Sincronización de teclado y mouse entre dispositivos
awful.spawn.with_shell("light-locker") -- Gestor de bloqueo de pantalla
-- }}}
