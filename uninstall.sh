#!/bin/bash

C_RED="196"
C_GREEN="82"
C_YELLOW="220"
C_BLUE="39"
C_CYAN="51"
C_WHITE="255"
C_GRAY="245"
C_DIM="240"

NC=$'\033[0m'
DIM=$'\033[2m'
RED=$'\033[0;31m'

CONFIG_DIR="$HOME/.config"
THEMES_DIR="$HOME/.themes"
ICONS_DIR="$HOME/.icons"
BIN_DIR="$HOME/.local/bin"
BACKUP_DIR="$HOME/.dotfiles-backup"

CONFIGS=(hypr waybar swaync kitty rofi)
BIN_SCRIPTS=(remoteWin10 wifiPowersave)

print_logo() {
    echo ""
    gum style \
        --foreground "$C_RED" --border double --border-foreground "$C_RED" \
        --align center --width 80 --padding "1 2" \
        "██╗  ██╗██╗   ██╗██████╗ ██████╗ ██╗      █████╗ ███╗   ██╗██████╗ " \
        "██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗██║     ██╔══██╗████╗  ██║██╔══██╗" \
        "███████║ ╚████╔╝ ██████╔╝██████╔╝██║     ███████║██╔██╗ ██║██║  ██║" \
        "██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══██╗██║     ██╔══██║██║╚██╗██║██║  ██║" \
        "██║  ██║   ██║   ██║     ██║  ██║███████╗██║  ██║██║ ╚████║██████╔╝" \
        "╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝"
    echo ""
    gum style --foreground "$C_RED" --bold --align center --width 80 "U N I N S T A L L"
    gum style --foreground "$C_GRAY" --align center --width 80 "by ayudash"
    echo ""
}

print_header() {
    echo ""
    gum style --foreground "$C_WHITE" --bold --border rounded \
        --border-foreground "$C_RED" --padding "0 2" --width 72 "$1"
    echo ""
}

print_success() { gum style --foreground "$C_GREEN"  "  ✓  $1"; }
print_error()   { gum style --foreground "$C_RED"    "  ✗  $1"; }
print_warning() { gum style --foreground "$C_YELLOW" "  ⚠  $1"; }
print_info()    { gum style --foreground "$C_DIM"    "  ℹ  $1"; }

remove_path() {
    local path="$1" name="$2"
    if [[ -e "$path" ]]; then
        rm -rf "$path"
        print_success "Removed: $name"
    else
        print_info "Not found: $name"
    fi
}

remove_all_configs() {
    print_header "Removing All Configurations"
    for config in "${CONFIGS[@]}"; do
        remove_path "$CONFIG_DIR/$config" "$config"
    done
}

remove_selected_configs() {
    print_header "Select Configurations to Remove"

    local available=()
    for config in "${CONFIGS[@]}"; do
        if [[ -e "$CONFIG_DIR/$config" ]]; then
            available+=("$config (installed)")
        else
            available+=("$config (not found)")
        fi
    done

    local selected
    selected=$(printf '%s\n' "${available[@]}" | gum choose --no-limit --header "Select configs to remove (space to toggle)")

    [[ -z "$selected" ]] && { print_info "Nothing selected"; return; }

    echo ""
    while IFS= read -r item; do
        local config="${item%% *}"
        remove_path "$CONFIG_DIR/$config" "$config"
    done <<< "$selected"
}

remove_scripts() {
    print_header "Removing Scripts"
    for script in "${BIN_SCRIPTS[@]}"; do
        remove_path "$BIN_DIR/$script" "$script"
    done
}

remove_shell_config() {
    print_header "Removing Shell Config"
    if [[ -f "$HOME/.zshrc" ]]; then
        if gum confirm "Remove .zshrc?" --default=false; then
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
    if [[ -d "$BACKUP_DIR" ]]; then
        print_header "Restoring from Backup"
        gum style --foreground "$C_CYAN" "  Backup location: $BACKUP_DIR"
        echo ""

        if [[ -d "$BACKUP_DIR/config" ]]; then
            cp -r "$BACKUP_DIR/config/"* "$CONFIG_DIR/" 2>/dev/null
            print_success "Restored config files"
        fi

        if [[ -f "$BACKUP_DIR/.zshrc" ]]; then
            cp "$BACKUP_DIR/.zshrc" "$HOME/"
            print_success "Restored .zshrc"
        fi

        print_success "Backup restored!"
    else
        print_header "Backup"
        print_info "No backup found at: $BACKUP_DIR"
    fi
}

full_uninstall() {
    print_warning "This will remove ALL configurations!"
    echo ""
    gum confirm "Are you sure?" --default=false || { print_info "Cancelled."; return; }

    remove_all_configs
    remove_scripts
    remove_shell_config
}

show_completion() {
    echo ""
    gum style \
        --foreground "$C_GREEN" --border double --border-foreground "$C_GREEN" \
        --align center --width 72 --padding "1 2" \
        "" "Uninstall Complete!" ""
    echo ""
    print_info "You may need to log out and back in for all changes to take effect."
    echo ""
}

main_menu() {
    clear
    print_logo

    gum style --foreground "$C_DIM" "  This will remove Hyprland dotfiles configurations."
    echo ""
    print_warning "This action cannot be undone unless you have a backup!"
    echo ""

    local choice
    choice=$(gum choose --height 10 --header "  Select an option" \
        "Full Uninstall            (Remove all configs, scripts, shell)" \
        "Remove All Configs        (hypr, waybar, swaync, kitty, rofi)" \
        "Remove Selected Configs   (Choose specific configs)" \
        "Remove Scripts Only       (~/.local/bin scripts)" \
        "Remove Shell Config       (.zshrc)" \
        "Restore from Backup       (Restore previous configs)" \
        "Quit")
    echo ""

    case "$choice" in
        "Full Uninstall"*)          full_uninstall; show_completion ;;
        "Remove All Configs"*)      remove_all_configs; show_completion ;;
        "Remove Selected Configs"*) remove_selected_configs ;;
        "Remove Scripts Only"*)     remove_scripts; show_completion ;;
        "Remove Shell Config"*)     remove_shell_config; show_completion ;;
        "Restore from Backup"*)     restore_backup ;;
        "Quit"|"")                  gum style --foreground "$C_DIM" "  Bye!"; exit 0 ;;
        *)                          print_error "Invalid choice!"; sleep 1; main_menu ;;
    esac
}

[[ $EUID -eq 0 ]] && { echo -e "${RED}Error: Do not run as root!${NC}"; exit 1; }

main_menu
