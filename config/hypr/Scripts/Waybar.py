import subprocess
import argparse
import os.path as path
from Utils import readFile, getPid

CONFIG = readFile(path.expanduser('~/.config/waybar/config'))
STYLE = readFile(path.expanduser('~/.config/waybar/style'))
PROCESS = 'waybar'

def runWaybar():
    pid = getPid(PROCESS)
    if not pid:
        subprocess.Popen([
            PROCESS,
            '--log-level', 'error',
            '--config', CONFIG,
            '--style', STYLE
        ])

def killWaybar():
    subprocess.run(['killall', PROCESS])

def reloadWaybar():
        killWaybar()
        runWaybar()

def main():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        'action',
        choices=['run', 'kill', 'reload']
    )

    args = parser.parse_args()

    match(args.action):
        case 'run':
            runWaybar()
        case 'kill':
            killWaybar()
        case 'reload':
            reloadWaybar()

if __name__ == '__main__':
    main()
    