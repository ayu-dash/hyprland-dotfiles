-- =============================================================================
-- NierAutomata Theme - Decoration & Animation Settings (Lua version)
-- =============================================================================

local colors = require("Themes.CatppucinMocha.colors")

-- General
hl.config({
  general = {
    gaps_in = 5,
    gaps_out = 10,
    border_size = 1,
    ["col.active_border"] = colors.border_focus,
    ["col.inactive_border"] = colors.border,
    resize_on_border = false,
    allow_tearing = false,
    layout = "dwindle",
  }
})

-- Decoration
hl.config({
  decoration = {
    rounding = 8,
    active_opacity = 1,
    inactive_opacity = 0.9,
    shadow = {
      enabled = true,
      range = 4,
      render_power = 3,
      color = colors.shadow,
    },
    blur = {
      enabled = true,
      size = 10,
      passes = 1,
      vibrancy = 0.1696,
    },
  }
})

-- Bezier curves
hl.curve("instant", { type = "bezier", points = { { 0, 0 }, { 0.1, 1 } } })
hl.curve("fast_decel", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1 } } })

-- Animations
hl.config({
  animations = {
    enabled = true,
  }
})

hl.animation({ leaf = "windows", enabled = true, speed = 2, bezier = "fast_decel", style = "popin 80%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2, bezier = "instant", style = "popin 85%" })
hl.animation({ leaf = "border", enabled = true, speed = 1, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 2, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2.5, bezier = "fast_decel", style = "slide" })
