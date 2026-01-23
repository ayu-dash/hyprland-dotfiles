"""
Rofi wallpaper selector module.
Displays available wallpapers and sets the selected one.
"""

import glob
import subprocess
from pathlib import Path

import Wallpaper
from .Shared import ROFI_THEMES, current_theme_dir


THEME: Path = ROFI_THEMES / "WallpaperSelector"
WALLPAPER_DIR: Path = current_theme_dir / "Wallpapers"
EXTENSIONS: tuple[str, ...] = ("*.jpg", "*.jpeg", "*.png", "*.gif")


def get_wallpapers() -> list[Path]:
    """Get all wallpaper files from the wallpaper directory."""
    return [
        Path(f)
        for ext in EXTENSIONS
        for f in glob.glob(str(WALLPAPER_DIR / ext))
    ]


def get_menu_items() -> dict[str, str]:
    """Create a mapping of display names to file paths."""
    wallpapers = get_wallpapers()
    return {wal.name: str(wal) for wal in wallpapers}


def show_menu() -> str | None:
    """Display the wallpaper selection menu and return the selected path."""
    items = get_menu_items()
    menu_items = "\n".join(f"{k}\0icon\x1f{v}" for k, v in items.items())

    result = subprocess.run(
        ["rofi", "-dmenu", "-theme", str(THEME), "-markup-rows", "-i", "-p", " "],
        input=menu_items,
        text=True,
        capture_output=True
    )

    selection = result.stdout.strip()
    return items.get(selection) if selection else None


def exec() -> None:
    """Execute the wallpaper selector and apply the selected wallpaper."""
    selected = show_menu()
    if selected:
        Wallpaper.set_wallpaper(selected)
