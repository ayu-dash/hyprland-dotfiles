"""
WiFi hotspot management module.
Provides functions to create, stop, and monitor a WiFi access point using create_ap.
"""

import argparse
import json
import subprocess
from pathlib import Path

from Utils import read_config, notify


CONFIG_PATH: Path = Path.home() / ".config/hypr/Configs/Hostpot.conf"
CONFIG: dict[str, str] | None = read_config(CONFIG_PATH)


def create_ap() -> None:
    """Create a WiFi access point using the configuration file."""
    if not CONFIG:
        notify("dialog-error", "Hotspot: Config file not found!", "critical")
        return

    if len(CONFIG.get("PASSWORD", "")) < 8:
        notify("dialog-error", "Hotspot: Password must be at least 8 characters!", "critical")
        return

    subprocess.Popen([
        "sudo", "create_ap",
        "--daemon",
        CONFIG["IFNAME"],
        CONFIG["IFNAME"],
        CONFIG["SSID"],
        CONFIG["PASSWORD"]
    ])

    print(json.dumps({
        "class": "connected",
        "text": " 󱜠",
        "tooltip": "Hotspot is running"
    }))

    notify("network-wireless", "Hotspot started successfully!")


def stop_ap() -> None:
    """Stop the running WiFi access point."""
    if CONFIG:
        subprocess.run(["sudo", "create_ap", "--stop", CONFIG["IFNAME"]])

    print(json.dumps({
        "class": "disconnected",
        "text": " 󱜡",
        "tooltip": "Hotspot is not running."
    }))

    notify("network-wireless", "Hotspot stopped successfully!")


def list_ap() -> list[str]:
    """List currently running access points."""
    result = subprocess.run(
        ["sudo", "create_ap", "--list-running"],
        capture_output=True,
        text=True
    )
    return result.stdout.strip().splitlines()


def toggle_ap() -> None:
    """Toggle the access point on or off."""
    if list_ap():
        stop_ap()
    else:
        create_ap()


def status_ap() -> None:
    """Print the current access point status in Waybar JSON format."""
    if list_ap():
        output = {
            "class": "connected",
            "text": " 󱜠",
            "tooltip": "Hotspot is running"
        }
    else:
        output = {
            "class": "disconnected",
            "text": " 󱜡",
            "tooltip": "Hotspot is not running."
        }

    print(json.dumps(output))


def main() -> None:
    """Parse arguments and execute the requested hotspot action."""
    parser = argparse.ArgumentParser(description="WiFi hotspot manager")
    parser.add_argument(
        "action",
        choices=["toggle", "status"],
        help="Hotspot action to perform"
    )

    args = parser.parse_args()

    match args.action:
        case "toggle":
            toggle_ap()
        case "status":
            status_ap()


if __name__ == "__main__":
    main()