"""
Utility functions for Hyprland scripts.
Provides common helpers for notifications, file operations, process management, and logging.
"""

import json
import logging
import subprocess
from datetime import datetime
from logging.handlers import RotatingFileHandler
from pathlib import Path
from typing import Any


# Logging configuration
LOG_DIR: Path = Path.home() / ".cache/hypr/logs"
LOG_FORMAT: str = "%(asctime)s | %(levelname)-8s | %(name)s | %(message)s"
LOG_DATE_FORMAT: str = "%Y-%m-%d %H:%M:%S"
LOG_MAX_BYTES: int = 1024 * 1024  # 1MB per file
LOG_BACKUP_COUNT: int = 3  # Keep 3 rotated files


def setup_logging() -> None:
    """Initialize the logging directory."""
    LOG_DIR.mkdir(parents=True, exist_ok=True)


def get_logger(name: str, level: int = logging.DEBUG) -> logging.Logger:
    """
    Get or create a logger with file and console handlers.
    
    Args:
        name: Name of the logger (typically script name)
        level: Logging level (default: DEBUG)
        
    Returns:
        Configured logger instance
    """
    setup_logging()
    
    logger = logging.getLogger(name)
    
    # Avoid adding duplicate handlers
    if logger.handlers:
        return logger
    
    logger.setLevel(level)
    
    # File handler with rotation
    log_file = LOG_DIR / f"{name}.log"
    file_handler = RotatingFileHandler(
        log_file,
        maxBytes=LOG_MAX_BYTES,
        backupCount=LOG_BACKUP_COUNT,
        encoding="utf-8"
    )
    file_handler.setLevel(logging.DEBUG)
    file_handler.setFormatter(logging.Formatter(LOG_FORMAT, LOG_DATE_FORMAT))
    
    # Console handler for errors only
    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.ERROR)
    console_handler.setFormatter(logging.Formatter("%(levelname)s: %(message)s"))
    
    logger.addHandler(file_handler)
    logger.addHandler(console_handler)
    
    return logger


def clean_old_logs(days: int = 7) -> None:
    """
    Remove log files older than specified days.
    
    Args:
        days: Number of days to keep logs (default: 7)
    """
    if not LOG_DIR.exists():
        return
    
    cutoff = datetime.now().timestamp() - (days * 86400)
    
    for log_file in LOG_DIR.glob("*.log*"):
        if log_file.stat().st_mtime < cutoff:
            log_file.unlink()

def notify(icon: str, msg: str, level: str = "low") -> None:
    """Send a desktop notification using notify-send."""
    run_silent([
        "notify-send",
        "-e",
        "-a", "volume-notify",
        "-h", "string:x-canonical-private-synchronous:sys_notif",
        "-u", level,
        "-i", icon,
        msg
    ])


def notify_with_progress(icon: str, msg: str, value: int, level: str = "low") -> None:
    """Send a desktop notification with a progress bar."""
    run_silent([
        "notify-send",
        "-e",
        "-h", f"int:value:{value}",
        "-h", "string:x-canonical-private-synchronous:sys_notif",
        "-c", "custom",
        "-u", level,
        "-i", icon,
        msg
    ])


def read_file(path: str | Path) -> str:
    """Read and return the contents of a file."""
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


def read_config(path: str | Path) -> dict[str, str] | None:
    """
    Parse a key=value configuration file into a dictionary.
    Returns None if the file is empty or invalid.
    """
    try:
        content = read_file(path)
        config: dict[str, str] = {}

        for line in content.splitlines():
            if "=" not in line:
                continue
            key, value = line.split("=", 1)
            config[key.strip()] = value.strip()

        return config if config else None
    except (FileNotFoundError, IOError):
        return None


def get_pid(process: str) -> str:
    """Get the PID of a running process."""
    stdout, _, _ = run_capture(["pidof", process])
    return stdout


def kill_all(process: str) -> None:
    """Terminate all instances of a process quietly and wait for completion."""
    run_silent(["killall", "-qw", process])


def load_json(data: str) -> Any:
    """Parse a JSON string and return the resulting object."""
    return json.loads(data)


def write_json(data: Any, path: str | Path) -> None:
    """Write data to a JSON file with indentation."""
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)


# =============================================================================
# Hyprland Utilities
# =============================================================================

def hyprctl(*args: str, json_output: bool = False) -> str | dict | list:
    """
    Execute a hyprctl command and return the output.
    
    Args:
        *args: Arguments to pass to hyprctl
        json_output: If True, parse output as JSON
        
    Returns:
        Command output as string or parsed JSON
    """
    cmd = ["hyprctl"] + list(args)
    if json_output:
        cmd.append("-j")
    
    stdout, _, _ = run_capture(cmd)
    
    if json_output:
        return json.loads(stdout) if stdout else {}
    return stdout


def hyprctl_keyword(keyword: str, value: str) -> None:
    """Set a Hyprland keyword value."""
    run_silent(["hyprctl", "keyword", keyword, value])


def hyprctl_batch(*commands: str) -> None:
    """Execute multiple hyprctl commands in batch."""
    batch_cmd = ";".join(commands)
    run_silent(["hyprctl", "--batch", batch_cmd])


def hyprctl_reload() -> None:
    """Reload Hyprland configuration."""
    run_silent(["hyprctl", "reload"])


def get_monitors() -> list[dict]:
    """Get list of connected monitors with their properties."""
    return hyprctl("monitors", json_output=True)


def get_active_window() -> dict:
    """Get information about the currently focused window."""
    return hyprctl("activewindow", json_output=True)


def get_theme_dir() -> Path:
    """Get the current theme directory path."""
    theme_vars = Path.home() / ".config/hypr/Themes/ThemeVariables.conf"
    if theme_vars.exists():
        content = theme_vars.read_text()
        for line in content.splitlines():
            if "$theme_dir" in line and "=" in line:
                path = line.split("=", 1)[1].strip()
                path = path.replace("$HOME", str(Path.home()))
                return Path(path)
    return Path.home() / ".config/hypr/Themes/NierAutomata"


# =============================================================================
# Process Utilities
# =============================================================================

def run_bg(cmd: list[str], **kwargs) -> subprocess.Popen:
    """
    Run a command in background with suppressed output.
    
    Args:
        cmd: Command and arguments as list
        **kwargs: Additional arguments for Popen
        
    Returns:
        Popen process object
    """
    defaults = {
        "stdout": subprocess.DEVNULL,
        "stderr": subprocess.DEVNULL,
    }
    defaults.update(kwargs)
    return subprocess.Popen(cmd, **defaults)


def is_running(process: str) -> bool:
    """Check if a process is currently running."""
    return bool(get_pid(process))


def run_silent(cmd: list[str]) -> int:
    """Run a command silently and return exit code."""
    result = subprocess.run(
        cmd,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL
    )
    return result.returncode


def run_capture(cmd: list[str]) -> tuple[str, str, int]:
    """
    Run a command and capture stdout, stderr, and return code.
    
    Returns:
        Tuple of (stdout, stderr, returncode)
    """
    result = subprocess.run(cmd, capture_output=True, text=True)
    return result.stdout.strip(), result.stderr.strip(), result.returncode


def run_with_input(cmd: list[str], input_data: str | bytes, text: bool = True) -> tuple[str | bytes, int]:
    """
    Run a command with input data piped to stdin and capture stdout.
    Useful for rofi -dmenu and similar interactive commands.
    
    Args:
        cmd: Command and arguments as list
        input_data: Data to send to stdin
        text: If True, handle as text; if False, handle as bytes
        
    Returns:
        Tuple of (stdout, returncode)
    """
    result = subprocess.run(cmd, input=input_data, capture_output=True, text=text)
    output = result.stdout.strip() if text and isinstance(result.stdout, str) else result.stdout
    return output, result.returncode


def run_pipeline(cmd1: list[str], cmd2: list[str], **kwargs) -> int:
    """
    Run two commands in a pipeline (cmd1 | cmd2).
    
    Args:
        cmd1: First command (stdout piped to cmd2)
        cmd2: Second command (receives stdin from cmd1)
        **kwargs: Additional arguments for the second Popen
        
    Returns:
        Return code of the second process
    """
    defaults = {
        "stdout": subprocess.DEVNULL,
        "stderr": subprocess.DEVNULL,
    }
    defaults.update(kwargs)
    p1 = subprocess.Popen(cmd1, stdout=subprocess.PIPE)
    p2 = subprocess.Popen(cmd2, stdin=p1.stdout, **defaults)
    if p1.stdout:
        p1.stdout.close()
    p2.wait()
    return p2.returncode


# Re-export subprocess constants for convenience
PIPE = subprocess.PIPE
DEVNULL = subprocess.DEVNULL