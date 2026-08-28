from Utils import hyprctl
import os.path as path
import os

BASE_WIDTH = 1366
BASE_FONT = 12
BASE_HEIGHT = 30
BASE_SPACING = 4
BASE_PADDING = 8
SIZE_CSS = path.join(path.dirname(__file__), "../Resources/size.css")

monitors = hyprctl("monitors", json_output=True)

css_blocks = []

for monitor in monitors:
    name = monitor.get("name", "Unknown").replace(" ", "-")
    width = monitor.get("width", "Unknown")
    scale = monitor.get("scale", "Unknown")

    logical_width = round(float(width) / float(scale), 2)
    ratio = round(logical_width / BASE_WIDTH, 3)

    font = int(BASE_FONT * ratio)
    height = int(BASE_HEIGHT * ratio)
    spacing = int(BASE_SPACING * ratio)
    padding = int(BASE_PADDING * ratio)

    css_block = f"""#waybar.{name} {{
  font-size: {font}px;
  min-height: {height}px;
}}
"""
    css_blocks.append(css_block)

os.makedirs(os.path.dirname(SIZE_CSS), exist_ok=True)
with open(SIZE_CSS, "w", encoding="utf-8") as css_file:
    css_file.write("\n\n".join(css_blocks))

print("\n\n".join(css_blocks))

