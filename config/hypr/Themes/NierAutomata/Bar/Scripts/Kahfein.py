"""
Kahfein (Caffeine) module for Waybar.
Prevents the system from going idle by toggling hypridle.
"""

import argparse
import json
import subprocess


PROCESS: str = "hypridle"


def get_pid(process: str) -> int | None:
    """Get PID of running process."""
    try:
        result = subprocess.run(
            ["pgrep", "-x", process],
            capture_output=True,
            text=True
        )
        if result.returncode == 0:
            return int(result.stdout.strip().split("\n")[0])
    except (ValueError, OSError):
        pass
    return None


def status() -> None:
    """Print Kahfein status in Waybar JSON format."""
    pid = get_pid(PROCESS)
    output = {
        "text": "󰛊" if pid else "󰅶",
        "tooltip": "Kahfein: Inactive" if pid else "Kahfein: Active",
        "class": "inactive" if pid else "active"
    }
    print(json.dumps(output))


def toggle() -> None:
    """Toggle hypridle on or off."""
    if get_pid(PROCESS):
        subprocess.run(["killall", PROCESS], capture_output=True)
    else:
        subprocess.Popen(
            [PROCESS],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )


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