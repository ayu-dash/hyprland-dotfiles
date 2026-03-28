import os
import time
from pathlib import Path
from Utils import is_running, read_file, run_capture, run_silent

# Unique state file per user to avoid permission conflicts in /tmp
STATE_FILE = Path(f"/tmp/lock_battery_frame_{os.getlogin()}")

CHARGING_ICONS: list[str] = ["󰢟", "󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅"]
BATTERY_ICONS: list[str] = ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]

def get_battery_info():
    try:
        # Resolve battery path
        bat_path = next(Path("/sys/class/power_supply").glob("BAT*"))
        capacity = int(read_file(bat_path / "capacity").strip())
        status = read_file(bat_path / "status").strip()
        
        start_index = min(capacity // 10, 10)
        
        if status == "Charging":
            # Determine current animation frame
            if STATE_FILE.exists():
                try:
                    frame = int(STATE_FILE.read_text().strip())
                except ValueError:
                    frame = start_index
            else:
                frame = start_index
                
            # Keep animation between current level and full
            frame = max(frame, start_index)
            icon = CHARGING_ICONS[frame]
            
            # Save next frame
            try:
                next_frame = frame + 1 if frame < 10 else start_index
                STATE_FILE.write_text(str(next_frame))
            except PermissionError:
                pass
            return icon
        
        elif status == "Full":
            if STATE_FILE.exists():
                try: STATE_FILE.unlink(missing_ok=True)
                except PermissionError: pass
            return "󰂅"
            
        else:
            if STATE_FILE.exists():
                try: STATE_FILE.unlink(missing_ok=True)
                except PermissionError: pass
            return BATTERY_ICONS[start_index]
            
    except (StopIteration, FileNotFoundError, ValueError, IndexError):
        return ""

def get_hotspot_status():
    return "󱜠" if is_running("hostapd") else ""

def get_interface_icon():
    stdout, _, _ = run_capture(["ip", "route"])
    default_iface = ""
    for line in stdout.splitlines():
        if line.startswith("default"):
            parts = line.split()
            if "dev" in parts:
                default_iface = parts[parts.index("dev") + 1]
            break
            
    if not default_iface:
        return "󱐅"
        
    # Check connectivity via ping
    if run_silent(["ping", "-q", "-c", "1", "-W", "1", "1.1.1.1"]) == 0:
        if default_iface.startswith("wl"):
            return ""
        elif default_iface.startswith(("en", "eth")):
            return "󰈀"
        return "󰈀"
    
    return "󱐅"

def main():
    hotspot = get_hotspot_status()
    net = get_interface_icon()
    battery = get_battery_info()
    
    # Filter out empty strings and join with single space for clean output
    icons = [i for i in [hotspot, net, battery] if i]
    print(" ".join(icons))

if __name__ == "__main__":
    main()
