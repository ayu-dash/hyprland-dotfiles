"""
Rofi screenshot module.
Provides screen capture options and notification with edit action.
"""

import os
import subprocess
from pathlib import Path

from .Shared import ROFI_THEMES


THEME: Path = ROFI_THEMES / "Screenshot"
SHOOTER: str = "hyprshot"
EDITOR: str = "swappy"
TEMP_PATH: Path = Path("/tmp")
TEMP_FILE: str = "screenshot_temp.png"
FULL_TEMP_PATH: Path = TEMP_PATH / TEMP_FILE

# Screenshot mode options
OPTIONS: dict[str, str] = {
    "full": "󰊓",
    "region": "󰩬",
    "window": "󰖯"
}


def show_menu() -> str:
    """Display the screenshot mode selection menu."""
    choices = "\n".join(OPTIONS.values())
    result = subprocess.run(
        ["rofi", "-dmenu", "-theme", str(THEME)],
        input=choices.encode(),
        stdout=subprocess.PIPE
    )
    return result.stdout.decode().strip()


def send_notification() -> bool:
    """
    Send a notification with the screenshot preview.
    Returns True if the user clicked 'Edit'.
    """
    try:
        result = subprocess.run(
            [
                "notify-send",
                "-i", str(FULL_TEMP_PATH),
                "Screenshot Taken",
                "Click 'Edit' to open Swappy",
                "--action=edit=Edit",
                "--wait"
            ],
            stdout=subprocess.PIPE
        )
        return result.stdout.decode().strip() == "edit"

    except FileNotFoundError:
        return False


def exec() -> None:
    """Execute the screenshot workflow."""
    selected = show_menu()

    # Determine screenshot mode
    mode_map = {
        OPTIONS["full"]: "output",
        OPTIONS["region"]: "region",
        OPTIONS["window"]: "window"
    }

    mode = mode_map.get(selected)
    if not mode:
        return

    # Take screenshot
    subprocess.run([SHOOTER, "-m", mode, "-o", str(TEMP_PATH), "-f", TEMP_FILE])

    # Handle result
    if FULL_TEMP_PATH.exists():
        should_edit = send_notification()

        if should_edit:
            subprocess.run([EDITOR, "-f", str(FULL_TEMP_PATH)])
            FULL_TEMP_PATH.unlink(missing_ok=True)