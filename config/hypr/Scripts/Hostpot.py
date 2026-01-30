#!/usr/bin/env python3
"""
Hotspot Management Script for Hyprland

This script manages a WiFi hotspot using hostapd and dnsmasq with virtual interface
support. It provides toggle functionality and status output compatible with Waybar.

Dependencies: hostapd, dnsmasq, iw, nmcli, iptables
Requires: Root privileges for network operations
"""

import subprocess
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

from Utils import get_logger

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
        subprocess.run(
            ["notify-send", "-a", "Hotspot", "-u", urgency, message],
            stderr=subprocess.DEVNULL
        )
        return

    uid = os.getenv('SUDO_UID')
    command = (
        f"export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/{uid}/bus && "
        f"export XDG_RUNTIME_DIR=/run/user/{uid} && "
        f"notify-send -a 'Hotspot' -u '{urgency}' '{message}'"
    )
    subprocess.run(["sudo", "-u", user, "sh", "-c", command], stderr=subprocess.DEVNULL)


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
    result = subprocess.run(
        ["iw", "dev", parent_interface, "info"],
        capture_output=True, text=True
    )
    match = re.search(r"channel\s+(\d+)", result.stdout)
    channel = match.group(1) if match else "1"
    log.debug(f"Active channel on {parent_interface}: {channel}")
    return channel


def create_virtual_interface(parent_interface: str) -> bool:
    """Create and configure a virtual AP interface."""
    log.info(f"Creating virtual interface on {parent_interface}")
    try:
        subprocess.run(["nmcli", "device", "set", parent_interface, "managed", "no"])
        
        log.debug("Resetting WiFi radio")
        subprocess.run(["rfkill", "block", "wifi"])
        time.sleep(0.5)
        subprocess.run(["rfkill", "unblock", "wifi"])
        time.sleep(1.5)

        subprocess.run(["iw", "dev", VIRTUAL_INTERFACE, "del"], stderr=subprocess.DEVNULL)
        
        result = subprocess.run([
            "iw", "dev", parent_interface, "interface", "add",
            VIRTUAL_INTERFACE, "type", "__ap"
        ])
        if result.returncode != 0:
            log.error("Failed to create virtual AP interface")
            return False

        subprocess.run([
            "ip", "link", "set", "dev", VIRTUAL_INTERFACE,
            "address", generate_virtual_mac(parent_interface)
        ])
        subprocess.run(["ip", "link", "set", parent_interface, "up"])
        subprocess.run(["nmcli", "device", "set", parent_interface, "managed", "yes"])
        time.sleep(0.5)
        subprocess.run(["ip", "link", "set", VIRTUAL_INTERFACE, "up"])
        subprocess.run(["nmcli", "device", "set", VIRTUAL_INTERFACE, "managed", "no"])
        
        log.info(f"Virtual interface {VIRTUAL_INTERFACE} created successfully")
        return True
    except Exception as e:
        log.error(f"Exception creating virtual interface: {e}")
        return False


def add_nat_rule(parent_interface: str) -> None:
    """Add NAT masquerade rule for hotspot traffic."""
    log.debug(f"Adding NAT rule for {parent_interface}")
    subprocess.run([
        "iptables", "-t", "nat", "-A", "POSTROUTING",
        "-o", parent_interface, "-s", "192.168.12.0/24", "-j", "MASQUERADE",
        "-m", "comment", "--comment", "hypr_hotspot"
    ])


def remove_nat_rule() -> None:
    """Remove only the NAT rules created by this hotspot script."""
    log.debug("Removing NAT rules")
    while True:
        result = subprocess.run(
            ["iptables", "-t", "nat", "-L", "POSTROUTING", "--line-numbers", "-n"],
            capture_output=True, text=True
        )
        
        line_num = None
        for line in result.stdout.splitlines():
            if "hypr_hotspot" in line:
                parts = line.split()
                if parts and parts[0].isdigit():
                    line_num = parts[0]
                    break
        
        if line_num:
            subprocess.run([
                "iptables", "-t", "nat", "-D", "POSTROUTING", line_num
            ], stderr=subprocess.DEVNULL)
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
                subprocess.run(["kill", pid], stderr=subprocess.DEVNULL)
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

    subprocess.Popen(
        ["hostapd", HOSTAPD_CONF],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL
    )
    time.sleep(1.5)
    
    if not is_hotspot_active():
        log.error("hostapd failed to start")
        send_notification("Error: hostapd failed to start", "critical")
        subprocess.run(["iw", "dev", VIRTUAL_INTERFACE, "del"], stderr=subprocess.DEVNULL)
        return
    
    subprocess.run(["ip", "addr", "flush", "dev", VIRTUAL_INTERFACE])
    subprocess.run(["ip", "addr", "add", "192.168.12.1/24", "dev", VIRTUAL_INTERFACE])
    
    subprocess.Popen([
        "dnsmasq",
        f"--interface={VIRTUAL_INTERFACE}",
        "--bind-interfaces",
        "--dhcp-range=192.168.12.10,192.168.12.100,12h",
        "--conf-file=/dev/null",
        f"--pid-file={DNSMASQ_PID}"
    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    
    subprocess.run(["sysctl", "-w", "net.ipv4.ip_forward=1"], capture_output=True)
    add_nat_rule(parent_interface)

    log.info("Hotspot started successfully")
    output_status()
    send_notification("Hotspot: ONLINE")


def stop_hotspot() -> None:
    """Stop the WiFi hotspot and clean up all resources."""
    log.info("Stopping hotspot")
    if os.geteuid() == 0:
        send_notification("Terminating hotspot...")
    
    subprocess.run(["killall", "-qw", "hostapd"], stderr=subprocess.DEVNULL)
    kill_dnsmasq()
    subprocess.run(["iw", "dev", VIRTUAL_INTERFACE, "del"], stderr=subprocess.DEVNULL)
    remove_nat_rule()
    
    log.info("Hotspot stopped")
    time.sleep(1)
    output_status()


def is_hotspot_active() -> bool:
    """Check if the hotspot is currently running."""
    result = subprocess.run(["pgrep", "-x", "hostapd"], capture_output=True)
    return result.returncode == 0


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