"""
Waybar process management module.
Provides functions to start and stop Waybar.
"""

import subprocess

from Utils import get_pid


def kill_waybar() -> None:
    """Kill all running Waybar instances."""
    subprocess.run(
        ["killall", "waybar"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL
    )


def run_waybar() -> None:
    """Start Waybar if not already running."""
    if not get_pid("waybar"):
        subprocess.Popen(
            ["waybar"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
