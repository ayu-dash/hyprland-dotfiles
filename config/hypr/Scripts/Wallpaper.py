import subprocess
import os.path as path
import argparse
import shutil
import json
from Utils import getPid

CACHE_DIR = path.expanduser('~/.cache')
WAL_DEST = path.join(CACHE_DIR, '.wal.jpg')
BAN_DEST = path.join(CACHE_DIR, '.ban.jpg')

FPS = '60'
TYPE = 'wipe'
DURATION = '1'

SWWW_PARAMS = [
    '--transition-fps', FPS,
    '--transition-type', TYPE,
    '--transition-duration', DURATION
]

def get_monitors():
    result = subprocess.run(
        ['hyprctl', 'monitors', '-j'],
        capture_output=True, text=True
    )
    return [m['name'] for m in json.loads(result.stdout)]

def startDaemon():
    if not getPid('swww-daemon'):
        subprocess.Popen(['swww-daemon'])

def swwwKill():
    subprocess.run(['swww', 'kill'])

def swwwRun():
    startDaemon()
    subprocess.run(['swww', 'restore'])

def setWallpaper(image_path):
    startDaemon()

    ext = path.splitext(image_path)[1].lower()
    
    if ext == '.gif':
        subprocess.run([
            'magick',
            image_path + '[0]',
            WAL_DEST
        ])
    else:
        shutil.copyfile(image_path, WAL_DEST)

    for mon in get_monitors():
        subprocess.run(['swww', 'img', image_path, '--outputs', mon] + SWWW_PARAMS)

    #subprocess.run(['swww', 'img', image_path] + SWWW_PARAMS)

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
