import sys
import os
import time
import json
from pathlib import Path
from Utils import run_capture, read_file

CACHE_FILE = Path.home() / ".cache/ip_cache.txt"
EXPIRY_TIME = 86400  # 24 hours

def get_location():
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

    # Fetch new data from ipinfo.io
    stdout, stderr, code = run_capture(["curl", "-s", "ipinfo.io"])
    if code == 0 and stdout:
        try:
            data = json.loads(stdout)
            location = f"{data.get('country', '')}, {data.get('city', '')}"
            with open(CACHE_FILE, "w") as f:
                f.write(location)
            return location
        except json.JSONDecodeError:
            pass
    
    return "Unknown Location"

if __name__ == "__main__":
    print(get_location())
