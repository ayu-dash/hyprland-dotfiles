import subprocess
import os.path as path
from .Shared import ROFI_THEMES

THEME = path.join(ROFI_THEMES, 'RofiEmojiPickerV2')

def exec():
    subprocess.run([
        'rofi',
        '-modi', 'emoji',
        '-show', 'emoji',
        '-emoji-format', '{emoji}',
        '-kb-secondary-copy', '',
        '-kb-custom-1', 'Ctrl+c',
        '-theme', THEME
    ])