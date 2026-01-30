"""
Rofi configuration file browser module.
Displays config files and opens them in the editor.
"""

import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path.home() / ".config/hypr/Scripts"))
from Utils import run_bg, run_capture
from .Shared import ROFI_THEMES


CONFIG_DIR: Path = Path.home() / ".config/hypr/Configs"
THEME: Path = ROFI_THEMES / "Configuration"
EDITOR: str = "code"

# Icon mapping for specific config files
ICON_MAP: dict[str, str] = {
    "Monitors.conf": " ",
    "KeyBinds.conf": " ",
    "WindowRules.conf": " ",
    "Envs.conf": " ",
    "Cursors.conf": " ",
    "AutoStartApps.conf": " ",
    "Inputs.conf": " ",
    "Hostpot.conf": " ",
}


def get_dir_items() -> list[tuple[str, str]]:
    """Scan the config directory and return display items."""
    if not CONFIG_DIR.exists():
        return []

    items: list[tuple[str, str]] = []

    try:
        for item in sorted(CONFIG_DIR.iterdir()):
            if item.name.startswith("."):
                continue

            # Determine icon
            if item.name in ICON_MAP:
                icon = ICON_MAP[item.name]
            elif item.is_dir():
                icon = " "
            else:
                icon = " "

            display_text = f"{icon}  {item.name}"
            items.append((display_text, item.name))

    except OSError:
        pass

    return items


def run_rofi(items: list[tuple[str, str]]) -> str:
    """Run rofi with the prepared items."""
    display_lines = [x[0] for x in items]

    result = subprocess.run(
        [
            "rofi", "-dmenu", "-i",
            "-format", "i",
            "-theme", str(THEME)
        ],
        input="\n".join(display_lines),
        stdout=subprocess.PIPE,
        text=True
    )
    return result.stdout.strip()


def exec() -> None:
    """Execute the configuration browser."""
    items = get_dir_items()
    if not items:
        return

    selection_index = run_rofi(items)

    if not selection_index:
        return

    try:
        idx = int(selection_index)
        selected_file = items[idx][1]
        target_path = CONFIG_DIR / selected_file

        if target_path.exists():
            run_bg([EDITOR, str(target_path)], start_new_session=True)

    except (ValueError, IndexError):
        pass
