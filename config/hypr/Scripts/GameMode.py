"""
Game mode toggle module for Hyprland.
Disables animations, blur, and gaps for optimal gaming performance.
"""

import os
import subprocess
from pathlib import Path

import Wallpaper
import Waybar
from Utils import notify


TEMP_FILE: Path = Path("/tmp/game-mode-on")


def enable_game_mode() -> None:
    """Enable game mode by disabling visual effects and killing unnecessary processes."""
    TEMP_FILE.touch()

    # Disable visual effects
    subprocess.run([
        "hyprctl", "--batch",
        "keyword animations:enabled 0;"
        "keyword decoration:blur:passes 0;"
        "keyword general:gaps_in 0;"
        "keyword general:gaps_out 0;"
        "keyword general:border_size 1;"
        "keyword decoration:rounding 0;"
    ])

    # Force full opacity on all windows
    subprocess.run([
        "hyprctl",
        "keyword",
        "windowrule",
        "opacity 1 override 1 override 1 override, ^(.*)$"
    ])

    # Kill background processes
    Wallpaper.swww_kill()
    Waybar.kill_waybar()

    notify("applications-games", "Gamemode: Enabled")


def disable_game_mode() -> None:
    """Disable game mode and restore normal desktop settings."""
    TEMP_FILE.unlink(missing_ok=True)
    subprocess.run(["hyprctl", "reload"])

    # Restart background processes
    Wallpaper.swww_run()
    Waybar.run_waybar()

    notify("applications-games", "Gamemode: Disabled")


def toggle_game_mode() -> None:
    """Toggle game mode on or off based on current state."""
    if TEMP_FILE.exists():
        disable_game_mode()
    else:
        enable_game_mode()


if __name__ == "__main__":
    toggle_game_mode()
