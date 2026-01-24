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

# ── Uninstall Functions ─────────────────────────────────────────────────────

remove_all_configs() {
    print_header "🗂️  Removing All Configurations"
    
    for config in "${CONFIGS[@]}"; do
        config_path="$CONFIG_DIR/$config"
        if [ -d "$config_path" ] || [ -f "$config_path" ]; then
            rm -rf "$config_path"
            print_success "Removed: $config"
        else
            print_info "Not found: $config"
        fi
    done
}

remove_selected_configs() {
    print_header "🗂️  Select Configurations to Remove"
    
    echo -e "  ${DIM}Available configurations:${NC}"
    echo ""
    
    local i=1
    for config in "${CONFIGS[@]}"; do
        config_path="$CONFIG_DIR/$config"
        if [ -d "$config_path" ] || [ -f "$config_path" ]; then
            echo -e "  ${CYAN}$i)${NC} $config ${GREEN}(installed)${NC}"
        else
            echo -e "  ${CYAN}$i)${NC} $config ${GRAY}(not found)${NC}"
        fi
        ((i++))
    done
    
    echo ""
    echo -e "  ${CYAN}0)${NC} Back to menu"
    echo ""
    
    echo -ne "  ${YELLOW}?${NC}  Enter numbers to remove (space separated, e.g. '1 3 5'): "
    read -r selections
    echo ""
    
    if [[ "$selections" == "0" ]]; then
        return
    fi
    
    for sel in $selections; do
        if [[ "$sel" =~ ^[0-9]+$ ]] && [ "$sel" -ge 1 ] && [ "$sel" -le "${#CONFIGS[@]}" ]; then
            config="${CONFIGS[$((sel-1))]}"
            config_path="$CONFIG_DIR/$config"
            if [ -d "$config_path" ] || [ -f "$config_path" ]; then
                rm -rf "$config_path"
                print_success "Removed: $config"
            else
                print_info "Not found: $config"
            fi
        fi
    done
}

remove_scripts() {
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
}

remove_shell_config() {
    print_header "🐚 Removing Shell Config"
    
    if [ -f "$HOME/.zshrc" ]; then
        choice=$(confirm_prompt "Remove .zshrc? [y/N]" "n")
        if [[ "$choice" == "y" || "$choice" == "yes" ]]; then
            rm -f "$HOME/.zshrc"
            print_success "Removed: .zshrc"
        else
            print_info "Skipped: .zshrc"
        fi
    else
        print_info ".zshrc not found"
    fi
}

restore_backup() {
    if [ -d "$BACKUP_DIR" ]; then
        print_header "📦 Restoring from Backup"
        
        echo -e "  ${CYAN}Backup location:${NC} $BACKUP_DIR"
        echo ""
        
        # Restore configs
        if [ -d "$BACKUP_DIR/config" ]; then
            echo -e "  ${GRAY}Restoring config files...${NC}"
            cp -r "$BACKUP_DIR/config/"* "$CONFIG_DIR/" 2>/dev/null
            print_success "Restored config files"
        fi
        
        # Restore zshrc
        if [ -f "$BACKUP_DIR/.zshrc" ]; then
            cp "$BACKUP_DIR/.zshrc" "$HOME/"
            print_success "Restored .zshrc"
        fi
        
        print_success "Backup restored!"
    else
        print_header "📦 Backup"
        print_info "No backup found at: $BACKUP_DIR"
    fi
}

full_uninstall() {
    print_warning "This will remove ALL configurations!"
    echo ""
    choice=$(confirm_prompt "Are you sure? [y/N]" "n")
    
    if [[ "$choice" != "y" && "$choice" != "yes" ]]; then
        print_info "Cancelled."
        return
    fi
    
    remove_all_configs
    remove_scripts
    remove_shell_config
}

show_completion() {
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
}

# ── Main Menu ───────────────────────────────────────────────────────────────

main_menu() {
    clear
    print_logo
    
    echo -e "  ${DIM}This will remove Hyprland dotfiles configurations.${NC}"
    echo ""
    print_warning "This action cannot be undone unless you have a backup!"
    echo ""
    
    echo -e "  ${BOLD}Select an option:${NC}"
    echo ""
    echo -e "  ${RED}1)${NC} Full Uninstall          ${DIM}(Remove all configs, scripts, shell)${NC}"
    echo -e "  ${YELLOW}2)${NC} Remove All Configs      ${DIM}(hypr, waybar, swaync, kitty, rofi)${NC}"
    echo -e "  ${YELLOW}3)${NC} Remove Selected Configs ${DIM}(Choose specific configs to remove)${NC}"
    echo -e "  ${YELLOW}4)${NC} Remove Scripts Only     ${DIM}(~/.local/bin scripts)${NC}"
    echo -e "  ${YELLOW}5)${NC} Remove Shell Config     ${DIM}(.zshrc)${NC}"
    echo -e "  ${GREEN}6)${NC} Restore from Backup     ${DIM}(Restore previous configs)${NC}"
    echo -e "  ${CYAN}0)${NC} Quit"
    echo ""
    
    echo -ne "  ${YELLOW}?${NC}  Enter choice [0-6]: "
    read choice
    echo ""
    
    case $choice in
        1) full_uninstall; show_completion ;;
        2) remove_all_configs; show_completion ;;
        3) remove_selected_configs ;;
        4) remove_scripts; show_completion ;;
        5) remove_shell_config; show_completion ;;
        6) restore_backup ;;
        0) echo -e "  ${DIM}Bye!${NC}"; exit 0 ;;
        *) echo -e "  ${RED}Invalid choice!${NC}"; sleep 1; main_menu ;;
    esac
}

# ── Entry Point ─────────────────────────────────────────────────────────────

if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}Error: Do not run as root!${NC}"
    exit 1
fi

main_menu
