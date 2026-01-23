"""
Rofi emoji picker module.
Launches rofi-emoji for quick emoji selection.
"""

import subprocess
from pathlib import Path

from .Shared import ROFI_THEMES


THEME: Path = ROFI_THEMES / "EmojiPicker"


def exec() -> None:
    """Launch the Rofi emoji picker."""
    subprocess.run([
        "rofi",
        "-modi", "emoji",
        "-show", "emoji",
        "-emoji-format", "{emoji}",
        "-kb-secondary-copy", "",
        "-kb-custom-1", "Ctrl+c",
        "-theme", str(THEME)
    ])