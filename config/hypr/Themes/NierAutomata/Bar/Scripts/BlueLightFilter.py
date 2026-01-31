"""
Blue Light Filter module for Waybar using hyprsunset.
Controls screen color temperature to reduce eye strain.
"""

import argparse
import json
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path.home() / ".config/hypr/Scripts"))
from Utils import getPid, killAll, notify

# Temperature presets (in Kelvin)
TEMP_OFF = 6500       # Neutral daylight (no filter)
TEMP_LOW = 5500       # Subtle warmth for daytime
TEMP_MEDIUM = 4500    # Comfortable evening use
TEMP_HIGH = 3500      # Strong night mode
TEMP_EXTREME = 2500   # Maximum eye protection

PRESETS = {
    "off": TEMP_OFF,
    "low": TEMP_LOW,
    "medium": TEMP_MEDIUM,
    "high": TEMP_HIGH,
    "extreme": TEMP_EXTREME,
}


STATE_FILE = Path("/tmp/bluelight_temp")


def save_state(temp: int) -> None:
    """Save current temperature to state file."""
    STATE_FILE.write_text(str(temp))


def load_state() -> int | None:
    """Load temperature from state file."""
    try:
        if STATE_FILE.exists():
            return int(STATE_FILE.read_text().strip())
    except (ValueError, OSError):
        pass
    return None


def get_current_status() -> tuple[bool, int]:
    """Check if hyprsunset is running and get current temperature."""
    pid = getPid("hyprsunset")
    if not pid:
        return False, TEMP_OFF

    # Try to load from state file first
    saved_temp = load_state()
    if saved_temp is not None:
        return True, saved_temp

    # Fallback: try to read from process arguments
    try:
        result = subprocess.run(
            ["ps", "-p", pid, "-o", "args="],
            capture_output=True,
            text=True
        )
        args = result.stdout.strip()
        if "-t" in args:
            parts = args.split()
            for i, part in enumerate(parts):
                if part == "-t" and i + 1 < len(parts):
                    return True, int(parts[i + 1])
    except (ValueError, IndexError):
        pass

    return True, TEMP_MEDIUM


def set_temperature(temp: int) -> None:
    """Set the color temperature using hyprsunset."""
    killAll("hyprsunset")

    if temp >= TEMP_OFF:
        # Remove state file when turning off
        if STATE_FILE.exists():
            STATE_FILE.unlink()
        notify("weather-clear", "Blue Light Filter: Off")
        return

    # Save current temperature to state file
    save_state(temp)

    subprocess.Popen(
        ["hyprsunset", "-t", str(temp)],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL
    )

    # Determine preset name for notification
    preset_name = "Custom"
    for name, preset_temp in PRESETS.items():
        if temp == preset_temp:
            preset_name = name.capitalize()
            break


    notify("weather-clear-night", f"Blue Light Filter: {preset_name} ({temp}K)")


def toggle() -> None:
    """Toggle blue light filter on/off."""
    # Use state file for consistency (more reliable than process detection)
    saved_temp = load_state()

    if saved_temp is not None:
        # Filter is on, turn it off
        set_temperature(TEMP_OFF)
    else:
        # Filter is off, turn it on at medium level
        set_temperature(TEMP_MEDIUM)


def cycle() -> None:
    """Cycle through temperature presets."""
    # Define cycle order (coolest to warmest)
    cycle_temps = [TEMP_OFF, TEMP_LOW, TEMP_MEDIUM, TEMP_HIGH, TEMP_EXTREME]

    # Get current state from file (more reliable than process detection)
    saved_temp = load_state()

    if saved_temp is None:
        # No state file means filter is off, start from Low
        next_temp = TEMP_LOW
    else:
        # Find nearest preset and move to next
        nearest_idx = 0
        min_diff = abs(saved_temp - cycle_temps[0])

        for i, temp in enumerate(cycle_temps):
            diff = abs(saved_temp - temp)
            if diff < min_diff:
                min_diff = diff
                nearest_idx = i

        next_idx = (nearest_idx + 1) % len(cycle_temps)
        next_temp = cycle_temps[next_idx]

    set_temperature(next_temp)


def increase() -> None:
    """Increase filter strength (warmer/lower temperature)."""
    _, current_temp = get_current_status()

    # Preset levels from coolest to warmest
    levels = [TEMP_OFF, TEMP_LOW, TEMP_MEDIUM, TEMP_HIGH, TEMP_EXTREME]

    # Find next warmer level
    for i, level in enumerate(levels):
        if current_temp >= level:
            if i + 1 < len(levels):
                set_temperature(levels[i + 1])
            return

    set_temperature(TEMP_LOW)


def decrease() -> None:
    """Decrease filter strength (cooler/higher temperature)."""
    is_active, current_temp = get_current_status()

    if not is_active:
        return  # Already off

    # Preset levels from coolest to warmest
    levels = [TEMP_OFF, TEMP_LOW, TEMP_MEDIUM, TEMP_HIGH, TEMP_EXTREME]

    # Find next cooler level
    for i in range(len(levels) - 1, -1, -1):
        if current_temp <= levels[i]:
            if i - 1 >= 0:
                set_temperature(levels[i - 1])
            else:
                set_temperature(TEMP_OFF)
            return

    set_temperature(TEMP_OFF)


def get_icon(temp: int) -> str:
    """Get appropriate icon based on temperature."""
    if temp >= TEMP_OFF:
        return "󰖙"   # Sun (no filter)
    elif temp >= TEMP_LOW:
        return "󰖚"   # Partly cloudy
    elif temp >= TEMP_MEDIUM:
        return "󰖛"   # Cloudy sun
    elif temp >= TEMP_HIGH:
        return "󰖔"   # Night
    return "󰖕"       # Moon (maximum warmth)


def get_css_class(temp: int) -> str:
    """Get CSS class based on temperature level."""
    if temp >= TEMP_OFF:
        return "off"
    elif temp >= TEMP_LOW:
        return "low"
    elif temp >= TEMP_MEDIUM:
        return "medium"
    elif temp >= TEMP_HIGH:
        return "high"
    return "extreme"


def output_waybar() -> None:
    """Generate Waybar-compatible JSON output."""
    is_active, temp = get_current_status()

    if not is_active:
        temp = TEMP_OFF

    icon = get_icon(temp)
    css_class = get_css_class(temp)

    # Determine preset name
    preset_name = "Off" if temp >= TEMP_OFF else "Custom"
    for name, preset_temp in PRESETS.items():
        if temp == preset_temp:
            preset_name = name.capitalize()
            break

    tooltip = f"Blue Light Filter: {preset_name}"
    if temp < TEMP_OFF:
        tooltip += f" ({temp}K)"

    output = {
        "text": icon,
        "tooltip": tooltip,
        "class": css_class
    }

    print(json.dumps(output))


def main() -> None:
    """Parse arguments and execute appropriate action."""
    parser = argparse.ArgumentParser(
        description="Blue Light Filter control using hyprsunset"
    )
    parser.add_argument(
        "action",
        nargs="?",
        default="status",
        choices=["toggle", "cycle", "increase", "decrease", "on", "off", "status", "low", "medium", "high", "extreme"],
        help="Action to perform"
    )
    parser.add_argument(
        "-t", "--temperature",
        type=int,
        help="Set custom temperature (2500-6500K)"
    )

    args = parser.parse_args()

    if args.temperature:
        # Clamp temperature to valid range
        temp = max(2500, min(6500, args.temperature))
        set_temperature(temp)
    elif args.action == "toggle":
        toggle()
    elif args.action == "cycle":
        cycle()
    elif args.action == "increase":
        increase()
    elif args.action == "decrease":
        decrease()
    elif args.action == "on":
        set_temperature(TEMP_MEDIUM)
    elif args.action == "off":
        set_temperature(TEMP_OFF)
    elif args.action == "low":
        set_temperature(TEMP_LOW)
    elif args.action == "medium":
        set_temperature(TEMP_MEDIUM)
    elif args.action == "high":
        set_temperature(TEMP_HIGH)
    elif args.action == "extreme":
        set_temperature(TEMP_EXTREME)
    else:  # status
        output_waybar()


if __name__ == "__main__":
    main()
