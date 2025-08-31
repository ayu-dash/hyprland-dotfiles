import subprocess
import os.path as path
from .Shared import ROFI_THEMES

THEME = path.join(ROFI_THEMES, 'RofiCalcV2')

def exec():
    subprocess.Popen([
        'rofi',
        '-show', 'calc',
        '-modi', 'calc',
        '-no-show-match',
        '-no-sort',
        '-no-persist-history',
        '-calc-command', 'echo -n {{result}} | wl-copy',
        '-theme', THEME
    ])
