import subprocess
import json

def notify(icon, msg, level = 'low'):
    subprocess.run(
    ['notify-send',
        '-e',
        '-a', 'volume-notify',
        '-h', 'string:x-canonical-private-synchronous:sys_notif',
        '-u', level,
        '-i', icon,
        msg
    ])

def notifyWithProgress(icon, msg, value, level = 'low'):
    subprocess.run(
    ['notify-send',
        '-e',
        '-h', f'int:value:{value}',
        '-h', 'string:x-canonical-private-synchronous:sys_notif',
        '-c', 'custom',
        '-u', level,
        '-i', icon,
        msg
    ])

def readFile(path):
    with open(path, 'r') as f:
        return f.read()
    
def readConfig(path):
    dict = {}
    file = readFile(path)

    for line in file.splitlines():
        key = line.split('=')[0].strip()
        value = line.split('=')[1].strip()
        dict[key] = value

    if dict is not None:
        return dict
    
    return None

def getPid(process):
    return subprocess.run(['pidof', process], capture_output=True, text=True).stdout.strip()

def killAll(process):
    subprocess.run(["killall", process], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def loadJson(data):
    return json.loads(data)

def writeJson(data, path):
    with open(path, 'w') as f:
        json.dump(data, f, indent=2)