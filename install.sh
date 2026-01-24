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
KVANTUM_DIR="$CONFIG_DIR/Kvantum"
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
    echo -e "${WHITE}                    ╭───────────────────────────────╮${NC}"
    echo -e "${WHITE}                    │    ${MAGENTA}D O T F I L E S  v2.0${WHITE}     │${NC}"
    echo -e "${WHITE}                    │         ${GRAY}by ${CYAN}ayudash${WHITE}           │${NC}"
    echo -e "${WHITE}                    ╰───────────────────────────────╯${NC}"
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

draw_progress_bar() {
    local current=$1
    local total=$2
    local width=30
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    # Build the bar string using standard ASCII
    local bar=""
    if [ $filled -gt 0 ]; then
        bar=$(printf "%0.s#" $(seq 1 $filled))
    fi
    if [ $empty -gt 0 ]; then
        bar="${bar}$(printf "%0.s." $(seq 1 $empty))"
    fi
    
    echo -ne "\r  ${WHITE}[${bar}]${NC} ${percentage}% "
}

install_packages_from_file() {
    local file="$1"
    local installer="$2"
    local total=$(count_packages "$file")
    local current=0
    
    # Refresh sudo credential cache to prevent prompt interfering with UI
    if [[ "$installer" == *"sudo"* ]]; then
        sudo -v
        # Keep-alive: update existing sudo time stamp if set, otherwise do nothing.
        while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
    fi
    
    # Hide cursor
    tput civis
    
    while IFS= read -r package || [[ -n "$package" ]]; do
        [[ -z "$package" || "$package" =~ ^# ]] && continue
        ((current++))
        
        # Show progress header
        echo -ne "\r\033[K"
        draw_progress_bar $current $total
        echo -e "Installing ${CYAN}$package${NC}..."
        
        # Show cursor for installer output
        tput cnorm
        
        # Run installer WITHOUT hiding output
        $installer -S --noconfirm "$package"
        
        # Hide cursor again for next bar update
        tput civis
    done < "$file"
    
    # Show full bar at end
    tput cnorm
}

# ── Installation Modules ────────────────────────────────────────────────────

update_repo() {
    if [ -d "$DOTFILES_DIR/.git" ]; then
        echo -e "  ${CYAN}▶${NC}  Checking for updates..."
        cd "$DOTFILES_DIR"
        
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
}

system_update() {
    print_header "🔄 Updating System"
    
    print_step "Synchronizing package databases and upgrading system..."
    echo ""
    echo -e "  ${GRAY}Running: sudo pacman -Syyu${NC}"
    echo ""
    
    if sudo pacman -Syyu --noconfirm; then
        echo ""
        print_success "System updated successfully"
    else
        echo ""
        print_error "System update failed"
        print_warning "Continuing with installation..."
    fi
}

install_packages_task() {
    print_header "📦 Installing Packages"

    print_step "Installing official packages..."
    install_packages_from_file "$PACMAN_PACKAGES" "sudo pacman"
    echo ""

    print_step "Setting up Yay (AUR helper)..."
    if ! command -v yay &> /dev/null; then
        mkdir -p "$TEMP_DIR"
        
        # Clone with progress
        echo -e "  ${GRAY}Cloning yay repository...${NC}"
        if git clone --progress "$YAY_REPO" "$TEMP_DIR/yay"; then
            print_success "Yay cloned"
            
            # Build and install visible to user
            echo -e "  ${GRAY}Building yay (this may take a while)...${NC}"
            cd "$TEMP_DIR/yay" 
            if makepkg -si --noconfirm; then
                print_success "Yay installed"
            else
                print_error "Failed to install Yay"
                echo -e "  ${YELLOW}⚠ Skipping AUR packages${NC}"
                return 1
            fi
            cd - > /dev/null
        else
            print_error "Failed to clone Yay"
            return 1
        fi
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
}

install_dotfiles_task() {
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
}

configure_shell_task() {
    print_header "🐚 Configuring Shell"

    print_step "Installing Oh My Zsh..."
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        RUNZSH=no sh -c "$(curl -fsSL $OH_MY_ZSH_REPO)" > /dev/null 2>&1 &
        spinner $! "Setting up Oh My Zsh..."
        print_success "Oh My Zsh installed"
    else
        print_info "Oh My Zsh already installed"
    fi

    print_step "Installing Zsh plugins..."
    ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    plugins=(
        "zsh-autosuggestions"
        "zsh-syntax-highlighting"
        "zsh-completions"
        "zsh-history-substring-search"
    )

    for plugin in "${plugins[@]}"; do
        if [ ! -d "$ZSH_CUSTOM/plugins/$plugin" ]; then
            git clone "https://github.com/zsh-users/$plugin" "$ZSH_CUSTOM/plugins/$plugin" 2>/dev/null
            print_success "$plugin"
        else
             print_info "$plugin already installed"
        fi
    done

    cp -f "$DOTFILES_DIR/.zshrc" "$HOME/"
    chsh -s /usr/bin/zsh
    print_success "Default shell set to Zsh"
}

install_themes_task() {
    print_header "🎨 Installing Themes & Icons"

    # ── GTK Icons ───────────────────────────────────────────────────────────
    if [ -d "$DOTFILES_DIR/assets/gtk/icons" ]; then
        print_step "Extracting GTK icon packs..."
        for archive in "$DOTFILES_DIR/assets/gtk/icons"/*.tar.xz; do
            [ -f "$archive" ] || continue
            name=$(basename "$archive" .tar.xz)
            echo -e "  ${GRAY}  Extracting: $name${NC}"
            tar xf "$archive" -C "$ICONS_DIR" 2>/dev/null
            print_success "$name"
        done
    else
        print_info "No GTK icons found in assets/gtk/icons"
    fi
    echo ""

    # ── GTK Themes ──────────────────────────────────────────────────────────
    if [ -d "$DOTFILES_DIR/assets/gtk/themes" ]; then
        print_step "Extracting GTK themes..."
        for archive in "$DOTFILES_DIR/assets/gtk/themes"/*.tar.xz; do
            [ -f "$archive" ] || continue
            name=$(basename "$archive" .tar.xz)
            echo -e "  ${GRAY}  Extracting: $name${NC}"
            tar xf "$archive" -C "$THEMES_DIR" 2>/dev/null
            print_success "$name"
        done
    else
        print_info "No GTK themes found in assets/gtk/themes"
    fi
    echo ""

    # ── Kvantum Themes ──────────────────────────────────────────────────────
    if [ -d "$DOTFILES_DIR/assets/kvantum/themes" ]; then
        print_step "Installing Kvantum themes..."
        mkdir -p "$KVANTUM_DIR"
        for archive in "$DOTFILES_DIR/assets/kvantum/themes"/*.tar.xz; do
            [ -f "$archive" ] || continue
            name=$(basename "$archive" .tar.xz)
            echo -e "  ${GRAY}  Extracting: $name${NC}"
            tar xf "$archive" -C "$KVANTUM_DIR" 2>/dev/null
            print_success "$name → ~/.config/Kvantum/"
        done
    else
        print_info "No Kvantum themes found in assets/kvantum/themes"
    fi
    echo ""

    # ── Kvantum Icons (if any) ──────────────────────────────────────────────
    if [ -d "$DOTFILES_DIR/assets/kvantum/icons" ]; then
        print_step "Installing Kvantum icons..."
        for archive in "$DOTFILES_DIR/assets/kvantum/icons"/*.tar.xz; do
            [ -f "$archive" ] || continue
            name=$(basename "$archive" .tar.xz)
            echo -e "  ${GRAY}  Extracting: $name${NC}"
            tar xf "$archive" -C "$ICONS_DIR" 2>/dev/null
            print_success "$name"
        done
    fi

    # ── Font Cache ──────────────────────────────────────────────────────────
    print_step "Rebuilding font cache..."
    echo -e "  ${GRAY}  Running: fc-cache -rv${NC}"
    fc-cache -rv 2>&1 | while read -r line; do
        echo -e "  ${DIM}  $line${NC}"
    done
    print_success "Font cache updated"
}

enable_services_task() {
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
}

install_system_configs_task() {
    print_header "🔧 Installing System Configurations"

    # NetworkManager configuration (for iwd backend)
    if [ -f "$DOTFILES_DIR/etc/NetworkManager.conf" ]; then
        print_step "Installing NetworkManager configuration..."
        echo -e "  ${GRAY}  Copying to /etc/NetworkManager/NetworkManager.conf${NC}"
        if sudo cp "$DOTFILES_DIR/etc/NetworkManager.conf" /etc/NetworkManager/NetworkManager.conf; then
            print_success "NetworkManager.conf installed"
        else
            print_error "Failed to install NetworkManager.conf"
        fi
    else
        print_info "NetworkManager.conf not found in etc/"
    fi

    # Add more system configs here if needed
    # Example:
    # if [ -f "$DOTFILES_DIR/etc/another-config" ]; then
    #     sudo cp "$DOTFILES_DIR/etc/another-config" /etc/destination/
    # fi
}

full_install() {
    system_update
    install_packages_task
    install_dotfiles_task
    configure_shell_task
    install_themes_task
    install_system_configs_task
    enable_services_task
    show_completion
}

show_completion() {
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

    if [[ "$choice" == "y" || "$choice" == "yes" ]]; then
        echo ""
        print_info "Rebooting in 3 seconds..."
        sleep 3
        systemctl reboot
    fi

    echo ""
    echo -e "  ${DIM}Run 'Hyprland' to start your new desktop!${NC}"
    echo ""
}

# ── Main Menu ──────────────────────────────────────────────────────────────

main_menu() {
    print_logo
    
    echo -e "  ${DIM}This installer will set up your Hyprland environment.${NC}"
    echo ""
    echo -e "  ${BOLD}Select an option:${NC}"
    echo ""
    echo -e "  ${CYAN}1)${NC} Full Installation        ${DIM}(Packages, Configs, Themes, Shell)${NC}"
    echo -e "  ${CYAN}2)${NC} Install Packages Only    ${DIM}(Pacman, AUR, VSCode)${NC}"
    echo -e "  ${CYAN}3)${NC} Install Dotfiles Only    ${DIM}(~/.config, ~/.local/bin)${NC}"
    echo -e "  ${CYAN}4)${NC} Install Themes Only      ${DIM}(Icons, GTK Themes)${NC}"
    echo -e "  ${CYAN}5)${NC} Configure Shell Only     ${DIM}(Zsh, Oh My Zsh)${NC}"
    echo -e "  ${RED}0)${NC} Quit"
    echo ""
    
    echo -ne "  ${YELLOW}?${NC}  Enter choice [1-5]: "
    read choice
    echo ""

    case $choice in
        1) full_install ;;
        2) install_packages_task; show_completion ;;
        3) install_dotfiles_task; show_completion ;;
        4) install_themes_task; show_completion ;;
        5) configure_shell_task; show_completion ;;
        0) echo -e "  ${DIM}Bye!${NC}"; exit 0 ;;
        *) echo -e "  ${RED}Invalid choice!${NC}"; sleep 1; clear; main_menu ;;
    esac
}

# ── Entry Point ─────────────────────────────────────────────────────────────

clear

if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}Error: Do not run as root!${NC}"
    exit 1
fi

update_repo
main_menu
