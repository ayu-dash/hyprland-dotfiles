"""
Rofi emoji picker module.
Launches rofi-emoji for quick emoji selection.
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path.home() / ".config/hypr/Scripts"))
from Utils import run_silent
from .Shared import ROFI_THEMES


THEME: Path = ROFI_THEMES / "EmojiPicker"


def exec() -> None:
    """Launch the Rofi emoji picker."""
    run_silent([
        "rofi",
        "-modi", "emoji",
        "-show", "emoji",
        "-emoji-format", "{emoji}",
        "-kb-secondary-copy", "",
        "-kb-custom-1", "Ctrl+c",
        "-theme", str(THEME)
    ])