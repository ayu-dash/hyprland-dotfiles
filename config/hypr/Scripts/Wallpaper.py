"""
Wallpaper management module.
Handles wallpaper setting and awww daemon control.
"""

import argparse
import os
import shutil
from pathlib import Path

from Utils import (
    get_logger, is_running, run_bg, run_silent,
    hyprctl, get_monitors as utils_get_monitors
)

log = get_logger("Wallpaper")

# Cache directories
CACHE_DIR: Path = Path.home() / ".cache"
WAL_DEST: Path = CACHE_DIR / ".wal.jpg"
BAN_DEST: Path = CACHE_DIR / ".ban.jpg"

# Awww transition settings
AWWW_PARAMS: list[str] = [
    "--transition-fps", "60",
    "--transition-type", "wipe",
    "--transition-duration", "1"
]


def get_monitors() -> list[str]:
    """Get list of connected monitor names."""
    monitors = utils_get_monitors()
    return [m["name"] for m in monitors]


def start_daemon() -> None:
    """Start awww-daemon if not already running."""
    if not is_running("awww-daemon"):
        log.debug("Starting awww-daemon")
        run_bg(["awww-daemon"])


def awww_kill() -> None:
    """Kill the awww daemon."""
    log.debug("Killing awww daemon")
    run_silent(["awww", "kill"])


HYPR_THEMES_DIR: Path = Path.home() / ".config/hypr/Themes"
DEFAULT_THEME: str = "NierAutomata"


def _get_default_wallpaper() -> str | None:
    """Find a default wallpaper from the active or default theme."""
    theme_dir = os.environ.get("HYPR_THEME_DIR", "")
    if not theme_dir:
        theme_dir = str(HYPR_THEMES_DIR / DEFAULT_THEME)

    wp_dir = Path(theme_dir) / "Wallpapers"
    if wp_dir.is_dir():
        images = sorted(wp_dir.glob("*"))
        if images:
            return str(images[0])
    return None


def awww_run() -> None:
    """Start awww daemon and restore previous wallpaper."""
    start_daemon()
    if WAL_DEST.exists():
        run_silent(["awww", "restore"])
        return
    # Fresh install: set default wallpaper
    wp = _get_default_wallpaper()
    if wp:
        log.info(f"No cached wallpaper, using default: {wp}")
        set_wallpaper(wp)
    else:
        log.warning("No wallpaper found to set")


def set_wallpaper(image_path: str) -> None:
    """Set wallpaper on all monitors and create banner image."""
    log.info(f"Setting wallpaper: {image_path}")
    start_daemon()

    path = Path(image_path)
    ext = path.suffix.lower()

    if ext == ".gif":
        log.debug("Extracting first frame from GIF")
        run_silent(["magick", f"{image_path}[0]", str(WAL_DEST)])
    else:
        shutil.copyfile(image_path, WAL_DEST)

    # Apply wallpaper to all monitors
    monitors = get_monitors()
    log.debug(f"Applying to monitors: {monitors}")
    for monitor in monitors:
        run_silent(["awww", "img", image_path, "--outputs", monitor] + AWWW_PARAMS)

    # Create blurred banner for lock screen
    run_silent(["magick", str(WAL_DEST), "-resize", "10%", str(BAN_DEST)])


def main() -> None:
    """Parse arguments and execute the requested wallpaper action."""
    parser = argparse.ArgumentParser(description="Wallpaper manager")
    parser.add_argument(
        "action",
        choices=["set", "run"],
        help="Wallpaper action to perform"
    )
    parser.add_argument(
        "--path",
        type=str,
        help="Path to wallpaper image"
    )

    args = parser.parse_args()

    match args.action:
        case "set":
            if args.path:
                set_wallpaper(args.path)
        case "run":
            awww_run()


if __name__ == "__main__":
    main()
