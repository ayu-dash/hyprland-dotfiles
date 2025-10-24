import subprocess
import argparse
import os.path as path
from Utils import notify, notifyWithProgress

MIN = 0
MAX = 100
DEFAULT_STEP=5

icon_dir  = path.expanduser('~/.config/swaync/icons')

def getVolume():
    output = subprocess.run(['wpctl', 'get-volume', '@DEFAULT_AUDIO_SINK@'], capture_output=True, text=True)
    result = output.stdout.strip().split()

    isMuted = result[-1] != '[MUTED]'
    currVolume = int(float(result[1]) * 100)

    return {'value': currVolume, 'muted': isMuted}

def isMicMuted():
    output = subprocess.run(['wpctl', 'get-volume', '@DEFAULT_AUDIO_SOURCE@'], capture_output=True, text=True)
    result = output.stdout.strip().split()

    return result[-1] != '[MUTED]'

def getVolumeIcon(value, isMuted):
    if value == 0 or isMuted:
        return path.join(icon_dir, 'volume-mute.png')
    elif value <= 30:
        return path.join(icon_dir, 'volume-low.png')
    elif value <= 60:
        return path.join(icon_dir, 'volume-mid.png')
    else:
        return path.join(icon_dir, 'volume-high.png')

def getMicIcon(isMuted):
    if isMuted:
        return path.join(icon_dir, 'microphone-mute.png')
    else:
        return path.join(icon_dir, 'microphone.png')

def audioUnmute():
    subprocess.run(['wpctl', 'set-mute', '@DEFAULT_AUDIO_SINK@', '0'])

def audioMuteToggle():
    currVolume = getVolume()
    status = 'Muted' if currVolume['muted'] else 'Unmuted'

    subprocess.run(['wpctl', 'set-mute', '@DEFAULT_AUDIO_SINK@', 'toggle'])
    notify(getVolumeIcon(currVolume['value'], currVolume['muted']), f'Volume is {status}')

def micMuteToggle():
    isMuted = isMicMuted()
    status = 'Muted' if isMuted else 'Unmuted'

    subprocess.run(['wpctl', 'set-mute', '@DEFAULT_AUDIO_SOURCE@', 'toggle'])
    notify(getMicIcon(isMuted), f'Microphone is {status}')

def adjustVolume(step, action='raise'):
    currVolume = getVolume()
    newVolume = currVolume['value'] + step if action == 'raise' else currVolume['value'] - step

    newVolume = min(newVolume, MAX)
    audioUnmute()
    subprocess.run(['wpctl', 'set-volume', '@DEFAULT_AUDIO_SINK@', f'{newVolume}%'])
    notifyWithProgress(getVolumeIcon(newVolume, False), f'Volume Level: {newVolume}%', newVolume)

def main():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        'audioAction',
        choices=['raiseVolume', 'lowerVolume', 'muteToggle', 'micToggle']
    )

    parser.add_argument(
        '--step',
        type=int,
        default=DEFAULT_STEP
    )

    args = parser.parse_args()

    match args.audioAction:
        case 'raiseVolume':
            adjustVolume(args.step, 'raise')
        case 'lowerVolume':
            adjustVolume(args.step, 'lower')
        case 'muteToggle':
            audioMuteToggle()
        case 'micToggle':
            micMuteToggle()

if __name__ == '__main__':
    main()
