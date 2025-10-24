import subprocess
import json
import argparse
from Utils import notify
from Utils import getPid

PROCESS = 'hypridle'

def status():
    pid = getPid(PROCESS)
    status = {
         'text': 'OFF' if pid else 'ON',
         'class': 'inactive' if pid else 'active'
    }
    print(json.dumps(status))

def toggle():
    if getPid(PROCESS):
        subprocess.run(['killall', PROCESS])
        notify('system-lock-screen', 'Kahfein enabled!')
    else:
        subprocess.Popen([PROCESS])
        notify('system-lock-screen', 'Kahfein disabled!')

def main():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        'action',
        choices=['toggle', 'status']
    )

    args = parser.parse_args()

    match(args.action):
        case 'toggle': toggle()
        case 'status': status()

if __name__ == '__main__':
    main()
