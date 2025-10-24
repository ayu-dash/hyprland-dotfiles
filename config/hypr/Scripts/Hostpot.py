import subprocess
from Utils import readConfig, notify
import json
import argparse
import os.path as path

CONFIG = readConfig(path.expanduser('~/.config/hypr/Configs/Hostpot.conf'))

def create_ap():
    if not CONFIG:
        notify('dialog-error', 'Hotspot: Config file not found!', 'critical')
        return

    if len(CONFIG['PASSWORD']) < 8:
        notify('dialog-error', 'Hotspot: Password must be at least 8 characters long!', 'critical')
        return

    subprocess.Popen([
        'sudo', 'create_ap',
        '--daemon',
        CONFIG['IFNAME'],
        CONFIG['IFNAME'],
        CONFIG['SSID'],
        CONFIG['PASSWORD']
    ])

    print(json.dumps({
        "class": "connected", 
        "text": " 󱜠", 
        "tooltip": "Hotspot is running" 
    }))

    notify('network-wireless', 'Hotspot started successfully!')

def stop_ap():
    subprocess.run(['sudo', 'create_ap', '--stop', CONFIG['IFNAME']])

    print(json.dumps({
        "class": "disconnected", 
        "text": " 󱜡", 
        "tooltip": "Hotspot is not running."  
    }))

    notify('network-wireless', 'Hotspot stopped successfully!')

def list_ap():
    return subprocess.run(
        ['sudo', 'create_ap', '--list-running'],
        capture_output=True, text=True
    ).stdout.strip().splitlines()

def toggle_ap():
    ap_list = list_ap()
    if ap_list:
        stop_ap()
    else:
        create_ap()

def status_ap():
    ap_list = list_ap()

    if ap_list:
        print(json.dumps({
            "class": "connected", 
            "text": " 󱜠", 
            "tooltip": "Hotspot is running" 
        }))
    else:
        print(json.dumps({
            "class": "disconnected", 
            "text": " 󱜡", 
            "tooltip": "Hotspot is not running."  
        }))


def main():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        'action',
        choices=['toggle', 'status']
    )

    args = parser.parse_args()

    match(args.action):
        case 'toggle': toggle_ap()
        case 'status': status_ap()

if __name__ == '__main__':
    main()