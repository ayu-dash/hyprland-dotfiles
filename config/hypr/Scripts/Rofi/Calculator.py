"""
Rofi calculator module.
Launches rofi-calc for quick calculations.
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path.home() / ".config/hypr/Scripts"))
from Utils import run_bg
from .Shared import ROFI_THEMES


THEME: Path = ROFI_THEMES / "Calculator"


def exec() -> None:
    """Launch the Rofi calculator."""
    run_bg([
        "rofi",
        "-show", "calc",
        "-modi", "calc",
        "-no-show-match",
        "-no-sort",
        "-no-history",
        "-lines", "0",
        "-calc-command", "echo -n '{result}' | wl-copy --type text/plain",
        "-theme", str(THEME)
    ])