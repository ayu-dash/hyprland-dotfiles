import subprocess
import os.path as path
from .Shared import ROFI_THEMES

THEME = path.join(ROFI_THEMES, 'RofiClipboard')

def exec():
    process = subprocess.Popen(
        ["cliphist", "list"],
        stdout=subprocess.PIPE
    )
    result = subprocess.run(
        ["rofi", "-dmenu", "-i", "-kb-secondary-copy", "", "-kb-custom-1", "Ctrl+c", "-theme", THEME],
        stdin=process.stdout,
        stdout=subprocess.PIPE
    )

    decodedResult = subprocess.run(
        ["cliphist", "decode"],
        input=result.stdout,
        stdout=subprocess.PIPE
    )

    subprocess.run(["wl-copy"], input=decodedResult.stdout)
