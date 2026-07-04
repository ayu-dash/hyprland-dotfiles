#!/bin/bash

# =============================================================================
# Celestia Theme Activation Script
# Uses Caelestia Shell (QuickShell) instead of Waybar + Swaync
# =============================================================================

HYPR_DIR="$HOME/.config/hypr"
THEME_NAME="Caelestia"
THEME_DIR="$HYPR_DIR/Themes/$THEME_NAME"

# ── Write Theme Configuration ───────────────────────────────────────────────
echo "\$theme_dir = \$HOME/.config/hypr/Themes/$THEME_NAME" > "$HYPR_DIR/Themes/ThemeVariables.conf"
echo "exec-once = \$HOME/.config/hypr/Themes/$THEME_NAME/Activate.sh" > "$HYPR_DIR/Themes/ThemeLoader.conf"

# ── Set Environment Variables ───────────────────────────────────────────────
# (Managed dynamically by Configs/envs.lua in the new Lua configuration)

# ── GTK / Libadwaita Dark Theme & Service Cleanup ───────────────────────────
# Run these asynchronously in the background so they do not block shell startup
(
  gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
  kvantummanager --set KvLibadwaitaDark
  killall -q swaync waybar
) &>/dev/null &

# ── Deploy Caelestia Shell Config ───────────────────────────────────────────
mkdir -p "$HOME/.config/caelestia"
ln -sf "$THEME_DIR/shell.json" "$HOME/.config/caelestia/shell.json"

# ── Symlink local shell fork to QuickShell config dir ───────────────────────
QUICKSHELL_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell"
mkdir -p "$QUICKSHELL_CONFIG"
ln -sfn "$THEME_DIR/Shell" "$QUICKSHELL_CONFIG/caelestia"

# ── Start Caelestia Shell (QuickShell) ──────────────────────────────────────
# Export user-local QML import path
export PATH="$HOME/.local/bin:$PATH"
export QML2_IMPORT_PATH="$HOME/.local/lib/qt6/qml:$QML2_IMPORT_PATH"
export QT_QPA_PLATFORMTHEME=qt6ct

# Build C++ QML Plugin if needed
PLUGIN_DIR="$HOME/.local/lib/qt6/qml/Caelestia"
M3SHAPES_DIR="$HOME/.local/lib/qt6/qml/M3Shapes"
if [ ! -d "$PLUGIN_DIR" ] || [ ! -d "$M3SHAPES_DIR" ]; then
  echo "[Celestia] Building C++ QML plugins (Caelestia & M3Shapes)..."
  BUILD_DIR="$THEME_DIR/Shell/build"
  mkdir -p "$BUILD_DIR"
  if cmake -B "$BUILD_DIR" -S "$THEME_DIR/Shell" \
     -DCMAKE_INSTALL_PREFIX="$HOME/.local" \
     -DINSTALL_QMLDIR="lib/qt6/qml" \
     -DVERSION="1.0.0" \
     -DGIT_REVISION="local" \
     -DENABLE_MODULES="plugin;m3shapes"; then
    cmake --build "$BUILD_DIR" && cmake --install "$BUILD_DIR"
    echo "[Celestia] QML plugins built and installed successfully."
  else
    echo "[Celestia] Error configuring/building QML plugins"
  fi
fi

# Kill existing quickshell instance if running, and only sleep if we actually killed one
if killall -q quickshell qs 2>/dev/null; then
  sleep 0.3
fi

# Start Caelestia Shell
if command -v caelestia &>/dev/null; then
  caelestia shell -d &
elif command -v quickshell &>/dev/null; then
  quickshell -c caelestia &
else
  qs -c caelestia &
fi

exit 0
