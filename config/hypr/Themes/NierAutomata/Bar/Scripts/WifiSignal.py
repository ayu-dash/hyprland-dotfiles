"""
WiFi signal strength module for Waybar.
Displays connection status and signal strength icons.
"""

import json
import subprocess


def run_command(cmd: str) -> str:
    """Run shell command and return output."""
    try:
        result = subprocess.run(
            cmd,
            shell=True,
            capture_output=True,
            text=True,
            timeout=5
        )
        return result.stdout.strip()
    except (subprocess.TimeoutExpired, OSError):
        return ""


def get_wifi_info() -> tuple[int | None, str | None]:
    """Get current WiFi connection info (signal strength, SSID)."""
    output = run_command("nmcli -t -f IN-USE,SIGNAL,SSID dev wifi list 2>/dev/null")

    for line in output.split("\n"):
        if line.startswith("*"):
            parts = line.split(":")
            if len(parts) >= 3:
                signal = int(parts[1]) if parts[1].isdigit() else 0
                ssid = parts[2] if parts[2] else "Unknown"
                return signal, ssid

    return None, None


def check_ethernet() -> bool:
    """Check if ethernet is connected."""
    output = run_command("nmcli -t -f TYPE con show --active")
    return "ethernet" in output


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