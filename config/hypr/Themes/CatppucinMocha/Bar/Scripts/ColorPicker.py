"""
Color Picker module for Waybar using hyprpicker.
Pick colors from screen and copy to clipboard.
"""

import argparse
import json
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path.home() / ".config/hypr/Scripts"))
from Utils import notify

# Available color formats
FORMATS = ["hex", "rgb", "hsl", "hsv", "cmyk"]


def pick_color(
    fmt: str = "hex",
    autocopy: bool = True,
    lowercase: bool = True,
    no_zoom: bool = False
) -> str | None:
    """Pick a color from screen using hyprpicker."""
    cmd = ["hyprpicker"]

    # Format option
    if fmt in FORMATS:
        cmd.extend(["-f", fmt])

    # Autocopy to clipboard
    if autocopy:
        cmd.append("-a")

    # Lowercase hex output
    if lowercase and fmt == "hex":
        cmd.append("-l")

    # Disable zoom lens
    if no_zoom:
        cmd.append("-z")

    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=60  # Timeout after 60 seconds
        )

        color = result.stdout.strip()
        if color:
            return color
        return None

    except subprocess.TimeoutExpired:
        notify("dialog-error", "Color Picker: Timeout")
        return None
    except FileNotFoundError:
        notify("dialog-error", "Color Picker: hyprpicker not found")
        return None


def pick_and_notify(fmt: str = "hex", lowercase: bool = True) -> None:
    """Pick color and show notification."""
    color = pick_color(fmt=fmt, autocopy=True, lowercase=lowercase)

    if color:
        notify("color-select", f"Copied: {color}")
    else:
        notify("dialog-warning", "Color Picker: Cancelled")


def output_waybar() -> None:
    """Generate Waybar-compatible JSON output."""
    output = {
        "text": "󰈋",
        "tooltip": "Color Picker (click to pick)",
        "class": "colorpicker"
    }
    print(json.dumps(output))


def main() -> None:
    """Parse arguments and execute color picker."""
    parser = argparse.ArgumentParser(
        description="Color Picker using hyprpicker"
    )
    parser.add_argument(
        "action",
        nargs="?",
        default="pick",
        choices=["pick", "status"] + FORMATS,
        help="Action or format to use"
    )
    parser.add_argument(
        "-f", "--format",
        choices=FORMATS,
        default="hex",
        help="Color format (default: hex)"
    )
    parser.add_argument(
        "-u", "--uppercase",
        action="store_true",
        help="Output hex in uppercase"
    )
    parser.add_argument(
        "-z", "--no-zoom",
        action="store_true",
        help="Disable zoom lens"
    )

    args = parser.parse_args()

    if args.action == "status":
        output_waybar()
    elif args.action in FORMATS:
        # Direct format selection
        pick_and_notify(fmt=args.action, lowercase=not args.uppercase)
    else:  # pick
        pick_and_notify(fmt=args.format, lowercase=not args.uppercase)


if __name__ == "__main__":
    main()
