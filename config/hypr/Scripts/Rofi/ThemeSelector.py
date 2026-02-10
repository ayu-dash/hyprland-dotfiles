"""
Rofi theme selector module.
Displays available themes and activates the selected one.
"""

import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path.home() / ".config/hypr/Scripts"))
from Utils import run_silent, notify, run_with_input
from .Shared import ROFI_THEMES


THEME_DIR: Path = Path.home() / ".config/hypr/Themes"
THEME: Path = ROFI_THEMES / "ThemeSelector"


def get_themes_with_names() -> list[tuple[str, str]]:
    """
    Get available themes with their display names.
    Returns list of (display_name, folder_name) tuples.
    """
    if not THEME_DIR.exists():
        return []

    themes: list[tuple[str, str]] = []

    try:
        for folder in sorted(THEME_DIR.iterdir()):
            if folder.name.startswith(".") or not folder.is_dir():
                continue

            # Try to read custom display name from Name.txt
            display_name = folder.name
            name_file = folder / "Name.txt"

            if name_file.exists():
                try:
                    content = name_file.read_text(encoding="utf-8").strip()
                    if content:
                        display_name = content.split("\n")[0]
                except (OSError, UnicodeDecodeError):
                    pass

            themes.append((display_name, folder.name))

    except OSError:
        return []

    return themes


def run_rofi(items: list[tuple[str, str]]) -> tuple[str, str] | None:
    """Run rofi and return the selected theme."""
    if not items:
        return None

    display_lines = [x[0] for x in items]
    line_count = min(len(items), 15)

    output, returncode = run_with_input(
        [
            "rofi", "-dmenu", "-i",
            "-p", "Select Theme",
            "-format", "i",
            "-lines", str(line_count),
            "-theme", str(THEME)
        ],
        "\n".join(display_lines)
    )

    if returncode != 0:
        return None

    if not output:
        return None

    try:
        return items[int(output)]
    except (ValueError, IndexError):
        return None


def apply_theme(folder_name: str) -> None:
    """Activate the selected theme by running its Activate script."""
    theme_path = THEME_DIR / folder_name
    
    sh_script = theme_path / "Activate.sh"
    
    if sh_script.exists():
        os.chmod(sh_script, 0o755)
        result = run_silent([str(sh_script)])
        if result == 0:
            notify("preferences-desktop-theme", f"Theme Applied: {folder_name}")
            return
    
    notify("dialog-error", f"No activation script found in {folder_name}")


def exec() -> None:
    """Execute the theme selector."""
    themes = get_themes_with_names()

    if not themes:
        notify("dialog-error", "No themes found!")
        return

    selection = run_rofi(themes)

    if selection:
        apply_theme(selection[1])
