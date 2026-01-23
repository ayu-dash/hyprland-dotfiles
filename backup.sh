#!/bin/bash

# =============================================================================
# Hyprland Dotfiles Backup Script
# =============================================================================

# ── Colors ──────────────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
BOLD='\033[1m'
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
    echo -e "  ${GRAY}ℹ${NC}  $1"
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

echo ""
echo -e "${CYAN}"
cat << 'EOF'
    ╭──────────────────────────────────────────────────────────────╮
    │                                                              │
    │   💾 Hyprland Dotfiles Backup                                │
    │                                                              │
    ╰──────────────────────────────────────────────────────────────╯
EOF
echo -e "${NC}"

# Check if backup exists
if [ -d "$BACKUP_DIR" ]; then
    print_info "Existing backup found at: $BACKUP_DIR"
    echo ""
    choice=$(confirm_prompt "Overwrite existing backup? [y/N]" "n")
    
    if [[ "$choice" != "y" ]]; then
        # Create timestamped backup instead
        BACKUP_DIR="$HOME/.dotfiles-backup-$TIMESTAMP"
        print_info "Creating new backup at: $BACKUP_DIR"
    else
        rm -rf "$BACKUP_DIR"
    fi
fi

echo ""

# ── Create Backup Directory ─────────────────────────────────────────────────

print_header "📦 Creating Backup"

mkdir -p "$BACKUP_DIR/config"
print_success "Created backup directory"

# ── Backup Configs ──────────────────────────────────────────────────────────

for config in "${CONFIGS[@]}"; do
    config_path="$CONFIG_DIR/$config"
    if [ -d "$config_path" ]; then
        cp -r "$config_path" "$BACKUP_DIR/config/"
        print_success "Backed up: $config"
    elif [ -f "$config_path" ]; then
        cp "$config_path" "$BACKUP_DIR/config/"
        print_success "Backed up: $config"
    else
        print_info "Not found: $config"
    fi
done

# ── Backup Home Files ───────────────────────────────────────────────────────

print_header "🏠 Backing Up Home Files"

# .zshrc
if [ -f "$HOME/.zshrc" ]; then
    cp "$HOME/.zshrc" "$BACKUP_DIR/"
    print_success "Backed up: .zshrc"
fi

# .gtkrc-2.0
if [ -f "$HOME/.gtkrc-2.0" ]; then
    cp "$HOME/.gtkrc-2.0" "$BACKUP_DIR/"
    print_success "Backed up: .gtkrc-2.0"
fi

# ── Create Manifest ─────────────────────────────────────────────────────────

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

# ── Calculate Size ──────────────────────────────────────────────────────────

BACKUP_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)

# ── Completion ──────────────────────────────────────────────────────────────

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
