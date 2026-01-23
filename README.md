# Hyprland Dotfiles

Personal Hyprland configuration with NierAutomata theme.

## Installation

```bash
git clone https://github.com/ayu-dash/hyprland-dotfiles.git ~/hyprland-dotfiles
cd ~/hyprland-dotfiles
chmod +x install.sh
./install.sh
```

## Dependencies

Dependencies are listed in separate files:
- `pacman-packages.txt` - Official Arch packages
- `yay-packages.txt` - AUR packages

## Keybindings

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

## Theme Structure

```
Themes/NierAutomata/
├── Activate.sh          # Theme activation script
├── Colors/              # Color definitions
│   ├── Gtk.css
│   ├── Hypr.conf
│   └── Rofi.css
├── Bar/                 # Waybar configuration
├── Rofi/                # Rofi themes
├── Swaync/              # Notification center
├── Kitty/               # Terminal theme
└── Wallpapers/          # Theme wallpapers
```

## Scripts

Python scripts located in `~/.config/hypr/Scripts/`:

| Script | Description |
|--------|-------------|
| `Audio.py` | Volume control with notifications |
| `Brightness.py` | Screen brightness control |
| `Battery.py` | Low battery notifications |
| `Wallpaper.py` | Wallpaper management |
| `GameMode.py` | Toggle performance mode |
| `RofiLauncher.py` | Rofi menu dispatcher |

## Credits

- [Hyprland](https://hyprland.org/)
- [Waybar](https://github.com/Alexays/Waybar)
- [Rofi](https://github.com/davatorium/rofi)
- [SwayNC](https://github.com/ErikReider/SwayNotificationCenter)
