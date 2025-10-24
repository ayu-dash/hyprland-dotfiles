import subprocess
import os.path as path
from Utils import getPid, killAll, loadJson

LAYOUT = path.expanduser('~/.config/wlogout/Layout')
STYLE = path.expanduser('~/.config/wlogout/Style.css')
PROCESS = 'wlogout'

W_PARAMS = {
    1920: 36,
    1360: 32,
}

H_PARAMS = {
    1080: 27,
    768: 24,
}

def getMonitorRes():
    monitor = subprocess.run(['hyprctl', 'monitors', '-j'], capture_output=True, text=True).stdout.strip()

    data = loadJson(monitor)[0]

    width = data['width']
    height = data['height']
    scale = data['scale']

    return width, height, scale

def main():
    if getPid(PROCESS):
        killAll(PROCESS)

    width, height, scale = getMonitorRes()

    xMargin = str(width * W_PARAMS[width] / (scale * 100))
    yMargin = str(height * H_PARAMS[height] / (scale * 100))

    subprocess.Popen([
        'wlogout',
        '--protocol', 'layer-shell',
        '-b', '2',
        '-R', xMargin,
        '-L', xMargin,
        '-T', yMargin,
        '-B', yMargin,
        '-C', STYLE,
        '-l', LAYOUT
    ])

if __name__ == "__main__":
    main()
