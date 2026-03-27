from Utils import run_capture

def main():
    album, _, _ = run_capture(["playerctl", "metadata", "--format", "{{ xesam:album }}"])
    if album:
        print(album)
    else:
        status, _, _ = run_capture(["playerctl", "status"])
        if status:
            print("Not album")
        else:
            print("")

if __name__ == "__main__":
    main()
