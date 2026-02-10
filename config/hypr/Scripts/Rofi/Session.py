"""
Rofi session management module.
Provides power options: lock, suspend, logout, reboot, shutdown.
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path.home() / ".config/hypr/Scripts"))
from Utils import run_bg, run_with_input
from .Shared import ROFI_THEMES


THEME: Path = ROFI_THEMES / "Session"

# Menu items: (display_label, command)
MENU_ITEMS: list[tuple[str, str]] = [
    ("   Lock", "loginctl lock-session"),
    ("   Suspend", "systemctl suspend"),
    ("   Logout", "hyprctl dispatch exit"),
    ("   Reboot", "systemctl reboot"),
    ("   Shutdown", "systemctl poweroff"),
]


def run_rofi() -> str:
    """Display the session menu and return the selected index."""
    display_lines = [label for label, _ in MENU_ITEMS]

    output, _ = run_with_input(
        [
            "rofi", "-dmenu", "-i",
            "-format", "i",
            "-theme", str(THEME)
        ],
        "\n".join(display_lines)
    )
    return output


def exec_command(cmd: str) -> None:
    """Execute a shell command in a new session."""
    try:
        run_bg(["sh", "-c", cmd], start_new_session=True)
    except OSError:
        pass


def exec() -> None:
    """Execute the session manager."""
    selection_index = run_rofi()

    if not selection_index:
        return

    try:
        idx = int(selection_index)
        _, command = MENU_ITEMS[idx]
        exec_command(command)

    except (ValueError, IndexError):
        pass