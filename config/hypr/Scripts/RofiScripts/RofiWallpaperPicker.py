import subprocess
import os.path as path
import glob
import Wallpaper
from .Shared import ROFI_THEMES

THEME = path.join(ROFI_THEMES, 'RofiWallpaperPicker')
WALLPAPER_DIR = path.expanduser('~/Pictures/wallpapers')
EXTENSIONS = ('*.jpg', '*.jpeg', '*.png', '*.gif')
WALLPAPERS = [f for ext in EXTENSIONS for f in glob.glob(path.join(WALLPAPER_DIR, ext))]

def getMenuItems():
    return {path.basename(wal): wal for wal in WALLPAPERS}

def showMenu():
    items = getMenuItems()
    menuItems = '\n'.join(f'{k}\0icon\x1f{v}' for k, v in items.items())

    output = subprocess.run(
        ["rofi", "-dmenu", "-theme", THEME, "-markup-rows", "-i", "-p", "Select Wallpaper"],
        input=menuItems, text=True, capture_output=True
    ).stdout.strip()

    return items[output]

def exec():
    selectedWal = showMenu()
    Wallpaper.setWallpaper(selectedWal)
