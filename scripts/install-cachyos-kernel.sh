#!/bin/bash
# ============================================================
# CachyOS Kernel Installer with BORE Scheduler
# Installs optimized kernel for gaming and desktop performance
# ============================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
DIM='\033[2m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     CachyOS Kernel Installer (BORE Scheduler)             ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}[ERROR]${NC} Do not run this script as root!"
    echo "Run as normal user, sudo will be used when needed."
    exit 1
fi

# Check architecture support
check_cpu_support() {
    echo -e "${YELLOW}[1/6]${NC} Checking CPU architecture support..."
    
    # Check for x86-64-v3 support
    if grep -q "avx2" /proc/cpuinfo && grep -q "bmi2" /proc/cpuinfo; then
        CPU_LEVEL="v3"
        echo -e "${GREEN}[INFO]${NC} CPU supports x86-64-v3 (AVX2, BMI2)"
    else
        CPU_LEVEL="generic"
        echo -e "${YELLOW}[INFO]${NC} CPU uses generic x86-64"
    fi
    
    # Check for x86-64-v4 support (AVX-512)
    if grep -q "avx512" /proc/cpuinfo; then
        CPU_LEVEL="v4"
        echo -e "${GREEN}[INFO]${NC} CPU supports x86-64-v4 (AVX-512)"
    fi
}

# Import CachyOS keys
import_keys() {
    echo -e "\n${YELLOW}[2/6]${NC} Importing CachyOS GPG keys..."
    
    if sudo pacman-key --list-keys F3B607488DB35A47 &>/dev/null; then
        echo -e "${GREEN}[INFO]${NC} Keys already imported"
    else
        sudo pacman-key --recv-keys F3B607488DB35A47 --keyserver keyserver.ubuntu.com
        sudo pacman-key --lsign-key F3B607488DB35A47
        echo -e "${GREEN}[OK]${NC} Keys imported successfully"
    fi
}

# Install CachyOS packages
install_cachyos_packages() {
    echo -e "\n${YELLOW}[3/6]${NC} Installing CachyOS keyring and mirrorlist..."
    
    local BASE_URL="https://mirror.cachyos.org/repo/x86_64/cachyos"
    
    # Fetch latest package versions dynamically
    echo -e "${CYAN}[INFO]${NC} Fetching latest package versions..."
    
    local KEYRING=$(curl -s "$BASE_URL/" | grep -oP 'cachyos-keyring-[^"]+\.pkg\.tar\.zst' | sort -V | tail -1)
    local MIRROR=$(curl -s "$BASE_URL/" | grep -oP 'cachyos-mirrorlist-[0-9]+-[0-9]+-any\.pkg\.tar\.zst' | sort -V | tail -1)
    local MIRROR_V3=$(curl -s "$BASE_URL/" | grep -oP 'cachyos-v3-mirrorlist-[0-9]+-[0-9]+-any\.pkg\.tar\.zst' | sort -V | tail -1)
    local MIRROR_V4=$(curl -s "$BASE_URL/" | grep -oP 'cachyos-v4-mirrorlist-[0-9]+-[0-9]+-any\.pkg\.tar\.zst' | sort -V | tail -1)
    
    if [[ -z "$KEYRING" ]] || [[ -z "$MIRROR" ]]; then
        echo -e "${RED}[ERROR]${NC} Failed to fetch package versions!"
        return 1
    fi
    
    echo -e "${DIM}  keyring: $KEYRING${NC}"
    echo -e "${DIM}  mirrorlist: $MIRROR${NC}"
    echo -e "${DIM}  v3-mirrorlist: $MIRROR_V3${NC}"
    echo -e "${DIM}  v4-mirrorlist: $MIRROR_V4${NC}"
    
    local URLS="$BASE_URL/$KEYRING $BASE_URL/$MIRROR"
    [[ -n "$MIRROR_V3" ]] && URLS="$URLS $BASE_URL/$MIRROR_V3"
    [[ -n "$MIRROR_V4" ]] && URLS="$URLS $BASE_URL/$MIRROR_V4"
    
    sudo pacman -U --noconfirm $URLS 2>/dev/null || {
        echo -e "${YELLOW}[WARN]${NC} Some packages may already be installed"
    }
    
    echo -e "${GREEN}[OK]${NC} CachyOS packages installed"
}

# Configure pacman.conf
configure_pacman() {
    echo -e "\n${YELLOW}[4/6]${NC} Configuring pacman.conf..."
    
    if grep -q "\[cachyos\]" /etc/pacman.conf; then
        echo -e "${GREEN}[INFO]${NC} CachyOS repository already configured"
    else
        echo -e "${CYAN}[INFO]${NC} Adding CachyOS repository to pacman.conf..."
        
        # Add repository based on CPU level
        case $CPU_LEVEL in
            v4)
                echo -e "\n# CachyOS Repositories\n[cachyos-v4]\nInclude = /etc/pacman.d/cachyos-v4-mirrorlist\n\n[cachyos-v3]\nInclude = /etc/pacman.d/cachyos-v3-mirrorlist\n\n[cachyos]\nInclude = /etc/pacman.d/cachyos-mirrorlist" | sudo tee -a /etc/pacman.conf > /dev/null
                ;;
            v3)
                echo -e "\n# CachyOS Repositories\n[cachyos-v3]\nInclude = /etc/pacman.d/cachyos-v3-mirrorlist\n\n[cachyos]\nInclude = /etc/pacman.d/cachyos-mirrorlist" | sudo tee -a /etc/pacman.conf > /dev/null
                ;;
            *)
                echo -e "\n# CachyOS Repository\n[cachyos]\nInclude = /etc/pacman.d/cachyos-mirrorlist" | sudo tee -a /etc/pacman.conf > /dev/null
                ;;
        esac
        
        echo -e "${GREEN}[OK]${NC} Repository added"
    fi
    
    # Sync database
    echo -e "${CYAN}[INFO]${NC} Syncing package database..."
    sudo pacman -Sy
}

# Select and install kernel
install_kernel() {
    echo -e "\n${YELLOW}[5/6]${NC} Selecting kernel to install..."
    echo ""
    echo -e "  ${WHITE}Available CachyOS Kernels:${NC}"
    echo ""
    echo -e "  ${CYAN}1)${NC} linux-cachyos          ${DIM}(Latest stable with BORE)${NC}"
    echo -e "  ${CYAN}2)${NC} linux-cachyos-lts      ${DIM}(Long Term Support with BORE)${NC}"
    echo -e "  ${CYAN}3)${NC} linux-cachyos-bore     ${DIM}(BORE only, no extra patches)${NC}"
    echo -e "  ${CYAN}4)${NC} linux-cachyos-eevdf    ${DIM}(EEVDF scheduler)${NC}"
    echo -e "  ${CYAN}5)${NC} linux-cachyos-sched-ext ${DIM}(sched-ext for custom schedulers)${NC}"
    echo -e "  ${RED}0)${NC} Cancel"
    echo ""
    echo -ne "  ${YELLOW}?${NC}  Enter choice [1-5]: "
    read -r choice
    
    local KERNEL=""
    case $choice in
        1) KERNEL="linux-cachyos linux-cachyos-headers" ;;
        2) KERNEL="linux-cachyos-lts linux-cachyos-lts-headers" ;;
        3) KERNEL="linux-cachyos-bore linux-cachyos-bore-headers" ;;
        4) KERNEL="linux-cachyos-eevdf linux-cachyos-eevdf-headers" ;;
        5) KERNEL="linux-cachyos-sched-ext linux-cachyos-sched-ext-headers" ;;
        0) 
            echo -e "\n${YELLOW}[CANCEL]${NC} Installation cancelled"
            exit 0
            ;;
        *)
            echo -e "\n${RED}[ERROR]${NC} Invalid choice"
            exit 1
            ;;
    esac
    
    echo ""
    echo -e "${CYAN}[INFO]${NC} Installing: $KERNEL"
    echo ""
    
    sudo pacman -S --needed $KERNEL
    
    echo -e "\n${GREEN}[OK]${NC} Kernel installed successfully"
}

# Update bootloader
update_bootloader() {
    echo -e "\n${YELLOW}[6/6]${NC} Updating bootloader..."
    
    # Detect bootloader
    if [[ -d /boot/grub ]]; then
        echo -e "${CYAN}[INFO]${NC} GRUB detected, regenerating config..."
        sudo grub-mkconfig -o /boot/grub/grub.cfg
        echo -e "${GREEN}[OK]${NC} GRUB config updated"
    elif [[ -d /boot/loader ]]; then
        echo -e "${CYAN}[INFO]${NC} systemd-boot detected"
        echo -e "${GREEN}[OK]${NC} Kernel entries auto-generated"
    elif [[ -f /boot/limine.conf ]] || [[ -f /boot/limine/limine.conf ]] || [[ -f /boot/EFI/BOOT/limine.conf ]]; then
        echo -e "${CYAN}[INFO]${NC} Limine detected"
        echo ""
        echo -e "  ${WHITE}Add this entry to /boot/limine.conf:${NC}"
        echo ""
        echo -e "  ${DIM}:CachyOS Linux${NC}"
        echo -e "  ${DIM}    PROTOCOL=linux${NC}"
        echo -e "  ${DIM}    KERNEL_PATH=boot:///vmlinuz-linux-cachyos${NC}"
        echo -e "  ${DIM}    CMDLINE=root=UUID=YOUR-ROOT-UUID rw${NC}"
        echo -e "  ${DIM}    MODULE_PATH=boot:///initramfs-linux-cachyos.img${NC}"
        echo ""
        echo -e "${YELLOW}[NOTE]${NC} Update limine.conf manually with correct paths"
    elif [[ -f /boot/refind_linux.conf ]] || [[ -d /boot/EFI/refind ]]; then
        echo -e "${CYAN}[INFO]${NC} rEFInd detected"
        echo -e "${GREEN}[OK]${NC} Kernel will be auto-detected"
    else
        echo -e "${YELLOW}[WARN]${NC} Unknown bootloader, update manually if needed"
    fi
}

# Show completion message
show_complete() {
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              Installation Complete!                        ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${WHITE}Next steps:${NC}"
    echo -e "  1. Reboot your system"
    echo -e "  2. Select CachyOS kernel from bootloader"
    echo ""
    echo -e "  ${WHITE}Verify after reboot:${NC}"
    echo -e "  ${DIM}uname -r${NC}  →  Should show 'cachyos' in kernel name"
    echo ""
    echo -e "  ${WHITE}Performance tips:${NC}"
    echo -e "  • Install ${CYAN}gamemode${NC} for automatic game optimizations"
    echo -e "  • Install ${CYAN}mangohud${NC} for FPS overlay"
    echo -e "  • Use ${CYAN}gamemoderun %command%${NC} in Steam launch options"
    echo ""
    
    echo -ne "  ${YELLOW}?${NC}  Reboot now? [y/N]: "
    read -r reboot_choice
    
    if [[ "${reboot_choice,,}" == "y" ]]; then
        echo -e "\n${CYAN}[INFO]${NC} Rebooting in 3 seconds..."
        sleep 3
        systemctl reboot
    fi
}

# Main
main() {
    check_cpu_support
    import_keys
    install_cachyos_packages
    configure_pacman
    install_kernel
    update_bootloader
    show_complete
}

main
