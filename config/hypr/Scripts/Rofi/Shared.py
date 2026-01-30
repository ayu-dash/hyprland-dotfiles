"""
Shared configuration for Rofi theme modules.
Dynamically determines the theme directory based on environment variables.
"""

import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path.home() / ".config/hypr/Scripts"))
from Utils import get_theme_dir


def get_rofi_theme_dir() -> Path:
    """
    Get the Rofi theme directory path.
    Uses HYPR_THEME_DIR environment variable if set, otherwise falls back to utility.
    """
    theme_dir = os.environ.get("HYPR_THEME_DIR")

    if theme_dir:
        return Path(theme_dir) / "Rofi"

    return get_theme_dir() / "Rofi"


def get_current_theme_dir() -> Path:
    """Get the current theme directory."""
    theme_dir = os.environ.get("HYPR_THEME_DIR")
    if theme_dir:
        return Path(theme_dir)
    return get_theme_dir()


# Exported constants
ROFI_THEMES: Path = get_rofi_theme_dir()
current_theme_dir: Path = get_current_theme_dir()