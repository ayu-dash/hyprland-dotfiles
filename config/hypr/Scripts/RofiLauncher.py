"""
Rofi launcher dispatcher module.
Routes rofi commands to appropriate sub-modules.
"""

import argparse

from Rofi import (
    MenuLauncher,
    WallpaperSelector,
    Calculator,
    Clipboard,
    Screenshot,
    EmojiPicker,
    Configuration,
    Session,
    ThemeSelector
)
from Utils import get_pid, kill_all, get_logger

log = get_logger("RofiLauncher")


PROCESS: str = "rofi"


def main() -> None:
    """Parse arguments and launch the appropriate Rofi module."""
    # Kill existing rofi instance if running
    if get_pid(PROCESS):
        kill_all(PROCESS)
        return

    parser = argparse.ArgumentParser(description="Rofi launcher dispatcher")
    parser.add_argument(
        "action",
        choices=["menu", "wall", "calc", "emoji", "clip", "cap", "config", "session", "theme"],
        help="Rofi module to launch"
    )

    args = parser.parse_args()

    match args.action:
        case "menu":
            MenuLauncher.exec()
        case "wall":
            WallpaperSelector.exec()
        case "calc":
            Calculator.exec()
        case "clip":
            Clipboard.exec()
        case "cap":
            Screenshot.exec()
        case "emoji":
            EmojiPicker.exec()
        case "config":
            Configuration.exec()
        case "session":
            Session.exec()
        case "theme":
            ThemeSelector.exec()


if __name__ == "__main__":
    main()
