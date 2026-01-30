"""
Battery monitoring and notification module.
Watches battery status via D-Bus and sends low/critical battery alerts.
"""

import subprocess
from collections.abc import Generator
from pathlib import Path

from Utils import notify, read_file, get_logger

log = get_logger("Battery")


# Battery threshold levels
BATTERY_THRESHOLDS: dict[str, int] = {
    "low": 20,
    "critical": 10
}

ICON_DIR: Path = Path.home() / ".config/hypr/Themes/NierAutomata/Swaync/Icons"

# Track which notifications have been sent
notified: set[str] = set()


def watch_battery() -> Generator[tuple[str, int], None, None]:
    """
    Monitor battery changes via D-Bus.
    Yields (status, capacity) tuples when battery state changes.
    """
    process = subprocess.Popen(
        [
            "dbus-monitor", "--system",
            "type='signal',interface='org.freedesktop.DBus.Properties',"
            "path='/org/freedesktop/UPower/devices/battery_BAT0'"
        ],
        stdout=subprocess.PIPE,
        text=True,
        bufsize=1
    )

    if process.stdout is None:
        return

    for line in process.stdout:
        if "PropertiesChanged" in line:
            try:
                status = read_file("/sys/class/power_supply/BAT0/status").strip()
                capacity = int(read_file("/sys/class/power_supply/BAT0/capacity").strip())
                log.debug(f"Battery: {status} at {capacity}%")
                yield status, capacity
            except (FileNotFoundError, ValueError) as e:
                log.error(f"Error reading battery info: {e}")
                continue


def get_battery_icon(value: int) -> str:
    """Get the appropriate battery icon based on level."""
    if value <= BATTERY_THRESHOLDS["critical"]:
        return str(ICON_DIR / "battery-critical.png")
    return str(ICON_DIR / "battery-low.png")


def send_notification(status: str, capacity: int) -> None:
    """Send battery notification based on status and capacity."""
    global notified

    if status == "Discharging":
        if capacity <= BATTERY_THRESHOLDS["critical"] and "critical" not in notified:
            log.warning(f"Battery critical: {capacity}%")
            notify(
                get_battery_icon(capacity),
                f"Battery Critical! {capacity}%. Plug in charger now!",
                level="critical"
            )
            notified.add("critical")
        elif capacity <= BATTERY_THRESHOLDS["low"] and "low" not in notified:
            log.info(f"Battery low: {capacity}%")
            notify(
                get_battery_icon(capacity),
                f"Battery Low! {capacity}%. Consider plugging in the charger.",
                level="normal"
            )
            notified.add("low")

    elif status == "Charging":
        if notified:
            log.info("Charger connected, clearing notifications")
        notified.clear()


def main() -> None:
    """Main loop: watch battery and send notifications."""
    log.info("Battery monitor started")
    for status, capacity in watch_battery():
        send_notification(status, capacity)


if __name__ == "__main__":
    main()
