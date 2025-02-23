import subprocess
import os.path as path
import argparse
import shutil
from Utils import getPid

CACHE_DIR = path.expanduser('~/.cache')
WAL_DEST = path.join(CACHE_DIR, '.wal')
BAN_DEST = path.join(CACHE_DIR, '.ban.jpg')

FPS = '60'
TYPE = 'wipe'
DURATION = '1'

SWWW_PARAMS = [
    '--transition-fps', FPS,
    '--transition-type', TYPE,
    '--transition-duration', DURATION
]

def startDaemon():
    if not getPid('swww-daemon'):
        subprocess.Popen(['swww', 'init'])

def swwwKill():
    subprocess.run(['swww', 'kill'])

def swwwRun():
    startDaemon()
    subprocess.run(['swww', 'restore'])

def setWallpaper(path):
    startDaemon()
    subprocess.run(['swww', 'img', path] + SWWW_PARAMS)

    shutil.copyfile(path, WAL_DEST)
    subprocess.run(['magick', WAL_DEST, '-resize', '10%', BAN_DEST])

def main():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        'action',
        choices=['set', 'run']
    )

    parser.add_argument(
        '--path',
        type=str
    )

    args = parser.parse_args()

    match(args.action):
        case 'set':
            setWallpaper(args.path)
        case 'run':
            swwwRun()


if __name__ == "__main__":
    main()
