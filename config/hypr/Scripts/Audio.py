"""
Audio volume and microphone control module.
Provides functions for adjusting volume, muting, and sending notifications.
"""

import argparse
import subprocess
from pathlib import Path
from typing import TypedDict

from Utils import notify, notify_with_progress, get_logger

log = get_logger("Audio")


# Constants
MIN_VOLUME: int = 0
MAX_VOLUME: int = 100
DEFAULT_STEP: int = 5

ICON_DIR: Path = Path.home() / ".config/hypr/Themes/NierAutomata/Swaync/Icons"


class VolumeInfo(TypedDict):
    """Type definition for volume information."""
    value: int
    muted: bool


def get_volume() -> VolumeInfo:
    """Get current volume level and mute status."""
    result = subprocess.run(
        ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"],
        capture_output=True,
        text=True
    )
    parts = result.stdout.strip().split()

    is_muted = "[MUTED]" in parts
    current_volume = int(float(parts[1]) * 100)

    return {"value": current_volume, "muted": is_muted}


def is_mic_muted() -> bool:
    """Check if the microphone is muted."""
    result = subprocess.run(
        ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"],
        capture_output=True,
        text=True
    )
    return "[MUTED]" in result.stdout


def get_volume_icon(value: int, is_muted: bool) -> str:
    """Get the appropriate volume icon based on level and mute status."""
    if value == 0 or is_muted:
        return str(ICON_DIR / "volume-mute.png")
    elif value <= 30:
        return str(ICON_DIR / "volume-low.png")
    elif value <= 60:
        return str(ICON_DIR / "volume-medium.png")
    return str(ICON_DIR / "volume-high.png")


def get_mic_icon(is_muted: bool) -> str:
    """Get the appropriate microphone icon based on mute status."""
    icon_name = "mic-off.png" if is_muted else "mic-on.png"
    return str(ICON_DIR / icon_name)


def audio_unmute() -> None:
    """Unmute the audio sink."""
    subprocess.run(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "0"])


def audio_mute_toggle() -> None:
    """Toggle audio mute and send notification."""
    volume_info = get_volume()
    subprocess.run(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])

    status = "Muted" if not volume_info["muted"] else "Unmuted"
    log.info(f"Audio {status.lower()} (volume: {volume_info['value']}%)")
    icon = get_volume_icon(volume_info["value"], not volume_info["muted"])
    notify(icon, f"Volume is {status}", level="critical")


def mic_mute_toggle() -> None:
    """Toggle microphone mute and send notification."""
    was_muted = is_mic_muted()
    subprocess.run(["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"])

    status = "Unmuted" if was_muted else "Muted"
    log.info(f"Microphone {status.lower()}")
    icon = get_mic_icon(not was_muted)
    notify(icon, f"Microphone is {status}", level="critical")


def adjust_volume(step: int, action: str = "raise") -> None:
    """Adjust volume by the specified step amount."""
    volume_info = get_volume()

    if action == "raise":
        new_volume = min(volume_info["value"] + step, MAX_VOLUME)
    else:
        new_volume = max(volume_info["value"] - step, MIN_VOLUME)

    audio_unmute()
    subprocess.run(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", f"{new_volume}%"])
    log.debug(f"Volume {action}: {volume_info['value']}% -> {new_volume}%")

    icon = get_volume_icon(new_volume, False)
    notify_with_progress(icon, f"Volume Level: {new_volume}%", new_volume, level="critical")


def main() -> None:
    """Parse arguments and execute the requested audio action."""
    parser = argparse.ArgumentParser(description="Audio control utility")
    parser.add_argument(
        "action",
        choices=["raiseVolume", "lowerVolume", "muteToggle", "micToggle"],
        help="Audio action to perform"
    )
    parser.add_argument(
        "--step",
        type=int,
        default=DEFAULT_STEP,
        help="Volume adjustment step (default: 5)"
    )

    args = parser.parse_args()

    match args.action:
        case "raiseVolume":
            adjust_volume(args.step, "raise")
        case "lowerVolume":
            adjust_volume(args.step, "lower")
        case "muteToggle":
            audio_mute_toggle()
        case "micToggle":
            mic_mute_toggle()


if __name__ == "__main__":
    main()
