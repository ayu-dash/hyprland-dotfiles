from Utils import is_running, run_silent

def main():
    if not is_running("hostapd"):
        run_silent(["systemctl", "suspend"])
    else:
        # pidof hyprlock | hyprlock
        if not is_running("hyprlock"):
            run_silent(["hyprlock"])

if __name__ == "__main__":
    main()
