"""
Game mode toggle module for Hyprland.
Disables animations, blur, and gaps for optimal gaming performance.
"""

from pathlib import Path

import Wallpaper
import Waybar
from Utils import notify, get_logger, hyprctl_batch, hyprctl_keyword, hyprctl_reload

log = get_logger("GameMode")

TEMP_FILE: Path = Path("/tmp/game-mode-on")


def enable_game_mode() -> None:
    """Enable game mode by disabling visual effects and killing unnecessary processes."""
    log.info("Enabling game mode")
    TEMP_FILE.touch()

    # Disable visual effects
    hyprctl_batch(
        "keyword animations:enabled 0",
        "keyword decoration:blur:passes 0",
        "keyword general:gaps_in 0",
        "keyword general:gaps_out 0",
        "keyword general:border_size 1",
        "keyword decoration:rounding 0"
    )

    # Force full opacity on all windows
    hyprctl_keyword("windowrule", "opacity 1 override 1 override 1 override, ^(.*)$")

    # Kill background processes
    log.debug("Killing swww and waybar")
    Wallpaper.swww_kill()
    Waybar.kill_waybar()

    notify("applications-games", "Gamemode: Enabled")


def disable_game_mode() -> None:
    """Disable game mode and restore normal desktop settings."""
    log.info("Disabling game mode")
    TEMP_FILE.unlink(missing_ok=True)
    hyprctl_reload()

    # Restart background processes
    log.debug("Restarting swww and waybar")
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
