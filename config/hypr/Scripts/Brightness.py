"""
Screen brightness control module.
Provides functions for adjusting brightness and sending notifications.
"""

import argparse
from pathlib import Path

from Utils import notify_with_progress, get_logger, run_capture, run_silent, get_theme_dir

log = get_logger("Brightness")


DEFAULT_STEP: int = 10

ICON_DIR: Path = get_theme_dir() / "Swaync/Icons"


def get_brightness_percentage() -> int:
    """Get current screen brightness as a percentage."""
    stdout, _, _ = run_capture(["brightnessctl", "-m"])
    try:
        # Output format: device,class,current,max%,current
        # The percentage is at index 3 (e.g., "100%")
        parts = stdout.split(",")
        percentage_str = parts[3].rstrip("%")
        return int(percentage_str)
    except (IndexError, ValueError):
        return 50  # Default fallback


def get_brightness_icon(value: int) -> str:
    """Get the appropriate brightness icon based on level."""
    if value <= 60:
        return str(ICON_DIR / "brightness-low.png")
    elif value <= 80:
        return str(ICON_DIR / "brightness-medium.png")
    return str(ICON_DIR / "brightness-high.png")


def adjust_brightness(step: int, action: str = "up") -> None:
    """Adjust screen brightness by the specified step amount."""
    old_value = get_brightness_percentage()
    adjustment = f"{step}%+" if action == "up" else f"{step}%-"
    run_silent(["brightnessctl", "s", adjustment])

    new_value = get_brightness_percentage()
    log.debug(f"Brightness {action}: {old_value}% -> {new_value}%")
    icon = get_brightness_icon(new_value)
    notify_with_progress(icon, f"Brightness Level: {new_value}%", new_value, level="critical")


def main() -> None:
    """Parse arguments and execute the requested brightness action."""
    parser = argparse.ArgumentParser(description="Brightness control utility")
    parser.add_argument(
        "action",
        choices=["up", "down"],
        help="Brightness action to perform"
    )
    parser.add_argument(
        "--step",
        type=int,
        default=DEFAULT_STEP,
        help="Brightness adjustment step (default: 10)"
    )

    args = parser.parse_args()

    match args.action:
        case "up":
            adjust_brightness(args.step, "up")
        case "down":
            adjust_brightness(args.step, "down")


if __name__ == "__main__":
    main()