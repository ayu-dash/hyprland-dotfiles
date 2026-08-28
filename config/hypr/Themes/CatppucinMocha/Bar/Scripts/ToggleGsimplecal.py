#!/usr/bin/env python3
import argparse
import json
import shutil
import subprocess
import time

APP = "gsimplecal"

def is_running() -> bool:
    result = subprocess.run(["pgrep", "-x", APP], capture_output=True, text=True)
    return result.returncode == 0


def get_active_monitor() -> dict | None:
    result = subprocess.run(["hyprctl", "monitors", "-j"], capture_output=True, text=True)
    if result.returncode != 0:
        return None

    try:
        monitors = json.loads(result.stdout)
    except json.JSONDecodeError:
        return None

    if not monitors:
        return None

    return next((m for m in monitors if m.get("focused")), monitors[0])


def get_active_workspace_id() -> int | None:
    result = subprocess.run(["hyprctl", "activeworkspace", "-j"], capture_output=True, text=True)
    if result.returncode != 0:
        return None

    try:
        ws = json.loads(result.stdout)
    except json.JSONDecodeError:
        return None

    return ws.get("id")


def find_gsimplecal_window(timeout: float = 3.0) -> bool:
    deadline = time.time() + timeout
    while time.time() < deadline:
        result = subprocess.run(["hyprctl", "clients", "-j"], capture_output=True, text=True)
        if result.returncode != 0:
            time.sleep(0.1)
            continue

        try:
            clients = json.loads(result.stdout)
        except json.JSONDecodeError:
            time.sleep(0.1)
            continue

        for client in clients:
            if client.get("class") == APP or client.get("initialClass") == APP:
                return True

        time.sleep(0.1)

    return False


def get_gsimplecal_window_size(timeout: float = 3.0) -> tuple[int, int] | None:
    deadline = time.time() + timeout
    while time.time() < deadline:
        result = subprocess.run(["hyprctl", "clients", "-j"], capture_output=True, text=True)
        if result.returncode != 0:
            time.sleep(0.1)
            continue

        try:
            clients = json.loads(result.stdout)
        except json.JSONDecodeError:
            time.sleep(0.1)
            continue

        for client in clients:
            if client.get("class") == APP or client.get("initialClass") == APP:
                size = client.get("size")
                if isinstance(size, list) and len(size) >= 2:
                    return int(size[0]), int(size[1])
                return None

        time.sleep(0.1)

    return None


def move_gsimplecal_to_workspace(workspace_id: int) -> None:
    subprocess.run([
        "hyprctl",
        "dispatch",
        f'hl.dsp.window.move({{workspace={workspace_id}, follow=true, window="class:gsimplecal"}})',
    ], check=False)


def calculate_window_position(monitor: dict, margin_x: int, margin_y: int, center: bool = False, window_width: int = 420) -> tuple[int, int]:
    left = int(monitor.get("x", 0))
    top = int(monitor.get("y", 0))
    width = int(monitor.get("width", 0))
    height = int(monitor.get("height", 0))

    if center:
        x = left + max(0, (width - window_width) // 2) + margin_x
    elif width >= 1400:
        x = left + width - window_width + margin_x
    elif width >= 1000:
        x = left + max(0, (width - window_width) // 2) + margin_x
    else:
        x = left + 20 + margin_x

    y = top + margin_y

    min_x = left + 10
    max_x = left + max(0, width - window_width - 10)
    x = max(min_x, min(x, max_x))
    y = max(top + 10, min(y, top + height - 100))
    return x, y


def apply_window_rule(margin_x: int, margin_y: int, center: bool = False, pin: bool = False) -> None:
    monitor = get_active_monitor()
    if not monitor:
        return

    geometry = get_gsimplecal_window_size(3.0)
    window_width = geometry[0] if geometry else 420

    x, y = calculate_window_position(monitor, margin_x, margin_y, center, window_width)

    if not find_gsimplecal_window():
        return

    subprocess.run([
        "hyprctl",
        "dispatch",
        'hl.dsp.window.float({action="set", window="class:gsimplecal"})',
    ], check=False)
    subprocess.run([
        "hyprctl",
        "dispatch",
        f'hl.dsp.window.move({{x={x},y={y},window="class:gsimplecal"}})',
    ], check=False)

    if pin:
        subprocess.run([
            "hyprctl",
            "dispatch",
            'hl.dsp.window.pin({window="class:gsimplecal"})',
        ], check=False)

    # No workspace follow/watch logic here; the window is placed once on launch.


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Toggle gsimplecal and position it relative to the active monitor")
    parser.add_argument("--margin-x", type=int, default=0, help="Horizontal margin offset for window placement")
    parser.add_argument("--margin-y", type=int, default=0, help="Vertical margin offset for window placement")
    parser.add_argument("--center", action="store_true", help="Center the gsimplecal window on the active monitor")
    parser.add_argument("--pin", action="store_true", help="Pin the gsimplecal window after placement")
    return parser.parse_args()


def toggle(margin_x: int, margin_y: int, center: bool = False, pin: bool = False) -> None:
    if is_running():
        subprocess.run(["pkill", "-x", APP], check=False)
        return

    if shutil.which(APP) is None:
        raise SystemExit(f"{APP} not found in PATH")

    subprocess.Popen(
        [APP],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=True,
    )

    if not find_gsimplecal_window(5.0):
        return

    apply_window_rule(margin_x, margin_y, center, pin)


if __name__ == "__main__":
    args = parse_args()
    toggle(args.margin_x, args.margin_y, args.center, args.pin)
