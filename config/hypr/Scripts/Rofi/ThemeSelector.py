"""
Rofi theme selector module.
Displays available themes and activates the selected one.
"""

import os
import subprocess
from pathlib import Path

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

    result = subprocess.run(
        [
            "rofi", "-dmenu", "-i",
            "-p", "Select Theme",
            "-format", "i",
            "-lines", str(line_count),
            "-theme", str(THEME)
        ],
        input="\n".join(display_lines),
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True
    )

    if result.returncode != 0:
        return None

    output = result.stdout.strip()
    if not output:
        return None

    try:
        return items[int(output)]
    except (ValueError, IndexError):
        return None


def apply_theme(folder_name: str) -> None:
    """Activate the selected theme by running its Activate.sh script."""
    theme_path = THEME_DIR / folder_name
    script_path = theme_path / "Activate.sh"

    if not script_path.exists():
        subprocess.run(["notify-send", "Error", f"Activate.sh not found in {folder_name}"])
        return

    try:
        os.chmod(script_path, 0o755)
        subprocess.run([str(script_path)], check=True)
        subprocess.run(["notify-send", "Theme Applied", f"Active: {folder_name}"])

    except subprocess.CalledProcessError:
        subprocess.run(["notify-send", "Error", "Failed to run Activate.sh"])


def exec() -> None:
    """Execute the theme selector."""
    themes = get_themes_with_names()

    if not themes:
        subprocess.run(["notify-send", "Error", "No themes found!"])
        return

    selection = run_rofi(themes)

    if selection:
        apply_theme(selection[1])
