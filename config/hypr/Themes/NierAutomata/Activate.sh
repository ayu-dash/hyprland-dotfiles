#!/bin/bash

# =============================================================================
# Theme Activation Script
# =============================================================================

HYPR_DIR="$HOME/.config/hypr"
THEME_NAME="NierAutomata"
THEME_DIR="$HYPR_DIR/Themes/$THEME_NAME"
LOCK_FILE="/tmp/theme_loading.lock"

# ── Write Theme Configuration ───────────────────────────────────────────────

echo "exec-once = \$HOME/.config/hypr/Themes/$THEME_NAME/Activate.sh" > "$HYPR_DIR/Themes/ThemeLoader.conf"
echo "\$theme_dir = \$HOME/.config/hypr/Themes/$THEME_NAME" > "$HYPR_DIR/Themes/ThemeVariables.conf"

# ── Set Environment Variables ───────────────────────────────────────────────

hyprctl keyword env "HYPR_THEME_DIR,$THEME_DIR"
hyprctl keyword env "KITTY_CONFIG_DIRECTORY,$THEME_DIR/Kitty/"

# ── Restart Services ────────────────────────────────────────────────────────
touch "$LOCK_FILE"
killall -qw swaync waybar

swaync -c "$THEME_DIR/Swaync/Config.json" -s "$THEME_DIR/Swaync/Style.css" &
waybar -c "$THEME_DIR/Bar/Config.jsonc" -s "$THEME_DIR/Bar/Config.css" &

disown -a

sleep 1.5
rm -f "$LOCK_FILE"

exit 0
