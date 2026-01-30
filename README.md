# Hyprland Dotfiles

An automated Hyprland dotfiles setup for Arch Linux–based distributions,
focused on modular configuration, hardware-aware installation, and a
flexible theming system for daily use.

![Hyprland](https://img.shields.io/badge/Hyprland-58E1FF?style=for-the-badge&logo=hyprland&logoColor=white)
![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)
![Wayland](https://img.shields.io/badge/Wayland-FFBC00?style=for-the-badge&logo=wayland&logoColor=black)

## ✨ Features

- 🚀 **Auto Installer** - One-command setup with interactive menu
- 🖥️ **GPU Auto-detect** - NVIDIA, AMD, Intel driver installation
- 🎮 **QEMU/KVM Ready** - Virtualization pre-configured
- 🐚 **Zsh + Oh My Zsh** - Modern shell with plugins

## 📦 Installation

```bash
git clone https://github.com/ayu-dash/hyprland-dotfiles.git ~/hyprland-dotfiles
cd ~/hyprland-dotfiles
./install.sh
```

### Installation Options

| Option | Description |
|--------|-------------|
| **1) Full Installation** | Complete setup (GPU, Packages, Configs, Themes, Shell) |
| **2) Install GPU Drivers** | AMD, NVIDIA, Intel auto-detect |
| **3) Install Packages Only** | Pacman, AUR, VSCode extensions |
| **4) Install Dotfiles Only** | ~/.config, ~/.local/bin |
| **5) Install Themes Only** | Icons, GTK Themes, Kvantum |
| **6) Configure Shell Only** | Zsh, Oh My Zsh, plugins |

## 📋 Requirements

- **OS**: Arch Linux (or Arch-based distros)
- **Display Server**: Wayland
- **AUR Helper**: yay (auto-installed)

## 📁 Dependencies

Dependencies are listed in separate files:
- `pacman-packages.txt` - Official Arch packages
- `yay-packages.txt` - AUR packages

## ⌨️ Keybindings

> `SUPER` = Windows/Meta key

### Applications

| Keys | Action |
|------|--------|
| `SUPER + Enter` | Terminal (Kitty) |
| `SUPER + F` | Browser (Firefox) |
| `SUPER + E` | File Manager (PCManFM) |
| `SUPER + V` | Code Editor (VS Code) |
| `SUPER + Space` | Application Launcher |
| `SUPER + C` | Calculator |
| `SUPER + T` | Theme Selector |
| `SUPER + W` | Wallpaper Selector |
| `SUPER + S` | Config Editor |
| `SUPER + Shift + C` | Clipboard History |
| `SUPER + Shift + Ctrl + Alt + Space` | Emoji Picker |

### Window Management

| Keys | Action |
|------|--------|
| `SUPER + Q` | Close Window |
| `SUPER + Ctrl + F` | Fullscreen |
| `SUPER + Ctrl + M` | Maximize |
| `SUPER + Ctrl + V` | Toggle Floating |
| `ALT + Tab` | Cycle Windows |

### Focus (Arrow Keys / VIM)

| Keys | Action |
|------|--------|
| `SUPER + ←/→/↑/↓` | Move Focus |
| `SUPER + H/J/K/L` | Move Focus (VIM) |

### Resize Window

| Keys | Action |
|------|--------|
| `SUPER + Shift + ←/→/↑/↓` | Resize |
| `SUPER + Shift + H/J/K/L` | Resize (VIM) |

### Move Window

| Keys | Action |
|------|--------|
| `SUPER + Ctrl + ←/→/↑/↓` | Move Window |
| `SUPER + Ctrl + H/J/K/L` | Move Window (VIM) |
| `SUPER + LMB Drag` | Move Window (Mouse) |
| `SUPER + RMB Drag` | Resize Window (Mouse) |

### Workspaces

| Keys | Action |
|------|--------|
| `SUPER + 1-0` | Switch to Workspace 1-10 |
| `SUPER + Ctrl + 1-0` | Move Window to Workspace (Follow) |
| `SUPER + Shift + 1-0` | Move Window to Workspace (Silent) |
| `SUPER + Scroll` | Switch Workspace |
| `SUPER + U` | Toggle Scratchpad |
| `SUPER + Shift + U` | Move to Scratchpad |

### Window Groups

| Keys | Action |
|------|--------|
| `Ctrl + Alt + G` | Toggle Group |
| `Ctrl + Alt + Tab` | Switch Group Window |
| `Ctrl + Alt + ←/→` | Cycle Group Windows |

### Screenshot

| Keys | Action |
|------|--------|
| `Print` | Screenshot Menu |
| `SUPER + Print` | Capture Window |
| `SUPER + Shift + Print` | Capture Region |

### System

| Keys | Action |
|------|--------|
| `SUPER + Alt + L` | Lock Screen |
| `SUPER + Alt + M` | Exit Hyprland |
| `Power Button` | Session Menu |
| `SUPER + G` | Toggle Game Mode |
| `SUPER + Alt + B` | Reload Waybar |

### Media Keys

| Keys | Action |
|------|--------|
| `Vol Up/Down` | Adjust Volume |
| `Mute` | Toggle Mute |
| `Mic Mute` | Toggle Microphone |
| `Brightness Up/Down` | Adjust Brightness |
| `Play/Pause` | Media Play/Pause |
| `Next/Prev` | Media Next/Previous |

## 🎨 Theme Structure

Themes are located in `~/.config/hypr/Themes/`. Each theme is a self-contained directory:

```
Themes/
├── ThemeLoader.conf         # Auto-loaded by Hyprland (exec-once)
├── ThemeVariables.conf      # $theme_dir variable for sourcing
│
└── <ThemeName>/             # Theme directory (e.g. NierAutomata)
    ├── Activate.sh          # Theme activation script
    ├── Decoration.conf      # Hyprland decorations (borders, shadows, blur)
    ├── Name.txt             # Theme display name
    │
    ├── Colors/              # Color definitions
    │   ├── Gtk.css          # GTK color variables
    │   ├── Hypr.conf        # Hyprland color variables
    │   └── Rofi.css         # Rofi color variables
    │
    ├── Bar/                 # Waybar configuration
    │   ├── Config.jsonc     # Modules configuration
    │   ├── Config.css       # Styling
    │   └── Scripts/         # Custom scripts (optional)
    │
    ├── Rofi/                # Rofi launcher themes
    │   ├── Base.rasi        # Shared styles
    │   ├── MenuLauncher.rasi
    │   ├── Calculator.rasi
    │   ├── Clipboard.rasi
    │   ├── Session.rasi
    │   └── ...
    │
    ├── Swaync/              # Notification center
    │   ├── Config.json      # SwayNC configuration
    │   ├── Style.css        # Styling
    │   ├── Icons/           # Notification icons (optional)
    │   └── Scripts/         # Widget scripts (optional)
    │
    ├── Kitty/               # Terminal configuration
    │   └── kitty.conf
    │
    └── Wallpapers/          # Theme wallpapers
```

### Creating a New Theme

1. Copy an existing theme: `cp -r Themes/NierAutomata Themes/MyTheme`
2. Edit `Name.txt` with your theme name
3. Modify colors in `Colors/`
4. Update `THEME_NAME` in `Activate.sh`
5. Select theme with `SUPER + T`

## 🔧 System Configurations

The installer automatically configures:

| Component | Configuration |
|-----------|---------------|
| **GPU Drivers** | NVIDIA (dkms/open), AMD, Intel auto-detect |
| **Display Manager** | greetd + tuigreet |
| **Virtualization** | QEMU/KVM + libvirt + virt-manager |
| **Shell** | Zsh + Oh My Zsh + plugins |

## 📜 Scripts

Python scripts located in `~/.config/hypr/Scripts/`:

| Script | Description |
|--------|-------------|
| `Audio.py` | Volume control with notifications |
| `Brightness.py` | Screen brightness control |
| `Battery.py` | Low battery notifications |
| `Wallpaper.py` | Wallpaper management |
| `GameMode.py` | Toggle performance mode |
| `RofiLauncher.py` | Rofi menu dispatcher |

## 🙏 Credits

- [Hyprland](https://hyprland.org/)
- [Waybar](https://github.com/Alexays/Waybar)
- [Rofi](https://github.com/davatorium/rofi)
- [SwayNC](https://github.com/ErikReider/SwayNotificationCenter)
- [tuigreet](https://github.com/apognu/tuigreet)
