"""
Theme Activation Script for Hyprland

Activates a theme by updating configuration files, setting environment
variables, and restarting UI services (waybar, swaync).
"""

import time
from pathlib import Path
import sys

sys.path.insert(0, str(Path.home() / ".config/hypr/Scripts"))
from Utils import get_logger, kill_all, run_bg, hyprctl_keyword

log = get_logger("Theme")

# Theme configuration
THEME_NAME = "NierAutomata"
HYPR_DIR = Path.home() / ".config/hypr"
THEME_DIR = HYPR_DIR / "Themes" / THEME_NAME
LOCK_FILE = Path("/tmp/theme_loading.lock")


def write_theme_config() -> None:
    """Write theme loader and variables configuration files."""
    log.info(f"Activating theme: {THEME_NAME}")
    
    loader_path = HYPR_DIR / "Themes/ThemeLoader.conf"
    variables_path = HYPR_DIR / "Themes/ThemeVariables.conf"
    
    loader_content = f"exec-once =  python $HOME/.config/hypr/Themes/{THEME_NAME}/Activate.py"
    variables_content = f"$theme_dir = $HOME/.config/hypr/Themes/{THEME_NAME}"
    
    loader_path.write_text(loader_content)
    variables_path.write_text(variables_content)
    log.debug("Theme configuration files written")


def set_environment_variables() -> None:
    """Set Hyprland environment variables for the theme."""
    log.debug("Setting environment variables")
    
    hyprctl_keyword("env", f"HYPR_THEME_DIR,{THEME_DIR}")
    hyprctl_keyword("env", f"KITTY_CONFIG_DIRECTORY,{THEME_DIR}/Kitty/")


def restart_services() -> None:
    """Restart UI services with theme-specific configurations."""
    log.info("Restarting UI services")
    
    # Create lock file to prevent notifications during theme loading
    LOCK_FILE.touch()
    
    # Kill existing services
    kill_all("swaync")
    kill_all("waybar")
    time.sleep(0.5)
    
    # Start swaync with theme config
    log.debug("Starting swaync")
    run_bg([
        "swaync",
        "-c", str(THEME_DIR / "Swaync/Config.json"),
        "-s", str(THEME_DIR / "Swaync/Style.css")
    ])
    
    # Start waybar with theme config
    log.debug("Starting waybar")
    run_bg([
        "waybar",
        "-c", str(THEME_DIR / "Bar/Config.jsonc"),
        "-s", str(THEME_DIR / "Bar/Config.css")
    ])
    
    # Wait for services to initialize then remove lock
    time.sleep(1.5)
    LOCK_FILE.unlink(missing_ok=True)
    log.info("Theme activation complete")


def main() -> None:
    """Main entry point for theme activation."""
    write_theme_config()
    set_environment_variables()
    restart_services()


if __name__ == "__main__":
    main()
