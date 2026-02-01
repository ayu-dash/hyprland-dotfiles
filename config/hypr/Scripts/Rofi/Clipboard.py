"""
Rofi clipboard manager module.
Displays clipboard history with text and image mode switching.
"""

import subprocess
import sys
from pathlib import Path
from typing import TypedDict

sys.path.insert(0, str(Path.home() / ".config/hypr/Scripts"))
from Utils import run_silent, run_capture
from .Shared import ROFI_THEMES


CACHE_DIR: Path = Path("/tmp/cliphist_thumbs")
THEME_PATH: Path = ROFI_THEMES / "Clipboard"

TEXT_PREFIX: str = "󰝤  "
BTN_ICON: str = "view-list"


class ModeConfig(TypedDict):
    """Configuration for clipboard display modes."""
    hint: str
    prompt: str
    css: list[str]


MODES: dict[str, ModeConfig] = {
    "text": {
        "hint": "m   (Switch to Gallery Mode)",
        "prompt": "Clipboard",
        "css": ["-theme-str", "element-icon { size: 0px; }"]
    },
    "image": {
        "hint": f"m (Text Mode) \0icon\x1f{BTN_ICON}",
        "prompt": "Gallery",
        "css": [
            "-show-icons",
            "-theme-str", "listview { lines: 3; columns: 4; flow: horizontal; }",
            "-theme-str", "element { orientation: vertical; children: [element-icon]; padding: 6px; }"
        ]
    }
}


def ensure_cache() -> None:
    """Create the thumbnail cache directory if it doesn't exist."""
    CACHE_DIR.mkdir(parents=True, exist_ok=True)


def is_image_content(content: str) -> bool:
    """Check if the clipboard content is an image."""
    image_indicators = ("binary", "image", "png", "jpg")
    return any(indicator in content.lower() for indicator in image_indicators)


def generate_thumbnail(clip_id: str, output_path: Path) -> None:
    """Generate a thumbnail from clipboard image data."""
    try:
        p1 = subprocess.Popen(["cliphist", "decode", clip_id], stdout=subprocess.PIPE)
        p2 = subprocess.Popen(
            ["magick", "-", "-resize", "256x256", str(output_path)],
            stdin=p1.stdout,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
        if p1.stdout:
            p1.stdout.close()
        p2.wait()
    except (OSError, subprocess.SubprocessError):
        pass


def get_clipboard_history() -> list[str]:
    """Get the clipboard history from cliphist."""
    stdout, _, _ = run_capture(["cliphist", "list"])
    if not stdout:
        return []
    return stdout.strip().split("\n")


def prepare_data(mode: str, raw_lines: list[str]) -> tuple[list[str], list[str]]:
    """Prepare display lines and target data for the given mode."""
    display_lines: list[str] = [MODES[mode]["hint"]]
    target_data: list[str] = ["SWITCH_ACTION"]

    if mode == "image":
        ensure_cache()

    for line in raw_lines:
        parts = line.split("\t", 1)
        if len(parts) < 2:
            continue

        clip_id, content = parts[0], parts[1].strip().replace("\n", " ")
        is_img = is_image_content(content)

        if mode == "text" and not is_img:
            display_lines.append(f"{TEXT_PREFIX}{content}")
            target_data.append(line)

        elif mode == "image" and is_img:
            thumb_path = CACHE_DIR / f"{clip_id}.png"
            if not thumb_path.exists():
                generate_thumbnail(clip_id, thumb_path)

            if thumb_path.exists():
                display_lines.append(f"{content}\0icon\x1f{thumb_path}")
                target_data.append(line)

    return display_lines, target_data


def run_rofi(mode: str, display_lines: list[str]) -> str:
    """Run rofi with the prepared display lines."""
    cmd = [
        "rofi", "-dmenu", "-i",
        "-theme", str(THEME_PATH),
        "-format", "i",
        "-filter", "",
        "-no-custom",
        "-p", MODES[mode]["prompt"]
    ]
    cmd.extend(MODES[mode]["css"])

    result = subprocess.run(
        cmd,
        input="\n".join(display_lines),
        stdout=subprocess.PIPE,
        text=True
    )
    return result.stdout.strip()


def decode_and_copy(line: str) -> None:
    """Decode clipboard entry and copy to clipboard."""
    try:
        clip_id = line.split("\t", 1)[0]
        decoded = subprocess.run(["cliphist", "decode", clip_id], stdout=subprocess.PIPE)
        subprocess.run(["wl-copy"], input=decoded.stdout)
    except (OSError, subprocess.SubprocessError):
        pass


def exec() -> None:
    """Execute the clipboard manager with mode switching support."""
    current_mode = "text"

    while True:
        raw_lines = get_clipboard_history()
        display_lines, target_data = prepare_data(current_mode, raw_lines)

        selection_index = run_rofi(current_mode, display_lines)

        if not selection_index:
            break

        try:
            idx = int(selection_index)
            target = target_data[idx]

            if target == "SWITCH_ACTION":
                current_mode = "image" if current_mode == "text" else "text"
                continue

            decode_and_copy(target)
            break

        except (ValueError, IndexError):
            break