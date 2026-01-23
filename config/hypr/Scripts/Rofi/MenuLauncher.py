"""
Rofi application launcher module.
Displays a drun menu for launching applications.
"""

import subprocess
from pathlib import Path

from .Shared import ROFI_THEMES


THEME: Path = ROFI_THEMES / "MenuLauncher"


def exec() -> None:
    """Launch the Rofi application menu."""
    subprocess.Popen([
        "rofi",
        "-show", "drun",
        "-theme", str(THEME)
    ])
