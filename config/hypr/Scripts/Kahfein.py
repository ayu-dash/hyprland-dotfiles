"""
Kahfein (Caffeine) module for Hyprland.
Prevents the system from going idle by toggling hypridle.
"""

import argparse
import json
import subprocess

from Utils import notify, get_pid


PROCESS: str = "hypridle"


def status() -> None:
    """Print the current Kahfein status in Waybar JSON format."""
    pid = get_pid(PROCESS)
    output = {
        "text": "OFF" if pid else "ON",
        "class": "inactive" if pid else "active"
    }
    print(json.dumps(output))


def toggle() -> None:
    """Toggle hypridle on or off and send notification."""
    if get_pid(PROCESS):
        subprocess.run(["killall", PROCESS])
        notify("system-lock-screen", "Kahfein enabled!")
    else:
        subprocess.Popen([PROCESS])
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
