import sys
from Utils import run_capture

def get_metadata(key):
    stdout, _, _ = run_capture(["playerctl", "metadata", "--format", f"{{{{ {key} }}}}" ])
    return stdout

def get_source_info():
    trackid = get_metadata("mpris:trackid")
    if "firefox" in trackid.lower():
        return "Firefox 󰈹"
    elif "spotify" in trackid.lower():
        return "Spotify "
    return ""

def main():
    if len(sys.argv) < 2:
        return

    arg = sys.argv[1]
    
    if arg == "--title":
        title = get_metadata("xesam:title")
        print(title[:30] if title else "")
    elif arg == "--arturl":
        url = get_metadata("mpris:artUrl")
        if url.startswith("file://"):
            url = url[7:]
        print(url if url else "")
    elif arg == "--artist":
        artist = get_metadata("xesam:artist")
        print(artist[:30] if artist else "")
    elif arg == "--length":
        length = get_metadata("mpris:length")
        if length:
            try:
                # Convert length from microseconds to seconds
                seconds = int(length) // 1000000
                print(f"{seconds} seconds")
            except ValueError:
                print("")
        else:
            print("")
    elif arg == "--album":
        album = get_metadata("xesam:album")
        print(album if album else "")
    elif arg == "--source":
        print(get_source_info())
    elif arg == "--status":
        stdout, _, _ = run_capture(["playerctl", "status"])
        print(stdout if stdout else "")

if __name__ == "__main__":
    main()
