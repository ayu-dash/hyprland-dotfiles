"""
Rofi calculator module.
Launches rofi-calc for quick calculations.
"""

import subprocess
from pathlib import Path

from .Shared import ROFI_THEMES


THEME: Path = ROFI_THEMES / "Calculator"


def exec() -> None:
    """Launch the Rofi calculator."""
    subprocess.Popen([
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