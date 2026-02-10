# Hyprland Dotfiles (Fedora Edition)

An automated Hyprland dotfiles setup optimized for Fedora Linux, featuring modular configuration, Copr repository integration regarding Hyprland ecosystem, and a flexible theming system.

![Hyprland](https://img.shields.io/badge/Hyprland-58E1FF?style=for-the-badge&logo=hyprland&logoColor=white)
![Fedora Linux](https://img.shields.io/badge/Fedora_Linux-51A2DA?style=for-the-badge&logo=fedora&logoColor=white)
![Wayland](https://img.shields.io/badge/Wayland-FFBC00?style=for-the-badge&logo=wayland&logoColor=black)

## ✨ Features

- 🚀 **Auto Installer** - One-command setup with interactive menu for Fedora
- 📦 **Copr Integration** - Automated setup for `solopasha/hyprland` & `erikreider/SwayNotificationCenter`
- 🖥️ **GDM Integration** - Seamless login via GNOME Display Manager
- 🎮 **QEMU/KVM Ready** - Virtualization pre-configured with libvirt
- 🐚 **Zsh + Oh My Zsh** - Modern shell with plugins
- 🌐 **NetworkManager** - Full integration with `nmcli` and `nm-connection-editor`

## 📦 Installation

```bash
git clone https://github.com/ayu-dash/hyprland-dotfiles.git ~/hyprland-dotfiles
cd ~/hyprland-dotfiles
chmod +x install.sh
./install.sh
```

### Installation Options

| Option | Description |
|--------|-------------|
| **1) Full Installation** | Complete setup (Repos, Packages, Configs, Themes, Shell) |
| **2) Setup Repos Only** | Enable Copr, VS Code, Chrome, RPM Fusion repos |
| **3) Install Packages Only** | DNF packages, Third-party apps, VSCode extensions |
| **4) Install Dotfiles Only** | `~/.config`, `~/.local/bin` |
| **5) Install Themes Only** | Icons, GTK Themes, Fonts |
| **6) Configure Shell Only** | Zsh, Oh My Zsh, plugins |
| **7) Install VS Code Extensions** | From `etc/CodeExtensions.txt` |
| **8) Build GitHub Packages** | Compile `rofi-emoji`, `rofi-calc` from source |

## 📋 Requirements

- **OS**: Fedora Linux (Workstation recommended)
- **Display Server**: Wayland
- **Package Manager**: dnf 

## 📁 Dependencies

Dependencies are listed in:
- `dnf-packages.txt` - Official Fedora & Copr packages

## ⌨️ Keybindings

> `SUPER` = Windows/Meta key

### Applications

| Keys | Action |
|------|--------|
| `SUPER + Enter` | Terminal (Kitty) |
| `SUPER + F` | Browser (Firefox) |
| `SUPER + E` | File Manager (Nautilus) |
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
| **Display Manager** | GDM (GNOME Display Manager) |
| **Virtualization** | QEMU/KVM + libvirt + virt-manager |
| **Network** | NetworkManager + nm-applet |
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
| `Hostpot.py` | WiFi Hotspot Management (requires `hostapd`) |
| `Waybar.py` | Waybar control |

## 🙏 Credits

- [Hyprland](https://hyprland.org/)
- [Waybar](https://github.com/Alexays/Waybar)
- [Rofi](https://github.com/davatorium/rofi)
- [SwayNC](https://github.com/ErikReider/SwayNotificationCenter)
