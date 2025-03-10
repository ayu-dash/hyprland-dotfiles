#!/bin/bash
clear

yay_repo="https://aur.archlinux.org/yay-git.git"
wal_repo="https://github.com/ayu-dash/wallpapers.git"
oh_my_zsh_repo="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"

HOME_DIR="$HOME"
DOTFILES_DIR="$HOME_DIR/hyprland-dotfiles"
CONFIG_DIR="$HOME_DIR/.config"
THEMES_DIR="$HOME_DIR/.themes"
ICONS_DIR="$HOME_DIR/.icons"
BIN_DIR="$HOME_DIR/.local/bin"
TEMP_DIR="/tmp/installation"

if [[ $EUID -eq 0 ]]; then
    echo "This script should not be executed as root! Exiting......."
    exit 1
fi

cat << EOF
                         __                __
 .---.-..--.--..--.--..--|  |.---.-..-----.|  |--.
 |  _  ||  |  ||  |  ||  _  ||  _  ||__ --||     |
 |___._||___  ||_____||_____||___._||_____||__|__|
        |_____|
             
EOF

echo "This process will replace your previous configurations."
read -p "Do you want to continue with the process? [y/N]: " choice
choice=${choice:-n}
choice=$(echo "$choice" | tr '[:upper:]' '[:lower:]')

if [[ "$choice" == "n" ]]; then
    exit 0
fi

depedencies=(waybar swaync git rofi-wayland rofi-calc rofi-emoji xdg-desktop-portal-gtk xdg-desktop-portal-hyprland xdg-user-dirs thunar gvfs tumbler thunar-archive-plugin kitty swww hyprlock hypridle cliphist bluez bluez-utils blueman nm-connection-editor network-manager-applet gtk3 vlc viewnior qt5-wayland qt6-wayland udiskie udisks2 nwg-look firefox btop base-devel imagemagick zsh fastfetch brightnessctl networkmanager unrar unzip dconf-editor xarchiver python sddm iwd gedit)

yay_depedencies=(wlogout hyprshot noto-fonts ttf-ms-win11-auto noto-fonts-emoji ttf-material-design-icons-webfont ttf-font-awesome nerd-fonts onlyoffice-bin sddm-theme-tokyo-night-git visual-studio-code-bin)

for depedency in "${depedencies[@]}"; do
    sudo pacman -S --noconfirm $depedency
done

# update home folders
xdg-user-dirs-update 2>&1 

# install yay
echo "installing yay"
 if [[ ! -d "$TEMP_DIR/yay" ]]; then
    git clone $yay_repo "$TEMP_DIR/yay"
else
    echo "yay directory already exists."
fi

cd "$TEMP_DIR/yay"
makepkg -si
cd "-"

for depedency in "${yay_depedencies[@]}"; do
    yay -S --noconfirm $depedency
done

# install vscode extention
echo "installing vscode extensions"
cat $DOTFILES_DIR/etc/CodeExtensions.txt | xargs -n 1 code --install-extension

echo "Installing dotfiles"

[ ! -d $CONFIG_DIR ] && mkdir -p "$CONFIG_DIR"
[ ! -d $BIN_DIR ] && mkdir -p "$BIN_DIR"
[ ! -d $THEMES_DIR ] && mkdir -p "$THEMES_DIR"
[ ! -d $ICONS_DIR ] && mkdir -p "$ICONS_DIR"

for dir in $DOTFILES_DIR/config/*; do
    dir_name=$(basename "$dir")

    if cp -R "${dir}" "$CONFIG_DIR"; then
        echo "Configuration installed succesfully $dir_name"
        sleep 1
    else
        echo "configuration failed to been installed."
        sleep 1
    fi
done

if cp -R "$DOTFILES_DIR/bin/"* "$BIN_DIR/"; then
    echo "Configuration installed successfully in $BIN_DIR"
    sleep 1
else
    echo "Configuration failed to install."
    sleep 1
fi

if [ -d "$HOME_DIR/.local/bin" ]; then
    chmod +x "$HOME_DIR/.local/bin/*"
else
    echo "Directory $HOME_DIR/.local/bin does not exist"
fi

#install theme and icon
tar xvf assets/Sweet-cursors.tar.xz -C $ICONS_DIR
tar xvf assets/candy-icons.tar.xz -C $ICONS_DIR
tar xvf assets/Catppuccin-Mocha-Standard-Lavender-Dark.tar.xz -C $THEMES_DIR

# install oh-my-zsh
echo "Installing oh my zsh"
RUNZSH=no sh -c "$(curl -fsSL $oh_my_zsh_repo)"

git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-completions.git ~/.oh-my-zsh/custom/plugins/zsh-completions
git clone https://github.com/zsh-users/zsh-history-substring-search.git ~/.oh-my-zsh/custom/plugins/zsh-history-substring-search

cp -f "$DOTFILES_DIR/.gtkrc-2.0" "$HOME_DIR"
cp -f "$DOTFILES_DIR/.zshrc" "$HOME"
sudo cp -f "$DOTFILES_DIR/etc/NetworkManager.conf" "/etc/NetworkManager/NetworkManager.conf"
sudo cp -f "$DOTFILES_DIR/etc/sddm.conf" "/etc/sddm.conf"

fc-cache -rv >/dev/null 2>&1

# enable service
echo "Enabling service"
for service in sddm bluetooth NetworkManager udisks2; do
    if systemctl list-unit-files | grep -q "^$service"; then
        sudo systemctl enable "$service"
    else
        echo "Warning: Service $service not found!"
    fi
done

# download wallpaper
echo "Downloading wallpapers"
read -p "Dowload wallpapers? [Y/n]: " choice
choice=${choice:-y}
choice=$(echo "$choice") | tr '[:upper:]' '[:lower:]'

if [[ "$choice" == "y" ]]; then
    if [[ ! -d "$HOME/Pictures/wallpapers" ]]; then
        git clone $wal_repo "$HOME/Pictures/wallpapers"
    else
        echo "Wallpapers directory already exists."
    fi
fi

########## --------- exit ---------- ##########
echo "Installation complete"

read -p "Reboot Now? [Y/n]: " choice
choice=${choice:-n}
choice=$(echo "$choice)" | tr '[:upper:]' '[:lower:]')

if [[ "$choice" == "n" ]]; then
    exit 0
else
    systemctl reboot
fi
