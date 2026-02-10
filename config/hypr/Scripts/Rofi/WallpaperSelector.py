"""
Rofi wallpaper selector module.
Displays available wallpapers and sets the selected one.
"""

import glob
import sys
from pathlib import Path

sys.path.insert(0, str(Path.home() / ".config/hypr/Scripts"))
import Wallpaper
from Utils import run_with_input
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

    output, _ = run_with_input(
        ["rofi", "-dmenu", "-theme", str(THEME), "-markup-rows", "-i", "-p", " "],
        menu_items
    )

    return items.get(output) if output else None


def exec() -> None:
    """Execute the wallpaper selector and apply the selected wallpaper."""
    selected = show_menu()
    if selected:
        Wallpaper.set_wallpaper(selected)
