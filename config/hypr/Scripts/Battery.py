import subprocess
from Utils import notify, readFile

BAT = {
    'low': 20,
    'critical': 10
}

notified = set()

def watchBattery():
    process = subprocess.Popen([
            'dbus-monitor', '--system',
            "type='signal',interface='org.freedesktop.DBus.Properties',path='/org/freedesktop/UPower/devices/battery_BAT0'"
        ], stdout=subprocess.PIPE, text=True, bufsize=1)

    status = None
    capacity = None

    for line in process.stdout:
        line = line.strip()
        print(f"DBus Monitor Output: {line}")  # Debugging output
        if 'PropertiesChanged' in line:
            status = readFile('/sys/class/power_supply/BAT0/status').strip()
            capacity = int(readFile('/sys/class/power_supply/BAT0/capacity').strip())
            yield status, capacity

def sendNotification(status, capacity):
    global notified

    if status == 'Discharging':
        if capacity <= BAT['critical'] and 'critical' not in notified:
            notify('battery-000', f'Battery Critical! {capacity}%. Plug in charger now!', level='normal')
            notified.add('critical')
        elif capacity <= BAT['low'] and 'low' not in notified:
            notify('battery-low', f'Battery Low! {capacity}%. Consider plugging in the charger.', level='normal')
            notified.add('low')

    if status == 'Charging':
        notified.clear()

def main():
    for status, capacity in watchBattery():
        print(capacity)
        sendNotification(status, capacity)

if __name__ == '__main__':
    main()
