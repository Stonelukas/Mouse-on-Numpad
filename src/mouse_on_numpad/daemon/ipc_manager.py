"""IPC management for status file and GUI indicator subprocess."""

import subprocess
from pathlib import Path


# Status file for IPC with GUI indicator
STATUS_FILE = Path("/tmp/mouse-on-numpad-status")


class IPCManager:
    """Manages IPC with GUI indicator (status file and subprocess)."""

    def __init__(self) -> None:
        self._indicator_proc: subprocess.Popen[bytes] | None = None

    def write_status(self, enabled: bool) -> None:
        """Write status to file for GUI indicator IPC."""
        try:
            STATUS_FILE.write_text("enabled" if enabled else "disabled")
        except OSError:
            pass  # Ignore file write errors

    def start_indicator(self) -> None:
        """Start indicator as subprocess (GTK 4 layer shell, separate from GTK 3 tray)."""
        import sys
        import os

        env = os.environ.copy()
        # gtk4-layer-shell must be preloaded before libwayland-client
        env["LD_PRELOAD"] = "/usr/lib/libgtk4-layer-shell.so"
        self._indicator_proc = subprocess.Popen(
            [sys.executable, "-m", "mouse_on_numpad", "--indicator"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            env=env,
        )

    def stop_indicator(self) -> None:
        """Stop indicator subprocess."""
        if self._indicator_proc:
            self._indicator_proc.terminate()

    def cleanup_status_file(self) -> None:
        """Clean up status file."""
        try:
            STATUS_FILE.unlink(missing_ok=True)
        except OSError:
            pass
