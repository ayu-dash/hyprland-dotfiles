import json
import subprocess
from pathlib import Path

BASE_WIDTH = 1366
BASE_FONT = 12
BASE_CC_WIDTH = 230
BASE_CC_HEIGHT = 512
CONFIG_PATH = Path(__file__).with_name("Config.json")

monitors = json.loads(subprocess.check_output(["hyprctl", "monitors", "-j"], text=True))
monitor = next((m for m in monitors if m.get("focused") is True), None)

if monitor is None:
    raise SystemExit("Tidak ada monitor yang sedang fokus")

name = monitor.get("name", "")
width = monitor.get("width", 0)
scale = monitor.get("scale", 1)

logical_width = round(float(width) / float(scale), 2)
ratio = round(logical_width / BASE_WIDTH, 3)

font = int(round(BASE_FONT * ratio))
cc_width = int(round(BASE_CC_WIDTH * ratio))
cc_height = int(round(BASE_CC_HEIGHT * ratio))

config = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
config["control-center-width"] = cc_width
config["control-center-height"] = cc_height
CONFIG_PATH.write_text(json.dumps(config, indent=4) + "\n", encoding="utf-8")

print(f"name={name}")
print(f"font={font}")
print(f"cc_width={cc_width}")
print(f"cc_height={cc_height}")
