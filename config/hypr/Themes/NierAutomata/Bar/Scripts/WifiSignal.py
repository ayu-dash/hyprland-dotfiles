"""
WiFi signal strength module for Waybar.
Displays connection status and signal strength icons.
"""

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path.home() / ".config/hypr/Scripts"))
from Utils import run_capture


def get_wifi_info() -> tuple[int | None, str | None]:
    """Get current WiFi connection info (signal strength, SSID) using iwd."""
    stdout, _, returncode = run_capture(["iwctl", "station", "wlan0", "show"])

    if returncode != 0 or not stdout:
        return None, None

    ssid = None
    signal = None

    for line in stdout.split("\n"):
        line = line.strip()
        if "Connected network" in line:
            # Format: "Connected network              SSID_NAME"
            parts = line.split()
            if len(parts) >= 3:
                ssid = " ".join(parts[2:])
        elif "RSSI" in line:
            # Format: "RSSI                          -XX dBm"
            parts = line.split()
            for i, part in enumerate(parts):
                if part.startswith("-") and part[1:].isdigit():
                    rssi = int(part)
                    # Convert RSSI (dBm) to percentage (rough approximation)
                    # -30 dBm = 100%, -90 dBm = 0%
                    signal = max(0, min(100, 2 * (rssi + 100)))
                    break

    if ssid and signal is not None:
        return signal, ssid

    return None, None


def check_ethernet() -> bool:
    """Check if ethernet is connected via /sys/class/net."""
    eth_interfaces = ["eth0", "enp0s31f6", "eno1"]
    for iface in eth_interfaces:
        operstate_path = Path(f"/sys/class/net/{iface}/operstate")
        if operstate_path.exists():
            try:
                state = operstate_path.read_text().strip()
                if state == "up":
                    return True
            except (OSError, IOError):
                continue
    return False


def get_signal_icon(signal: int) -> tuple[str, str]:
    """Get icon and CSS class based on signal strength."""
    if signal >= 80:
        return "󰤨", "excellent"
    elif signal >= 60:
        return "󰤥", "good"
    elif signal >= 40:
        return "󰤢", "fair"
    elif signal >= 20:
        return "󰤟", "weak"
    return "󰤯", "very-weak"


def main() -> None:
    """Generate Waybar-compatible network status output."""
    signal, ssid = get_wifi_info()

    if signal is None:
        # No WiFi, check ethernet
        if check_ethernet():
            output = {
                "text": "󰈀",
                "tooltip": "Ethernet",
                "class": "ethernet"
            }
        else:
            output = {
                "text": "󰤭",
                "tooltip": "Disconnected",
                "class": "disconnected"
            }
    else:
        icon, css_class = get_signal_icon(signal)
        output = {
            "text": icon,
            "tooltip": f"{ssid} ({signal}%)",
            "class": css_class
        }

    print(json.dumps(output))


if __name__ == "__main__":
    main()