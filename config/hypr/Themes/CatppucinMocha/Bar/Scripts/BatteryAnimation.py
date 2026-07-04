"""
Battery animation module for Waybar.
Displays battery icon with charging animation.
"""

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path.home() / ".config/hypr/Scripts"))
from Utils import read_file

# Simulation settings (for testing)
SIMULATE_CHARGING: bool = False
SIMULATE_LEVEL: int = 20

# Charging animation icons (empty to full)
CHARGING_ICONS: list[str] = ["󰢟", "󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅"]

# Battery level icons (not charging)
BATTERY_ICONS: list[str] = ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]

STATE_FILE: Path = Path("/tmp/battery_animation_frame")


def get_battery_info() -> tuple[str, int]:
    """Get battery status and level from system or simulation."""
    if (len(sys.argv) > 1 and sys.argv[1] == "sim") or SIMULATE_CHARGING:
        status = "Charging"
        level = int(sys.argv[2]) if len(sys.argv) > 2 else SIMULATE_LEVEL
    else:
        try:
            bat_path = next(Path("/sys/class/power_supply").glob("BAT*"))
            status = read_file(bat_path / "status").strip()
            level = int(read_file(bat_path / "capacity").strip())
        except (StopIteration, FileNotFoundError, ValueError):
            status = "Unknown"
            level = 0

    return status, level


def get_css_class(level: int, status: str) -> str:
    """Determine CSS class based on battery level and status."""
    if status == "Charging":
        return "charging"
    elif status == "Full":
        return "full"
    elif level <= 20:
        return "critical"
    elif level <= 40:
        return "warning"
    return "normal"


def get_charging_icon(level: int) -> str:
    """Get animated charging icon based on current frame."""
    start_index = min(level // 10, 10)

    # Read current frame
    if STATE_FILE.exists():
        try:
            frame = int(STATE_FILE.read_text().strip())
        except ValueError:
            frame = start_index
    else:
        frame = start_index

    # Ensure frame is not less than start index
    frame = max(frame, start_index)
    icon = CHARGING_ICONS[frame]

    # Update frame for next call
    next_frame = frame + 1 if frame < 10 else start_index
    STATE_FILE.write_text(str(next_frame))

    return icon


def main() -> None:
    """Generate Waybar-compatible battery output."""
    status, level = get_battery_info()
    start_index = min(level // 10, 10)

    if status == "Charging":
        icon = get_charging_icon(level)
        tooltip = f"Charging {level}%"
        css_class = "charging"
    elif status == "Full":
        icon = "󰂅"
        tooltip = "Fully Charged"
        css_class = "full"
        STATE_FILE.unlink(missing_ok=True)
    else:
        icon = BATTERY_ICONS[start_index]
        tooltip = f"Battery {level}%"
        css_class = get_css_class(level, status)
        STATE_FILE.unlink(missing_ok=True)

    output = {
        "text": icon,
        "tooltip": tooltip,
        "class": css_class,
        "percentage": level
    }

    print(json.dumps(output))


if __name__ == "__main__":
    main()