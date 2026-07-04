#!/bin/bash

# =============================================================================
# Theme Activation Script
# =============================================================================

HYPR_DIR="$HOME/.config/hypr"
THEME_NAME="CatppucinMocha"
THEME_DIR="$HYPR_DIR/Themes/$THEME_NAME"

# ── Write Theme Configuration ───────────────────────────────────────────────
echo "\$theme_dir = \$HOME/.config/hypr/Themes/$THEME_NAME" > "$HYPR_DIR/Themes/ThemeVariables.conf"
echo "exec-once = \$HOME/.config/hypr/Themes/$THEME_NAME/Activate.sh" > "$HYPR_DIR/Themes/ThemeLoader.conf"

# ── Set Environment Variables ───────────────────────────────────────────────
hyprctl eval "hl.env('HYPR_THEME_DIR', '$THEME_DIR')"
if [ -d "$THEME_DIR/Kitty" ]; then
    hyprctl eval "hl.env('KITTY_CONFIG_DIRECTORY', '$THEME_DIR/Kitty/')"
fi

# ── GTK / Libadwaita Dark Theme ─────────────────────────────────────────────
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
kvantummanager --set KvLibadwaitaDark

# ── Restart Services ────────────────────────────────────────────────────────
killall -qw swaync waybar

if [ -f "$THEME_DIR/Swaync/Config.json" ]; then
    swaync -c "$THEME_DIR/Swaync/Config.json" -s "$THEME_DIR/Swaync/Style.css" > /dev/null 2>&1 &
else
    swaync > /dev/null 2>&1 &
fi

waybar -c "$THEME_DIR/Bar/Config.jsonc" -s "$THEME_DIR/Bar/Config.css" > /dev/null 2>&1 &

exit 0
