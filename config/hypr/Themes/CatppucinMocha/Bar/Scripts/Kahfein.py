"""
Kahfein (Caffeine) module for Waybar.
Prevents the system from going idle by toggling hypridle.
"""

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path.home() / ".config/hypr/Scripts"))
from Utils import is_running, run_bg, kill_all, get_logger

log = get_logger("Kahfein")

PROCESS: str = "hypridle"


def status() -> None:
    """Print Kahfein status in Waybar JSON format."""
    running = is_running(PROCESS)
    output = {
        "text": "󰛊" if running else "󰅶",
        "tooltip": "Kahfein: Inactive" if running else "Kahfein: Active",
        "class": "inactive" if running else "active"
    }
    print(json.dumps(output))


def toggle() -> None:
    """Toggle hypridle on or off."""
    if is_running(PROCESS):
        log.info("Enabling caffeine mode (killing hypridle)")
        kill_all(PROCESS)
    else:
        log.info("Disabling caffeine mode (starting hypridle)")
        run_bg([PROCESS])


def main() -> None:
    """Parse arguments and execute the requested action."""
    parser = argparse.ArgumentParser(description="Kahfein - Caffeine for Hyprland")
    parser.add_argument("action", choices=["toggle", "status"])

    args = parser.parse_args()

    match args.action:
        case "toggle":
            toggle()
        case "status":
            status()


if __name__ == "__main__":
    main()