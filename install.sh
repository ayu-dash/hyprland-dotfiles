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

YAY_REPO="https://aur.archlinux.org/yay-git.git"
OH_MY_ZSH_REPO="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"

DOTFILES_DIR="$HOME/hyprland-dotfiles"
CONFIG_DIR="$HOME/.config"
THEMES_DIR="$HOME/.themes"
ICONS_DIR="$HOME/.icons"
KVANTUM_DIR="$CONFIG_DIR/Kvantum"
BIN_DIR="$HOME/.local/bin"
FONTS_DIR="$HOME/.local/share/fonts"
TEMP_DIR="/tmp/installation"

PACMAN_PACKAGES="$DOTFILES_DIR/pacman-packages.txt"
YAY_PACKAGES="$DOTFILES_DIR/yay-packages.txt"
VSCODE_EXTENSIONS="$DOTFILES_DIR/etc/CodeExtensions.txt"

ensure_gum() {
    command -v gum &>/dev/null && return
    echo "Installing gum..."
    sudo pacman -S --noconfirm gum 2>/dev/null || { echo "ERROR: Install gum manually: sudo pacman -S gum"; exit 1; }
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
    gum style --foreground "$C_MAGENTA" --bold --align center --width 80 "D O T F I L E S  v2.0"
    gum style --foreground "$C_GRAY" --align center --width 80 "by ayudash"
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
    local file="$1" installer="$2"
    local total=$(count_packages "$file") current=0 failed=()

    while IFS= read -r pkg || [[ -n "$pkg" ]]; do
        [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
        ((current++))
        echo -e "\n${GRAY}($current/$total)${NC} Installing ${CYAN}$pkg${NC}..."
        $installer -S --noconfirm --needed "$pkg" || failed+=("$pkg")
    done < "$file"

    echo ""
    if (( ${#failed[@]} > 0 )); then
        print_warning "Failed packages:"
        printf "    ${RED}✗${NC} %s\n" "${failed[@]}"
    fi
    print_success "Installed $((current - ${#failed[@]}))/$total packages"
}

install_pacman_packages() {
    local -n _pkgs=$1
    for pkg in "${_pkgs[@]}"; do
        echo -e "  ${GRAY}Installing: $pkg${NC}"
        if sudo pacman -S --noconfirm --needed "$pkg" 2>/dev/null; then
            print_success "$pkg"
        else
            print_warning "$pkg (may not be available)"
        fi
    done
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

install_vscode_ext() {
    if ! command -v code &>/dev/null; then
        print_error "VS Code (code) not found"
        print_info "Install first: yay -S visual-studio-code-bin"
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

install_font_files() {
    local dir="$1"
    if find "$dir" -type f \( -iname "*variable*" -o -iname "*vf.ttf" -o -iname "*vf.otf" \) | grep -q .; then
        find "$dir" -type f \( -iname "*variable*" -o -iname "*vf.ttf" -o -iname "*vf.otf" \) -exec cp -f {} "$FONTS_DIR/" \;
    else
        find "$dir" -type f \( -iname "*.ttf" -o -iname "*.otf" \) -exec cp -f {} "$FONTS_DIR/" \;
    fi
}

write_resolved_conf() {
    sudo tee /etc/systemd/resolved.conf >/dev/null <<< "$1"
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
            if git pull origin main 2>&1 || git pull origin master 2>&1; then
                echo ""
                print_success "Updated to latest version"
                print_info "Restarting installer..."
                sleep 1
                exec "$0" "$@"
            else
                echo ""
                print_error "Failed to update"
                print_info "Try: git pull origin main --rebase"
            fi
        fi
    else
        print_success "Already on latest version"
    fi
    cd - >/dev/null
}

system_update() {
    print_header "Updating System"
    print_step "Synchronizing package databases and upgrading system..."
    echo -e "\n  ${GRAY}Running: sudo pacman -Syyu${NC}\n"

    if sudo pacman -Syyu --noconfirm; then
        echo ""; print_success "System updated successfully"
    else
        echo ""; print_error "System update failed"; print_warning "Continuing..."
    fi
}

install_packages_task() {
    print_header "Installing Packages"

    print_step "Installing official packages..."
    install_packages_from_file "$PACMAN_PACKAGES" "sudo pacman"
    echo ""

    print_step "Setting up Yay (AUR helper)..."
    if ! command -v yay &>/dev/null; then
        mkdir -p "$TEMP_DIR"
        local yay_installed=false attempt=0 max_attempts=2

        while [[ "$yay_installed" == false && $attempt -lt $max_attempts ]]; do
            ((attempt++))

            if [[ -d "$TEMP_DIR/yay" ]]; then
                print_info "Reusing existing yay folder..."
            else
                echo -e "\n${GRAY}(1/2)${NC} Cloning ${CYAN}yay-git${NC} from AUR..."
                echo ""
                if git clone --progress "$YAY_REPO" "$TEMP_DIR/yay"; then
                    echo ""; print_success "Yay repository cloned"
                else
                    print_error "Failed to clone Yay"; return 1
                fi
            fi

            echo -e "\n${GRAY}(2/2)${NC} Building ${CYAN}yay${NC}..."
            echo ""
            cd "$TEMP_DIR/yay"

            if makepkg -si --noconfirm; then
                echo ""; print_success "Yay installed successfully"
                yay_installed=true
            else
                print_error "Failed to build Yay (attempt $attempt/$max_attempts)"
                cd - >/dev/null
                rm -rf "$TEMP_DIR/yay"

                if (( attempt < max_attempts )); then
                    gum confirm "Retry yay installation?" || { print_warning "Skipping AUR packages"; return 1; }
                else
                    print_error "Max attempts reached"; print_warning "Skipping AUR packages"; return 1
                fi
            fi
            cd - >/dev/null 2>&1
        done
    else
        print_info "Yay already installed, skipping"
    fi
    echo ""

    print_step "Installing AUR packages..."
    install_packages_from_file "$YAY_PACKAGES" "yay"
    echo ""

    print_step "Installing VS Code extensions..."
    install_vscode_ext
}

install_vscode_extensions_task() {
    print_header "Installing VS Code Extensions"
    install_vscode_ext
}

install_dotfiles_task() {
    print_header "Installing Dotfiles"
    mkdir -p "$CONFIG_DIR" "$BIN_DIR" "$THEMES_DIR" "$ICONS_DIR"
    xdg-user-dirs-update 2>&1

    print_step "Copying configuration files..."
    for dir in "$DOTFILES_DIR/config/"*; do
        local name=$(basename "$dir")
        cp -R "$dir" "$CONFIG_DIR/" 2>/dev/null && print_success "$name" || print_error "$name"
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
    print_header "Configuring Shell"

    print_step "Installing Oh My Zsh..."
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        echo ""
        RUNZSH=no CHSH=no sh -c "$(curl -fsSL $OH_MY_ZSH_REPO)"
        echo ""; print_success "Oh My Zsh installed"
    else
        print_info "Oh My Zsh already installed"
    fi

    print_step "Installing Zsh plugins..."
    local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    local plugins=(zsh-autosuggestions zsh-syntax-highlighting zsh-completions zsh-history-substring-search)

    for plugin in "${plugins[@]}"; do
        if [[ ! -d "$zsh_custom/plugins/$plugin" ]]; then
            git clone "https://github.com/zsh-users/$plugin" "$zsh_custom/plugins/$plugin" 2>/dev/null
            print_success "$plugin"
        else
            print_info "$plugin already installed"
        fi
    done

    cp -f "$DOTFILES_DIR/.zshrc" "$HOME/"
    chsh -s /usr/bin/zsh
    print_success "Default shell set to Zsh"
    echo ""
}

configure_git_task() {
    print_header "Configuring Git Globals"
    print_step "Setting up Git user configuration..."
    echo ""

    if gum confirm "Configure Git global user data?" --default=true; then
        local git_name
        git_name=$(gum input --placeholder "Enter Git username (user.name)")
        if [[ -n "$git_name" ]]; then
            git config --global user.name "$git_name"
            print_success "Git user.name set to: $git_name"
        fi

        local git_email
        git_email=$(gum input --placeholder "Enter Git email (user.email)")
        if [[ -n "$git_email" ]]; then
            git config --global user.email "$git_email"
            print_success "Git user.email set to: $git_email"
        fi
        echo ""
    else
        print_info "Skipping Git configuration"
        echo ""
    fi
}

install_themes_task() {
    print_header "Installing Themes & Icons"

    print_step "Extracting GTK icon packs..."
    [[ -d "$DOTFILES_DIR/assets/gtk/icons" ]] \
        && extract_archives "$DOTFILES_DIR/assets/gtk/icons" "$ICONS_DIR" \
        || print_info "No GTK icons found"
    echo ""

    print_step "Extracting GTK themes..."
    [[ -d "$DOTFILES_DIR/assets/gtk/themes" ]] \
        && extract_archives "$DOTFILES_DIR/assets/gtk/themes" "$THEMES_DIR" \
        || print_info "No GTK themes found"
    echo ""

    print_step "Installing Kvantum themes..."
    if [[ -d "$DOTFILES_DIR/assets/kvantum/themes" ]]; then
        mkdir -p "$KVANTUM_DIR"
        extract_archives "$DOTFILES_DIR/assets/kvantum/themes" "$KVANTUM_DIR"
    else
        print_info "No Kvantum themes found"
    fi
    echo ""

    if [[ -d "$DOTFILES_DIR/assets/kvantum/icons" ]]; then
        print_step "Installing Kvantum icons..."
        extract_archives "$DOTFILES_DIR/assets/kvantum/icons" "$ICONS_DIR"
        echo ""
    fi

    if [[ -d "$DOTFILES_DIR/assets/fonts" ]]; then
        print_step "Installing custom fonts..."
        mkdir -p "$FONTS_DIR"

        for zipfile in "$DOTFILES_DIR/assets/fonts"/*.zip; do
            [[ -f "$zipfile" ]] || continue
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
    manage_services "disable --now" NetworkManager wpa_supplicant systemd-networkd-wait-online.service
}

mask_service_task() {
    print_header "Masking Services"
    manage_services mask swaync.service systemd-networkd-wait-online.service
}

enable_services_task() {
    print_header "Enabling Services"
    manage_services enable greetd bluetooth iwd udisks2 tailscaled systemd-resolved systemd-networkd wifi-restart
}

lock_dns_to_resolved() {
    for file in /etc/systemd/network/*.network; do
        [[ -f $file ]] || continue
        grep -q "^\[DHCPv4\]" "$file" || continue
        sed -n '/^\[DHCPv4\]/,/^\[/p' "$file" | grep -q "^UseDNS=" || sudo sed -i '/^\[DHCPv4\]/a UseDNS=no' "$file"
        grep -q "^\[IPv6AcceptRA\]" "$file" && ! sed -n '/^\[IPv6AcceptRA\]/,/^\[/p' "$file" | grep -q "^UseDNS=" \
            && sudo sed -i '/^\[IPv6AcceptRA\]/a UseDNS=no' "$file"
    done
}

unlock_dns_to_dhcp() {
    for file in /etc/systemd/network/*.network; do
        [[ -f $file ]] || continue
        sudo sed -i '/^\[DHCPv4\]/{n;/^UseDNS=no$/d}' "$file"
        sudo sed -i '/^\[IPv6AcceptRA\]/{n;/^UseDNS=no$/d}' "$file"
    done
}

configure_dns_task() {
    print_header "Configuring DNS Resolver"

    local choice
    choice=$(gum choose --height 8 --header "Select DNS provider" \
        Cloudflare Google DHCP Custom "Skip (Current)")

    case "$choice" in
        Cloudflare)
            print_step "Setting up Cloudflare DNS..."
            write_resolved_conf "[Resolve]
DNS=1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com
FallbackDNS=9.9.9.9 149.112.112.112
DNSOverTLS=opportunistic"
            lock_dns_to_resolved
            print_success "Cloudflare DNS configured"
            ;;
        Google)
            print_step "Setting up Google DNS..."
            write_resolved_conf "[Resolve]
DNS=8.8.8.8#dns.google 8.8.4.4#dns.google
FallbackDNS=9.9.9.9 149.112.112.112
DNSOverTLS=opportunistic"
            lock_dns_to_resolved
            print_success "Google DNS configured"
            ;;
        DHCP)
            print_step "Reverting to DHCP DNS..."
            write_resolved_conf "[Resolve]
DNSOverTLS=no"
            unlock_dns_to_dhcp
            print_success "DHCP DNS restored"
            ;;
        Custom)
            local servers
            servers=$(gum input --placeholder "Enter DNS servers (space-separated, e.g. 1.1.1.1 8.8.8.8)")
            [[ -z "$servers" ]] && return
            write_resolved_conf "[Resolve]
DNS=$servers
FallbackDNS=9.9.9.9 149.112.112.112"
            lock_dns_to_resolved
            print_success "Custom DNS configured"
            ;;
        *)
            print_info "Skipping DNS configuration"; return
            ;;
    esac

    print_step "Finalizing resolv.conf symlink..."
    sudo chattr -i /etc/resolv.conf 2>/dev/null
    sudo rm -f /etc/resolv.conf
    sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

    print_step "Restarting network services..."
    sudo systemctl restart systemd-networkd systemd-resolved
    print_success "DNS configuration applied"
}

install_system_configs_task() {
    print_header "Installing System Configurations"

    print_step "Configuring systemd-networkd..."
    copy_system_config "$DOTFILES_DIR/etc/systemd/network/20-wired.network" "/etc/systemd/network/20-wired.network" "systemd-networkd wired config"
    echo ""

    print_step "Configuring faster shutdown..."
    copy_system_config "$DOTFILES_DIR/etc/systemd/system.conf.d/99-timeout.conf" "/etc/systemd/system.conf.d/99-timeout.conf" "DefaultTimeoutStopSec=10s"
    echo ""

    print_step "Configuring faster user session shutdown..."
    copy_system_config "$DOTFILES_DIR/etc/systemd/user.conf.d/99-timeout.conf" "/etc/systemd/user.conf.d/99-timeout.conf" "DefaultTimeoutStopSec=5s (user)"
    echo ""

    print_step "Disabling hardware watchdog..."
    copy_system_config "$DOTFILES_DIR/etc/modprobe.d/nowatchdog.conf" "/etc/modprobe.d/nowatchdog.conf" "Blacklist iTCO_wdt"
    echo ""

    print_step "Installing greetd configuration..."
    copy_system_config "$DOTFILES_DIR/etc/greetd/config.toml" "/etc/greetd/config.toml" "greetd config" \
        && print_info "tuigreet will launch Hyprland by default"
    copy_system_config "$DOTFILES_DIR/etc/pam.d/greetd" "/etc/pam.d/greetd" "greetd PAM config"
    echo ""

    print_step "Configuring sudoers rules..."
    local hotspot_script="$HOME/.config/hypr/Scripts/Hostpot.py"
    install_sudoers_rule "/etc/sudoers.d/hyprland-hotspot" \
        "$USER ALL=(ALL) NOPASSWD: /usr/bin/python $hotspot_script toggle" \
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

    print_step "Configuring WiFi power save..."
    if [ -d /sys/class/power_supply ] && ls /sys/class/power_supply/BAT* &>/dev/null; then
        local wifi_script="$BIN_DIR/wifiPowersave"
        cat <<EOF | sudo tee /etc/udev/rules.d/99-wifi-powersave.rules >/dev/null
SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", RUN+="$wifi_script on"
SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="1", RUN+="$wifi_script off"
EOF
        sudo udevadm control --reload
        sudo udevadm trigger --subsystem-match=power_supply
        print_success "WiFi power save udev rules installed"
        print_info "Battery: power save on / AC: power save off"
    else
        print_info "No battery detected, skipping WiFi power save"
    fi
    echo ""

    print_step "Installing polkit rules..."
    copy_system_config "$DOTFILES_DIR/etc/polkit-1/rules.d/10-manage-iwd.rules" "/etc/polkit-1/rules.d/10-manage-iwd.rules" "iwd polkit rule (wheel group)"
    echo ""

    print_step "Installing WiFi restart service..."
    copy_system_config "$DOTFILES_DIR/etc/systemd/system/wifi-restart.service" "/etc/systemd/system/wifi-restart.service" "WiFi restart service"
    echo ""
}

configure_qemu_kvm_task() {
    print_header "Configuring QEMU/KVM"

    pacman -Qi libvirt &>/dev/null || { print_info "libvirt not installed, skipping"; return 0; }

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

install_gpu_drivers_task() {
    print_header "Installing GPU Drivers"

    local gpu_info=$(lspci -nn 2>/dev/null | grep -iE "vga|3d|display")
    local has_nvidia=false has_amd=false has_intel=false

    echo "$gpu_info" | grep -qi "nvidia"           && has_nvidia=true
    echo "$gpu_info" | grep -qiE "amd|radeon|ati"  && has_amd=true
    echo "$gpu_info" | grep -qi "intel"            && has_intel=true

    print_step "Detected GPU(s):"
    echo "$gpu_info" | while read -r line; do echo -e "     ${WHITE}$line${NC}"; done
    echo ""

    gum confirm "Proceed with GPU driver installation?" || { print_info "Skipping"; return 0; }
    echo ""

    if [[ "$has_nvidia" == true ]]; then
        print_step "NVIDIA GPU detected"
        local kernel=$(uname -r) is_std=false
        [[ "$kernel" == *"-arch"* && "$kernel" != *"-zen"* && "$kernel" != *"-lts"* && "$kernel" != *"-hardened"* ]] && is_std=true

        echo -e "\n  ${DIM}Detected kernel: ${WHITE}$kernel${NC}\n"

        local nvidia_choice
        if [[ "$is_std" == true ]]; then
            nvidia_choice=$(gum choose --height 8 --header "Select NVIDIA driver" \
                "nvidia-dkms       (Works with all kernels)" \
                "nvidia            (Standard - for linux kernel only)" \
                "nvidia-open-dkms  (Open source - for RTX 20+)" \
                "Skip NVIDIA driver")
        else
            print_info "Non-standard kernel, DKMS required"
            echo ""
            nvidia_choice=$(gum choose --height 6 --header "Select NVIDIA driver" \
                "nvidia-dkms       (Recommended for $kernel)" \
                "nvidia-open-dkms  (Open source - for RTX 20+)" \
                "Skip NVIDIA driver")
        fi

        local nvidia_pkgs=()
        case "$nvidia_choice" in
            nvidia-dkms*)      nvidia_pkgs=(nvidia-dkms nvidia-utils nvidia-settings lib32-nvidia-utils libva-nvidia-driver) ;;
            "nvidia "*)        nvidia_pkgs=(nvidia nvidia-utils nvidia-settings lib32-nvidia-utils libva-nvidia-driver) ;;
            nvidia-open-dkms*) nvidia_pkgs=(nvidia-open-dkms nvidia-utils nvidia-settings lib32-nvidia-utils libva-nvidia-driver) ;;
            *)                 print_info "Skipping NVIDIA driver" ;;
        esac

        if (( ${#nvidia_pkgs[@]} > 0 )); then
            echo ""
            install_pacman_packages nvidia_pkgs

            print_step "Configuring NVIDIA for Hyprland..."
            if [[ -f /etc/mkinitcpio.conf ]] && ! grep -q "nvidia" /etc/mkinitcpio.conf; then
                print_info "Adding NVIDIA modules to mkinitcpio.conf"
                if grep -q "^MODULES=()" /etc/mkinitcpio.conf; then
                    sudo sed -i 's/^MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
                else
                    sudo sed -i 's/^MODULES=(\([^)]*\))/MODULES=(\1 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
                fi
                sudo mkinitcpio -P
                print_success "mkinitcpio updated"
            fi

            echo "options nvidia_drm modeset=1 fbdev=1" | sudo tee /etc/modprobe.d/nvidia.conf >/dev/null
            print_success "NVIDIA modprobe config created"

            echo ""
            print_info "Add these to your Hyprland config:"
            for env in "LIBVA_DRIVER_NAME,nvidia" "XDG_SESSION_TYPE,wayland" "GBM_BACKEND,nvidia-drm" "__GLX_VENDOR_LIBRARY_NAME,nvidia" "NVD_BACKEND,direct"; do
                echo -e "  ${DIM}env = $env${NC}"
            done
        fi
        echo ""
    fi

    if [[ "$has_amd" == true ]]; then
        print_step "AMD GPU detected"
        echo ""
        local amd_pkgs=(lib32-mesa lib32-vulkan-radeon lib32-libva-mesa-driver lib32-mesa-vdpau xf86-video-amdgpu xf86-video-ati mesa mesa-vdpau vulkan-radeon libva-mesa-driver)

        gum style --foreground "$C_WHITE" --bold "  AMD packages to install:"
        printf "  ${DIM}  - %s${NC}\n" "${amd_pkgs[@]}"
        echo ""

        if gum confirm "Install AMD drivers?"; then
            install_pacman_packages amd_pkgs
            echo ""
            print_info "AMD uses open-source AMDGPU, no extra config needed"
            print_info "For HW video accel: env = LIBVA_DRIVER_NAME,radeonsi"
        else
            print_info "Skipping AMD driver installation"
        fi
        echo ""
    fi

    if [[ "$has_intel" == true ]]; then
        print_step "Intel GPU detected"
        echo ""
        local intel_pkgs=(mesa lib32-mesa vulkan-intel lib32-vulkan-intel intel-media-driver)

        gum style --foreground "$C_WHITE" --bold "  Intel packages to install:"
        printf "  ${DIM}  - %s${NC}\n" "${intel_pkgs[@]}"
        echo ""

        if gum confirm "Install Intel drivers?"; then
            install_pacman_packages intel_pkgs
            echo ""
            print_info "For VA-API: env = LIBVA_DRIVER_NAME,iHD"
        else
            print_info "Skipping Intel driver installation"
        fi
        echo ""
    fi

    if [[ "$has_nvidia" == false && "$has_amd" == false && "$has_intel" == false ]]; then
        print_warning "No supported GPU detected"
        print_info "Installing generic mesa drivers..."
        sudo pacman -S --noconfirm --needed mesa lib32-mesa 2>/dev/null
        print_success "Generic drivers installed"
    fi

    print_success "GPU driver setup complete"
}

configure_plymouth_task() {
    print_header "Configuring Plymouth Boot Splash"

    if ! pacman -Qi plymouth &>/dev/null; then
        print_info "Plymouth not installed, skipping"
        return 0
    fi

    print_step "Adding plymouth hook to mkinitcpio..."
    if [[ -f /etc/mkinitcpio.conf ]]; then
        if ! grep -q "plymouth" /etc/mkinitcpio.conf; then
            sudo sed -i 's/^HOOKS=(\(.*\)udev\(.*\))/HOOKS=(\1udev plymouth\2)/' /etc/mkinitcpio.conf
            print_success "Plymouth hook added after udev"
        else
            print_info "Plymouth hook already present"
        fi
    fi

    print_step "Selecting Plymouth theme..."
    local themes
    themes=$(plymouth-set-default-theme --list 2>/dev/null)
    if [[ -n "$themes" ]]; then
        local theme
        theme=$(echo "$themes" | gum choose --height 10 --header "Select boot splash theme")
        if [[ -n "$theme" ]]; then
            sudo plymouth-set-default-theme -R "$theme"
            print_success "Theme set to: $theme"
        fi
    else
        print_info "No themes found, using default"
        sudo plymouth-set-default-theme -R bgrt 2>/dev/null || sudo mkinitcpio -P
    fi

    print_step "Configuring kernel parameters..."
    local params="quiet splash loglevel=3"

    if [[ -d /boot/loader/entries ]]; then
        for entry in /boot/loader/entries/*.conf; do
            [[ -f "$entry" ]] || continue
            if ! grep -q "splash" "$entry"; then
                sudo sed -i "/^options/s/$/ $params/" "$entry"
                print_success "Updated: $(basename "$entry")"
            else
                print_info "Already configured: $(basename "$entry")"
            fi
        done
    elif [[ -f /etc/default/grub ]]; then
        if ! grep -q "splash" /etc/default/grub; then
            sudo sed -i "s/^GRUB_CMDLINE_LINUX_DEFAULT=\"\(.*\)\"/GRUB_CMDLINE_LINUX_DEFAULT=\"\1 $params\"/" /etc/default/grub
            sudo grub-mkconfig -o /boot/grub/grub.cfg
            print_success "GRUB config updated"
        else
            print_info "GRUB already configured"
        fi
    else
        print_warning "Bootloader not detected, add manually: $params"
    fi
    echo ""
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
    configure_plymouth_task
    disable_services_task
    enable_services_task
    mask_service_task
    configure_dns_task
    configure_git_task
    show_completion
}

show_completion() {
    echo ""
    gum style \
        --foreground "$C_GREEN" --border double --border-foreground "$C_GREEN" \
        --align center --width 72 --padding "1 2" \
        "" "Installation Complete!" "" \
        "Your Hyprland environment is ready." \
        "Please reboot to apply all changes." ""
    echo ""

    if gum confirm "Reboot now?" --default=false; then
        echo ""; print_info "Rebooting in 3 seconds..."; sleep 3
        systemctl reboot
    fi

    echo -e "\n  ${DIM}Run 'Hyprland' to start your new desktop!${NC}\n"
}

main_menu() {
    print_logo
    gum style --foreground "$C_DIM" "  This installer will set up your Hyprland environment."
    echo ""

    local choice
    choice=$(gum choose --height 12 --header "  Select an option" \
        "Full Installation         (GPU, Packages, Configs, Themes, Shell)" \
        "Install GPU Drivers       (AMD, NVIDIA, Intel auto-detect)" \
        "Install Packages Only     (Pacman, AUR, VSCode)" \
        "Install Dotfiles Only     (~/.config, ~/.local/bin)" \
        "Install Themes Only       (Icons, GTK Themes)" \
        "Configure Shell Only      (Zsh, Oh My Zsh)" \
        "Install VS Code Ext       (From CodeExtensions.txt)" \
        "Configure Git Globals     (user.name, user.email)" \
        "Quit")
    echo ""

    case "$choice" in
        "Full Installation"*)     full_install ;;
        "Install GPU Drivers"*)   install_gpu_drivers_task; show_completion ;;
        "Install Packages Only"*) install_packages_task; show_completion ;;
        "Install Dotfiles Only"*) install_dotfiles_task; show_completion ;;
        "Install Themes Only"*)   install_themes_task; show_completion ;;
        "Configure Shell Only"*)  configure_shell_task; show_completion ;;
        "Install VS Code Ext"*)   install_vscode_extensions_task; show_completion ;;
        "Configure Git Globals"*) configure_git_task; show_completion ;;
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
