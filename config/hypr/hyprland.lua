-- =============================================================================
-- Hyprland Configuration (Lua)
-- =============================================================================
-- Entry point - loads all config modules via require()
-- Backup of original hyprlang config: ~/.config/hypr.backup.*
-- =============================================================================

-- Environment variables
require("Configs.envs")

-- Autostart applications
require("Configs.autostart")

-- Keybindings
require("Configs.keybinds")

-- Monitor configuration
require("Configs.monitor")

-- Workspace rules
require("Configs.workspaces")

-- Window rules
require("Configs.window_rules")

-- Input & gestures
require("Configs.input")

-- Cursor settings
require("Configs.cursors")

-- Dynamic active theme loader
local function get_active_theme()
  local file = io.open(os.getenv("HOME") .. "/.config/hypr/Themes/ThemeVariables.conf", "r")
  if not file then return "NierAutomata" end
  local content = file:read("*all")
  file:close()
  local theme = content:match("%$theme_dir%s*=%s*%S+/Themes/([%w_-]+)")
  return theme or "NierAutomata"
end

local active_theme = get_active_theme()
require("Themes." .. active_theme .. ".decoration")

-- Layout
hl.config({
  master = {
    new_status = "master",
  }
})

-- Misc
hl.config({
  misc = {
    force_default_wallpaper = 0,
    disable_hyprland_logo = true,
  }
})
