#!/bin/bash

# =============================================================================
# Hyprland Dotfiles Installer v3.0 (Fedora Edition)
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

OH_MY_ZSH_REPO="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"

HOME_DIR="$HOME"
DOTFILES_DIR="$HOME_DIR/hyprland-dotfiles"
CONFIG_DIR="$HOME_DIR/.config"
THEMES_DIR="$HOME_DIR/.themes"
ICONS_DIR="$HOME_DIR/.icons"
KVANTUM_DIR="$CONFIG_DIR/Kvantum"
BIN_DIR="$HOME_DIR/.local/bin"
BUILD_DIR="$HOME_DIR/build"
TEMP_DIR="/tmp/installation"

DNF_PACKAGES="$DOTFILES_DIR/dnf-packages.txt"

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
    echo -e "${WHITE}                    │    ${MAGENTA}D O T F I L E S  v3.0${WHITE}     │${NC}"
    echo -e "${WHITE}                    │     ${GRAY}Fedora Edition${WHITE}            │${NC}"
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

install_packages_from_file() {
    local file="$1"
    local total=$(count_packages "$file")
    local current=0
    local failed_packages=()
    
    while IFS= read -r package || [[ -n "$package" ]]; do
        [[ -z "$package" || "$package" =~ ^# ]] && continue
        ((current++))
        
        echo -e "\n${GRAY}($current/$total)${NC} Installing ${CYAN}$package${NC}..."
        
        if ! sudo dnf install -y "$package"; then
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
                if ! git diff --quiet || ! git diff --cached --quiet; then
                    echo -e "  ${GRAY}ℹ${NC}  Stashing local changes..."
                    git stash push -m "Auto-stash before update" > /dev/null 2>&1
                fi
                
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
    
    print_step "Upgrading system packages..."
    echo ""
    echo -e "  ${GRAY}Running: sudo dnf upgrade -y${NC}"
    echo ""
    
    if sudo dnf upgrade -y; then
        echo ""
        print_success "System updated successfully"
    else
        echo ""
        print_error "System update failed"
        print_warning "Continuing with installation..."
    fi
}

setup_repos_task() {
    print_header "📦 Setting Up Repositories"

    # ── Copr: solopasha/hyprland ────────────────────────────────────────────
    print_step "Enabling Copr: solopasha/hyprland..."
    if sudo dnf copr enable -y solopasha/hyprland; then
        print_success "solopasha/hyprland enabled"
    else
        print_error "Failed to enable solopasha/hyprland"
    fi
    echo ""

    # ── Copr: erikreider/SwayNotificationCenter ─────────────────────────────
    print_step "Enabling Copr: erikreider/SwayNotificationCenter..."
    if sudo dnf copr enable -y erikreider/SwayNotificationCenter; then
        print_success "erikreider/SwayNotificationCenter enabled"
    else
        print_error "Failed to enable erikreider/SwayNotificationCenter"
    fi
    echo ""

    # ── VS Code (Microsoft RPM Repo) ───────────────────────────────────────
    print_step "Adding Visual Studio Code repository..."
    if [ ! -f /etc/yum.repos.d/vscode.repo ]; then
        sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
        sudo tee /etc/yum.repos.d/vscode.repo > /dev/null << 'VSCODE_REPO'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
VSCODE_REPO
        print_success "VS Code repository added"
    else
        print_info "VS Code repository already configured"
    fi
    echo ""

    # ── Google Chrome ──────────────────────────────────────────────────────
    print_step "Adding Google Chrome repository..."
    if [ ! -f /etc/yum.repos.d/google-chrome.repo ]; then
        sudo tee /etc/yum.repos.d/google-chrome.repo > /dev/null << 'CHROME_REPO'
[google-chrome]
name=google-chrome
baseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
CHROME_REPO
        print_success "Google Chrome repository added"
    else
        print_info "Google Chrome repository already configured"
    fi
    echo ""

    # ── RPM Fusion (for extra codecs/packages) ─────────────────────────────
    print_step "Enabling RPM Fusion repositories..."
    if ! rpm -q rpmfusion-free-release &>/dev/null; then
        if sudo dnf install -y \
            "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
            "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"; then
            print_success "RPM Fusion enabled"
        else
            print_warning "Failed to enable RPM Fusion"
        fi
    else
        print_info "RPM Fusion already enabled"
    fi
    echo ""
}

install_packages_task() {
    print_header "📦 Installing Packages"

    # ── Development Tools Group ─────────────────────────────────────────────
    print_step "Installing Development Tools group..."
    if sudo dnf group install -y "Development Tools"; then
        print_success "Development Tools installed"
    else
        print_warning "Development Tools group may already be installed"
    fi
    echo ""

    # ── DNF Packages ────────────────────────────────────────────────────────
    print_step "Installing packages from dnf-packages.txt..."
    install_packages_from_file "$DNF_PACKAGES"
    echo ""

    # ── Third-Party Packages ───────────────────────────────────────────────
    print_step "Installing third-party packages..."
    
    # VS Code
    echo -e "\n${GRAY}Installing ${CYAN}code${NC} (Visual Studio Code)..."
    sudo dnf install -y code 2>&1 || print_warning "VS Code installation failed"

    # Google Chrome
    echo -e "\n${GRAY}Installing ${CYAN}google-chrome-stable${NC}..."
    sudo dnf install -y google-chrome-stable 2>&1 || print_warning "Google Chrome installation failed"
    echo ""

    # ── NVM (Node Version Manager) ──────────────────────────────────────────
    print_step "Installing NVM..."
    if [ ! -d "$HOME/.nvm" ]; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
        print_success "NVM installed"
    else
        print_info "NVM already installed"
    fi
    echo ""

    # ── PNPM ────────────────────────────────────────────────────────────────
    print_step "Installing PNPM..."
    if ! command -v pnpm &>/dev/null; then
        curl -fsSL https://get.pnpm.io/install.sh | sh -
        print_success "PNPM installed"
    else
        print_info "PNPM already installed"
    fi
    echo ""

    # ── VS Code Extensions ──────────────────────────────────────────────────
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
        print_info "VS Code not found or CodeExtensions.txt missing, skipping"
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
            print_info "Install VS Code first: sudo dnf install code"
        else
            print_error "CodeExtensions.txt not found at $DOTFILES_DIR/etc/CodeExtensions.txt"
        fi
    fi
}

install_github_packages_task() {
    print_header "🔧 Building Packages from GitHub"

    mkdir -p "$BUILD_DIR"

    # ── Build Dependencies ──────────────────────────────────────────────────
    print_step "Installing build dependencies for rofi plugins..."
    sudo dnf install -y \
        autoconf automake libtool \
        rofi-wayland-devel \
        cairo-devel \
        glib2-devel \
        libqalculate-devel \
        json-glib-devel \
        xdotool \
        xsel \
        wl-clipboard \
        wtype \
        2>&1
    echo ""

    # ── rofi-emoji ──────────────────────────────────────────────────────────
    print_step "Building rofi-emoji..."
    if [ -d "$BUILD_DIR/rofi-emoji" ]; then
        print_info "rofi-emoji directory already exists, pulling updates..."
        cd "$BUILD_DIR/rofi-emoji"
        git pull 2>&1
    else
        git clone https://github.com/Mange/rofi-emoji.git "$BUILD_DIR/rofi-emoji"
        cd "$BUILD_DIR/rofi-emoji"
    fi

    if autoreconf -i && ./configure && make && sudo make install; then
        print_success "rofi-emoji installed"
    else
        print_error "rofi-emoji build failed"
    fi
    cd - > /dev/null 2>&1
    echo ""

    # ── rofi-calc ───────────────────────────────────────────────────────────
    print_step "Building rofi-calc..."
    if [ -d "$BUILD_DIR/rofi-calc" ]; then
        print_info "rofi-calc directory already exists, pulling updates..."
        cd "$BUILD_DIR/rofi-calc"
        git pull 2>&1
    else
        git clone https://github.com/svenstaro/rofi-calc.git "$BUILD_DIR/rofi-calc"
        cd "$BUILD_DIR/rofi-calc"
    fi

    if autoreconf -i && ./configure && make && sudo make install; then
        print_success "rofi-calc installed"
    else
        print_error "rofi-calc build failed"
    fi
    cd - > /dev/null 2>&1
    echo ""

    print_info "GitHub packages built in ~/build"
}

install_thirdparty_apps_task() {
    print_header "📦 Installing Third-Party Applications"

    # ── Zen Browser ─────────────────────────────────────────────────────────
    print_step "Zen Browser..."
    print_info "Zen Browser is not available in Fedora repos."
    print_info "Install manually from: https://zen-browser.app/download"
    print_info "Or use Flatpak: flatpak install flathub app.zen_browser.zen"
    echo ""

    # ── OnlyOffice ──────────────────────────────────────────────────────────
    print_step "OnlyOffice Desktop Editors..."
    print_info "Install from: https://www.onlyoffice.com/download-desktop.aspx"
    print_info "Or use Flatpak: flatpak install flathub org.onlyoffice.desktopeditors"
    echo ""

    # ── LocalSend ───────────────────────────────────────────────────────────
    print_step "LocalSend..."
    print_info "Install via Flatpak: flatpak install flathub org.localsend.localsend_app"
    echo ""

    # ── Heroic Games Launcher ───────────────────────────────────────────────
    print_step "Heroic Games Launcher..."
    print_info "Install via Flatpak: flatpak install flathub com.heroicgameslauncher.hgl"
    print_info "Or download AppImage from: https://heroicgameslauncher.com/downloads"
    echo ""

    # ── MySQL Workbench ─────────────────────────────────────────────────────
    print_step "MySQL Workbench..."
    print_info "Download RPM from: https://dev.mysql.com/downloads/workbench/"
    print_info "Then install: sudo dnf install ./mysql-workbench-*.rpm"
    echo ""

    # ── NerdFonts (JetBrainsMono) ───────────────────────────────────────────
    print_step "Installing JetBrainsMono Nerd Font..."
    local NERD_FONTS_DIR="$HOME/.local/share/fonts/NerdFonts"
    mkdir -p "$NERD_FONTS_DIR"
    
    if [ ! -f "$NERD_FONTS_DIR/JetBrainsMonoNerdFont-Regular.ttf" ]; then
        local nf_url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"
        echo -e "  ${GRAY}Downloading JetBrainsMono Nerd Font...${NC}"
        if curl -fsSL "$nf_url" -o "/tmp/JetBrainsMono.tar.xz"; then
            tar xf "/tmp/JetBrainsMono.tar.xz" -C "$NERD_FONTS_DIR"
            rm -f "/tmp/JetBrainsMono.tar.xz"
            fc-cache -fv > /dev/null 2>&1
            print_success "JetBrainsMono Nerd Font installed"
        else
            print_error "Failed to download JetBrainsMono Nerd Font"
        fi
    else
        print_info "JetBrainsMono Nerd Font already installed"
    fi
    echo ""
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
            
            TEMP_FONT_DIR=$(mktemp -d)
            unzip -q "$zipfile" -d "$TEMP_FONT_DIR"
            install_font_files_from_dir "$TEMP_FONT_DIR"
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



mask_service_task() {
    print_header "🛑  Masking Services"
    systemctl --user mask swaync.service    
}

enable_services_task() {
    print_header "⚙️  Enabling Services"

    SERVICES=(gdm bluetooth NetworkManager udisks2)

    for service in "${SERVICES[@]}"; do
        if systemctl list-unit-files "${service}.service" &>/dev/null; then
            sudo systemctl enable "$service" > /dev/null 2>&1
            print_success "$service"
        else
            print_warning "$service not found"
        fi
    done

    # Ensure NetworkManager is running
    print_step "Starting NetworkManager..."
    if sudo systemctl start NetworkManager 2>/dev/null; then
        print_success "NetworkManager is running"
    else
        print_info "NetworkManager already running"
    fi
}

install_system_configs_task() {
    print_header "🔧 Installing System Configurations"

    # ── Hotspot Sudoers ──────────────────────────────────────────────────────
    print_step "Configuring hotspot sudoers..."
    local sudoers_file="/etc/sudoers.d/hyprland-hotspot"
    local hotspot_script="$HOME/.config/hypr/Scripts/Hostpot.py"
    local sudoers_entry="$USER ALL=(ALL) NOPASSWD: /usr/bin/python3 $hotspot_script toggle"
    
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
    if ! rpm -q libvirt &>/dev/null; then
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

full_install() {
    system_update
    setup_repos_task
    install_packages_task
    install_github_packages_task
    install_thirdparty_apps_task
    install_dotfiles_task
    configure_shell_task
    install_themes_task
    install_system_configs_task
    configure_qemu_kvm_task
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
    │   GDM will start on next boot.                               │
    │   Select Hyprland from the session menu.                     │
    │                                                              │
    ╰──────────────────────────────────────────────────────────────╯
EOF
    echo -e "${NC}"

    echo -e "  ${DIM}Post-install reminders:${NC}"
    echo -e "  ${GRAY}  • Zen Browser: https://zen-browser.app/download${NC}"
    echo -e "  ${GRAY}  • OnlyOffice:  flatpak install flathub org.onlyoffice.desktopeditors${NC}"
    echo -e "  ${GRAY}  • LocalSend:   flatpak install flathub org.localsend.localsend_app${NC}"
    echo -e "  ${GRAY}  • Heroic:      flatpak install flathub com.heroicgameslauncher.hgl${NC}"
    echo ""

    choice=$(confirm_prompt "Reboot now? [y/N]" "n")

    if [[ "$choice" == "y" || "$choice" == "yes" ]]; then
        echo ""
        print_info "Rebooting in 3 seconds..."
        sleep 3
        systemctl reboot
    fi

    echo ""
    echo -e "  ${DIM}Run 'systemctl start gdm' or reboot to start your new desktop!${NC}"
    echo ""
}

# ── Main Menu ──────────────────────────────────────────────────────────────

main_menu() {
    print_logo
    
    echo -e "  ${DIM}This installer will set up your Hyprland environment on Fedora.${NC}"
    echo ""
    echo -e "  ${BOLD}Select an option:${NC}"
    echo ""
    echo -e "  ${CYAN}1)${NC} Full Installation          ${DIM}(Repos, Packages, Configs, Themes, Shell)${NC}"
    echo -e "  ${CYAN}2)${NC} Setup Repos Only           ${DIM}(Copr, VS Code, Chrome, RPM Fusion)${NC}"
    echo -e "  ${CYAN}3)${NC} Install Packages Only      ${DIM}(DNF, Third-party, VS Code extensions)${NC}"
    echo -e "  ${CYAN}4)${NC} Install Dotfiles Only      ${DIM}(~/.config, ~/.local/bin)${NC}"
    echo -e "  ${CYAN}5)${NC} Install Themes Only        ${DIM}(Icons, GTK Themes, Fonts)${NC}"
    echo -e "  ${CYAN}6)${NC} Configure Shell Only       ${DIM}(Zsh, Oh My Zsh)${NC}"
    echo -e "  ${CYAN}7)${NC} Install VS Code Extensions ${DIM}(From CodeExtensions.txt)${NC}"
    echo -e "  ${CYAN}8)${NC} Build GitHub Packages      ${DIM}(rofi-emoji, rofi-calc)${NC}"
    echo -e "  ${RED}0)${NC} Quit"
    echo ""
    
    echo -ne "  ${YELLOW}?${NC}  Enter choice [0-8]: "
    read choice < /dev/tty
    echo ""

    case $choice in
        1) full_install ;;
        2) setup_repos_task; show_completion ;;
        3) install_packages_task; show_completion ;;
        4) install_dotfiles_task; show_completion ;;
        5) install_themes_task; show_completion ;;
        6) configure_shell_task; show_completion ;;
        7) install_vscode_extensions_task; show_completion ;;
        8) install_github_packages_task; show_completion ;;
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
