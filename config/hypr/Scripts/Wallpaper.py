"""
Wallpaper management module.
Handles wallpaper setting and swww daemon control.
"""

import argparse
import json
import shutil
import subprocess
from pathlib import Path

from Utils import get_pid


# Cache directories
CACHE_DIR: Path = Path.home() / ".cache"
WAL_DEST: Path = CACHE_DIR / ".wal.jpg"
BAN_DEST: Path = CACHE_DIR / ".ban.jpg"

# Swww transition settings
SWWW_PARAMS: list[str] = [
    "--transition-fps", "60",
    "--transition-type", "wipe",
    "--transition-duration", "1"
]


def get_monitors() -> list[str]:
    """Get list of connected monitor names."""
    result = subprocess.run(
        ["hyprctl", "monitors", "-j"],
        capture_output=True,
        text=True
    )
    monitors = json.loads(result.stdout)
    return [m["name"] for m in monitors]


def start_daemon() -> None:
    """Start swww-daemon if not already running."""
    if not get_pid("swww-daemon"):
        subprocess.Popen(["swww-daemon"])


def swww_kill() -> None:
    """Kill the swww daemon."""
    subprocess.run(["swww", "kill"])


def swww_run() -> None:
    """Start swww daemon and restore previous wallpaper."""
    start_daemon()
    subprocess.run(["swww", "restore"])


def set_wallpaper(image_path: str) -> None:
    """Set wallpaper on all monitors and create banner image."""
    start_daemon()

    path = Path(image_path)
    ext = path.suffix.lower()

    # For GIFs, extract first frame as static image
    if ext == ".gif":
        subprocess.run([
            "magick",
            f"{image_path}[0]",
            str(WAL_DEST)
        ])
    else:
        shutil.copyfile(image_path, WAL_DEST)

    # Apply wallpaper to all monitors
    for monitor in get_monitors():
        subprocess.run(["swww", "img", image_path, "--outputs", monitor] + SWWW_PARAMS)

    # Create blurred banner for lock screen
    subprocess.run(["magick", str(WAL_DEST), "-resize", "10%", str(BAN_DEST)])


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
            swww_run()


if __name__ == "__main__":
    main()
