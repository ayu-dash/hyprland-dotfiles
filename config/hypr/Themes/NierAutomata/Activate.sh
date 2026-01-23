#!/bin/bash

# =============================================================================
# NierAutomata Theme Activation Script
# =============================================================================
# This script activates the NierAutomata theme by:
# 1. Writing theme path to loader/variable files
# 2. Setting environment variables for Hyprland
# 3. Restarting theme-dependent services (SwayNC, Waybar)
# =============================================================================

# ── Configuration ───────────────────────────────────────────────────────────

LOADER_FILE="$HOME/.config/hypr/Themes/ThemeLoader.conf"
VAR_FILE="$HOME/.config/hypr/Themes/ThemeVariables.conf"
THEME_DIR="$HOME/.config/hypr/Themes/NierAutomata"

# ── Write Theme Configuration ───────────────────────────────────────────────

echo "exec-once = $THEME_DIR/Activate.sh" > "$LOADER_FILE"
echo "\$theme_dir = $THEME_DIR" > "$VAR_FILE"

# ── Set Environment Variables ───────────────────────────────────────────────

hyprctl keyword env "HYPR_THEME_DIR,$THEME_DIR"
hyprctl keyword env "KITTY_CONFIG_DIRECTORY,$THEME_DIR/Kitty/"

# ── Restart Services ────────────────────────────────────────────────────────

# SwayNC (Notification Center)
pkill swaync
swaync -c "$THEME_DIR/Swaync/Config.json" -s "$THEME_DIR/Swaync/Style.css" > /dev/null 2>&1 &

# Waybar
pkill waybar
waybar -c "$THEME_DIR/Bar/Config.jsonc" -s "$THEME_DIR/Bar/Config.css" > /dev/null 2>&1 &

exit 0