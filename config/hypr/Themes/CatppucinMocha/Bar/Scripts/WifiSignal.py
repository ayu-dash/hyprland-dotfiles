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


def check_network() -> tuple[str | None, str | None, str | None]:
    """Check active network interfaces via /sys/class/net.
    Returns (icon, type_name, iface_name) or (None, None, None).
    """
    net_dir = Path("/sys/class/net")
    if not net_dir.exists():
        return None, None, None

    # (prefix_tuple, type_name, icon, priority)
    types = [
        (("en", "eth"),           "Ethernet", "󰈀", 1),
        (("tun", "wg"),           "VPN",      "󰦝", 2),
        (("br", "virbr"),         "Bridge",   "󰌗", 3),
        (("vnet", "tap", "veth"), "NAT",      "󰛳", 4),
        (("docker", "podman"),    "Container","󰡨", 5),
    ]

    found = []
    for iface_path in net_dir.iterdir():
        name = iface_path.name
        if name in ("lo",) or name.startswith(("wl", "wlan")):
            continue
        try:
            state = (iface_path / "operstate").read_text().strip()
        except (OSError, IOError):
            continue
        if state != "up":
            continue
        for prefixes, type_name, icon, priority in types:
            if name.startswith(prefixes):
                found.append((icon, type_name, name, priority))
                break
        else:
            found.append(("󰛳", "Network", name, 99))

    if not found:
        return None, None, None

    found.sort(key=lambda x: x[3])
    return found[0][0], found[0][1], found[0][2]


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
        # No WiFi, check other interfaces
        icon, type_name, iface_name = check_network()
        if icon:
            output = {
                "text": icon,
                "tooltip": f"{type_name}: {iface_name}",
                "class": type_name.lower()
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