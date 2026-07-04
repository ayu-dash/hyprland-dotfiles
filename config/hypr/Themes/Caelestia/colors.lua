-- =============================================================================
-- Celestia Color Palette for Hyprland (Lua version)
-- Dynamically loads color schemes from Caelestia
-- =============================================================================

local colors = {}

-- Try to load the dynamic scheme from ~/.config/hypr/scheme/current.lua
local success, current = pcall(require, "Themes.Caelestia.Colors.color")
if not success or not current then
  current = {}
end

local function to_rgba(hex, alpha)
  if not hex then return nil end
  alpha = alpha or "ff"
  return "rgba(" .. hex .. alpha .. ")"
end

-- Core Background & Text
colors.background      = to_rgba(current.background) or "rgba(0f1119ff)"
colors.background_alt  = to_rgba(current.surfaceContainer) or "rgba(161822ff)"
colors.foreground      = to_rgba(current.onBackground) or "rgba(e2e2e9ff)"
colors.foreground_alt  = to_rgba(current.onSurfaceVariant) or "rgba(a3a4b1ff)"

-- Surface Layers (Depth)
colors.surface_0       = to_rgba(current.surface) or "rgba(0f1119ff)"
colors.surface_1       = to_rgba(current.surfaceContainerLow) or "rgba(1a1c28ff)"
colors.surface_2       = to_rgba(current.surfaceContainer) or "rgba(222536ff)"
colors.surface_3       = to_rgba(current.surfaceContainerHigh) or "rgba(2c2f44ff)"

-- Accent System (Celestial Violet / Dynamic Accent)
colors.accent          = to_rgba(current.primary) or "rgba(b4a0ffff)"
colors.accent_alt      = to_rgba(current.secondary) or "rgba(d0c4ffff)"
colors.accent_dim      = to_rgba(current.primaryContainer) or "rgba(7c6bc4ff)"

-- Semantic Colors
colors.success         = to_rgba(current.success) or "rgba(7dd3a0ff)"
colors.warning         = to_rgba(current.warning) or "rgba(f5c06bff)"
colors.info            = to_rgba(current.primary) or "rgba(7abaebff)"
colors.danger          = to_rgba(current.error) or "rgba(f07085ff)"

-- Border & Focus
colors.border          = to_rgba(current.outlineVariant) or "rgba(2c2f44ff)"
colors.border_focus    = to_rgba(current.primary) or "rgba(b4a0ffff)"
colors.border_urgent   = to_rgba(current.error) or "rgba(f07085ff)"

-- Selection & Cursor
colors.selection_bg    = to_rgba(current.secondaryContainer) or "rgba(33365cff)"
colors.selection_fg    = to_rgba(current.onSecondaryContainer) or "rgba(f0f0f8ff)"
colors.cursor          = to_rgba(current.primary) or "rgba(b4a0ffff)"

-- Overlay & State
colors.overlay         = to_rgba(current.scrim, "88") or "rgba(00000088)"
colors.shadow          = to_rgba(current.shadow, "9a") or "rgba(0000009a)"
colors.highlight       = to_rgba(current.secondaryContainer) or "rgba(33365cff)"
colors.disabled        = to_rgba(current.outline, "aa") or "rgba(5a5c71ff)"

-- Terminal ANSI Colors (Role-Based)
colors.color0  = to_rgba(current.term0) or "rgba(0f1119ff)"
colors.color1  = to_rgba(current.term1) or "rgba(f07085ff)"
colors.color2  = to_rgba(current.term2) or "rgba(7dd3a0ff)"
colors.color3  = to_rgba(current.term3) or "rgba(f5c06bff)"
colors.color4  = to_rgba(current.term4) or "rgba(7abaebff)"
colors.color5  = to_rgba(current.term5) or "rgba(b4a0ffff)"
colors.color6  = to_rgba(current.term6) or "rgba(6ed4daff)"
colors.color7  = to_rgba(current.term7) or "rgba(e2e2e9ff)"
colors.color8  = to_rgba(current.term8) or "rgba(2c2f44ff)"
colors.color9  = to_rgba(current.term9) or "rgba(ff8fa2ff)"
colors.color10 = to_rgba(current.term10) or "rgba(a0f0c0ff)"
colors.color11 = to_rgba(current.term11) or "rgba(ffd68eff)"
colors.color12 = to_rgba(current.term12) or "rgba(9dd0f5ff)"
colors.color13 = to_rgba(current.term13) or "rgba(d0c4ffff)"
colors.color14 = to_rgba(current.term14) or "rgba(90e8efff)"
colors.color15 = to_rgba(current.term15) or "rgba(f0f0f8ff)"

return colors
