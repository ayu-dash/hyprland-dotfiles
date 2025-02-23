import subprocess
import os.path as path
from .Shared import ROFI_THEMES

THEME = path.join(ROFI_THEMES, 'RofiScreenshot')
SHOOTER = 'hyprshot'

OPTION = {
    'full': '󰊓',
    'region': '󰒅',
    'window': ''
}

def showMenu():
    choices = f'{OPTION['full']}\n{OPTION['region']}\n{OPTION['window']}'
    result = subprocess.run(
        ["rofi", "-dmenu", "-theme", THEME],
        input=choices.encode(),
        stdout=subprocess.PIPE
    )
    return result.stdout.decode().strip()

def exec():
    selected = showMenu()

    if selected == OPTION['full']:
        subprocess.run([SHOOTER, "-m", "output"])
    elif selected == OPTION['region']:
        subprocess.run([SHOOTER, "-m", "region"])
    elif selected == OPTION['window']:
        subprocess.run([SHOOTER, "-m", "window"])
    else:
        print("No valid option selected.")
