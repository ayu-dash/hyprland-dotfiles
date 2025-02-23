import argparse
from posix import kill
import subprocess
from RofiScripts import *
from Utils import getPid, killAll

PROCESS = "rofi"

def main():
    if getPid(PROCESS):
        killAll(PROCESS)
        return

    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=["menu", "wall", "calc", "emoji", "clip", "cap"])
    args = parser.parse_args()

    match(args.action):
        case 'menu':
            RofiMenuLauncher.exec()
        case 'wall':
            RofiWallpaperPicker.exec()
        case 'calc':
            RofiCalc.exec()
        case 'clip':
            RofiClipboard.exec()
        case 'cap':
            RofiScreenshot.exec()
        case 'emoji':
            RofiEmojiPicker.exec()

if __name__ == "__main__":
    main()
