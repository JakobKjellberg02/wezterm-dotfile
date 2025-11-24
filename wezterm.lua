-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

-- Font
config.font = wezterm.font("JetBrainsMonoNL Nerd Font")

-- Window
config.window_decorations = "RESIZE"
config.window_background_opacity = 0.95
-- Color
config.color_scheme = 'Gruvbox Dark (Gogh)'
config.colors = {
  tab_bar = {
    background = "#1d2021", -- background behind tab bar

    active_tab = {
      bg_color = "#d79921",
      fg_color = "#282828",
      intensity = "Bold",
    },

    inactive_tab = {
      bg_color = "#3c3836",
      fg_color = "#a89984",
    },

    inactive_tab_hover = {
      bg_color = "#504945",
      fg_color = "#ebdbb2",
    },

    new_tab = {
      bg_color = "#1d2021",
      fg_color = "#928374",
    },

    new_tab_hover = {
      bg_color = "#3c3836",
      fg_color = "#ebdbb2",
    },
  }
}


-- tmux
config.leader = { key = "q", mods = "ALT", timeout_milliseconds = 3000 }
config.keys = {
    {
        mods = "LEADER",
        key = "c",
        action = wezterm.action.SpawnTab "CurrentPaneDomain",
    },
    {
        mods = "LEADER",
        key = "x",
        action = wezterm.action.CloseCurrentPane { confirm = true }
    },
    {
        mods = "LEADER",
        key = "b",
        action = wezterm.action.ActivateTabRelative(-1)
    },
    {
        mods = "LEADER",
        key = "n",
        action = wezterm.action.ActivateTabRelative(1)
    },
    {
        mods = "LEADER",
        key = "|",
        action = wezterm.action.SplitHorizontal { domain = "CurrentPaneDomain" }
    },
    {
        mods = "LEADER",
        key = "-",
        action = wezterm.action.SplitVertical { domain = "CurrentPaneDomain" }
    },
    {
        mods = "LEADER",
        key = "h",
        action = wezterm.action.ActivatePaneDirection "Left"    
    },
    {
        mods = "LEADER",
        key = "j",
        action = wezterm.action.ActivatePaneDirection "Down"
    },
    {
        mods = "LEADER",
        key = "k",
        action = wezterm.action.ActivatePaneDirection "Up"
    },
    {
        mods = "LEADER",
        key = "l",
        action = wezterm.action.ActivatePaneDirection "Right"
    },
    {
        mods = "LEADER",
        key = "LeftArrow",
        action = wezterm.action.AdjustPaneSize { "Left", 5 }
    },
    {
        mods = "LEADER",
        key = "RightArrow",
        action = wezterm.action.AdjustPaneSize { "Right", 5 }
    },
    {
        mods = "LEADER",
        key = "DownArrow",
        action = wezterm.action.AdjustPaneSize { "Down", 5 }
    },
    {
        mods = "LEADER",
        key = "UpArrow",
        action = wezterm.action.AdjustPaneSize { "Up", 5 }
    },
    {
        mods = 'SHIFT|CTRL',
        key = "n",
        action = wezterm.action.ToggleFullScreen,
    },
}

for i = 0, 9 do
    -- leader + number to activate that tab
    table.insert(config.keys, {
        key = tostring(i),
        mods = "LEADER",
        action = wezterm.action.ActivateTab(i),
    })
end

-- tab bar
config.hide_tab_bar_if_only_one_tab = false
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false
config.tab_and_split_indices_are_zero_based = true

-- tmux status
wezterm.on("update-right-status", function(window, _)
    local SOLID_LEFT_ARROW = ""
    local ARROW_FOREGROUND = { Foreground = { Color = "#458588" } }
    local prefix = ""

    if window:leader_is_active() then
        prefix = " " .. utf8.char(0x0001F50D) 
        SOLID_LEFT_ARROW = utf8.char(0xe0b2)
    end

    if window:active_tab():tab_id() ~= 0 then
        ARROW_FOREGROUND = { Foreground = { Color = " 	#8ec07c" } }
    end -- arrow color based on if tab is first pane

    window:set_left_status(wezterm.format {
        { Background = { Color = " 	#458588" } },
        { Text = prefix },
        ARROW_FOREGROUND,
        { Text = SOLID_LEFT_ARROW }
    })
end)

local function get_vpn_status()
  local success_wg, out_wg = wezterm.run_child_process({
    "sh", "-c", "wg show 2>/dev/null"
  })

  if success_wg and out_wg and out_wg:match("interface: (%S+)") then
    local iface = out_wg:match("interface: (%S+)")
    return "VPN: ON (" .. iface .. ")", "#98971a"
  end

  local success_ip, out_ip = wezterm.run_child_process({
    "sh", "-c", "ip -o link show | awk -F': ' '{print $2}'"
  })

  if success_ip and out_ip then
    for line in out_ip:gmatch("[^\r\n]+") do
      if line:match("^proton") or line:match("^pvpn") then
        return "VPN: ON (" .. line .. ")", "#98971a"
      end
    end
  end

  return "VPN: OFF", "#cc241d"
end

wezterm.on("update-right-status", function(window, pane)
  -- vpn
  local vpn_text, vpn_color = get_vpn_status()

  -- battery
  local battery_text = ""
  local battery_color = "#756f68"

  for _, b in ipairs(wezterm.battery_info()) do
    local charge = b.state_of_charge * 100
    battery_text = string.format("%.0f%%", charge)

    if charge < 15 then
      battery_color = "#bd1313"
    elseif charge < 50 then 
      battery_color = "#bd5f13"
    else
      battery_color = "#13bd1e"
    end
    break
  end

  -- date
  local date = wezterm.strftime("%d-%m-%Y %H:%M")


  window:set_right_status(wezterm.format({
    { Foreground = { Color = vpn_color } },
    { Text = "🔒 " .. vpn_text .. "   " },

    { Foreground = { Color = battery_color } },
    { Text = "🔋 " .. battery_text .. "   " },

    { Foreground = { Color = "#b8bb26" } },
    { Text = "🕒 " .. date .. "  " },
  }))
end)

return config
