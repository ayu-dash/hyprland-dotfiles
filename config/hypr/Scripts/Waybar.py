"""
Waybar process management module.
Provides functions to start and stop Waybar.
"""

from Utils import is_running, run_bg, kill_all


def kill_waybar() -> None:
    """Kill all running Waybar instances."""
    kill_all("waybar")


def run_waybar() -> None:
    """Start Waybar if not already running."""
    if not is_running("waybar"):
        run_bg(["waybar"])
