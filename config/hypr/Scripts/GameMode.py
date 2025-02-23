import os
import Wallpaper
import Waybar
from Utils import notify
import subprocess

TEMP_FILE = '/tmp/game-mode-on'

def enableGameMode():
    open(TEMP_FILE, "w").close()
    subprocess.run([
        'hyprctl', '--batch',
        'keyword animations:enabled 0;',
        'keyword decoration:blur:passes 0;',
        'keyword general:gaps_in 0;',
        'keyword general:gaps_out 0;',
        'keyword general:border_size 1;',
        'keyword decoration:rounding 0;',
        'keyword windowrule opacity 1 override 1 override 1 override, "^(.*)$"'
    ]) 

    subprocess.run([
        'hyprctl', 
        'keyword', 
        'windowrule', 
        'opacity 1 override 1 override 1 override, ^(.*)$'
    ])

    Wallpaper.swwwKill()
    Waybar.killWaybar()

    notify('applications-games', 'Gamemode: Enabled')

def disableGameMode():
    os.remove(TEMP_FILE)
    subprocess.run(['hyprctl', 'reload'])

    Wallpaper.swwwRun()
    Waybar.runWaybar()

    notify('applications-games', 'Gamemode: Disabled')

def toggleGameMode():
    if os.path.exists(TEMP_FILE):
        disableGameMode()
    else:
        enableGameMode()

if __name__ == "__main__":
    toggleGameMode()
