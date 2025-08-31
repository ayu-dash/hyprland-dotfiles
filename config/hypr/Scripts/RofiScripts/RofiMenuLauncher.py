import subprocess
import os.path as path
from .Shared import ROFI_THEMES

THEME = path.join(ROFI_THEMES, 'RofiMenuLauncherV2')

def exec():
    subprocess.Popen([
        'rofi',
        '-show', 'drun',
        '-theme', THEME
    ])
