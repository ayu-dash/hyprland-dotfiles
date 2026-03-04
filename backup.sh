#!/bin/bash

C_GREEN="82"
C_YELLOW="220"
C_BLUE="39"
C_CYAN="51"
C_WHITE="255"
C_GRAY="245"
C_DIM="240"

NC=$'\033[0m'
DIM=$'\033[2m'
GRAY=$'\033[0;90m'
RED=$'\033[0;31m'

CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.dotfiles-backup"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

CONFIGS=(hypr waybar swaync kitty rofi)

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
    gum style --foreground "$C_BLUE" --bold --align center --width 80 "B A C K U P"
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
print_error()   { gum style --foreground "$C_GREEN"  "  ✗  $1"; }
print_info()    { gum style --foreground "$C_DIM"    "  ℹ  $1"; }

backup_item() {
    local src="$1" dest="$2" name="$3"
    if [[ -e "$src" ]]; then
        cp -r "$src" "$dest"
        print_success "Backed up: $name"
        return 0
    else
        print_info "Not found: $name"
        return 1
    fi
}

prepare_backup_dir() {
    local action="$1"
    if [[ -d "$BACKUP_DIR" ]]; then
        print_info "Existing backup found at: $BACKUP_DIR"
        if [[ "$action" == "overwrite" ]]; then
            print_step "Removing existing backup..."
            rm -rf "$BACKUP_DIR"
        else
            BACKUP_DIR="$HOME/.dotfiles-backup-$TIMESTAMP"
            print_step "Creating new backup at: $BACKUP_DIR"
        fi
    fi
    mkdir -p "$BACKUP_DIR/config"
    print_success "Created backup directory"
}

backup_all_configs() {
    print_header "Backing Up All Configurations"
    local count=0
    for config in "${CONFIGS[@]}"; do
        backup_item "$CONFIG_DIR/$config" "$BACKUP_DIR/config/" "$config" && ((count++))
    done
    print_info "Backed up $count configurations"
}

backup_selected_configs() {
    print_header "Select Configurations to Backup"

    local available=()
    for config in "${CONFIGS[@]}"; do
        [[ -e "$CONFIG_DIR/$config" ]] \
            && available+=("$config (exists)") \
            || available+=("$config (not found)")
    done

    local selected
    selected=$(printf '%s\n' "${available[@]}" | gum choose --no-limit --header "Select configs to backup (space to toggle)")

    [[ -z "$selected" ]] && { print_info "Nothing selected"; return; }

    echo ""
    while IFS= read -r item; do
        local config="${item%% *}"
        backup_item "$CONFIG_DIR/$config" "$BACKUP_DIR/config/" "$config"
    done <<< "$selected"
}

backup_home_files() {
    print_header "Backing Up Home Files"
    backup_item "$HOME/.zshrc" "$BACKUP_DIR/" ".zshrc"
    backup_item "$HOME/.gtkrc-2.0" "$BACKUP_DIR/" ".gtkrc-2.0"
}

create_manifest() {
    print_header "Creating Manifest"
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
    print_header "Existing Backups"
    local found=0

    for backup in "$HOME"/.dotfiles-backup*; do
        [[ -d "$backup" ]] || continue
        local size=$(du -sh "$backup" 2>/dev/null | cut -f1)
        local date=""
        [[ -f "$backup/manifest.txt" ]] && date=$(grep "Created:" "$backup/manifest.txt" | cut -d: -f2-)

        gum style --foreground "$C_CYAN" "  → $(basename "$backup") ($size)"
        [[ -n "$date" ]] && echo -e "    ${GRAY}Created:$date${NC}"
        echo ""
        ((found++))
    done

    (( found == 0 )) && print_info "No backups found"

    echo ""
    gum input --placeholder "Press Enter to continue..." >/dev/null
}

full_backup() {
    echo ""
    if gum confirm "Overwrite existing backup if found?" --default=false; then
        prepare_backup_dir "overwrite"
    else
        prepare_backup_dir "new"
    fi

    backup_all_configs
    backup_home_files
    create_manifest
}

show_completion() {
    local size=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)
    echo ""
    gum style \
        --foreground "$C_GREEN" --border double --border-foreground "$C_GREEN" \
        --align center --width 72 --padding "1 2" \
        "" "Backup Complete!" ""
    echo ""
    gum style --foreground "$C_CYAN" "  Location: $BACKUP_DIR"
    gum style --foreground "$C_CYAN" "  Size:     $size"
    echo ""
    print_info "Run ./install.sh to install new dotfiles"
    echo ""
}

main_menu() {
    clear
    print_logo

    gum style --foreground "$C_DIM" "  This will backup your current Hyprland configurations."
    echo ""

    local choice
    choice=$(gum choose --height 10 --header "  Select an option" \
        "Full Backup               (All configs + home files)" \
        "Select Configs to Backup  (Choose specific configs)" \
        "Backup Home Files Only    (.zshrc, .gtkrc-2.0)" \
        "View Existing Backups     (List all backup folders)" \
        "Quit")
    echo ""

    case "$choice" in
        "Full Backup"*)              full_backup; show_completion ;;
        "Select Configs to Backup"*) prepare_backup_dir "new"; backup_selected_configs; create_manifest; show_completion ;;
        "Backup Home Files Only"*)   prepare_backup_dir "new"; backup_home_files; create_manifest; show_completion ;;
        "View Existing Backups"*)    view_existing_backups; main_menu ;;
        "Quit"|"")                   gum style --foreground "$C_DIM" "  Bye!"; exit 0 ;;
        *)                           print_error "Invalid choice!"; sleep 1; main_menu ;;
    esac
}

[[ $EUID -eq 0 ]] && { echo -e "${RED}Error: Do not run as root!${NC}"; exit 1; }

main_menu
