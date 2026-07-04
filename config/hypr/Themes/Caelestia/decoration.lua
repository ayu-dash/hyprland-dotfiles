-- =============================================================================
-- Celestia Theme - Decoration & Animation Settings (Lua version)
-- Modern, fluid design inspired by Caelestia Shell
-- =============================================================================

local colors = require("Themes.Caelestia.colors")

-- General
hl.config({
  general = {
    gaps_in = 4,
    gaps_out = 8,
    border_size = 2,
    ["col.active_border"] = colors.border_focus,
    ["col.inactive_border"] = colors.border,
    resize_on_border = true,
    allow_tearing = false,
    layout = "dwindle",
  }
})

-- Decoration
hl.config({
  decoration = {
    rounding = 12,
    active_opacity = 1,
    inactive_opacity = 0.92,
    shadow = {
      enabled = true,
      range = 12,
      render_power = 3,
      color = colors.shadow,
    },
    blur = {
      enabled = true,
      size = 12,
      passes = 3,
      noise = 0.02,
      contrast = 0.9,
      brightness = 0.8,
      vibrancy = 0.2,
      vibrancy_darkness = 0.5,
    },
  }
})

-- Bezier curves (fluid, Caelestia-inspired)
hl.curve("fluid_decel", { type = "bezier", points = { { 0.05, 0.7 }, { 0.1, 1.0 } } })
hl.curve("fluid_accel", { type = "bezier", points = { { 0.3, 0.0 }, { 0.8, 0.15 } } })
hl.curve("overshoot",   { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
hl.curve("smooth",      { type = "bezier", points = { { 0.25, 0.1 }, { 0.25, 1.0 } } })

-- Animations
hl.config({
  animations = {
    enabled = true,
  }
})

hl.animation({ leaf = "windows", enabled = true, speed = 3, bezier = "overshoot", style = "popin 80%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2.5, bezier = "fluid_accel", style = "popin 85%" })
hl.animation({ leaf = "border", enabled = true, speed = 2, bezier = "smooth" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 30, bezier = "smooth", style = "loop" })
hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "smooth" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "fluid_decel", style = "slide" })
