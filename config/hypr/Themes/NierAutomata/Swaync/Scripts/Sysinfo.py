"""
System information monitor for Swaync widget.
Updates system stats (CPU, RAM, Swap, Disk, Uptime, Temp) in Swaync config.
"""

import argparse
import json
import os
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path.home() / ".config/hypr/Scripts"))
from Utils import get_logger, run_silent, get_theme_dir

log = get_logger("Sysinfo")

CONFIG_PATH = get_theme_dir() / "Swaync/Config.json"


def reload_swaync() -> None:
    """Reload Swaync to apply config changes."""
    run_silent(['swaync-client', '-R'])


def update_label(label_id: str, text: str) -> None:
    """Update a label widget in the Swaync config."""
    try:
        with open(CONFIG_PATH, 'r') as f:
            config = json.load(f)
        if label_id in config.get('widget-config', {}):
            config['widget-config'][label_id]['text'] = text
        with open(CONFIG_PATH, 'w') as f:
            json.dump(config, f, indent=4)
    except (FileNotFoundError, json.JSONDecodeError) as e:
        log.error(f"Failed to update label: {e}")


def progress_bar(percent: int, width: int = 30) -> str:
    """Generate a text progress bar."""
    filled = int(width * percent / 100)
    empty = width - filled
    return '━' * filled + '─' * empty


def get_uptime() -> str:
    """Get system uptime."""
    try:
        with open('/proc/uptime', 'r') as f:
            seconds = int(float(f.read().split()[0]))
        hours, remainder = divmod(seconds, 3600)
        minutes = remainder // 60
        return f"  Uptime: {hours}h {minutes}m"
    except (FileNotFoundError, ValueError):
        return "  Uptime: N/A"


def get_temp() -> str:
    """Get CPU temperature."""
    try:
        temp = int(open('/sys/class/thermal/thermal_zone0/temp').read()) // 1000
        return f"  Temp: {temp}°C"
    except (FileNotFoundError, ValueError):
        return "  Temp: N/A"


def get_cpu() -> str:
    """Get CPU usage percentage."""
    try:
        with open('/proc/stat', 'r') as f:
            line = f.readline()
        values = list(map(int, line.split()[1:]))
        idle = values[3]
        total = sum(values)
        
        prev_file = Path('/tmp/cpu_prev')
        try:
            with open(prev_file, 'r') as f:
                prev = f.read().split()
                prev_idle, prev_total = int(prev[0]), int(prev[1])
                percent = int(100 * (1 - (idle - prev_idle) / (total - prev_total)))
        except (FileNotFoundError, ValueError, ZeroDivisionError):
            percent = 0
        
        with open(prev_file, 'w') as f:
            f.write(f'{idle} {total}')
        
        return f"  CPU\t{progress_bar(percent)} {percent}%"
    except (FileNotFoundError, ValueError):
        return "  CPU\t N/A"


def get_ram() -> str:
    """Get RAM usage."""
    try:
        with open('/proc/meminfo', 'r') as f:
            lines = f.readlines()
        total = int(lines[0].split()[1]) / 1024
        available = int(lines[2].split()[1]) / 1024
        used = total - available
        percent = int((used / total) * 100)
        used_h = f"{used/1024:.1f}G" if used >= 1024 else f"{used:.0f}M"
        total_h = f"{total/1024:.1f}G" if total >= 1024 else f"{total:.0f}M"
        return f"  RAM\t{progress_bar(percent)} {used_h}/{total_h}"
    except (FileNotFoundError, ValueError, ZeroDivisionError):
        return "  RAM\t N/A"


def get_swap() -> str:
    """Get Swap usage."""
    try:
        with open('/proc/meminfo', 'r') as f:
            content = f.read()
        total = free = 0
        for line in content.splitlines():
            if 'SwapTotal' in line:
                total = int(line.split()[1]) / 1024
            if 'SwapFree' in line:
                free = int(line.split()[1]) / 1024
        used = total - free
        percent = int((used / total) * 100) if total > 0 else 0
        used_h = f"{used/1024:.1f}G" if used >= 1024 else f"{used:.0f}M"
        total_h = f"{total/1024:.1f}G" if total >= 1024 else f"{total:.0f}M"
        return f"󰓡  Swap\t{progress_bar(percent)} {used_h}/{total_h}"
    except (FileNotFoundError, ValueError, ZeroDivisionError):
        return "󰓡  Swap\t N/A"


def get_disk() -> str:
    """Get disk usage."""
    try:
        stat = os.statvfs('/')
        total = stat.f_blocks * stat.f_frsize
        free = stat.f_bavail * stat.f_frsize
        used = total - free
        percent = int((used / total) * 100)
        return f"󰋊  Disk\t{progress_bar(percent)} {used/1024**3:.0f}G/{total/1024**3:.0f}G"
    except OSError:
        return "󰋊  Disk\t N/A"


def update_widget() -> None:
    """Update the sysinfo widget with current stats."""
    info = '\n'.join([
        get_uptime(),
        get_temp(),
        get_cpu(),
        get_ram(),
        get_swap(),
        get_disk()
    ])
    update_label('label#sysinfo', info)
    reload_swaync()


def daemon(interval: int) -> None:
    """Run continuous update loop."""
    log.info(f"Starting sysinfo daemon (interval: {interval}s)")
    while True:
        update_widget()
        time.sleep(interval)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='System Monitor')
    subparsers = parser.add_subparsers(dest='command', required=True)
    subparsers.add_parser('update', help='Update once')
    daemon_parser = subparsers.add_parser('daemon', help='Run loop')
    daemon_parser.add_argument('-i', '--interval', type=int, default=10)
    args = parser.parse_args()
    
    if args.command == 'update':
        update_widget()
    elif args.command == 'daemon':
        daemon(args.interval)