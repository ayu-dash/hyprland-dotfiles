"""
Game mode toggle module for Hyprland.
Disables animations, blur, and gaps for optimal gaming performance.
"""

from pathlib import Path

import Wallpaper
from Utils import notify, get_logger, hyprctl_batch, hyprctl_keyword, hyprctl_reload, run_bg, kill_all

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
    log.debug("Killing swww, waybar, and swaync")
    Wallpaper.swww_kill()
    kill_all("waybar")
    kill_all("swaync")

    notify("applications-games", "Gamemode: Enabled")


def disable_game_mode() -> None:
    """Disable game mode and restore normal desktop settings."""
    log.info("Disabling game mode")
    TEMP_FILE.unlink(missing_ok=True)
    hyprctl_reload()

    # Restart wallpaper daemon
    log.debug("Restarting swww")
    Wallpaper.swww_run()

    # Reload active theme (this will restart waybar and swaync with correct config)
    log.debug("Reloading active theme")
    theme_loader = Path.home() / ".config/hypr/Themes/ThemeLoader.conf"
    if theme_loader.exists():
        # Parse ThemeLoader.conf to get the activate script path
        content = theme_loader.read_text()
        # Extract theme name from: exec-once = $HOME/.config/hypr/Themes/ThemeName/Activate.sh
        import re
        match = re.search(r'Themes/([^/]+)/Activate\.sh', content)
        if match:
            theme_name = match.group(1)
            activate_script = Path.home() / f".config/hypr/Themes/{theme_name}/Activate.sh"
            if activate_script.exists():
                log.debug(f"Running {activate_script}")
                run_bg(["bash", str(activate_script)])

    notify("applications-games", "Gamemode: Disabled")


def toggle_game_mode() -> None:
    """Toggle game mode on or off based on current state."""
    if TEMP_FILE.exists():
        disable_game_mode()
    else:
        enable_game_mode()


if __name__ == "__main__":
    toggle_game_mode()
