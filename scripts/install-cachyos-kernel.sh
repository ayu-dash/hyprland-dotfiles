#!/bin/bash
# ============================================================
# CachyOS Kernel Installer with BORE Scheduler
# Uses official CachyOS repository setup script
# https://wiki.cachyos.org/features/optimized_repos/
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

TEMP_DIR="/tmp/cachyos-install"

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

# Cleanup function
cleanup() {
    rm -rf "$TEMP_DIR" 2>/dev/null || true
}
trap cleanup EXIT

# Check architecture support
check_cpu_support() {
    echo -e "${YELLOW}[1/4]${NC} Checking CPU architecture support..."
    
    CPU_LEVEL="generic"
    
    # Check for x86-64-v3 support
    if grep -q "avx2" /proc/cpuinfo && grep -q "bmi2" /proc/cpuinfo; then
        CPU_LEVEL="v3"
        echo -e "${GREEN}[INFO]${NC} CPU supports x86-64-v3 (AVX2, BMI2)"
    fi
    
    # Check for x86-64-v4 support (AVX-512)
    if grep -q "avx512" /proc/cpuinfo; then
        CPU_LEVEL="v4"
        echo -e "${GREEN}[INFO]${NC} CPU supports x86-64-v4 (AVX-512)"
    fi
    
    # Check for Zen 4/5
    if grep -q "znver4\|znver5" /proc/cpuinfo 2>/dev/null || \
       (grep -q "AMD" /proc/cpuinfo && grep -q "avx512" /proc/cpuinfo); then
        # Additional check for Zen 4/5 model
        local cpu_model=$(grep "model name" /proc/cpuinfo | head -1)
        if echo "$cpu_model" | grep -qiE "7[0-9]{3}|9[0-9]{3}X3D|Ryzen.*7[0-9]{3}"; then
            CPU_LEVEL="znver4"
            echo -e "${GREEN}[INFO]${NC} CPU detected as AMD Zen 4/5 architecture"
        fi
    fi
    
    if [[ "$CPU_LEVEL" == "generic" ]]; then
        echo -e "${YELLOW}[INFO]${NC} CPU uses generic x86-64"
    fi
}

# Setup CachyOS repositories using official script
setup_cachyos_repos() {
    echo -e "\n${YELLOW}[2/4]${NC} Setting up CachyOS repositories..."
    
    # Check if already configured
    if grep -q "\[cachyos\]" /etc/pacman.conf && pacman -Qi cachyos-keyring &>/dev/null; then
        echo -e "${GREEN}[INFO]${NC} CachyOS repositories already configured"
        echo -e "${CYAN}[INFO]${NC} Syncing package database..."
        sudo pacman -Sy
        return 0
    fi
    
    echo -e "${CYAN}[INFO]${NC} Downloading official CachyOS repository script..."
    
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"
    
    # Download official script
    if ! curl -sL https://mirror.cachyos.org/cachyos-repo.tar.xz -o cachyos-repo.tar.xz; then
        echo -e "${RED}[ERROR]${NC} Failed to download CachyOS repository script!"
        return 1
    fi
    
    # Extract
    tar xf cachyos-repo.tar.xz
    cd cachyos-repo
    
    echo -e "${CYAN}[INFO]${NC} Running official CachyOS repository setup..."
    echo -e "${DIM}  This will install CachyOS pacman and configure repositories${NC}"
    echo -e "${DIM}  based on your CPU architecture ($CPU_LEVEL)${NC}"
    echo ""
    
    # Run official script
    sudo ./cachyos-repo.sh
    
    echo -e "\n${GREEN}[OK]${NC} CachyOS repositories configured successfully"
    
    cd - > /dev/null
}

# Select and install kernel
install_kernel() {
    echo -e "\n${YELLOW}[3/4]${NC} Selecting kernel to install..."
    echo ""
    echo -e "  ${WHITE}Available CachyOS Kernels:${NC}"
    echo ""
    echo -e "  ${CYAN}1)${NC} linux-cachyos          ${DIM}(Recommended - Latest stable with BORE)${NC}"
    echo -e "  ${CYAN}2)${NC} linux-cachyos-lts      ${DIM}(Long Term Support with BORE)${NC}"
    echo -e "  ${CYAN}3)${NC} linux-cachyos-bore     ${DIM}(BORE only, minimal patches)${NC}"
    echo -e "  ${CYAN}4)${NC} linux-cachyos-eevdf    ${DIM}(EEVDF scheduler)${NC}"
    echo -e "  ${CYAN}5)${NC} linux-cachyos-sched-ext ${DIM}(sched-ext for custom schedulers)${NC}"
    echo -e "  ${CYAN}6)${NC} linux-cachyos-hardened ${DIM}(Security-focused)${NC}"
    echo -e "  ${RED}0)${NC} Cancel"
    echo ""
    echo -ne "  ${YELLOW}?${NC}  Enter choice [0-6]: "
    read -r choice
    
    local KERNEL=""
    local KERNEL_NAME=""
    case $choice in
        1) 
            KERNEL="linux-cachyos linux-cachyos-headers"
            KERNEL_NAME="linux-cachyos"
            ;;
        2) 
            KERNEL="linux-cachyos-lts linux-cachyos-lts-headers"
            KERNEL_NAME="linux-cachyos-lts"
            ;;
        3) 
            KERNEL="linux-cachyos-bore linux-cachyos-bore-headers"
            KERNEL_NAME="linux-cachyos-bore"
            ;;
        4) 
            KERNEL="linux-cachyos-eevdf linux-cachyos-eevdf-headers"
            KERNEL_NAME="linux-cachyos-eevdf"
            ;;
        5) 
            KERNEL="linux-cachyos-sched-ext linux-cachyos-sched-ext-headers"
            KERNEL_NAME="linux-cachyos-sched-ext"
            ;;
        6)
            KERNEL="linux-cachyos-hardened linux-cachyos-hardened-headers"
            KERNEL_NAME="linux-cachyos-hardened"
            ;;
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
    
    # Store kernel name for bootloader config
    INSTALLED_KERNEL="$KERNEL_NAME"
}

# Update bootloader
update_bootloader() {
    echo -e "\n${YELLOW}[4/4]${NC} Updating bootloader..."
    
    # Detect bootloader
    if [[ -d /boot/grub ]]; then
        echo -e "${CYAN}[INFO]${NC} GRUB detected, regenerating config..."
        sudo grub-mkconfig -o /boot/grub/grub.cfg
        echo -e "${GREEN}[OK]${NC} GRUB config updated"
    elif [[ -d /boot/loader ]]; then
        echo -e "${CYAN}[INFO]${NC} systemd-boot detected"
        echo -e "${GREEN}[OK]${NC} Kernel entries auto-generated by kernel install hooks"
    elif [[ -f /boot/limine.conf ]] || [[ -f /boot/limine/limine.conf ]] || [[ -f /boot/EFI/BOOT/limine.conf ]]; then
        echo -e "${CYAN}[INFO]${NC} Limine detected"
        echo ""
        echo -e "  ${WHITE}Add this entry to /boot/limine.conf:${NC}"
        echo ""
        echo -e "  ${DIM}:CachyOS Linux${NC}"
        echo -e "  ${DIM}    PROTOCOL=linux${NC}"
        echo -e "  ${DIM}    KERNEL_PATH=boot:///vmlinuz-${INSTALLED_KERNEL:-linux-cachyos}${NC}"
        echo -e "  ${DIM}    CMDLINE=root=UUID=YOUR-ROOT-UUID rw loglevel=3${NC}"
        echo -e "  ${DIM}    MODULE_PATH=boot:///initramfs-${INSTALLED_KERNEL:-linux-cachyos}.img${NC}"
        echo ""
        echo -e "${YELLOW}[NOTE]${NC} Update limine.conf manually with your root UUID"
        echo -e "${DIM}  Get UUID with: blkid | grep -i root${NC}"
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
    echo -e "  ${WHITE}Summary:${NC}"
    echo -e "  • CPU Architecture: ${CYAN}x86-64-${CPU_LEVEL}${NC}"
    echo -e "  • Kernel installed: ${CYAN}${INSTALLED_KERNEL:-linux-cachyos}${NC}"
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
    echo -e "  • Use ${CYAN}mangohud gamemoderun %command%${NC} in Steam launch options"
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
    setup_cachyos_repos
    install_kernel
    update_bootloader
    show_complete
}

main
