import sys
import os
import time
from pathlib import Path
from Utils import run_capture, read_file

CACHE_FILE = Path.home() / ".cache/wttr_cache.txt"
EXPIRY_TIME = 86400  # 24 hours

def get_weather():
    if not CACHE_FILE.parent.exists():
        CACHE_FILE.parent.mkdir(parents=True, exist_ok=True)
    
    if CACHE_FILE.exists():
        last_modified = CACHE_FILE.stat().st_mtime
        if time.time() - last_modified < EXPIRY_TIME:
            try:
                cached_data = read_file(CACHE_FILE).strip()
                if cached_data:
                    return cached_data
            except:
                pass

    # Fetch new data
    stdout, stderr, code = run_capture(["curl", "-s", "wttr.in?format=%c+%C+%t"])
    if code == 0 and stdout:
        with open(CACHE_FILE, "w") as f:
            f.write(stdout)
        return stdout
    
    return "Weather Unavailable"

if __name__ == "__main__":
    print(get_weather())
