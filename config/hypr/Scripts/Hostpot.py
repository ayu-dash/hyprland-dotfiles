"""
Hotspot Management Script for Hyprland

This script manages a WiFi hotspot using hostapd and dnsmasq with virtual interface
support. It provides toggle functionality and status output compatible with Waybar.

Dependencies: hostapd, dnsmasq, iw, iptables
Requires: Root privileges for network operations
"""

import json
import time
import re
import argparse
import os
import sys
from pathlib import Path

# Add Scripts directory to path for imports when running as root
SUDO_USER = os.getenv('SUDO_USER')
USER_HOME = Path(f"/home/{SUDO_USER}") if SUDO_USER else Path.home()
SCRIPTS_DIR = USER_HOME / ".config/hypr/Scripts"
sys.path.insert(0, str(SCRIPTS_DIR))

from Utils import get_logger, run_silent, run_capture, run_bg, kill_all

log = get_logger("Hotspot")

CONFIG_PATH = USER_HOME / ".config/hypr/Configs/Hostpot.conf"
HOSTAPD_CONF = "/tmp/hypr_hostapd.conf"
DNSMASQ_PID = "/tmp/hypr_dnsmasq.pid"
VIRTUAL_INTERFACE = "ap0"

def load_config(path: str) -> dict:
    """Load hotspot configuration from file."""
    config = {}
    try:
        with open(path, 'r') as file:
            for line in file:
                if '=' in line:
                    key, value = line.strip().split('=', 1)
                    config[key.strip()] = value.strip().strip('"').strip("'")
        log.debug(f"Loaded config from {path}")
        return config
    except (FileNotFoundError, PermissionError) as e:
        log.warning(f"Failed to load config: {e}")
        return {}


CONFIG = load_config(str(CONFIG_PATH))

def send_notification(message: str, urgency: str = "low") -> None:
    """Send desktop notification with proper D-Bus session handling."""
    user = os.getenv('SUDO_USER')
    if not user:
        run_silent(["notify-send", "-a", "Hotspot", "-u", urgency, message])
        return

    uid = os.getenv('SUDO_UID')
    command = (
        f"export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/{uid}/bus && "
        f"export XDG_RUNTIME_DIR=/run/user/{uid} && "
        f"notify-send -a 'Hotspot' -u '{urgency}' '{message}'"
    )
    run_silent(["sudo", "-u", user, "sh", "-c", command])


def generate_virtual_mac(parent_interface: str) -> str:
    """Generate a valid MAC address for the virtual interface."""
    try:
        with open(f"/sys/class/net/{parent_interface}/address", 'r') as file:
            mac_parts = file.read().strip().split(':')
        mac_parts[0] = f"{int(mac_parts[0], 16) | 0x02:02x}"
        mac_parts[-1] = f"{(int(mac_parts[-1], 16) + 1) % 256:02x}"
        mac = ":".join(mac_parts)
        log.debug(f"Generated virtual MAC: {mac}")
        return mac
    except (FileNotFoundError, PermissionError):
        log.warning("Using fallback MAC address")
        return "02:00:00:44:55:66"


def get_active_channel(parent_interface: str) -> str:
    """Retrieve the current WiFi channel of the parent interface."""
    stdout, _, _ = run_capture(["iw", "dev", parent_interface, "info"])
    match = re.search(r"channel\s+(\d+)", stdout)
    channel = match.group(1) if match else "1"
    log.debug(f"Active channel on {parent_interface}: {channel}")
    return channel


def create_virtual_interface(parent_interface: str) -> bool:
    """Create and configure a virtual AP interface."""
    log.info(f"Creating virtual interface on {parent_interface}")
    try:

        log.debug("Resetting WiFi radio")
        run_silent(["rfkill", "block", "wifi"])
        time.sleep(0.5)
        run_silent(["rfkill", "unblock", "wifi"])
        time.sleep(1.5)

        run_silent(["iw", "dev", VIRTUAL_INTERFACE, "del"])
        
        result = run_silent([
            "iw", "dev", parent_interface, "interface", "add",
            VIRTUAL_INTERFACE, "type", "__ap"
        ])
        if result != 0:
            log.error("Failed to create virtual AP interface")
            return False

        run_silent([
            "ip", "link", "set", "dev", VIRTUAL_INTERFACE,
            "address", generate_virtual_mac(parent_interface)
        ])
        run_silent(["ip", "link", "set", parent_interface, "up"])

        time.sleep(0.5)
        run_silent(["ip", "link", "set", VIRTUAL_INTERFACE, "up"])

        
        log.info(f"Virtual interface {VIRTUAL_INTERFACE} created successfully")
        return True
    except Exception as e:
        log.error(f"Exception creating virtual interface: {e}")
        return False


def add_nat_rule(parent_interface: str) -> None:
    """Add NAT masquerade rule for hotspot traffic."""
    log.debug(f"Adding NAT rule for {parent_interface}")
    run_silent([
        "iptables", "-t", "nat", "-A", "POSTROUTING",
        "-o", parent_interface, "-s", "192.168.12.0/24", "-j", "MASQUERADE",
        "-m", "comment", "--comment", "hypr_hotspot"
    ])


def remove_nat_rule() -> None:
    """Remove only the NAT rules created by this hotspot script."""
    log.debug("Removing NAT rules")
    while True:
        stdout, _, _ = run_capture(
            ["iptables", "-t", "nat", "-L", "POSTROUTING", "--line-numbers", "-n"]
        )
        
        line_num = None
        for line in stdout.splitlines():
            if "hypr_hotspot" in line:
                parts = line.split()
                if parts and parts[0].isdigit():
                    line_num = parts[0]
                    break
        
        if line_num:
            run_silent([
                "iptables", "-t", "nat", "-D", "POSTROUTING", line_num
            ])
        else:
            break


def kill_dnsmasq() -> None:
    """Kill only the dnsmasq instance started by this script using PID file."""
    if os.path.exists(DNSMASQ_PID):
        try:
            with open(DNSMASQ_PID, 'r') as f:
                pid = f.read().strip()
            if pid:
                log.debug(f"Killing dnsmasq PID {pid}")
                run_silent(["kill", pid])
            os.remove(DNSMASQ_PID)
        except (FileNotFoundError, PermissionError, ProcessLookupError) as e:
            log.warning(f"Error killing dnsmasq: {e}")


def start_hotspot() -> None:
    """Start the WiFi hotspot with all required services."""
    if os.geteuid() != 0:
        log.error("Root privileges required")
        print("Error: Root privileges required. Run with sudo.")
        sys.exit(1)

    parent_interface = CONFIG.get("IFNAME", "wlan0")
    channel = get_active_channel(parent_interface)

    log.info(f"Starting hotspot on channel {channel}")
    send_notification(f"Initializing hotspot on channel {channel}...")

    if not create_virtual_interface(parent_interface):
        log.error("Failed to create virtual interface")
        send_notification("Error: Failed to create virtual interface", "critical")
        return

    hostapd_config = "\n".join([
        f"interface={VIRTUAL_INTERFACE}",
        "driver=nl80211",
        f"ssid={CONFIG.get('SSID', 'Hotspot')}",
        "hw_mode=g",
        f"channel={channel}",
        "wpa=2",
        f"wpa_passphrase={CONFIG.get('PASSWORD', '12345678')}",
        "wpa_key_mgmt=WPA-PSK",
        "wpa_pairwise=CCMP",
        "rsn_pairwise=CCMP"
    ])
    
    with open(HOSTAPD_CONF, "w") as file:
        file.write(hostapd_config)
    log.debug(f"hostapd config written to {HOSTAPD_CONF}")

    run_bg(["hostapd", HOSTAPD_CONF])
    time.sleep(1.5)
    
    if not is_hotspot_active():
        log.error("hostapd failed to start")
        send_notification("Error: hostapd failed to start", "critical")
        run_silent(["iw", "dev", VIRTUAL_INTERFACE, "del"])
        return
    
    run_silent(["ip", "addr", "flush", "dev", VIRTUAL_INTERFACE])
    run_silent(["ip", "addr", "add", "192.168.12.1/24", "dev", VIRTUAL_INTERFACE])
    
    run_bg([
        "dnsmasq",
        f"--interface={VIRTUAL_INTERFACE}",
        "--bind-interfaces",
        "--dhcp-range=192.168.12.10,192.168.12.100,12h",
        "--conf-file=/dev/null",
        f"--pid-file={DNSMASQ_PID}"
    ])
    
    run_capture(["sysctl", "-w", "net.ipv4.ip_forward=1"])
    add_nat_rule(parent_interface)

    log.info("Hotspot started successfully")
    output_status()
    send_notification("Hotspot: ONLINE")


def stop_hotspot() -> None:
    """Stop the WiFi hotspot and clean up all resources."""
    log.info("Stopping hotspot")
    if os.geteuid() == 0:
        send_notification("Terminating hotspot...")
    
    kill_all("hostapd")
    kill_dnsmasq()
    run_silent(["iw", "dev", VIRTUAL_INTERFACE, "del"])
    remove_nat_rule()
    
    log.info("Hotspot stopped")
    time.sleep(1)
    output_status()


def is_hotspot_active() -> bool:
    """Check if the hotspot is currently running."""
    _, _, returncode = run_capture(["pgrep", "-x", "hostapd"])
    return returncode == 0


def output_status() -> None:
    """Output hotspot status in Waybar-compatible JSON format."""
    if is_hotspot_active():
        status = {"class": "connected", "text": " 󱜠", "tooltip": "ON"}
    else:
        status = {"class": "disconnected", "text": " 󱜡", "tooltip": "OFF"}
    print(json.dumps(status))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Manage WiFi hotspot with virtual interface support"
    )
    parser.add_argument(
        "action",
        choices=["toggle", "status"],
        help="Action to perform: toggle hotspot on/off, or get status"
    )
    args = parser.parse_args()
    
    if args.action == "status":
        output_status()
    elif args.action == "toggle":
        if os.geteuid() != 0:
            log.error("Toggle requires root privileges")
            print("Error: Root privileges required for toggle. Run with sudo.")
            sys.exit(1)
        
        if is_hotspot_active():
            stop_hotspot()
        else:
            start_hotspot()