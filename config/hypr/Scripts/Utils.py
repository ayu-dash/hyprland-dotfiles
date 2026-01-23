"""
Utility functions for Hyprland scripts.
Provides common helpers for notifications, file operations, and process management.
"""

import json
import subprocess
from pathlib import Path
from typing import Any


def notify(icon: str, msg: str, level: str = "low") -> None:
    """Send a desktop notification using notify-send."""
    subprocess.run([
        "notify-send",
        "-e",
        "-a", "volume-notify",
        "-h", "string:x-canonical-private-synchronous:sys_notif",
        "-u", level,
        "-i", icon,
        msg
    ])


def notify_with_progress(icon: str, msg: str, value: int, level: str = "low") -> None:
    """Send a desktop notification with a progress bar."""
    subprocess.run([
        "notify-send",
        "-e",
        "-h", f"int:value:{value}",
        "-h", "string:x-canonical-private-synchronous:sys_notif",
        "-c", "custom",
        "-u", level,
        "-i", icon,
        msg
    ])


def read_file(path: str | Path) -> str:
    """Read and return the contents of a file."""
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


def read_config(path: str | Path) -> dict[str, str] | None:
    """
    Parse a key=value configuration file into a dictionary.
    Returns None if the file is empty or invalid.
    """
    try:
        content = read_file(path)
        config: dict[str, str] = {}

        for line in content.splitlines():
            if "=" not in line:
                continue
            key, value = line.split("=", 1)
            config[key.strip()] = value.strip()

        return config if config else None
    except (FileNotFoundError, IOError):
        return None


def get_pid(process: str) -> str:
    """Get the PID of a running process."""
    result = subprocess.run(
        ["pidof", process],
        capture_output=True,
        text=True
    )
    return result.stdout.strip()


def kill_all(process: str) -> None:
    """Terminate all instances of a process."""
    subprocess.run(
        ["killall", process],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL
    )


def load_json(data: str) -> Any:
    """Parse a JSON string and return the resulting object."""
    return json.loads(data)


def write_json(data: Any, path: str | Path) -> None:
    """Write data to a JSON file with indentation."""
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)