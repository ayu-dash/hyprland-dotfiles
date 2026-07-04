-- =============================================================================
-- Catppuccin Mocha Color Palette for Hyprland (Lua version)
-- =============================================================================

local colors = {}

-- Core Background & Text
colors.background      = "rgba(1e1e2eaa)" -- base
colors.background_alt  = "rgba(181825aa)" -- mantle
colors.foreground      = "rgba(cdd6f4aa)" -- text
colors.foreground_alt  = "rgba(bac2deaa)" -- subtext1

-- Surface Layers (Depth)
colors.surface_0       = "rgba(313244aa)"
colors.surface_1       = "rgba(45475aaa)"
colors.surface_2       = "rgba(585b70aa)"
colors.surface_3       = "rgba(6c7086aa)"

-- Accent System
colors.accent          = "rgba(cba6f7aa)" -- mauve
colors.accent_alt      = "rgba(f5c2e7aa)" -- pink
colors.accent_dim      = "rgba(f5e0dcaa)" -- rosewater

-- Semantic Colors
colors.success         = "rgba(a6e3a1aa)" -- green
colors.warning         = "rgba(f9e2afaa)" -- yellow
colors.info            = "rgba(89b4faaa)" -- blue
colors.danger          = "rgba(f38ba8aa)" -- red

-- Border & Focus
colors.border          = "rgba(313244aa)" -- surface0
colors.border_focus    = "rgba(cba6f7aa)" -- mauve
colors.border_urgent   = "rgba(f38ba8aa)" -- red

-- Selection & Cursor
colors.selection_bg    = "rgba(585b70aa)" -- surface2
colors.selection_fg    = "rgba(cdd6f4aa)" -- text
colors.cursor          = "rgba(f5e0dcaa)" -- rosewater

-- Overlay & State
colors.overlay         = "rgba(00000088)"
colors.shadow          = "rgba(11111baa)" -- crust
colors.highlight       = "rgba(45475aaa)" -- surface1
colors.disabled        = "rgba(6c7086aa)" -- overlay0

-- Terminal ANSI Colors (Role-Based)
colors.color0  = "rgba(45475aaa)"
colors.color1  = "rgba(f38ba8aa)"
colors.color2  = "rgba(a6e3a1aa)"
colors.color3  = "rgba(f9e2afaa)"
colors.color4  = "rgba(89b4faaa)"
colors.color5  = "rgba(f5c2e7aa)"
colors.color6  = "rgba(94e2d5aa)"
colors.color7  = "rgba(bac2deaa)"
colors.color8  = "rgba(585b70aa)"
colors.color9  = "rgba(f38ba8aa)"
colors.color10 = "rgba(a6e3a1aa)"
colors.color11 = "rgba(f9e2afaa)"
colors.color12 = "rgba(89b4faaa)"
colors.color13 = "rgba(f5c2e7aa)"
colors.color14 = "rgba(94e2d5aa)"
colors.color15 = "rgba(a6adc8aa)"

return colors
