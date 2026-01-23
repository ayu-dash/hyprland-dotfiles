#!/bin/bash
clear

# ============================================================================
# CONFIGURATION
# ============================================================================

# Repository URLs
YAY_REPO="https://aur.archlinux.org/yay-git.git"
WALLPAPER_REPO="https://github.com/ayu-dash/wallpapers.git"
OH_MY_ZSH_REPO="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"

# Directories
HOME_DIR="$HOME"
DOTFILES_DIR="$HOME_DIR/hyprland-dotfiles"
CONFIG_DIR="$HOME_DIR/.config"
THEMES_DIR="$HOME_DIR/.themes"
ICONS_DIR="$HOME_DIR/.icons"
BIN_DIR="$HOME_DIR/.local/bin"
TEMP_DIR="/tmp/installation"

# Package list files
PACMAN_PACKAGES="$DOTFILES_DIR/pacman-packages.txt"
YAY_PACKAGES="$DOTFILES_DIR/yay-packages.txt"

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

print_header() {
    echo ""
    echo "========================================"
    echo "  $1"
    echo "========================================"
    echo ""
}

confirm_prompt() {
    local message="$1"
    local default="$2"
    read -p "$message " choice
    choice=${choice:-$default}
    echo "$choice" | tr '[:upper:]' '[:lower:]'
}

install_packages_from_file() {
    local file="$1"
    local installer="$2"
    
    while IFS= read -r package || [[ -n "$package" ]]; do
        [[ -z "$package" || "$package" =~ ^# ]] && continue
        $installer -S --noconfirm "$package"
    done < "$file"
}

# ============================================================================
# PRE-FLIGHT CHECKS
# ============================================================================

if [[ $EUID -eq 0 ]]; then
    echo "This script should not be executed as root! Exiting..."
    exit 1
fi

# ============================================================================
# WELCOME BANNER
# ============================================================================

cat << EOF
                         __                __
 .---.-..--.--..--.--..--|  |.---.-..-----.|  |--.
 |  _  ||  |  ||  |  ||  _  ||  _  ||__ --||     |
 |___._||___  ||_____||_____||___._||_____||__|__|
        |_____|
             
EOF

echo "This process will replace your previous configurations."
choice=$(confirm_prompt "Do you want to continue? [y/N]:" "n")

if [[ "$choice" == "n" ]]; then
    exit 0
fi

# ============================================================================
# PACKAGE INSTALLATION
# ============================================================================

print_header "Installing Pacman Packages"
install_packages_from_file "$PACMAN_PACKAGES" "sudo pacman"

print_header "Installing Yay (AUR Helper)"
if ! command -v yay &> /dev/null; then
    mkdir -p "$TEMP_DIR"
    git clone "$YAY_REPO" "$TEMP_DIR/yay"
    cd "$TEMP_DIR/yay" && makepkg -si && cd -
else
    echo "Yay is already installed."
fi

print_header "Installing AUR Packages"
install_packages_from_file "$YAY_PACKAGES" "yay"

print_header "Installing VS Code Extensions"
if command -v code &> /dev/null; then
    xargs -n 1 code --install-extension < "$DOTFILES_DIR/etc/CodeExtensions.txt"
else
    echo "VS Code not found, skipping extensions."
fi

# ============================================================================
# DOTFILES INSTALLATION
# ============================================================================

print_header "Installing Dotfiles"

# Create required directories
mkdir -p "$CONFIG_DIR" "$BIN_DIR" "$THEMES_DIR" "$ICONS_DIR"

# Update XDG directories
xdg-user-dirs-update 2>&1

# Copy config files
for dir in "$DOTFILES_DIR/config/"*; do
    dir_name=$(basename "$dir")
    if cp -R "$dir" "$CONFIG_DIR/"; then
        echo "✓ Installed: $dir_name"
    else
        echo "✗ Failed: $dir_name"
    fi
done

# Copy bin scripts
if cp -R "$DOTFILES_DIR/bin/"* "$BIN_DIR/"; then
    chmod +x "$BIN_DIR"/*
    echo "✓ Installed: bin scripts"
else
    echo "✗ Failed: bin scripts"
fi

# ============================================================================
# SHELL CONFIGURATION
# ============================================================================

print_header "Configuring Shell"

# Install Oh My Zsh
echo "Installing Oh My Zsh..."
RUNZSH=no sh -c "$(curl -fsSL $OH_MY_ZSH_REPO)"

# Install Zsh plugins
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions" 2>/dev/null
git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" 2>/dev/null
git clone https://github.com/zsh-users/zsh-completions "$ZSH_CUSTOM/plugins/zsh-completions" 2>/dev/null
git clone https://github.com/zsh-users/zsh-history-substring-search "$ZSH_CUSTOM/plugins/zsh-history-substring-search" 2>/dev/null

# Copy zshrc
cp -f "$DOTFILES_DIR/.zshrc" "$HOME/"

# Set default shell
chsh -s /usr/bin/zsh

# ============================================================================
# FONTS & THEMES
# ============================================================================

print_header "Configuring Fonts & Themes"

# Extract all icons from assets/icons
echo "Installing icons..."
if [ -d "$DOTFILES_DIR/assets/icons" ]; then
    for archive in "$DOTFILES_DIR/assets/icons"/*.tar.xz; do
        [ -f "$archive" ] || continue
        name=$(basename "$archive" .tar.xz)
        tar xvf "$archive" -C "$ICONS_DIR" && echo "✓ $name installed"
    done
fi

# Extract all themes from assets/themes
echo "Installing themes..."
if [ -d "$DOTFILES_DIR/assets/themes" ]; then
    for archive in "$DOTFILES_DIR/assets/themes"/*.tar.xz; do
        [ -f "$archive" ] || continue
        name=$(basename "$archive" .tar.xz)
        tar xvf "$archive" -C "$THEMES_DIR" && echo "✓ $name installed"
    done
fi

# Rebuild font cache
fc-cache -rv >/dev/null 2>&1
echo "✓ Font cache updated"

# ============================================================================
# SYSTEM SERVICES
# ============================================================================

print_header "Enabling System Services"

SERVICES=(ly bluetooth NetworkManager udisks2 tailscaled)

for service in "${SERVICES[@]}"; do
    if systemctl list-unit-files | grep -q "^$service"; then
        sudo systemctl enable "$service"
        echo "✓ Enabled: $service"
    else
        echo "⚠ Not found: $service"
    fi
done

# ============================================================================
# COMPLETION
# ============================================================================

print_header "Installation Complete!"

echo "Your Hyprland dotfiles have been installed successfully."
echo ""

choice=$(confirm_prompt "Reboot now? [y/N]:" "n")

if [[ "$choice" == "y" ]]; then
    systemctl reboot
fi
