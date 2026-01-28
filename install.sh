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
    local package=$3
    local cols=$(tput cols 2>/dev/null || echo 80)
    
    # Calculate bar width dynamically (leave space for other elements)
    # Format: (XXX/XXX) package_name [bar] XXX%
    local prefix="($current/$total) $package "
    local suffix=" 100%"
    local bar_width=$((cols - ${#prefix} - ${#suffix} - 4))
    
    # Minimum bar width
    [ $bar_width -lt 10 ] && bar_width=10
    [ $bar_width -gt 40 ] && bar_width=40
    
    local percentage=$((current * 100 / total))
    local filled=$((current * bar_width / total))
    local empty=$((bar_width - filled))
    
    # Build progress bar
    local bar=""
    [ $filled -gt 0 ] && bar=$(printf "%0.s#" $(seq 1 $filled))
    [ $empty -gt 0 ] && bar="${bar}$(printf "%0.s-" $(seq 1 $empty))"
    
    # Print: (current/total) package [######-----] XX%
    printf "\r${GRAY}(%3d/%3d)${NC} ${WHITE}%-30s${NC} ${CYAN}[${WHITE}%s${CYAN}]${NC} %3d%%" \
        "$current" "$total" "${package:0:30}" "$bar" "$percentage"
}

install_packages_from_file() {
    local file="$1"
    local installer="$2"
    local total=$(count_packages "$file")
    local current=0
    local failed_packages=()
    
    # Refresh sudo credential cache to prevent prompt interfering with UI
    if [[ "$installer" == *"sudo"* ]]; then
        sudo -v
        # Keep-alive: update existing sudo time stamp if set, otherwise do nothing.
        while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
    fi
    
    while IFS= read -r package || [[ -n "$package" ]]; do
        [[ -z "$package" || "$package" =~ ^# ]] && continue
        ((current++))
        
        # Show package counter header
        echo -e "\n${GRAY}($current/$total)${NC} Installing ${CYAN}$package${NC}..."
        
        # Run installer with native progress output visible
        if ! $installer -S --noconfirm --needed "$package"; then
            failed_packages+=("$package")
        fi
    done < "$file"
    
    echo ""
    
    if [ ${#failed_packages[@]} -gt 0 ]; then
        print_warning "Some packages failed to install:"
        for pkg in "${failed_packages[@]}"; do
            echo -e "    ${RED}✗${NC} $pkg"
        done
    fi
    
    print_success "Installed $((current - ${#failed_packages[@]}))/$total packages"
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
        
        local yay_installed=false
        local max_attempts=2
        local attempt=0
        
        while [ "$yay_installed" = false ] && [ $attempt -lt $max_attempts ]; do
            ((attempt++))
            
            # Check if yay folder already exists (from previous failed attempt)
            if [ -d "$TEMP_DIR/yay" ]; then
                print_info "Found existing yay folder from previous attempt"
                echo -e "\n${GRAY}(1/2)${NC} Skipping clone, using existing folder..."
            else
                # Clone with progress
                echo -e "\n${GRAY}(1/2)${NC} Cloning ${CYAN}yay-git${NC} from AUR..."
                echo ""
                if git clone --progress "$YAY_REPO" "$TEMP_DIR/yay"; then
                    echo ""
                    print_success "Yay repository cloned"
                else
                    print_error "Failed to clone Yay"
                    return 1
                fi
            fi
            
            # Build and install with visible output
            echo -e "\n${GRAY}(2/2)${NC} Building ${CYAN}yay${NC} (this may take a while)..."
            echo ""
            cd "$TEMP_DIR/yay"
            
            if makepkg -si --noconfirm; then
                echo ""
                print_success "Yay installed successfully"
                yay_installed=true
            else
                print_error "Failed to build/install Yay (attempt $attempt/$max_attempts)"
                cd - > /dev/null
                
                # Clean up failed build
                echo -e "  ${GRAY}Cleaning up failed build...${NC}"
                rm -rf "$TEMP_DIR/yay"
                
                if [ $attempt -lt $max_attempts ]; then
                    echo ""
                    choice=$(confirm_prompt "Retry yay installation? [Y/n]" "y")
                    if [[ "$choice" != "y" && "$choice" != "yes" ]]; then
                        print_warning "Skipping AUR packages"
                        return 1
                    fi
                    echo ""
                else
                    print_error "Max retry attempts reached"
                    print_warning "Skipping AUR packages"
                    return 1
                fi
            fi
            
            cd - > /dev/null 2>&1
        done
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

install_gpu_drivers_task() {
    print_header "🖥️  Installing GPU Drivers"

    local gpu_info
    gpu_info=$(lspci -nn 2>/dev/null | grep -iE "vga|3d|display")

    local has_nvidia=false
    local has_amd=false
    local has_intel=false

    # Detect GPU vendors
    if echo "$gpu_info" | grep -qi "nvidia"; then
        has_nvidia=true
    fi
    if echo "$gpu_info" | grep -qiE "amd|radeon|ati"; then
        has_amd=true
    fi
    if echo "$gpu_info" | grep -qi "intel"; then
        has_intel=true
    fi

    print_step "Detected GPU(s):"
    echo -e "  ${GRAY}$gpu_info${NC}"
    echo ""

    # ── NVIDIA Driver Installation ──────────────────────────────────────────
    if [ "$has_nvidia" = true ]; then
        print_step "NVIDIA GPU detected"
        echo ""
        echo -e "  ${BOLD}Select NVIDIA driver:${NC}"
        echo -e "  ${CYAN}1)${NC} nvidia-dkms       ${DIM}(Recommended - works with all kernels)${NC}"
        echo -e "  ${CYAN}2)${NC} nvidia            ${DIM}(Standard - for linux kernel only)${NC}"
        echo -e "  ${CYAN}3)${NC} nvidia-open-dkms  ${DIM}(Open source - for RTX 20+ series)${NC}"
        echo -e "  ${CYAN}4)${NC} Skip NVIDIA driver"
        echo ""
        echo -ne "  ${YELLOW}?${NC}  Enter choice [1-4]: "
        read nvidia_choice

        local nvidia_packages=()

        case $nvidia_choice in
            1)
                nvidia_packages=("nvidia-dkms" "nvidia-utils" "nvidia-settings" "lib32-nvidia-utils" "libva-nvidia-driver")
                print_step "Installing nvidia-dkms driver..."
                ;;
            2)
                nvidia_packages=("nvidia" "nvidia-utils" "nvidia-settings" "lib32-nvidia-utils" "libva-nvidia-driver")
                print_step "Installing nvidia driver..."
                ;;
            3)
                nvidia_packages=("nvidia-open-dkms" "nvidia-utils" "nvidia-settings" "lib32-nvidia-utils" "libva-nvidia-driver")
                print_step "Installing nvidia-open-dkms driver..."
                ;;
            4)
                print_info "Skipping NVIDIA driver installation"
                ;;
            *)
                print_warning "Invalid choice, skipping NVIDIA driver"
                ;;
        esac

        if [ ${#nvidia_packages[@]} -gt 0 ]; then
            echo ""
            for pkg in "${nvidia_packages[@]}"; do
                echo -e "  ${GRAY}Installing: $pkg${NC}"
                if sudo pacman -S --noconfirm --needed "$pkg" 2>/dev/null; then
                    print_success "$pkg"
                else
                    print_warning "$pkg (may not be available or already installed)"
                fi
            done

            # Configure NVIDIA for Wayland/Hyprland
            print_step "Configuring NVIDIA for Hyprland..."

            # Add nvidia modules to mkinitcpio
            if [ -f /etc/mkinitcpio.conf ]; then
                if ! grep -q "nvidia" /etc/mkinitcpio.conf; then
                    print_info "Adding NVIDIA modules to mkinitcpio.conf"
                    sudo sed -i 's/^MODULES=(\(.*\))/MODULES=(\1 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
                    sudo mkinitcpio -P
                    print_success "mkinitcpio updated"
                else
                    print_info "NVIDIA modules already in mkinitcpio.conf"
                fi
            fi

            # Create modprobe config for nvidia_drm.modeset=1
            print_info "Enabling nvidia_drm.modeset"
            echo "options nvidia_drm modeset=1 fbdev=1" | sudo tee /etc/modprobe.d/nvidia.conf > /dev/null
            print_success "NVIDIA modprobe config created"

            # Add environment variables hint
            echo ""
            print_info "Add these to your Hyprland config for best experience:"
            echo -e "  ${DIM}env = LIBVA_DRIVER_NAME,nvidia${NC}"
            echo -e "  ${DIM}env = XDG_SESSION_TYPE,wayland${NC}"
            echo -e "  ${DIM}env = GBM_BACKEND,nvidia-drm${NC}"
            echo -e "  ${DIM}env = __GLX_VENDOR_LIBRARY_NAME,nvidia${NC}"
            echo -e "  ${DIM}env = NVD_BACKEND,direct${NC}"
        fi
        echo ""
    fi

    # ── AMD Driver Installation ─────────────────────────────────────────────
    if [ "$has_amd" = true ]; then
        print_step "AMD GPU detected"
        echo ""

        local amd_packages=(
            "mesa"
            "lib32-mesa"
            "vulkan-radeon"
            "lib32-vulkan-radeon"
            "libva-mesa-driver"
            "lib32-libva-mesa-driver"
            "mesa-vdpau"
            "lib32-mesa-vdpau"
        )

        echo -e "  ${BOLD}AMD packages to install:${NC}"
        for pkg in "${amd_packages[@]}"; do
            echo -e "  ${DIM}  - $pkg${NC}"
        done
        echo ""

        choice=$(confirm_prompt "Install AMD drivers? [Y/n]" "y")

        if [[ "$choice" == "y" || "$choice" == "yes" ]]; then
            for pkg in "${amd_packages[@]}"; do
                echo -e "  ${GRAY}Installing: $pkg${NC}"
                if sudo pacman -S --noconfirm --needed "$pkg" 2>/dev/null; then
                    print_success "$pkg"
                else
                    print_warning "$pkg (may not be available)"
                fi
            done

            echo ""
            print_info "AMD drivers use open-source AMDGPU, no extra config needed"
            print_info "For hardware video acceleration, add to Hyprland:"
            echo -e "  ${DIM}env = LIBVA_DRIVER_NAME,radeonsi${NC}"
        else
            print_info "Skipping AMD driver installation"
        fi
        echo ""
    fi

    # ── Intel Driver Installation ───────────────────────────────────────────
    if [ "$has_intel" = true ]; then
        print_step "Intel GPU detected"
        echo ""

        local intel_packages=(
            "mesa"
            "lib32-mesa"
            "vulkan-intel"
            "lib32-vulkan-intel"
            "intel-media-driver"
        )

        echo -e "  ${BOLD}Intel packages to install:${NC}"
        for pkg in "${intel_packages[@]}"; do
            echo -e "  ${DIM}  - $pkg${NC}"
        done
        echo ""

        choice=$(confirm_prompt "Install Intel drivers? [Y/n]" "y")

        if [[ "$choice" == "y" || "$choice" == "yes" ]]; then
            for pkg in "${intel_packages[@]}"; do
                echo -e "  ${GRAY}Installing: $pkg${NC}"
                if sudo pacman -S --noconfirm --needed "$pkg" 2>/dev/null; then
                    print_success "$pkg"
                else
                    print_warning "$pkg (may not be available)"
                fi
            done

            echo ""
            print_info "Intel drivers configured. For VA-API, add to Hyprland:"
            echo -e "  ${DIM}env = LIBVA_DRIVER_NAME,iHD${NC}"
        else
            print_info "Skipping Intel driver installation"
        fi
        echo ""
    fi

    # ── No GPU Detected ─────────────────────────────────────────────────────
    if [ "$has_nvidia" = false ] && [ "$has_amd" = false ] && [ "$has_intel" = false ]; then
        print_warning "No supported GPU detected"
        print_info "Installing generic mesa drivers..."
        sudo pacman -S --noconfirm --needed mesa lib32-mesa 2>/dev/null
        print_success "Generic drivers installed"
    fi

    print_success "GPU driver setup complete"
}

full_install() {
    system_update
    install_gpu_drivers_task
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
    echo -e "  ${CYAN}1)${NC} Full Installation        ${DIM}(GPU, Packages, Configs, Themes, Shell)${NC}"
    echo -e "  ${CYAN}2)${NC} Install GPU Drivers      ${DIM}(AMD, NVIDIA, Intel auto-detect)${NC}"
    echo -e "  ${CYAN}3)${NC} Install Packages Only    ${DIM}(Pacman, AUR, VSCode)${NC}"
    echo -e "  ${CYAN}4)${NC} Install Dotfiles Only    ${DIM}(~/.config, ~/.local/bin)${NC}"
    echo -e "  ${CYAN}5)${NC} Install Themes Only      ${DIM}(Icons, GTK Themes)${NC}"
    echo -e "  ${CYAN}6)${NC} Configure Shell Only     ${DIM}(Zsh, Oh My Zsh)${NC}"
    echo -e "  ${RED}0)${NC} Quit"
    echo ""
    
    echo -ne "  ${YELLOW}?${NC}  Enter choice [1-6]: "
    read choice
    echo ""

    case $choice in
        1) full_install ;;
        2) install_gpu_drivers_task; show_completion ;;
        3) install_packages_task; show_completion ;;
        4) install_dotfiles_task; show_completion ;;
        5) install_themes_task; show_completion ;;
        6) configure_shell_task; show_completion ;;
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
