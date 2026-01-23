"""
Shared configuration for Rofi theme modules.
Dynamically determines the theme directory based on environment variables.
"""

import os
from pathlib import Path


def get_rofi_theme_dir() -> Path:
    """
    Get the Rofi theme directory path.
    Uses HYPR_THEME_DIR environment variable if set, otherwise falls back to default.
    """
    theme_dir = os.environ.get("HYPR_THEME_DIR")

    if theme_dir:
        return Path(theme_dir) / "Rofi"

    return Path.home() / ".config/hypr/Themes/NierAutomata/Rofi"


def get_current_theme_dir() -> Path | None:
    """Get the current theme directory from environment variable."""
    theme_dir = os.environ.get("HYPR_THEME_DIR")
    return Path(theme_dir) if theme_dir else None


# Exported constants
ROFI_THEMES: Path = get_rofi_theme_dir()
current_theme_dir: Path = get_current_theme_dir() or Path.home() / ".config/hypr/Themes/NierAutomata"