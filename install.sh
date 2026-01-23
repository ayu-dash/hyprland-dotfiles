#!/bin/bash

# =============================================================================
# Hyprland Dotfiles Installer v2.0
# =============================================================================

# ── Colors ──────────────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ── Configuration ───────────────────────────────────────────────────────────

YAY_REPO="https://aur.archlinux.org/yay-git.git"
OH_MY_ZSH_REPO="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"

HOME_DIR="$HOME"
DOTFILES_DIR="$HOME_DIR/hyprland-dotfiles"
CONFIG_DIR="$HOME_DIR/.config"
THEMES_DIR="$HOME_DIR/.themes"
ICONS_DIR="$HOME_DIR/.icons"
BIN_DIR="$HOME_DIR/.local/bin"
TEMP_DIR="/tmp/installation"

PACMAN_PACKAGES="$DOTFILES_DIR/pacman-packages.txt"
YAY_PACKAGES="$DOTFILES_DIR/yay-packages.txt"

# ── Helper Functions ────────────────────────────────────────────────────────

print_logo() {
    echo -e "${CYAN}"
    cat << 'EOF'
    
    ██╗  ██╗██╗   ██╗██████╗ ██████╗ ██╗      █████╗ ███╗   ██╗██████╗ 
    ██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗██║     ██╔══██╗████╗  ██║██╔══██╗
    ███████║ ╚████╔╝ ██████╔╝██████╔╝██║     ███████║██╔██╗ ██║██║  ██║
    ██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══██╗██║     ██╔══██║██║╚██╗██║██║  ██║
    ██║  ██║   ██║   ██║     ██║  ██║███████╗██║  ██║██║ ╚████║██████╔╝
    ╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝ 
                                                                        
EOF
    echo -e "${NC}"
    echo -e "${WHITE}                    ╭─────────────────────────────╮${NC}"
    echo -e "${WHITE}                    │   ${MAGENTA}D O T F I L E S  v2.0${WHITE}   │${NC}"
    echo -e "${WHITE}                    │      ${GRAY}by ${CYAN}ayudash${WHITE}            │${NC}"
    echo -e "${WHITE}                    ╰─────────────────────────────╯${NC}"
    echo ""
}

print_header() {
    echo ""
    echo -e "${BLUE}╭──────────────────────────────────────────────────────────────╮${NC}"
    echo -e "${BLUE}│${NC}  ${BOLD}${WHITE}$1${NC}"
    echo -e "${BLUE}╰──────────────────────────────────────────────────────────────╯${NC}"
    echo ""
}

print_step() {
    echo -e "  ${CYAN}▶${NC}  $1"
}

print_success() {
    echo -e "  ${GREEN}✓${NC}  $1"
}

print_error() {
    echo -e "  ${RED}✗${NC}  $1"
}

print_warning() {
    echo -e "  ${YELLOW}⚠${NC}  $1"
}

print_info() {
    echo -e "  ${GRAY}ℹ${NC}  ${DIM}$1${NC}"
}

spinner() {
    local pid=$1
    local msg=$2
    local spinstr='⣾⣽⣻⢿⡿⣟⣯⣷'
    while kill -0 $pid 2>/dev/null; do
        for (( i=0; i<${#spinstr}; i++ )); do
            echo -ne "\r  ${CYAN}${spinstr:$i:1}${NC}  $msg"
            sleep 0.1
        done
    done
    echo -ne "\r"
}

confirm_prompt() {
    local message="$1"
    local default="$2"
    echo -ne "  ${YELLOW}?${NC}  $message "
    read choice
    choice=${choice:-$default}
    echo "$choice" | tr '[:upper:]' '[:lower:]'
}

count_packages() {
    local file="$1"
    grep -v '^#' "$file" | grep -v '^$' | wc -l
}

install_packages_from_file() {
    local file="$1"
    local installer="$2"
    local total=$(count_packages "$file")
    local current=0
    
    while IFS= read -r package || [[ -n "$package" ]]; do
        [[ -z "$package" || "$package" =~ ^# ]] && continue
        ((current++))
        echo -ne "\r  ${CYAN}[$current/$total]${NC} Installing ${WHITE}$package${NC}...          "
        $installer -S --noconfirm "$package" > /dev/null 2>&1
        if [[ $? -eq 0 ]]; then
            echo -ne "\r  ${GREEN}[$current/$total]${NC} ${GREEN}✓${NC} $package                    \n"
        else
            echo -ne "\r  ${RED}[$current/$total]${NC} ${RED}✗${NC} $package                    \n"
        fi
    done < "$file"
}

# ── Pre-flight Checks ───────────────────────────────────────────────────────

clear

if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}Error: Do not run as root!${NC}"
    exit 1
fi

# ── Update Repository ───────────────────────────────────────────────────────

if [ -d "$DOTFILES_DIR/.git" ]; then
    echo -e "  ${CYAN}▶${NC}  Checking for updates..."
    cd "$DOTFILES_DIR"
    
    # Fetch latest
    git fetch origin > /dev/null 2>&1
    
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse @{u} 2>/dev/null)
    
    if [ "$LOCAL" != "$REMOTE" ]; then
        echo -e "  ${YELLOW}⚠${NC}  New version available!"
        echo -ne "  ${YELLOW}?${NC}  Update to latest version? [Y/n] "
        read update_choice
        update_choice=${update_choice:-y}
        
        if [[ "${update_choice,,}" == "y" ]]; then
            git pull origin main > /dev/null 2>&1 || git pull origin master > /dev/null 2>&1
            echo -e "  ${GREEN}✓${NC}  Updated to latest version"
            echo -e "  ${GRAY}ℹ${NC}  Restarting installer..."
            sleep 1
            exec "$0" "$@"
        fi
    else
        echo -e "  ${GREEN}✓${NC}  Already on latest version"
    fi
    
    cd - > /dev/null
fi

# ── Welcome ─────────────────────────────────────────────────────────────────

print_logo

echo -e "  ${DIM}This installer will set up your Hyprland environment.${NC}"
echo -e "  ${DIM}It will install packages, copy configs, and configure your shell.${NC}"
echo ""
echo -e "  ${YELLOW}⚠${NC}  ${WHITE}Warning:${NC} This will replace existing configurations!"
echo ""

choice=$(confirm_prompt "Continue with installation? [y/N]" "n")

if [[ "$choice" != "y" ]]; then
    echo ""
    echo -e "  ${DIM}Installation cancelled.${NC}"
    echo ""
    exit 0
fi

echo ""

# ── Package Installation ────────────────────────────────────────────────────

print_header "📦 Installing Packages"

print_step "Installing official packages..."
install_packages_from_file "$PACMAN_PACKAGES" "sudo pacman"
echo ""

print_step "Setting up Yay (AUR helper)..."
if ! command -v yay &> /dev/null; then
    mkdir -p "$TEMP_DIR"
    git clone "$YAY_REPO" "$TEMP_DIR/yay" > /dev/null 2>&1 &
    spinner $! "Cloning yay repository..."
    print_success "Yay cloned"
    cd "$TEMP_DIR/yay" && makepkg -si --noconfirm > /dev/null 2>&1
    print_success "Yay installed"
    cd - > /dev/null
else
    print_info "Yay already installed, skipping"
fi
echo ""

print_step "Installing AUR packages..."
install_packages_from_file "$YAY_PACKAGES" "yay"
echo ""

print_step "Installing VS Code extensions..."
if command -v code &> /dev/null && [ -f "$DOTFILES_DIR/etc/CodeExtensions.txt" ]; then
    xargs -n 1 code --install-extension < "$DOTFILES_DIR/etc/CodeExtensions.txt" > /dev/null 2>&1 &
    spinner $! "Installing extensions..."
    print_success "VS Code extensions installed"
else
    print_info "VS Code not found, skipping"
fi

# ── Dotfiles Installation ───────────────────────────────────────────────────

print_header "📁 Installing Dotfiles"

mkdir -p "$CONFIG_DIR" "$BIN_DIR" "$THEMES_DIR" "$ICONS_DIR"
xdg-user-dirs-update 2>&1

print_step "Copying configuration files..."
for dir in "$DOTFILES_DIR/config/"*; do
    dir_name=$(basename "$dir")
    if cp -R "$dir" "$CONFIG_DIR/" 2>/dev/null; then
        print_success "$dir_name"
    else
        print_error "$dir_name"
    fi
done
echo ""

print_step "Installing scripts..."
if cp -R "$DOTFILES_DIR/bin/"* "$BIN_DIR/" 2>/dev/null; then
    chmod +x "$BIN_DIR"/* 2>/dev/null
    print_success "Scripts copied to ~/.local/bin"
else
    print_error "Failed to copy scripts"
fi

# ── Shell Configuration ─────────────────────────────────────────────────────

print_header "🐚 Configuring Shell"

print_step "Installing Oh My Zsh..."
RUNZSH=no sh -c "$(curl -fsSL $OH_MY_ZSH_REPO)" > /dev/null 2>&1 &
spinner $! "Setting up Oh My Zsh..."
print_success "Oh My Zsh installed"

print_step "Installing Zsh plugins..."
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
plugins=(
    "zsh-autosuggestions"
    "zsh-syntax-highlighting"
    "zsh-completions"
    "zsh-history-substring-search"
)

for plugin in "${plugins[@]}"; do
    git clone "https://github.com/zsh-users/$plugin" "$ZSH_CUSTOM/plugins/$plugin" 2>/dev/null
    print_success "$plugin"
done

cp -f "$DOTFILES_DIR/.zshrc" "$HOME/"
chsh -s /usr/bin/zsh
print_success "Default shell set to Zsh"

# ── Themes & Icons ──────────────────────────────────────────────────────────

print_header "🎨 Installing Themes & Icons"

if [ -d "$DOTFILES_DIR/assets/icons" ]; then
    print_step "Extracting icon packs..."
    for archive in "$DOTFILES_DIR/assets/icons"/*.tar.xz; do
        [ -f "$archive" ] || continue
        name=$(basename "$archive" .tar.xz)
        tar xf "$archive" -C "$ICONS_DIR" 2>/dev/null
        print_success "$name"
    done
fi

if [ -d "$DOTFILES_DIR/assets/themes" ]; then
    print_step "Extracting GTK themes..."
    for archive in "$DOTFILES_DIR/assets/themes"/*.tar.xz; do
        [ -f "$archive" ] || continue
        name=$(basename "$archive" .tar.xz)
        tar xf "$archive" -C "$THEMES_DIR" 2>/dev/null
        print_success "$name"
    done
fi

print_step "Rebuilding font cache..."
fc-cache -rv >/dev/null 2>&1 &
spinner $! "Updating font cache..."
print_success "Font cache updated"

# ── System Services ─────────────────────────────────────────────────────────

print_header "⚙️  Enabling Services"

SERVICES=(ly bluetooth NetworkManager udisks2 tailscaled)

for service in "${SERVICES[@]}"; do
    if systemctl list-unit-files | grep -q "^$service"; then
        sudo systemctl enable "$service" > /dev/null 2>&1
        print_success "$service"
    else
        print_warning "$service not found"
    fi
done

# ── Completion ──────────────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}"
cat << 'EOF'
    ╭──────────────────────────────────────────────────────────────╮
    │                                                              │
    │   ✓  Installation Complete!                                  │
    │                                                              │
    │   Your Hyprland environment is ready.                        │
    │   Please reboot to apply all changes.                        │
    │                                                              │
    ╰──────────────────────────────────────────────────────────────╯
EOF
echo -e "${NC}"

choice=$(confirm_prompt "Reboot now? [y/N]" "n")

if [[ "$choice" == "y" ]]; then
    echo ""
    print_info "Rebooting in 3 seconds..."
    sleep 3
    systemctl reboot
fi

echo ""
echo -e "  ${DIM}Run 'Hyprland' to start your new desktop!${NC}"
echo ""
