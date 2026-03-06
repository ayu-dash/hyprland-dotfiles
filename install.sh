#!/bin/bash

C_RED="196"
C_GREEN="82"
C_YELLOW="220"
C_BLUE="39"
C_MAGENTA="213"
C_CYAN="51"
C_WHITE="255"
C_GRAY="245"
C_DIM="240"

NC=$'\033[0m'
DIM=$'\033[2m'
GRAY=$'\033[0;90m'
WHITE=$'\033[1;37m'
CYAN=$'\033[0;36m'
GREEN=$'\033[0;32m'
RED=$'\033[0;31m'
YELLOW=$'\033[0;33m'

OH_MY_ZSH_REPO="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"

DOTFILES_DIR="$HOME/hyprland-dotfiles"
CONFIG_DIR="$HOME/.config"
THEMES_DIR="$HOME/.themes"
ICONS_DIR="$HOME/.icons"
KVANTUM_DIR="$CONFIG_DIR/Kvantum"
BIN_DIR="$HOME/.local/bin"
FONTS_DIR="$HOME/.local/share/fonts"
APPS_DIR="$HOME/.local/share/applications"
BUILD_DIR="$HOME/build"
TEMP_DIR="/tmp/installation"

DNF_PACKAGES="$DOTFILES_DIR/dnf-packages.txt"
FLATPAK_PACKAGES="$DOTFILES_DIR/flatpak-packages.txt"
VSCODE_EXTENSIONS="$DOTFILES_DIR/etc/CodeExtensions.txt"

ensure_gum() {
    command -v gum &>/dev/null && return
    echo "Installing gum..."
    sudo dnf install -y gum || { echo "ERROR: Install gum manually: sudo dnf install gum"; exit 1; }
}

print_logo() {
    echo ""
    gum style \
        --foreground "$C_CYAN" --border double --border-foreground "$C_CYAN" \
        --align center --width 80 --padding "1 2" \
        "██╗  ██╗██╗   ██╗██████╗ ██████╗ ██╗      █████╗ ███╗   ██╗██████╗ " \
        "██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗██║     ██╔══██╗████╗  ██║██╔══██╗" \
        "███████║ ╚████╔╝ ██████╔╝██████╔╝██║     ███████║██╔██╗ ██║██║  ██║" \
        "██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══██╗██║     ██╔══██║██║╚██╗██║██║  ██║" \
        "██║  ██║   ██║   ██║     ██║  ██║███████╗██║  ██║██║ ╚████║██████╔╝" \
        "╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝"
    echo ""
    gum style --foreground "$C_MAGENTA" --bold --align center --width 80 "D O T F I L E S  v3.0"
    gum style --foreground "$C_GRAY" --align center --width 80 "Fedora Edition — by ayudash"
    echo ""
}

print_header() {
    echo ""
    gum style --foreground "$C_WHITE" --bold --border rounded \
        --border-foreground "$C_BLUE" --padding "0 2" --width 72 "$1"
    echo ""
}

print_step()    { gum style --foreground "$C_CYAN"   "  ▶  $1"; }
print_success() { gum style --foreground "$C_GREEN"  "  ✓  $1"; }
print_error()   { gum style --foreground "$C_RED"    "  ✗  $1"; }
print_warning() { gum style --foreground "$C_YELLOW" "  ⚠  $1"; }
print_info()    { gum style --foreground "$C_DIM"    "  ℹ  $1"; }

count_packages() { grep -v '^#' "$1" | grep -v '^$' | wc -l; }

copy_system_config() {
    local src="$1" dest="$2" name="$3"
    [[ -f "$src" || -d "$src" ]] || return 1
    sudo mkdir -p "$(dirname "$dest")"
    if sudo cp -r "$src" "$dest"; then
        print_success "$name"
    else
        print_error "Failed to install $name"
        return 1
    fi
}

extract_archives() {
    local src_dir="$1" dest_dir="$2"
    [[ -d "$src_dir" ]] || return 1
    for archive in "$src_dir"/*.tar.xz; do
        [[ -f "$archive" ]] || continue
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
    local total=$(count_packages "$file") current=0 failed=()

    while IFS= read -r package || [[ -n "$package" ]]; do
        [[ -z "$package" || "$package" =~ ^# ]] && continue
        ((current++))
        echo -e "\n${GRAY}($current/$total)${NC} Installing ${CYAN}$package${NC}..."
        sudo dnf install -y "$package" || failed+=("$package")
    done < "$file"

    echo ""
    if (( ${#failed[@]} > 0 )); then
        print_warning "Failed packages:"
        printf "    ${RED}✗${NC} %s\n" "${failed[@]}"
    fi
    print_success "Installed $((current - ${#failed[@]}))/$total packages"
}

manage_services() {
    local action="$1"; shift
    for svc in "$@"; do
        if systemctl list-unit-files "${svc}.service" &>/dev/null; then
            sudo systemctl $action "$svc" >/dev/null 2>&1
            print_success "$svc"
        else
            print_warning "$svc not found"
        fi
    done
}

install_sudoers_rule() {
    local file="$1" content="$2" label="$3"
    if echo "$content" | sudo tee "$file" >/dev/null && sudo chmod 440 "$file"; then
        print_success "$label"
    else
        print_error "Failed to install $label"
    fi
}

install_font_files() {
    local dir="$1"
    if find "$dir" -type f \( -iname "*variable*" -o -iname "*vf.ttf" -o -iname "*vf.otf" \) | grep -q .; then
        find "$dir" -type f \( -iname "*variable*" -o -iname "*vf.ttf" -o -iname "*vf.otf" \) -exec cp -f {} "$FONTS_DIR/" \;
    else
        find "$dir" -type f \( -iname "*.ttf" -o -iname "*.otf" \) -exec cp -f {} "$FONTS_DIR/" \;
    fi
}

install_vscode_ext() {
    if ! command -v code &>/dev/null; then
        print_error "VS Code (code) not found"
        print_info "Install first: sudo dnf install code"
        return 1
    fi
    [[ -f "$VSCODE_EXTENSIONS" ]] || { print_error "CodeExtensions.txt not found"; return 1; }

    local total=$(count_packages "$VSCODE_EXTENSIONS") current=0 failed=()

    while IFS= read -r ext || [[ -n "$ext" ]]; do
        [[ -z "$ext" || "$ext" =~ ^# ]] && continue
        ((current++))
        echo -e "\n${GRAY}($current/$total)${NC} Installing ${CYAN}$ext${NC}..."
        code --install-extension "$ext" --force 2>&1 || failed+=("$ext")
    done < "$VSCODE_EXTENSIONS"

    echo ""
    if (( ${#failed[@]} > 0 )); then
        print_warning "Failed extensions:"
        printf "    ${RED}✗${NC} %s\n" "${failed[@]}"
    fi
    print_success "Installed $((current - ${#failed[@]}))/$total extensions"
}

update_repo() {
    [[ -d "$DOTFILES_DIR/.git" ]] || return
    print_step "Checking for updates..."
    cd "$DOTFILES_DIR"

    git fetch origin >/dev/null 2>&1
    local LOCAL=$(git rev-parse HEAD)
    local REMOTE=$(git rev-parse @{u} 2>/dev/null)

    if [[ "$LOCAL" != "$REMOTE" ]]; then
        print_warning "New version available!"
        if gum confirm "Update to latest version?"; then
            if ! git diff --quiet || ! git diff --cached --quiet; then
                print_info "Stashing local changes..."
                git stash push -m "Auto-stash before update" >/dev/null 2>&1
            fi
            echo ""
            if git pull origin fedora 2>&1; then
                echo ""
                print_success "Updated to latest version"
                print_info "Restarting installer..."
                sleep 1
                exec "$0" "$@"
            else
                echo ""
                print_error "Failed to update"
                print_info "Try: git pull origin fedora --rebase"
            fi
        fi
    else
        print_success "Already on latest version"
    fi

    cd - > /dev/null
}

system_update() {
    print_header "Updating System"

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
    print_header "Setting Up Repositories"

    print_step "Enabling Copr: solopasha/hyprland..."
    sudo dnf copr enable -y solopasha/hyprland && print_success "solopasha/hyprland enabled" || print_error "Failed to enable solopasha/hyprland"
    echo ""

    print_step "Enabling Copr: erikreider/SwayNotificationCenter..."
    sudo dnf copr enable -y erikreider/SwayNotificationCenter && print_success "erikreider/SwayNotificationCenter enabled" || print_error "Failed to enable erikreider/SwayNotificationCenter"
    echo ""

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

    print_step "Enabling RPM Fusion repositories..."
    if ! rpm -q rpmfusion-free-release &>/dev/null; then
        sudo dnf install -y \
            "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
            "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm" \
            && print_success "RPM Fusion enabled" || print_warning "Failed to enable RPM Fusion"
    else
        print_info "RPM Fusion already enabled"
    fi
    echo ""

    print_step "Enabling Flathub (Flatpak) repository..."
    if ! flatpak remote-list | grep -q flathub; then
        sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo \
            && print_success "Flathub repository enabled" || print_warning "Failed to enable Flathub"
    else
        print_info "Flathub repository already configured"
    fi
    echo ""
}

install_packages_task() {
    print_header "Installing Packages"

    print_step "Installing Development Tools group..."
    sudo dnf group install -y "Development Tools" && print_success "Development Tools installed" || print_warning "Development Tools group may already be installed"
    echo ""

    print_step "Installing packages from dnf-packages.txt..."
    install_packages_from_file "$DNF_PACKAGES"
    echo ""

    print_step "Installing third-party packages..."

    echo -e "\n${GRAY}Installing ${CYAN}code${NC} (Visual Studio Code)..."
    sudo dnf install -y code 2>&1 || print_warning "VS Code installation failed"

    echo -e "\n${GRAY}Installing ${CYAN}google-chrome-stable${NC}..."
    sudo dnf install -y google-chrome-stable 2>&1 || print_warning "Google Chrome installation failed"
    echo ""

    print_step "Installing NVM..."
    if [ ! -d "$HOME/.nvm" ]; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
        print_success "NVM installed"
    else
        print_info "NVM already installed"
    fi
    echo ""

    print_step "Installing PNPM..."
    if ! command -v pnpm &>/dev/null; then
        curl -fsSL https://get.pnpm.io/install.sh | sh -
        print_success "PNPM installed"
    else
        print_info "PNPM already installed"
    fi
    echo ""

    print_step "Installing VS Code extensions..."
    install_vscode_ext
}

build_cargo_package() {
    local name="$1"
    if cargo build --release; then
        cp -f "target/release/$name" "$BIN_DIR/"
        chmod +x "$BIN_DIR/$name"
        mkdir -p "$HOME/bin"
        ln -sf "$BIN_DIR/$name" "$HOME/bin/$name"
        print_success "$name installed to ~/.local/bin and symlinked to ~/bin"
    else
        print_error "$name build failed"
    fi
}

prepare_github_repo() {
    local name="$1" repo_url="$2"
    print_step "Building $name..."
    if [ -d "$BUILD_DIR/$name" ]; then
        print_info "$name directory already exists, pulling updates..."
        cd "$BUILD_DIR/$name"
        git pull 2>&1
    else
        git clone "$repo_url" "$BUILD_DIR/$name"
        cd "$BUILD_DIR/$name"
    fi
}

install_github_packages_task() {
    print_header "Building Packages from GitHub"

    mkdir -p "$BUILD_DIR"

    prepare_github_repo "rofi-emoji" "https://github.com/Mange/rofi-emoji.git"

    autoreconf -i && mkdir -p build && cd build && ../configure && make && sudo make install \
        && print_success "rofi-emoji installed" || print_error "rofi-emoji build failed"
    cd "$BUILD_DIR" > /dev/null 2>&1
    echo ""

    prepare_github_repo "rofi-calc" "https://github.com/svenstaro/rofi-calc.git"

    meson setup build && meson compile -C build && sudo meson install -C build \
        && print_success "rofi-calc installed" || print_error "rofi-calc build failed"
    cd "$BUILD_DIR" > /dev/null 2>&1
    echo ""

    prepare_github_repo "wlctl" "https://github.com/aashish-thapa/wlctl.git"


    build_cargo_package "wlctl"
    cd "$BUILD_DIR" > /dev/null 2>&1
    echo ""

    prepare_github_repo "bluetui" "https://github.com/pythops/bluetui"

    build_cargo_package "bluetui"
    cd "$BUILD_DIR" > /dev/null 2>&1
    echo ""

    prepare_github_repo "hyprshot" "https://github.com/Gustash/hyprshot.git"

    chmod +x hyprshot
    ln -sf "$BUILD_DIR/hyprshot/hyprshot" "$BIN_DIR/hyprshot"
    print_success "hyprshot installed to ~/.local/bin"
    cd "$BUILD_DIR" > /dev/null 2>&1
    echo ""

    print_info "GitHub packages built in ~/build"
}

install_thirdparty_apps_task() {
    print_header "Installing Third-Party Applications"

    if command -v flatpak &>/dev/null; then
        print_step "Installing Flatpak Applications..."
        
        if [ ! -f "$FLATPAK_PACKAGES" ]; then
            print_error "flatpak-packages.txt not found"
        else
            local flatpaks=()
            while IFS= read -r fp || [[ -n "$fp" ]]; do
                [[ -z "$fp" || "$fp" =~ ^# ]] && continue
                flatpaks+=("$fp")
            done < "$FLATPAK_PACKAGES"

            if [[ ${#flatpaks[@]} -eq 0 ]]; then
                print_info "No Flatpak packages to install."
            else
                echo -e "  ${GRAY}The following Flatpak apps will be installed:${NC}"
                for fp in "${flatpaks[@]}"; do
                    echo -e "  ${DIM}  - $fp${NC}"
                done
                echo ""

                if gum confirm "Install these Flatpak applications?"; then
                    for fp in "${flatpaks[@]}"; do
                        echo -e "\n${GRAY}Installing ${CYAN}$fp${NC}..."
                        if sudo flatpak install -y flathub "$fp"; then
                            print_success "$fp installed"
                        else
                            print_error "Failed to install $fp"
                        fi
                    done
                else
                    print_info "Skipping Flatpak applications"
                fi
                echo ""
            fi
        fi
    else
        print_info "Flatpak not installed, skipping Flatpak applications"
    fi

    print_step "MySQL Workbench..."
    print_info "Download RPM from: https://dev.mysql.com/downloads/workbench/"
    print_info "Then install: sudo dnf install ./mysql-workbench-*.rpm"
    echo ""

    print_step "Installing JetBrainsMono Nerd Font..."
    local NERD_FONTS_DIR="$HOME/.local/share/fonts/NerdFonts"
    mkdir -p "$NERD_FONTS_DIR"

    if [ ! -f "$NERD_FONTS_DIR/JetBrainsMonoNerdFont-Regular.ttf" ]; then
        local nf_url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"
        echo -e "  ${GRAY}Downloading JetBrainsMono Nerd Font...${NC}"
        if curl -fsSL "$nf_url" -o "/tmp/JetBrainsMono.tar.xz"; then
            tar xf "/tmp/JetBrainsMono.tar.xz" -C "$NERD_FONTS_DIR"
            rm -f "/tmp/JetBrainsMono.tar.xz"
            gum spin --spinner dot --title "Rebuilding font cache..." -- fc-cache -fv >/dev/null 2>&1
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
    print_header "Installing Dotfiles"

    mkdir -p "$CONFIG_DIR" "$BIN_DIR" "$THEMES_DIR" "$ICONS_DIR"
    xdg-user-dirs-update 2>&1

    print_step "Copying configuration files..."
    for dir in "$DOTFILES_DIR/config/"*; do
        local dir_name=$(basename "$dir")
        cp -R "$dir" "$CONFIG_DIR/" 2>/dev/null \
            && print_success "$dir_name" || print_error "$dir_name"
    done
    echo ""

    print_step "Installing scripts..."
    if cp -R "$DOTFILES_DIR/bin/"* "$BIN_DIR/" 2>/dev/null; then
        chmod +x "$BIN_DIR"/* 2>/dev/null
        print_success "Scripts copied to ~/.local/bin"
    else
        print_error "Failed to copy scripts"
    fi
    echo ""

    print_step "Copying desktop applications..."
    mkdir -p "$APPS_DIR"
    if cp -R "$DOTFILES_DIR/applications/"* "$APPS_DIR/" 2>/dev/null; then
        print_success "Applications copied to ~/.local/share/applications"
    else
        print_error "Failed to copy applications"
    fi
}

configure_shell_task() {
    print_header "Configuring Shell"

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
    local plugins=(
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
    print_header "Installing Themes & Icons"

    print_step "Extracting GTK icon packs..."
    if [ -d "$DOTFILES_DIR/assets/gtk/icons" ]; then
        extract_archives "$DOTFILES_DIR/assets/gtk/icons" "$ICONS_DIR"
    else
        print_info "No GTK icons found"
    fi
    echo ""

    print_step "Extracting GTK themes..."
    if [ -d "$DOTFILES_DIR/assets/gtk/themes" ]; then
        extract_archives "$DOTFILES_DIR/assets/gtk/themes" "$THEMES_DIR"
    else
        print_info "No GTK themes found"
    fi
    echo ""

    print_step "Installing Kvantum themes..."
    if [ -d "$DOTFILES_DIR/assets/kvantum/themes" ]; then
        mkdir -p "$KVANTUM_DIR"
        extract_archives "$DOTFILES_DIR/assets/kvantum/themes" "$KVANTUM_DIR"
    else
        print_info "No Kvantum themes found"
    fi
    echo ""

    if [ -d "$DOTFILES_DIR/assets/kvantum/icons" ]; then
        print_step "Installing Kvantum icons..."
        extract_archives "$DOTFILES_DIR/assets/kvantum/icons" "$ICONS_DIR"
        echo ""
    fi

    if [ -d "$DOTFILES_DIR/assets/fonts" ]; then
        print_step "Installing custom fonts..."
        mkdir -p "$FONTS_DIR"

        for zipfile in "$DOTFILES_DIR/assets/fonts"/*.zip; do
            [ -f "$zipfile" ] || continue
            print_info "Extracting $(basename "$zipfile")..."
            local tmp=$(mktemp -d)
            unzip -q "$zipfile" -d "$tmp"
            install_font_files "$tmp"
            rm -rf "$tmp"
        done

        find "$DOTFILES_DIR/assets/fonts" -mindepth 1 -maxdepth 1 -type d | while read -r d; do
            install_font_files "$d"
        done

        find "$DOTFILES_DIR/assets/fonts" -maxdepth 1 -type f \( -iname "*.ttf" -o -iname "*.otf" \) \
            -exec cp -f {} "$FONTS_DIR/" \; 2>/dev/null

        print_success "Fonts installed to ~/.local/share/fonts"
        echo ""
    fi

    print_step "Rebuilding font cache..."
    gum spin --spinner dot --title "Rebuilding font cache..." -- fc-cache -fv >/dev/null 2>&1
    print_success "Font cache updated"
}

disable_services_task() {
    print_header "Disabling Services"
    manage_services disable swaync.service NetworkManager-wait-online.service plymouth-quit-wait.service ModemManager.service  nfs-client.target gssproxy.service rpcbind.service sssd-kcm.service lvm2-monitor.service
}

mask_service_task() {
    print_header "Masking Services"
    manage_services mask swaync.service NetworkManager-wait-online.service plymouth-quit-wait.service ModemManager.service  nfs-client.target gssproxy.service rpcbind.service sssd-kcm.service lvm2-monitor.service
}

enable_services_task() {
    print_header "Enabling Services"
    manage_services enable gdm bluetooth NetworkManager udisks2

    print_step "Starting NetworkManager..."
    sudo systemctl start NetworkManager 2>/dev/null \
        && print_success "NetworkManager is running" || print_info "NetworkManager already running"
}

install_system_configs_task() {
    print_header "Installing System Configurations"

    print_step "Optimizing DNF configuration..."
    sudo tee /etc/dnf/dnf.conf > /dev/null << 'EOF'
# see `man dnf.conf` for defaults and possible options

[main]
gpgcheck=True
installonly_limit=3
clean_requirements_on_remove=True
best=False
skip_if_unavailable=True
fastestmirror=True
max_parallel_downloads=10
defaultyes=True
EOF
    print_success "DNF configuration optimized"
    echo ""

    print_step "Configuring faster boot (GRUB timeout & Plymouth fix)..."
    local grub_updated=false
    
    if grep -q "GRUB_TIMEOUT=5" /etc/default/grub 2>/dev/null; then
        sudo sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=1/g' /etc/default/grub
        print_success "GRUB timeout reduced to 1s"
        grub_updated=true
    fi

    if ! grep -q "initcall_blacklist=simpledrm_platform_driver_init" /etc/default/grub 2>/dev/null; then
        sudo sed -i 's/GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="initcall_blacklist=simpledrm_platform_driver_init /g' /etc/default/grub
        print_success "Plymouth simpledrm freeze fix applied"
        grub_updated=true
    fi

    if [ "$grub_updated" = true ]; then
        sudo grub2-mkconfig -o /boot/grub2/grub.cfg >/dev/null 2>&1
    else
        print_info "GRUB config unchanged (already optimized)"
    fi
    echo ""

    print_step "Configuring WiFi power save..."
    local wifi_script="$BIN_DIR/wifiPowersave"
    sudo tee /etc/udev/rules.d/99-wifi-powersave.rules >/dev/null <<EOF
SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", RUN+="$wifi_script on"
SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="1", RUN+="$wifi_script off"
EOF
    print_success "WiFi power save udev rules installed"
    echo ""


    print_step "Configuring faster shutdown..."
    copy_system_config "$DOTFILES_DIR/etc/systemd/system.conf.d/99-timeout.conf" "/etc/systemd/system.conf.d/99-timeout.conf" "System DefaultTimeoutStopSec=10s"
    copy_system_config "$DOTFILES_DIR/etc/systemd/user.conf.d/timeout.conf" "/etc/systemd/user.conf.d/timeout.conf" "User DefaultTimeoutStopSec=5s"
    sudo systemctl daemon-reload
    systemctl --user daemon-reload
    echo ""

    print_step "Optimizing systemd-journald..."
    sudo sed -i 's/^#SystemMaxUse=.*/SystemMaxUse=50M/' /etc/systemd/journald.conf
    sudo systemctl restart systemd-journald
    print_success "systemd-journald max size set to 50M"
    echo ""

    print_step "Configuring sudoers rules..."

    local hotspot_script="$HOME/.config/hypr/Scripts/Hostpot.py"
    install_sudoers_rule "/etc/sudoers.d/hyprland-hotspot" \
        "$USER ALL=(ALL) NOPASSWD: /usr/bin/python3 $hotspot_script toggle" \
        "Hotspot sudoers rule"

    install_sudoers_rule "/etc/sudoers.d/hyprland-remote-win10" \
        "%libvirt ALL=(ALL) NOPASSWD: /usr/bin/virsh
%libvirt ALL=(ALL) NOPASSWD: /usr/bin/virsh start remotewin10
%libvirt ALL=(ALL) NOPASSWD: /usr/bin/virsh shutdown remotewin10
%libvirt ALL=(ALL) NOPASSWD: /usr/bin/virsh reboot remotewin10
%libvirt ALL=(ALL) NOPASSWD: /usr/bin/virt-manager
%libvirt ALL=(ALL) NOPASSWD: /usr/bin/qemu-system-x86_64" \
        "Libvirt sudoers rules"

    install_sudoers_rule "/etc/sudoers.d/hyprland-hda-verb" \
        "$USER ALL=(ALL) NOPASSWD: /usr/bin/hda-verb" \
        "HDA Verb sudoers rule"
    echo ""
}

configure_qemu_kvm_task() {
    print_header "Configuring QEMU/KVM"

    rpm -q libvirt &>/dev/null || { print_info "libvirt not installed, skipping"; return 0; }

    print_step "Enabling libvirtd service..."
    sudo systemctl enable libvirtd && print_success "libvirtd enabled" || print_error "Failed to enable libvirtd"

    print_step "Adding user to libvirt group..."
    sudo usermod -aG libvirt "$USER" && print_success "User $USER added to libvirt group" || print_error "Failed to add user"

    print_step "Starting libvirtd service..."
    sudo systemctl start libvirtd && print_success "libvirtd started" || print_warning "Failed (may need reboot)"

    print_step "Configuring default network..."
    sudo virsh net-autostart default 2>/dev/null && print_success "Default network autostart" || print_warning "Not found or configured"
    sudo virsh net-start default 2>/dev/null && print_success "Default network started" || print_info "Already running"

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
    disable_services_task
    mask_service_task
    show_completion
}

show_completion() {
    echo ""
    gum style \
        --foreground "$C_GREEN" --border double --border-foreground "$C_GREEN" \
        --align center --width 72 --padding "1 2" \
        "" "Installation Complete!" "" \
        "Your Hyprland environment is ready." \
        "Please reboot to apply all changes." \
        "" \
        "GDM will start on next boot." \
        "Select Hyprland from the session menu." ""
    echo ""

    if gum confirm "Reboot now?" --default=false; then
        echo ""
        print_info "Rebooting in 3 seconds..."
        sleep 3
        systemctl reboot
    fi

    echo -e "\n  ${DIM}Run 'systemctl start gdm' or reboot to start your new desktop!${NC}\n"
}

main_menu() {
    print_logo
    gum style --foreground "$C_DIM" "  This installer will set up your Hyprland environment on Fedora."
    echo ""

    local choice
    choice=$(gum choose --height 12 --header "  Select an option" \
        "Full Installation         (Repos, Packages, Configs, Themes, Shell)" \
        "Setup Repos Only          (Copr, VS Code, Chrome, RPM Fusion)" \
        "Install Packages Only     (DNF, Third-party, VS Code extensions)" \
        "Install Dotfiles Only     (~/.config, ~/.local/bin)" \
        "Install Themes Only       (Icons, GTK Themes, Fonts)" \
        "Configure Shell Only      (Zsh, Oh My Zsh)" \
        "Install VS Code Ext       (From CodeExtensions.txt)" \
        "Build GitHub Packages     (rofi-emoji, rofi-calc)" \
        "Quit")
    echo ""

    case "$choice" in
        "Full Installation"*)     full_install ;;
        "Setup Repos Only"*)      setup_repos_task; show_completion ;;
        "Install Packages Only"*) install_packages_task; show_completion ;;
        "Install Dotfiles Only"*) install_dotfiles_task; show_completion ;;
        "Install Themes Only"*)   install_themes_task; show_completion ;;
        "Configure Shell Only"*)  configure_shell_task; show_completion ;;
        "Install VS Code Ext"*)   install_vscode_ext; show_completion ;;
        "Build GitHub Packages"*) install_github_packages_task; show_completion ;;
        "Quit"|"")                gum style --foreground "$C_DIM" "  Bye!"; exit 0 ;;
        *)                        print_error "Invalid choice!"; sleep 1; clear; main_menu ;;
    esac
}

clear

[[ $EUID -eq 0 ]] && { echo -e "${RED}Error: Do not run as root!${NC}"; exit 1; }

ensure_gum

gum style --foreground "$C_YELLOW" "This installer requires sudo privileges."
echo ""
sudo -v || { echo -e "${RED}Failed to obtain sudo privileges${NC}"; exit 1; }

(while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done) &
SUDO_KEEPALIVE_PID=$!
trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null' EXIT

update_repo
main_menu
