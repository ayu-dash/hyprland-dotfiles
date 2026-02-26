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
    echo -ne "  ${YELLOW}?${NC}  $message " > /dev/tty
    read choice < /dev/tty
    choice=${choice:-$default}
    echo "$choice" | tr '[:upper:]' '[:lower:]'
}

count_packages() {
    local file="$1"
    grep -v '^#' "$file" | grep -v '^$' | wc -l
}

copy_system_config() {
    local src="$1"
    local dest="$2"
    local name="$3"
    
    if [ -f "$src" ] || [ -d "$src" ]; then
        sudo mkdir -p "$(dirname "$dest")"
        if sudo cp -r "$src" "$dest"; then
            print_success "$name"
            return 0
        else
            print_error "Failed to install $name"
            return 1
        fi
    fi
    return 1
}

extract_archives() {
    local src_dir="$1"
    local dest_dir="$2"
    local label="$3"
    
    [ -d "$src_dir" ] || return 1
    
    for archive in "$src_dir"/*.tar.xz; do
        [ -f "$archive" ] || continue
        local name=$(basename "$archive" .tar.xz)
        echo -e "  ${GRAY}  Extracting: $name${NC}"
        if tar xf "$archive" -C "$dest_dir" 2>/dev/null; then
            print_success "$name"
        else
            print_error "$name"
        fi
    done
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
            echo -ne "  ${YELLOW}?${NC}  Update to latest version? [Y/n] " > /dev/tty
            read update_choice < /dev/tty
            update_choice=${update_choice:-y}
            
            if [[ "${update_choice,,}" == "y" ]]; then
                # Stash local changes if any
                if ! git diff --quiet || ! git diff --cached --quiet; then
                    echo -e "  ${GRAY}ℹ${NC}  Stashing local changes..."
                    git stash push -m "Auto-stash before update" > /dev/null 2>&1
                fi
                
                # Pull with visible output
                echo ""
                if git pull origin main 2>&1 || git pull origin master 2>&1; then
                    echo ""
                    echo -e "  ${GREEN}✓${NC}  Updated to latest version"
                    echo -e "  ${GRAY}ℹ${NC}  Restarting installer..."
                    sleep 1
                    exec "$0" "$@"
                else
                    echo ""
                    echo -e "  ${RED}✗${NC}  Failed to update"
                    echo -e "  ${GRAY}ℹ${NC}  Try: git pull origin main --rebase"
                fi
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
        local total_ext=$(grep -v '^#' "$DOTFILES_DIR/etc/CodeExtensions.txt" | grep -v '^$' | wc -l)
        local current_ext=0
        local failed_ext=()
        
        while IFS= read -r ext || [[ -n "$ext" ]]; do
            [[ -z "$ext" || "$ext" =~ ^# ]] && continue
            ((current_ext++))
            echo -e "\n${GRAY}($current_ext/$total_ext)${NC} Installing ${CYAN}$ext${NC}..."
            if ! code --install-extension "$ext" --force 2>&1; then
                failed_ext+=("$ext")
            fi
        done < "$DOTFILES_DIR/etc/CodeExtensions.txt"
        
        echo ""
        if [ ${#failed_ext[@]} -gt 0 ]; then
            print_warning "Some extensions failed to install:"
            for ext in "${failed_ext[@]}"; do
                echo -e "    ${RED}✗${NC} $ext"
            done
        fi
        print_success "Installed $((current_ext - ${#failed_ext[@]}))/$total_ext extensions"
    else
        print_info "VS Code not found, skipping"
    fi
}

install_vscode_extensions_task() {
    print_header "📦 Installing VS Code Extensions"

    if command -v code &> /dev/null && [ -f "$DOTFILES_DIR/etc/CodeExtensions.txt" ]; then
        local total_ext=$(grep -v '^#' "$DOTFILES_DIR/etc/CodeExtensions.txt" | grep -v '^$' | wc -l)
        local current_ext=0
        local failed_ext=()
        
        while IFS= read -r ext || [[ -n "$ext" ]]; do
            [[ -z "$ext" || "$ext" =~ ^# ]] && continue
            ((current_ext++))
            echo -e "\n${GRAY}($current_ext/$total_ext)${NC} Installing ${CYAN}$ext${NC}..."
            if ! code --install-extension "$ext" --force 2>&1; then
                failed_ext+=("$ext")
            fi
        done < "$DOTFILES_DIR/etc/CodeExtensions.txt"
        
        echo ""
        if [ ${#failed_ext[@]} -gt 0 ]; then
            print_warning "Some extensions failed to install:"
            for ext in "${failed_ext[@]}"; do
                echo -e "    ${RED}✗${NC} $ext"
            done
        fi
        print_success "Installed $((current_ext - ${#failed_ext[@]}))/$total_ext extensions"
    else
        if ! command -v code &> /dev/null; then
            print_error "VS Code (code) command not found"
            print_info "Install VS Code first: yay -S visual-studio-code-bin"
        else
            print_error "CodeExtensions.txt not found at $DOTFILES_DIR/etc/CodeExtensions.txt"
        fi
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
        echo ""
        RUNZSH=no CHSH=no sh -c "$(curl -fsSL $OH_MY_ZSH_REPO)"
        echo ""
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
    print_step "Extracting GTK icon packs..."
    if [ -d "$DOTFILES_DIR/assets/gtk/icons" ]; then
        extract_archives "$DOTFILES_DIR/assets/gtk/icons" "$ICONS_DIR" "GTK icons"
    else
        print_info "No GTK icons found"
    fi
    echo ""

    # ── GTK Themes ──────────────────────────────────────────────────────────
    print_step "Extracting GTK themes..."
    if [ -d "$DOTFILES_DIR/assets/gtk/themes" ]; then
        extract_archives "$DOTFILES_DIR/assets/gtk/themes" "$THEMES_DIR" "GTK themes"
    else
        print_info "No GTK themes found"
    fi
    echo ""

    # ── Kvantum Themes ──────────────────────────────────────────────────────
    print_step "Installing Kvantum themes..."
    if [ -d "$DOTFILES_DIR/assets/kvantum/themes" ]; then
        mkdir -p "$KVANTUM_DIR"
        extract_archives "$DOTFILES_DIR/assets/kvantum/themes" "$KVANTUM_DIR" "Kvantum themes"
    else
        print_info "No Kvantum themes found"
    fi
    echo ""

    # ── Kvantum Icons ───────────────────────────────────────────────────────
    if [ -d "$DOTFILES_DIR/assets/kvantum/icons" ]; then
        print_step "Installing Kvantum icons..."
        extract_archives "$DOTFILES_DIR/assets/kvantum/icons" "$ICONS_DIR" "Kvantum icons"
        echo ""
    fi

    # ── Custom Fonts ────────────────────────────────────────────────────────
    if [ -d "$DOTFILES_DIR/assets/fonts" ]; then
        print_step "Installing custom fonts..."
        FONTS_DIR="$HOME/.local/share/fonts"
        mkdir -p "$FONTS_DIR"

        # Function to install fonts from a specific directory
        install_font_files_from_dir() {
            local search_path="$1"
            # Check for Variable fonts first
            if find "$search_path" -type f \( -iname "*variable*" -o -iname "*vf.ttf" -o -iname "*vf.otf" \) | grep -q .; then
                find "$search_path" -type f \( -iname "*variable*" -o -iname "*vf.ttf" -o -iname "*vf.otf" \) -exec cp -f {} "$FONTS_DIR/" \;
            else
                # Fallback: Install ALL font files found
                find "$search_path" -type f \( -iname "*.ttf" -o -iname "*.otf" \) -exec cp -f {} "$FONTS_DIR/" \;
            fi
        }

        # 1. Handle ZIP archives
        for zipfile in "$DOTFILES_DIR/assets/fonts"/*.zip; do
            [ -f "$zipfile" ] || continue
            print_info "Extracting $(basename "$zipfile")..."
            
            # Create temp dir for extraction
            TEMP_FONT_DIR=$(mktemp -d)
            unzip -q "$zipfile" -d "$TEMP_FONT_DIR"
            
            # Install fonts from extraction dir
            install_font_files_from_dir "$TEMP_FONT_DIR"
            
            # Cleanup
            rm -rf "$TEMP_FONT_DIR"
        done

        # 2. Handle font subdirectories (uncompressed families)
        find "$DOTFILES_DIR/assets/fonts" -mindepth 1 -maxdepth 1 -type d | while read -r font_dir; do
            install_font_files_from_dir "$font_dir"
        done

        # 3. Handle loose files in root
        if find "$DOTFILES_DIR/assets/fonts" -maxdepth 1 -type f \( -iname "*.ttf" -o -iname "*.otf" \) | grep -q .; then
             find "$DOTFILES_DIR/assets/fonts" -maxdepth 1 -type f \( -iname "*.ttf" -o -iname "*.otf" \) -exec cp -f {} "$FONTS_DIR/" \;
        fi

        print_success "Fonts installed to ~/.local/share/fonts"
        echo ""
    fi

    # ── Font Cache ──────────────────────────────────────────────────────────
    print_step "Rebuilding font cache..."
    fc-cache -fv > /dev/null 2>&1
    print_success "Font cache updated"
}

disable_services_task() {
    print_header "🛑  Disabling Services"
    
    SERVICES=(NetworkManager wpa_supplicant systemd-networkd)
    for service in "${SERVICES[@]}"; do
        if systemctl list-unit-files "${service}.service" &>/dev/null; then
            sudo systemctl disable --now "$service" > /dev/null 2>&1
            print_success "$service"
        else
            print_warning "$service not found"
        fi
    done
}

mask_service_task() {
    print_header "🛑  Masking Services"
    systemctl --user mask swaync.service    
}

enable_services_task() {
    print_header "⚙️  Enabling Services"

    SERVICES=(greetd bluetooth iwd udisks2 tailscaled systemd-resolved)

    for service in "${SERVICES[@]}"; do
        if systemctl list-unit-files "${service}.service" &>/dev/null; then
            sudo systemctl enable "$service" > /dev/null 2>&1
            print_success "$service"
        else
            print_warning "$service not found"
        fi
    done
}

install_system_configs_task() {
    print_header "🔧 Installing System Configurations"

    # ── IWD Configuration ────────────────────────────────────────────────────
    print_step "Configuring IWD..."
    copy_system_config \
        "$DOTFILES_DIR/etc/iwd/main.conf" \
        "/etc/iwd/main.conf" \
        "iwd main.conf"
    echo ""

    # ── DNS Resolver (systemd-resolved) ────────────────────────────────────────
    print_step "Configuring DNS resolver (systemd-resolved)..."
    sudo chattr -i /etc/resolv.conf 2>/dev/null
    sudo rm -f /etc/resolv.conf
    if sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf; then
        print_success "resolv.conf -> systemd-resolved stub"
        print_info "DNS managed by systemd-resolved via iwd"
    else
        print_error "Failed to create resolv.conf symlink"
    fi
    echo ""

    # ── Greetd ──────────────────────────────────────────────────────────────
    print_step "Installing greetd configuration..."
    if copy_system_config \
        "$DOTFILES_DIR/etc/greetd/config.toml" \
        "/etc/greetd/config.toml" \
        "greetd config"; then
        print_info "tuigreet will launch Hyprland by default"
    fi
    echo ""

    # ── Hotspot Sudoers ──────────────────────────────────────────────────────
    print_step "Configuring hotspot sudoers..."
    local sudoers_file="/etc/sudoers.d/hyprland-hotspot"
    local hotspot_script="$HOME/.config/hypr/Scripts/Hostpot.py"
    local sudoers_entry="$USER ALL=(ALL) NOPASSWD: /usr/bin/python $hotspot_script toggle"
    
    if echo "$sudoers_entry" | sudo tee "$sudoers_file" > /dev/null && sudo chmod 440 "$sudoers_file"; then
        print_success "Hotspot sudoers rule installed"
        print_info "User $USER can toggle hotspot without password"
    else
        print_error "Failed to install hotspot sudoers rule"
    fi
    echo ""

    # ── Libvirt Sudoers ──────────────────────────────────────────────────────
    print_step "Configuring libvirt sudoers..."
    local sudoers_file="/etc/sudoers.d/hyprland-remote-win10"
    
    if sudo tee "$sudoers_file" > /dev/null << 'EOF'
%libvirt ALL=(ALL) NOPASSWD: /usr/bin/virsh
%libvirt ALL=(ALL) NOPASSWD: /usr/bin/virsh start remotewin10
%libvirt ALL=(ALL) NOPASSWD: /usr/bin/virsh shutdown remotewin10
%libvirt ALL=(ALL) NOPASSWD: /usr/bin/virsh reboot remotewin10
%libvirt ALL=(ALL) NOPASSWD: /usr/bin/virt-manager
%libvirt ALL=(ALL) NOPASSWD: /usr/bin/qemu-system-x86_64
EOF
    then
        sudo chmod 440 "$sudoers_file"
        print_success "Libvirt sudoers rules installed"
    else
        print_error "Failed to install libvirt sudoers rules"
    fi
    echo ""

    # ── Hda Verb ──────────────────────────────────────────────────────────
    print_step "Configuring HDA Verb..."
    local sudoers_file="/etc/sudoers.d/hyprland-hda-verb"
    local sudoers_entry="$USER ALL=(ALL) NOPASSWD: /usr/bin/hda-verb"

    if echo "$sudoers_entry" | sudo tee "$sudoers_file" > /dev/null && sudo chmod 440 "$sudoers_file"; then
        print_success "HDA Verb sudoers rules installed"
    else
        print_error "Failed to install HDA Verb sudoers rules"
    fi
    echo ""
}

configure_qemu_kvm_task() {
    print_header "🖥️  Configuring QEMU/KVM"

    # Check if libvirt is installed
    if ! pacman -Qi libvirt &>/dev/null; then
        print_info "libvirt not installed, skipping QEMU/KVM configuration"
        return 0
    fi

    print_step "Enabling libvirtd service..."
    if sudo systemctl enable libvirtd; then
        print_success "libvirtd enabled"
    else
        print_error "Failed to enable libvirtd"
    fi

    print_step "Adding user to libvirt group..."
    if sudo usermod -aG libvirt "$USER"; then
        print_success "User $USER added to libvirt group"
    else
        print_error "Failed to add user to libvirt group"
    fi

    print_step "Starting libvirtd service..."
    if sudo systemctl start libvirtd; then
        print_success "libvirtd started"
    else
        print_warning "Failed to start libvirtd (may need reboot)"
    fi

    print_step "Configuring default network..."
    if sudo virsh net-autostart default 2>/dev/null; then
        print_success "Default network set to autostart"
    else
        print_warning "Default network not found or already configured"
    fi

    if sudo virsh net-start default 2>/dev/null; then
        print_success "Default network started"
    else
        print_info "Default network already running or not available"
    fi

    echo ""
    print_info "QEMU/KVM configured. Log out and back in for group changes."
    print_info "Use 'virt-manager' to manage virtual machines."
    echo ""
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
    echo "$gpu_info" | while read -r line; do
        echo -e "     ${WHITE}$line${NC}"
    done
    echo ""

    # Ask for confirmation before proceeding
    choice=$(confirm_prompt "Proceed with GPU driver installation? [Y/n]" "y")
    if [[ "$choice" != "y" && "$choice" != "yes" ]]; then
        print_info "Skipping GPU driver installation"
        return 0
    fi
    echo ""

    # ── NVIDIA Driver Installation ──────────────────────────────────────────
    if [ "$has_nvidia" = true ]; then
        print_step "NVIDIA GPU detected"
        
        # Detect kernel type
        local current_kernel
        current_kernel=$(uname -r)
        local is_standard_kernel=false
        
        if [[ "$current_kernel" == *"-arch"* ]] && [[ "$current_kernel" != *"-zen"* ]] && [[ "$current_kernel" != *"-lts"* ]] && [[ "$current_kernel" != *"-hardened"* ]]; then
            is_standard_kernel=true
        fi
        
        echo ""
        echo -e "  ${DIM}Detected kernel: ${WHITE}$current_kernel${NC}"
        echo ""
        
        if [ "$is_standard_kernel" = true ]; then
            echo -e "  ${BOLD}Select NVIDIA driver:${NC}"
            echo -e "  ${CYAN}1)${NC} nvidia-dkms       ${DIM}(Works with all kernels)${NC}"
            echo -e "  ${CYAN}2)${NC} nvidia            ${DIM}(Standard - for linux kernel only)${NC}"
            echo -e "  ${CYAN}3)${NC} nvidia-open-dkms  ${DIM}(Open source - for RTX 20+ series)${NC}"
            echo -e "  ${CYAN}4)${NC} Skip NVIDIA driver"
            echo ""
            echo -ne "  ${YELLOW}?${NC}  Enter choice [1-4]: " > /dev/tty
            read nvidia_choice < /dev/tty
        else
            # Non-standard kernel (zen, lts, hardened, etc.) - must use DKMS
            print_info "Non-standard kernel detected, DKMS driver required"
            echo ""
            echo -e "  ${BOLD}Select NVIDIA driver:${NC}"
            echo -e "  ${CYAN}1)${NC} nvidia-dkms       ${DIM}(Recommended for $current_kernel)${NC}"
            echo -e "  ${CYAN}2)${NC} nvidia-open-dkms  ${DIM}(Open source - for RTX 20+ series)${NC}"
            echo -e "  ${CYAN}3)${NC} Skip NVIDIA driver"
            echo ""
            echo -ne "  ${YELLOW}?${NC}  Enter choice [1-3]: " > /dev/tty
            read nvidia_choice < /dev/tty
            
            # Remap choices for non-standard kernel
            case $nvidia_choice in
                1) nvidia_choice=1 ;;  # nvidia-dkms
                2) nvidia_choice=3 ;;  # nvidia-open-dkms
                3) nvidia_choice=4 ;;  # skip
                *) nvidia_choice=0 ;;  # invalid
            esac
        fi

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
                    # Handle both empty and non-empty MODULES arrays
                    if grep -q "^MODULES=()" /etc/mkinitcpio.conf; then
                        sudo sed -i 's/^MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
                    else
                        sudo sed -i 's/^MODULES=(\([^)]*\))/MODULES=(\1 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
                    fi
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
    configure_qemu_kvm_task
    disable_services_task
    enable_services_task
    mask_service_task
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
    echo -e "  ${CYAN}1)${NC} Full Installation        ${DIM}(GPU, Packages, Configs, Themes, Shell, XAMPP)${NC}"
    echo -e "  ${CYAN}2)${NC} Install GPU Drivers      ${DIM}(AMD, NVIDIA, Intel auto-detect)${NC}"
    echo -e "  ${CYAN}3)${NC} Install Packages Only    ${DIM}(Pacman, AUR, VSCode)${NC}"
    echo -e "  ${CYAN}4)${NC} Install Dotfiles Only    ${DIM}(~/.config, ~/.local/bin)${NC}"
    echo -e "  ${CYAN}5)${NC} Install Themes Only      ${DIM}(Icons, GTK Themes)${NC}"
    echo -e "  ${CYAN}6)${NC} Configure Shell Only     ${DIM}(Zsh, Oh My Zsh)${NC}"
    echo -e "  ${CYAN}7)${NC} Install VS Code Extensions ${DIM}(From CodeExtensions.txt)${NC}"
    echo -e "  ${RED}0)${NC} Quit"
    echo ""
    
    echo -ne "  ${YELLOW}?${NC}  Enter choice [0-7]: "
    read choice < /dev/tty
    echo ""

    case $choice in
        1) full_install ;;
        2) install_gpu_drivers_task; show_completion ;;
        3) install_packages_task; show_completion ;;
        4) install_dotfiles_task; show_completion ;;
        5) install_themes_task; show_completion ;;
        6) configure_shell_task; show_completion ;;
        7) install_vscode_extensions_task; show_completion ;;
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

# Request sudo password once and keep it alive
echo -e "${YELLOW}This installer requires sudo privileges.${NC}"
echo ""
sudo -v || { echo -e "${RED}Failed to obtain sudo privileges${NC}"; exit 1; }

# Keep sudo alive in background
SUDO_KEEPALIVE_PID=""
(while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done) &
SUDO_KEEPALIVE_PID=$!

# Cleanup function
cleanup() {
    if [[ -n "$SUDO_KEEPALIVE_PID" ]]; then
        kill "$SUDO_KEEPALIVE_PID" 2>/dev/null
    fi
}
trap cleanup EXIT

update_repo
main_menu
