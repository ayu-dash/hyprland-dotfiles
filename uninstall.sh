#!/bin/bash

# =============================================================================
# Hyprland Dotfiles Uninstaller
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

CONFIG_DIR="$HOME/.config"
THEMES_DIR="$HOME/.themes"
ICONS_DIR="$HOME/.icons"
BIN_DIR="$HOME/.local/bin"
BACKUP_DIR="$HOME/.dotfiles-backup"

# Configs to remove
CONFIGS=(
    "hypr"
    "waybar"
    "swaync"
    "kitty"
    "rofi"
)

# Bin scripts to remove
BIN_SCRIPTS=(
    "remoteWin10"
)

# ── Helper Functions ────────────────────────────────────────────────────────

print_logo() {
    echo -e "${RED}"
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
    echo -e "${WHITE}                    │      ${RED}U N I N S T A L L${WHITE}        │${NC}"
    echo -e "${WHITE}                    │         ${GRAY}by ${CYAN}ayudash${WHITE}           │${NC}"
    echo -e "${WHITE}                    ╰───────────────────────────────╯${NC}"
    echo ""
}

print_header() {
    echo ""
    echo -e "${RED}╭──────────────────────────────────────────────────────────────╮${NC}"
    echo -e "${RED}│${NC}  ${BOLD}${WHITE}$1${NC}"
    echo -e "${RED}╰──────────────────────────────────────────────────────────────╯${NC}"
    echo ""
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

confirm_prompt() {
    local message="$1"
    local default="$2"
    echo -ne "  ${YELLOW}?${NC}  $message "
    read choice
    choice=${choice:-$default}
    echo "$choice" | tr '[:upper:]' '[:lower:]'
}

# ── Main ────────────────────────────────────────────────────────────────────

clear
print_logo

echo -e "  ${DIM}This will remove Hyprland dotfiles configurations.${NC}"
echo ""
print_warning "This action cannot be undone unless you have a backup!"
echo ""

choice=$(confirm_prompt "Are you sure you want to uninstall? [y/N]" "n")

if [[ "$choice" != "y" && "$choice" != "yes" ]]; then
    echo ""
    print_info "Uninstall cancelled."
    echo ""
    exit 0
fi

# ── Remove Configurations ───────────────────────────────────────────────────

print_header "🗂️  Removing Configurations"

for config in "${CONFIGS[@]}"; do
    config_path="$CONFIG_DIR/$config"
    if [ -d "$config_path" ] || [ -f "$config_path" ]; then
        rm -rf "$config_path"
        print_success "Removed: $config"
    else
        print_info "Not found: $config"
    fi
done

# ── Remove Bin Scripts ──────────────────────────────────────────────────────

print_header "📜 Removing Scripts"

for script in "${BIN_SCRIPTS[@]}"; do
    script_path="$BIN_DIR/$script"
    if [ -f "$script_path" ]; then
        rm -f "$script_path"
        print_success "Removed: $script"
    else
        print_info "Not found: $script"
    fi
done

# ── Remove Zsh Config ───────────────────────────────────────────────────────

print_header "🐚 Removing Shell Config"

if [ -f "$HOME/.zshrc" ]; then
    choice=$(confirm_prompt "Remove .zshrc? [y/N]" "n")
    if [[ "$choice" == "y" || "$choice" == "yes" ]]; then
        rm -f "$HOME/.zshrc"
        print_success "Removed: .zshrc"
    else
        print_info "Skipped: .zshrc"
    fi
fi

# ── Restore Backup ──────────────────────────────────────────────────────────

if [ -d "$BACKUP_DIR" ]; then
    print_header "📦 Backup Found"
    
    echo -e "  ${CYAN}Backup location:${NC} $BACKUP_DIR"
    echo ""
    
    choice=$(confirm_prompt "Restore from backup? [y/N]" "n")
    
    if [[ "$choice" == "y" || "$choice" == "yes" ]]; then
        # Restore configs
        if [ -d "$BACKUP_DIR/config" ]; then
            cp -r "$BACKUP_DIR/config/"* "$CONFIG_DIR/" 2>/dev/null
            print_success "Restored config files"
        fi
        
        # Restore zshrc
        if [ -f "$BACKUP_DIR/.zshrc" ]; then
            cp "$BACKUP_DIR/.zshrc" "$HOME/"
            print_success "Restored .zshrc"
        fi
        
        print_success "Backup restored!"
    fi
fi

# ── Completion ──────────────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}"
cat << 'EOF'
    ╭──────────────────────────────────────────────────────────────╮
    │                                                              │
    │   ✓  Uninstall Complete!                                     │
    │                                                              │
    ╰──────────────────────────────────────────────────────────────╯
EOF
echo -e "${NC}"

print_info "You may need to log out and back in for all changes to take effect."
echo ""
