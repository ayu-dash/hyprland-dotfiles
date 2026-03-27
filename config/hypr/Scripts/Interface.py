from Utils import run_capture, run_silent

def get_interface_icon():
    # Get default interface
    stdout, _, _ = run_capture(["ip", "route"])
    default_iface = ""
    for line in stdout.splitlines():
        if line.startswith("default"):
            parts = line.split()
            if "dev" in parts:
                default_iface = parts[parts.index("dev") + 1]
            break
            
    if not default_iface:
        return "󱐅"
        
    # Ping 1.1.1.1
    if run_silent(["ping", "-q", "-c", "1", "-W", "1", "1.1.1.1"]) == 0:
        if default_iface.startswith("wl"):
            return ""
        elif default_iface.startswith(("en", "eth")):
            return "󰈀"
        return "󰈀" # generic net
    
    return "󱐅"

if __name__ == "__main__":
    print(get_interface_icon())
