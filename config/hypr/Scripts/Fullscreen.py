import os
import socket
import subprocess
import Waybar
from Utils import loadJson

XDG_RUNTIME_DIR = os.getenv('XDG_RUNTIME_DIR')
HYPRLAND_INSTANCE_SIGNATURE = os.getenv('HYPRLAND_INSTANCE_SIGNATURE')
TEMP_FILE = '/tmp/game-mode-on' 

if not XDG_RUNTIME_DIR or not HYPRLAND_INSTANCE_SIGNATURE:
    exit(1)

SOCK_PATH = os.path.join(XDG_RUNTIME_DIR, 'hypr', HYPRLAND_INSTANCE_SIGNATURE, '.socket2.sock')

def isFullscreen():
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as soc:
        soc.connect(SOCK_PATH)
        while True:
            data = soc.recv(4096).decode('utf-8')
            print(data)
            if 'fullscreen' in data or 'activewindow' in data:
                activeWindow = subprocess.run(['hyprctl', 'activewindow', '-j'], capture_output=True, text=True).stdout.strip()
                fullscreen = loadJson(activeWindow).get('fullscreen')

                yield True if fullscreen == 2 else False

def isGameModeActive():
    return os.path.exists(TEMP_FILE)

def main():
    for status in isFullscreen():
        print(status)
        if not isGameModeActive():
            if status:
                Waybar.killWaybar()
            else:
                Waybar.runWaybar()
                
if __name__ == '__main__':
    main()
