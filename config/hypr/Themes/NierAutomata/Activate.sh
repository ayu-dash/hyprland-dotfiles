#!/bin/bash

# =============================================================================
# Theme Activation Script
# =============================================================================

HYPR_DIR="$HOME/.config/hypr"
THEME_NAME="NierAutomata"
THEME_DIR="$HYPR_DIR/Themes/$THEME_NAME"

# ── Write Theme Configuration ───────────────────────────────────────────────

echo "exec-once = \$HOME/.config/hypr/Themes/$THEME_NAME/Activate.sh" > "$HYPR_DIR/Themes/ThemeLoader.conf"
echo "\$theme_dir = \$HOME/.config/hypr/Themes/$THEME_NAME" > "$HYPR_DIR/Themes/ThemeVariables.conf"

# ── Set Environment Variables ───────────────────────────────────────────────

hyprctl keyword env "HYPR_THEME_DIR,$THEME_DIR"
hyprctl keyword env "KITTY_CONFIG_DIRECTORY,$THEME_DIR/Kitty/"

# ── Restart Services ────────────────────────────────────────────────────────

pkill swaync
swaync -c "$THEME_DIR/Swaync/Config.json" -s "$THEME_DIR/Swaync/Style.css" &>/dev/null &

pkill waybar
waybar -c "$THEME_DIR/Bar/Config.jsonc" -s "$THEME_DIR/Bar/Config.css" &>/dev/null &

exit 0