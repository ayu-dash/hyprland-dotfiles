import subprocess
import argparse
import os.path as path
from Utils import notifyWithProgress

DEFAULT_STEP = 10

icon_dir  = path.expanduser('~/.config/swaync/icons')

def getBrightnessPercentage():
    output = subprocess.run(['brightnessctl', '-m'], capture_output=True, text=True)
    result = output.stdout.split(',')[3].rstrip('%')
    
    return int(result)

def getBrightnessIcon(value):
    if value <= 60:
        return path.join(icon_dir, 'brightness-60.png')
    elif value <= 80:
        return path.join(icon_dir, 'brightness-80.png')
    else:
        return path.join(icon_dir, 'brightness-100.png')

def adjustBrightness(step, action='up'):
    val = f'{step}%+' if action == 'up' else f'{step}%-'
    subprocess.run(['brightnessctl', 's', f'{val}'])

    newVal = getBrightnessPercentage()
    notifyWithProgress(getBrightnessIcon(newVal), f'Brightness Level: {newVal}%', newVal)

def main():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        'action',
        choices=['up', 'down']
    )

    parser.add_argument(
        '--step',
        type=int,
        default=DEFAULT_STEP
    )

    args = parser.parse_args()

    match args.action:
        case 'up':
            adjustBrightness(args.step, 'up')
        case 'down':
            adjustBrightness(args.step, 'down')

if __name__ == '__main__':
    main()