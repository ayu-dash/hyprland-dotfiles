#!/bin/bash

# =============================================================================
# Hyprland Dotfiles Backup Script
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
BACKUP_DIR="$HOME/.dotfiles-backup"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Configs to backup
CONFIGS=(
    "hypr"
    "waybar"
    "swaync"
    "kitty"
    "rofi"
)

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

print_success() {
    echo -e "  ${GREEN}✓${NC}  $1"
}

print_error() {
    echo -e "  ${RED}✗${NC}  $1"
}

print_info() {
    echo -e "  ${GRAY}ℹ${NC}  ${DIM}$1${NC}"
}

print_step() {
    echo -e "  ${CYAN}▶${NC}  ${WHITE}$1${NC}"
}

confirm_prompt() {
    local message="$1"
    local default="$2"
    echo -ne "  ${YELLOW}?${NC}  $message "
    read choice
    choice=${choice:-$default}
    echo "$choice" | tr '[:upper:]' '[:lower:]'
}

# ── Backup Functions ────────────────────────────────────────────────────────

prepare_backup_dir() {
    local action="$1"
    
    if [ -d "$BACKUP_DIR" ]; then
        print_info "Existing backup found at: $BACKUP_DIR"
        echo ""
        
        if [[ "$action" == "overwrite" ]]; then
            print_step "Removing existing backup..."
            rm -rf "$BACKUP_DIR"
        else
            # Create timestamped backup instead
            BACKUP_DIR="$HOME/.dotfiles-backup-$TIMESTAMP"
            echo ""
            print_step "Creating new backup at: $BACKUP_DIR"
        fi
    fi
    
    mkdir -p "$BACKUP_DIR/config"
    print_success "Created backup directory"
}

backup_all_configs() {
    print_header "🗂️  Backing Up All Configurations"
    
    local count=0
    
    for config in "${CONFIGS[@]}"; do
        config_path="$CONFIG_DIR/$config"
        if [ -d "$config_path" ]; then
            echo -e "  ${GRAY}  Copying: $config${NC}"
            cp -r "$config_path" "$BACKUP_DIR/config/"
            print_success "Backed up: $config"
            ((count++))
        elif [ -f "$config_path" ]; then
            echo -e "  ${GRAY}  Copying: $config${NC}"
            cp "$config_path" "$BACKUP_DIR/config/"
            print_success "Backed up: $config"
            ((count++))
        else
            print_info "Not found: $config"
        fi
    done
    
    print_info "Backed up $count configurations"
}

backup_selected_configs() {
    print_header "🗂️  Select Configurations to Backup"
    
    echo -e "  ${DIM}Available configurations:${NC}"
    echo ""
    
    local i=1
    for config in "${CONFIGS[@]}"; do
        config_path="$CONFIG_DIR/$config"
        if [ -d "$config_path" ] || [ -f "$config_path" ]; then
            echo -e "  ${CYAN}$i)${NC} $config ${GREEN}(exists)${NC}"
        else
            echo -e "  ${CYAN}$i)${NC} $config ${GRAY}(not found)${NC}"
        fi
        ((i++))
    done
    
    echo ""
    echo -e "  ${CYAN}0)${NC} Back to menu"
    echo ""
    
    echo -ne "  ${YELLOW}?${NC}  Enter numbers to backup (space separated, e.g. '1 3 5'): "
    read -r selections
    echo ""
    
    if [[ "$selections" == "0" ]]; then
        return
    fi
    
    for sel in $selections; do
        if [[ "$sel" =~ ^[0-9]+$ ]] && [ "$sel" -ge 1 ] && [ "$sel" -le "${#CONFIGS[@]}" ]; then
            config="${CONFIGS[$((sel-1))]}"
            config_path="$CONFIG_DIR/$config"
            if [ -d "$config_path" ]; then
                echo -e "  ${GRAY}  Copying: $config${NC}"
                cp -r "$config_path" "$BACKUP_DIR/config/"
                print_success "Backed up: $config"
            elif [ -f "$config_path" ]; then
                echo -e "  ${GRAY}  Copying: $config${NC}"
                cp "$config_path" "$BACKUP_DIR/config/"
                print_success "Backed up: $config"
            else
                print_info "Not found: $config"
            fi
        fi
    done
}

backup_home_files() {
    print_header "🏠 Backing Up Home Files"
    
    # .zshrc
    if [ -f "$HOME/.zshrc" ]; then
        echo -e "  ${GRAY}  Copying: .zshrc${NC}"
        cp "$HOME/.zshrc" "$BACKUP_DIR/"
        print_success "Backed up: .zshrc"
    else
        print_info ".zshrc not found"
    fi
    
    # .gtkrc-2.0
    if [ -f "$HOME/.gtkrc-2.0" ]; then
        echo -e "  ${GRAY}  Copying: .gtkrc-2.0${NC}"
        cp "$HOME/.gtkrc-2.0" "$BACKUP_DIR/"
        print_success "Backed up: .gtkrc-2.0"
    else
        print_info ".gtkrc-2.0 not found"
    fi
}

create_manifest() {
    print_header "📋 Creating Manifest"
    
    cat > "$BACKUP_DIR/manifest.txt" << EOF
Hyprland Dotfiles Backup
========================
Created: $(date)
User: $USER
Host: $(hostname)

Backed up configs:
$(ls -la "$BACKUP_DIR/config/" 2>/dev/null)

Home files:
$(ls -la "$BACKUP_DIR"/*.* 2>/dev/null | grep -v manifest)
EOF
    
    print_success "Created manifest.txt"
}

view_existing_backups() {
    print_header "📦 Existing Backups"
    
    local found=0
    
    for backup in "$HOME"/.dotfiles-backup*; do
        if [ -d "$backup" ]; then
            local size=$(du -sh "$backup" 2>/dev/null | cut -f1)
            local date=""
            if [ -f "$backup/manifest.txt" ]; then
                date=$(grep "Created:" "$backup/manifest.txt" | cut -d: -f2-)
            fi
            echo -e "  ${CYAN}→${NC} $(basename "$backup") ${DIM}($size)${NC}"
            [ -n "$date" ] && echo -e "    ${GRAY}Created:$date${NC}"
            echo ""
            ((found++))
        fi
    done
    
    if [ "$found" -eq 0 ]; then
        print_info "No backups found"
    fi
    
    echo ""
    echo -ne "  ${YELLOW}?${NC}  Press Enter to continue..."
    read
}

full_backup() {
    echo ""
    choice=$(confirm_prompt "Overwrite existing backup if found? [y/N]" "n")
    
    if [[ "$choice" == "y" || "$choice" == "yes" ]]; then
        prepare_backup_dir "overwrite"
    else
        prepare_backup_dir "new"
    fi
    
    backup_all_configs
    backup_home_files
    create_manifest
}

show_completion() {
    BACKUP_SIZE=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)
    
    echo ""
    echo -e "${GREEN}"
    cat << 'EOF'
    ╭──────────────────────────────────────────────────────────────╮
    │                                                              │
    │   ✓  Backup Complete!                                        │
    │                                                              │
    ╰──────────────────────────────────────────────────────────────╯
EOF
    echo -e "${NC}"
    
    echo -e "  ${CYAN}Location:${NC} $BACKUP_DIR"
    echo -e "  ${CYAN}Size:${NC}     $BACKUP_SIZE"
    echo ""
    print_info "Run ./install.sh to install new dotfiles"
    echo ""
}

# ── Main Menu ───────────────────────────────────────────────────────────────

main_menu() {
    clear
    print_logo
    
    echo -e "  ${DIM}This will backup your current Hyprland configurations.${NC}"
    echo ""
    
    echo -e "  ${BOLD}Select an option:${NC}"
    echo ""
    echo -e "  ${GREEN}1)${NC} Full Backup              ${DIM}(All configs + home files)${NC}"
    echo -e "  ${YELLOW}2)${NC} Select Configs to Backup ${DIM}(Choose specific configs)${NC}"
    echo -e "  ${YELLOW}3)${NC} Backup Home Files Only   ${DIM}(.zshrc, .gtkrc-2.0)${NC}"
    echo -e "  ${CYAN}4)${NC} View Existing Backups    ${DIM}(List all backup folders)${NC}"
    echo -e "  ${RED}0)${NC} Quit"
    echo ""
    
    echo -ne "  ${YELLOW}?${NC}  Enter choice [0-4]: "
    read choice
    echo ""
    
    case $choice in
        1) full_backup; show_completion ;;
        2) 
            prepare_backup_dir "new"
            backup_selected_configs
            create_manifest
            show_completion
            ;;
        3)
            prepare_backup_dir "new"
            backup_home_files
            create_manifest
            show_completion
            ;;
        4) view_existing_backups; main_menu ;;
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
