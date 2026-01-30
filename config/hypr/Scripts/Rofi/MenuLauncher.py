"""
Rofi application launcher module.
Displays a drun menu for launching applications.
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path.home() / ".config/hypr/Scripts"))
from Utils import run_bg
from .Shared import ROFI_THEMES


THEME: Path = ROFI_THEMES / "MenuLauncher"


def exec() -> None:
    """Launch the Rofi application menu."""
    run_bg([
        "rofi",
        "-show", "drun",
        "-theme", str(THEME)
    ])
