"""
Kahfein (Caffeine) module for Hyprland.
Prevents the system from going idle by toggling hypridle.
"""

import argparse
import json

from Utils import notify, is_running, run_bg, kill_all, get_logger

log = get_logger("Kahfein")

PROCESS: str = "hypridle"


def status() -> None:
    """Print the current Kahfein status in Waybar JSON format."""
    running = is_running(PROCESS)
    output = {
        "text": "OFF" if running else "ON",
        "class": "inactive" if running else "active"
    }
    print(json.dumps(output))


def toggle() -> None:
    """Toggle hypridle on or off and send notification."""
    if is_running(PROCESS):
        log.info("Enabling caffeine mode (killing hypridle)")
        kill_all(PROCESS)
        notify("system-lock-screen", "Kahfein enabled!")
    else:
        log.info("Disabling caffeine mode (starting hypridle)")
        run_bg([PROCESS])
        notify("system-lock-screen", "Kahfein disabled!")


def main() -> None:
    """Parse arguments and execute the requested Kahfein action."""
    parser = argparse.ArgumentParser(description="Kahfein - Caffeine for Hyprland")
    parser.add_argument(
        "action",
        choices=["toggle", "status"],
        help="Kahfein action to perform"
    )

    args = parser.parse_args()

    match args.action:
        case "toggle":
            toggle()
        case "status":
            status()


if __name__ == "__main__":
    main()
