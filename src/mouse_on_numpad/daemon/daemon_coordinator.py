"""Main daemon coordinator for mouse-on-numpad."""

import signal
import time
import threading

from ..core import ConfigManager, StateManager, ErrorLogger
from ..input import MonitorManager, PositionMemory, AudioFeedback, ScrollController
from ..input.movement_controller import MovementController
from ..tray_icon import TrayIcon

from .keyboard_capture import KeyboardCapture
from .hotkey_dispatcher import HotkeyDispatcher
from .ipc_manager import IPCManager
from .position_manager import PositionManager
from .mouse_factory import create_mouse_controller


# Main loop timing
MAIN_LOOP_INTERVAL = 0.1  # seconds
SHUTDOWN_GRACE_PERIOD = 0.1  # seconds


class Daemon:
    """Main daemon connecting numpad keys to mouse control.

    Uses evdev for keyboard capture (works on Wayland) and pynput for mouse.
    Hotkeys are configurable via config.json.
    """

    def __init__(
        self,
        config: ConfigManager | None = None,
        state: StateManager | None = None,
        logger: ErrorLogger | None = None,
    ) -> None:
        self.logger = logger or ErrorLogger(console_output=True)
        self.config = config or ConfigManager()
        self.state = state or StateManager()
        self.mouse = create_mouse_controller(self.logger)  # UInput preferred, ydotool fallback
        self.monitors = MonitorManager()
        self.positions = PositionMemory(self.config, self.monitors)
        self.audio = AudioFeedback(self.config)
        self.movement = MovementController(self.config, self.mouse)
        self.scroll = ScrollController(self.config, self.mouse)
        self.tray = TrayIcon(on_toggle=self._toggle_mode, on_quit=self.stop)

        # Delegate components
        self.keyboard = KeyboardCapture(self.logger)
        self.hotkeys = HotkeyDispatcher(self.config, self.logger)
        self.ipc = IPCManager()
        self.position_mgr = PositionManager(self.monitors, self.positions)

        self._running = False
        self._devices: list = []
        self._threads: list[threading.Thread] = []
        self._held_buttons: set[str] = set()  # Mouse buttons held via toggle (left, middle)
        self._save_mode = {"active": False}  # Position save mode active
        self._load_mode = {"active": False}  # Position load mode active

    def reload_hotkeys(self) -> None:
        """Reload hotkeys from config (called after settings change)."""
        self._save_mode["active"] = False
        self._load_mode["active"] = False
        self.hotkeys.reload_hotkeys(
            self.movement, self.scroll, self._release_all_held_buttons
        )

    def _toggle_mode(self) -> None:
        """Toggle mouse mode (called from tray menu)."""
        enabled = self.state.toggle()
        if not enabled:
            self.movement.stop_all()
            self.scroll.stop_all()
            self._release_all_held_buttons()
        self.tray.update(enabled)
        self.ipc.write_status(enabled)
        self.logger.info("Mouse mode: %s", "enabled" if enabled else "disabled")
        print(f"Mouse mode: {'ENABLED' if enabled else 'DISABLED'}")

    def _release_all_held_buttons(self) -> None:
        """Release all held mouse buttons."""
        for button in list(self._held_buttons):
            self.mouse.release(button)
        self._held_buttons.clear()

    def _handle_key(self, keycode: int, pressed: bool) -> bool:
        """Handle a key event. Returns True if key should be suppressed."""
        return self.hotkeys.handle_key(
            keycode,
            pressed,
            self.state,
            self.mouse,
            self.movement,
            self.scroll,
            self.tray,
            self.ipc.write_status,
            self._held_buttons,
            self._save_mode,
            self._load_mode,
            self.position_mgr.save_position_to_slot,
            self.position_mgr.load_position_from_slot,
            self.position_mgr.cycle_monitor,
        )

    def start(self) -> None:
        """Start the daemon."""
        self._running = True

        # Find keyboards
        self._devices = self.keyboard.find_keyboards()
        if not self._devices:
            print("ERROR: No keyboard devices found. Make sure you're in 'input' group.")
            print("Run: sudo usermod -aG input $USER && reboot")
            return

        # Set up signal handlers
        signal.signal(signal.SIGINT, lambda *_: self.stop())
        signal.signal(signal.SIGTERM, lambda *_: self.stop())

        # Start system tray icon
        self.tray.start()

        # Write initial status (disabled)
        self.ipc.write_status(False)

        # Start indicator subprocess
        self.ipc.start_indicator()

        self.logger.info("Daemon started. Mouse mode: DISABLED")
        print("Mouse on Numpad daemon started (evdev backend).")
        print("Press Numpad+ to toggle mouse mode ON/OFF")
        print(f"Monitoring {len(self._devices)} keyboard(s)")
        print("System tray + overlay indicator active.")
        print("Press Ctrl+C to stop.")

        # Start reader threads for each device
        for dev in self._devices:
            thread = threading.Thread(
                target=self.keyboard.read_device,
                args=(dev, self._handle_key, lambda: self._running),
                daemon=True,
            )
            thread.start()
            self._threads.append(thread)

        # Keep running
        while self._running:
            time.sleep(MAIN_LOOP_INTERVAL)

    def stop(self) -> None:
        """Stop the daemon."""
        self._running = False
        # Stop movement and scroll threads
        self.movement.stop_all()
        self.scroll.stop_all()
        time.sleep(SHUTDOWN_GRACE_PERIOD)  # Allow threads to exit gracefully
        self.tray.stop()
        # Stop indicator subprocess
        self.ipc.stop_indicator()
        # Clean up status file
        self.ipc.cleanup_status_file()
        for dev in self._devices:
            try:
                dev.close()
            except OSError:
                pass
        self.logger.info("Daemon stopped.")
        print("\nDaemon stopped.")
