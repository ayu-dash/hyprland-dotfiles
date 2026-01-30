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

# =============================================================================
# Configuration Constants
# =============================================================================

SUDO_USER = os.getenv('SUDO_USER')
USER_HOME = Path(f"/home/{SUDO_USER}") if SUDO_USER else Path.home()

CONFIG_PATH = USER_HOME / ".config/hypr/Configs/Hostpot.conf"
HOSTAPD_CONF = "/tmp/hypr_hostapd.conf"
VIRTUAL_INTERFACE = "ap0"


# =============================================================================
# Configuration Loader
# =============================================================================

def load_config(path: str) -> dict:
    """
    Load hotspot configuration from file.
    
    Args:
        path: Path to the configuration file
        
    Returns:
        Dictionary containing configuration key-value pairs
    """
    config = {}
    try:
        with open(path, 'r') as file:
            for line in file:
                if '=' in line:
                    key, value = line.strip().split('=', 1)
                    config[key.strip()] = value.strip().strip('"').strip("'")
        return config
    except (FileNotFoundError, PermissionError):
        return {}


CONFIG = load_config(str(CONFIG_PATH))


# =============================================================================
# Utility Functions
# =============================================================================

def send_notification(message: str, urgency: str = "low") -> None:
    """
    Send desktop notification with proper D-Bus session handling.
    
    When running as root via sudo, notifications must be sent to the
    original user's session by setting appropriate environment variables.
    
    Args:
        message: Notification message to display
        urgency: Notification urgency level (low, normal, critical)
    """
    user = os.getenv('SUDO_USER')
    if not user:
        subprocess.run(
            ["notify-send", "-a", "YoRHa", "-u", urgency, message],
            stderr=subprocess.DEVNULL
        )
        return

    uid = os.getenv('SUDO_UID')
    
    # Construct shell command with proper D-Bus environment for user session
    command = (
        f"export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/{uid}/bus && "
        f"export XDG_RUNTIME_DIR=/run/user/{uid} && "
        f"notify-send -a 'YoRHa Hotspot' -u '{urgency}' '{message}'"
    )
    
    subprocess.run(
        ["sudo", "-u", user, "sh", "-c", command],
        stderr=subprocess.DEVNULL
    )


def generate_virtual_mac(parent_interface: str) -> str:
    """
    Generate a valid MAC address for the virtual interface.
    
    Creates a locally administered MAC address derived from the parent
    interface MAC to avoid conflicts while maintaining uniqueness.
    
    Args:
        parent_interface: Name of the parent network interface
        
    Returns:
        MAC address string in colon-separated format
    """
    try:
        with open(f"/sys/class/net/{parent_interface}/address", 'r') as file:
            mac_parts = file.read().strip().split(':')
        
        # Set locally administered bit (LAA)
        mac_parts[0] = f"{int(mac_parts[0], 16) | 0x02:02x}"
        # Increment last octet to differentiate from parent
        mac_parts[-1] = f"{(int(mac_parts[-1], 16) + 1) % 256:02x}"
        
        return ":".join(mac_parts)
    except (FileNotFoundError, PermissionError):
        return "02:00:00:44:55:66"


def get_active_channel(parent_interface: str) -> str:
    """
    Retrieve the current WiFi channel of the parent interface.
    
    The virtual AP must operate on the same channel as the parent
    interface to enable concurrent operation.
    
    Args:
        parent_interface: Name of the parent network interface
        
    Returns:
        Channel number as string, defaults to "1" if detection fails
    """
    result = subprocess.run(
        ["iw", "dev", parent_interface, "info"],
        capture_output=True,
        text=True
    )
    match = re.search(r"channel\s+(\d+)", result.stdout)
    return match.group(1) if match else "1"


# =============================================================================
# Core Hotspot Operations
# =============================================================================

def create_virtual_interface(parent_interface: str) -> bool:
    """
    Create and configure a virtual AP interface.
    
    Performs WiFi radio reset and creates a virtual interface in AP mode.
    The parent interface is temporarily unmanaged to allow direct control.
    
    Args:
        parent_interface: Name of the parent network interface
        
    Returns:
        True if interface creation succeeded, False otherwise
    """
    try:
        # Temporarily disable NetworkManager control
        subprocess.run(["nmcli", "device", "set", parent_interface, "managed", "no"])
        
        # Reset WiFi radio to clear any stuck state
        subprocess.run(["rfkill", "block", "wifi"])
        time.sleep(0.5)
        subprocess.run(["rfkill", "unblock", "wifi"])
        time.sleep(1.5)

        # Remove existing virtual interface if present
        subprocess.run(
            ["iw", "dev", VIRTUAL_INTERFACE, "del"],
            stderr=subprocess.DEVNULL
        )
        
        # Create new virtual AP interface
        result = subprocess.run([
            "iw", "dev", parent_interface, "interface", "add",
            VIRTUAL_INTERFACE, "type", "__ap"
        ])
        if result.returncode != 0:
            return False

        # Configure virtual interface MAC and bring up interfaces
        subprocess.run([
            "ip", "link", "set", "dev", VIRTUAL_INTERFACE,
            "address", generate_virtual_mac(parent_interface)
        ])
        subprocess.run(["ip", "link", "set", parent_interface, "up"])
        
        # Re-enable NetworkManager for parent, disable for virtual
        subprocess.run(["nmcli", "device", "set", parent_interface, "managed", "yes"])
        time.sleep(0.5)
        subprocess.run(["ip", "link", "set", VIRTUAL_INTERFACE, "up"])
        subprocess.run(["nmcli", "device", "set", VIRTUAL_INTERFACE, "managed", "no"])
        
        return True
    except Exception:
        return False


def start_hotspot() -> None:
    """
    Start the WiFi hotspot with all required services.
    
    Creates virtual interface, starts hostapd for AP functionality,
    configures dnsmasq for DHCP, and sets up NAT for internet sharing.
    Requires root privileges.
    """
    if os.geteuid() != 0:
        print("Error: Root privileges required. Run with sudo.")
        sys.exit(1)

    parent_interface = CONFIG.get("IFNAME", "wlan0")
    channel = get_active_channel(parent_interface)

    send_notification(f"Initializing hotspot on channel {channel}...")

    if not create_virtual_interface(parent_interface):
        send_notification("Error: Failed to create virtual interface", "critical")
        return

    # Generate hostapd configuration
    hostapd_config = "\n".join([
        f"interface={VIRTUAL_INTERFACE}",
        "driver=nl80211",
        f"ssid={CONFIG.get('SSID', 'YoRHa')}",
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

    # Start hostapd in background
    subprocess.Popen(
        ["hostapd", HOSTAPD_CONF],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL
    )
    time.sleep(1.5)
    
    # Configure IP addressing for the virtual interface
    subprocess.run(["ip", "addr", "flush", "dev", VIRTUAL_INTERFACE])
    subprocess.run(["ip", "addr", "add", "192.168.12.1/24", "dev", VIRTUAL_INTERFACE])
    
    # Start DHCP server
    subprocess.run([
        "dnsmasq",
        f"--interface={VIRTUAL_INTERFACE}",
        "--bind-interfaces",
        "--dhcp-range=192.168.12.10,192.168.12.100,12h",
        "--conf-file=/dev/null"
    ])
    
    # Enable IP forwarding and configure NAT
    subprocess.run(["sysctl", "-w", "net.ipv4.ip_forward=1"], capture_output=True)
    subprocess.run([
        "iptables", "-t", "nat", "-A", "POSTROUTING",
        "-o", parent_interface, "-j", "MASQUERADE"
    ])

    output_status()
    send_notification("YoRHa Hotspot: ONLINE")


def stop_hotspot() -> None:
    """
    Stop the WiFi hotspot and clean up all resources.
    
    Terminates hostapd and dnsmasq processes, removes the virtual
    interface, and flushes NAT rules.
    """
    if os.geteuid() == 0:
        send_notification("Terminating hotspot...")
    
    subprocess.run(["killall", "-qw", "hostapd", "dnsmasq"])
    subprocess.run(["iw", "dev", VIRTUAL_INTERFACE, "del"], stderr=subprocess.DEVNULL)
    subprocess.run(["iptables", "-t", "nat", "-F"], stderr=subprocess.DEVNULL)
    
    time.sleep(1)
    output_status()


def is_hotspot_active() -> bool:
    """
    Check if the hotspot is currently running.
    
    Returns:
        True if hostapd process is running, False otherwise
    """
    result = subprocess.run(["pgrep", "-x", "hostapd"], capture_output=True)
    return result.returncode == 0


def output_status() -> None:
    """
    Output hotspot status in Waybar-compatible JSON format.
    
    Prints JSON with class, text (icon), and tooltip for integration
    with Waybar custom module.
    """
    if is_hotspot_active():
        status = {"class": "connected", "text": " 󱜠", "tooltip": "ON"}
    else:
        status = {"class": "disconnected", "text": " 󱜡", "tooltip": "OFF"}
    
    print(json.dumps(status))


# =============================================================================
# Entry Point
# =============================================================================

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
            sys.exit(1)
        
        if is_hotspot_active():
            stop_hotspot()
        else:
            start_hotspot()