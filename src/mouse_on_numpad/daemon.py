"""Daemon that connects hotkeys to mouse actions."""

import signal
import subprocess
import time
import threading
from pathlib import Path
import evdev

from .core import ConfigManager, StateManager, ErrorLogger
from .input import MonitorManager, PositionMemory, AudioFeedback, ScrollController

# Status file for IPC with GUI indicator
STATUS_FILE = Path("/tmp/mouse-on-numpad-status")
# ydotool scroll multiplier - ydotool uses larger values than UInput for visible scrolling
YDOTOOL_SCROLL_MULTIPLIER = 15
from .input.movement_controller import MovementController
from .tray_icon import TrayIcon


class YdotoolMouse:
    """Mouse controller using ydotool (fallback for systems without uinput)."""

    def move(self, dx: int, dy: int) -> None:
        """Move mouse relative to current position."""
        subprocess.run(["ydotool", "mousemove", "-x", str(dx), "-y", str(dy)], check=False)

    def click(self, button: str = "left") -> None:
        """Click mouse button."""
        btn_map = {"left": "0xC0", "right": "0xC1", "middle": "0xC2"}
        btn = btn_map.get(button, "0xC0")
        subprocess.run(["ydotool", "click", btn], check=False)

    def scroll(self, dx: int, dy: int) -> None:
        """Scroll mouse wheel."""
        if dy != 0:
            subprocess.run(
                ["ydotool", "mousemove", "--wheel", "-y", str(dy * YDOTOOL_SCROLL_MULTIPLIER)],
                check=False,
            )

    def close(self) -> None:
        """No cleanup needed for ydotool."""
        pass


def create_mouse_controller(logger: ErrorLogger) -> "YdotoolMouse | UinputMouse":
    """Create best available mouse controller (UInput preferred, ydotool fallback).

    Args:
        logger: Error logger for status messages.

    Returns:
        UinputMouse if available, otherwise YdotoolMouse fallback.
    """
    try:
        from .input.uinput_mouse import UinputMouse
        mouse = UinputMouse()
        logger.info("Using UInput mouse controller (zero overhead)")
        return mouse
    except PermissionError as e:
        logger.warning("UInput permission denied: %s", e)
        logger.info("Falling back to ydotool")
        return YdotoolMouse()
    except OSError as e:
        logger.warning("UInput not available: %s", e)
        logger.info("Falling back to ydotool")
        return YdotoolMouse()


# Type alias for mouse controller
from .input.uinput_mouse import UinputMouse


class Daemon:
    """Main daemon connecting numpad keys to mouse control.

    Uses evdev for keyboard capture (works on Wayland) and pynput for mouse.
    """

    # Evdev keycodes for numpad
    KEY_KPPLUS = 78      # Toggle mouse mode (like Windows version)
    KEY_KPASTERISK = 55  # Save position mode
    KEY_KPMINUS = 74     # Load position mode

    # Click actions
    CLICK_ACTIONS = {
        76: "left",    # KEY_KP5 - left click
        82: "right",   # KEY_KP0 - right click
        96: "middle",  # KEY_KPENTER - middle click
    }

    # Movement keys (cardinal directions only - diagonals via multi-key)
    MOVEMENT_KEYS = {
        72: ("up",),           # KEY_KP8
        80: ("down",),         # KEY_KP2
        75: ("left",),         # KEY_KP4
        77: ("right",),        # KEY_KP6
    }

    # Scroll keys (corner numpad keys)
    SCROLL_KEYS = {
        71: ("up",),      # KEY_KP7 - scroll up
        79: ("down",),    # KEY_KP1 - scroll down
        73: ("right",),   # KEY_KP9 - scroll right (horizontal)
        81: ("left",),    # KEY_KP3 - scroll left (horizontal)
    }

    # Hold keys - toggle hold/release for drag operations
    HOLD_KEYS = {
        83: "left",   # KEY_KPDOT - toggle left click hold
    }

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
        self._running = False
        self._devices: list[evdev.InputDevice] = []
        self._threads: list[threading.Thread] = []
        self._held_keys: set[int] = set()
        self._held_buttons: set[str] = set()  # Mouse buttons held via toggle (left, middle)
        self._indicator_proc: subprocess.Popen[bytes] | None = None

    def _toggle_mode(self) -> None:
        """Toggle mouse mode (called from tray menu)."""
        enabled = self.state.toggle()
        if not enabled:
            self.movement.stop_all()
            self.scroll.stop_all()
            self._release_all_held_buttons()
        self.tray.update(enabled)
        self._write_status(enabled)
        self.logger.info("Mouse mode: %s", "enabled" if enabled else "disabled")
        print(f"Mouse mode: {'ENABLED' if enabled else 'DISABLED'}")

    def _write_status(self, enabled: bool) -> None:
        """Write status to file for GUI indicator IPC."""
        try:
            STATUS_FILE.write_text("enabled" if enabled else "disabled")
        except OSError:
            pass  # Ignore file write errors

    def _find_keyboards(self) -> list[evdev.InputDevice]:
        """Find all keyboard devices."""
        keyboards = []
        for path in evdev.list_devices():
            try:
                dev = evdev.InputDevice(path)
                caps = dev.capabilities()
                # Check if device has key events and numpad keys
                if evdev.ecodes.EV_KEY in caps:
                    keys = caps[evdev.ecodes.EV_KEY]
                    # Check for numpad keys
                    if 76 in keys or 72 in keys:  # KP5 or KP8
                        keyboards.append(dev)
                        self.logger.info("Found keyboard: %s", dev.name)
            except (OSError, IOError):
                continue
        return keyboards

    def _handle_key(self, keycode: int, pressed: bool) -> bool:
        """Handle a key event. Returns True if key should be suppressed."""
        # Toggle mouse mode with Numpad+ (like Windows version)
        if keycode == self.KEY_KPPLUS and pressed:
            enabled = self.state.toggle()
            if not enabled:
                # Stop all movement, scroll, and release held buttons when disabling
                self.movement.stop_all()
                self.scroll.stop_all()
                self._release_all_held_buttons()
            # Update tray icon and status file
            self.tray.update(enabled)
            self._write_status(enabled)
            self.logger.info("Mouse mode: %s", "enabled" if enabled else "disabled")
            print(f"Mouse mode: {'ENABLED' if enabled else 'DISABLED'}")
            return True  # Suppress this key

        # Only process movement/click keys when enabled
        if not self.state.is_enabled:
            return False  # Let key pass through

        # Handle click actions
        if keycode in self.CLICK_ACTIONS:
            if pressed:
                button = self.CLICK_ACTIONS[keycode]
                self.mouse.click(button)
            return True  # Suppress click keys

        # Handle movement keys
        if keycode in self.MOVEMENT_KEYS:
            directions = self.MOVEMENT_KEYS[keycode]
            if pressed:
                # Start moving in direction(s)
                for direction in directions:
                    self.movement.start_direction(direction)
            else:
                # Stop moving in direction(s)
                for direction in directions:
                    self.movement.stop_direction(direction)
            return True  # Suppress movement keys

        # Handle scroll keys
        if keycode in self.SCROLL_KEYS:
            directions = self.SCROLL_KEYS[keycode]
            if pressed:
                for direction in directions:
                    self.scroll.start_direction(direction)
            else:
                for direction in directions:
                    self.scroll.stop_direction(direction)
            return True  # Suppress scroll keys

        # Handle hold keys (toggle mouse button hold for drag operations)
        if keycode in self.HOLD_KEYS and pressed:
            button = self.HOLD_KEYS[keycode]
            if button in self._held_buttons:
                # Release the button
                self.mouse.release(button)
                self._held_buttons.discard(button)
            else:
                # Press and hold the button
                self.mouse.press(button)
                self._held_buttons.add(button)
            return True  # Suppress hold keys

        return False  # Don't suppress other keys

    def _release_all_held_buttons(self) -> None:
        """Release all held mouse buttons."""
        for button in list(self._held_buttons):
            self.mouse.release(button)
        self._held_buttons.clear()

    def _read_device(self, device: evdev.InputDevice) -> None:
        """Read events from a device in a thread."""
        try:
            # Grab device to prevent keys from reaching other apps
            device.grab()
            self.logger.info("Grabbed device: %s", device.name)
        except OSError:
            self.logger.warning("Could not grab device: %s", device.name)

        try:
            ui = evdev.UInput.from_device(device, name=f"mouse-on-numpad-{device.name}")
        except OSError:
            ui = None

        try:
            for event in device.read_loop():
                if not self._running:
                    break
                if event.type == evdev.ecodes.EV_KEY:
                    pressed = event.value in (1, 2)  # 1=press, 2=repeat
                    suppress = self._handle_key(event.code, pressed)
                    # Forward non-suppressed keys back to system
                    if not suppress and ui:
                        ui.write_event(event)
                        ui.syn()
                elif ui:
                    # Forward other events (SYN, etc.)
                    ui.write_event(event)
        except OSError:
            self.logger.warning("Device disconnected: %s", device.name)
        finally:
            try:
                device.ungrab()
            except OSError:
                pass
            if ui:
                ui.close()

    def start(self) -> None:
        """Start the daemon."""
        self._running = True

        # Find keyboards
        self._devices = self._find_keyboards()
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
        self._write_status(False)

        # Start indicator as subprocess (GTK 4 layer shell, separate from GTK 3 tray)
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

        self.logger.info("Daemon started. Mouse mode: DISABLED")
        print("Mouse on Numpad daemon started (evdev backend).")
        print("Press Numpad+ to toggle mouse mode ON/OFF")
        print(f"Monitoring {len(self._devices)} keyboard(s)")
        print("System tray + overlay indicator active.")
        print("Press Ctrl+C to stop.")

        # Start reader threads for each device
        for dev in self._devices:
            thread = threading.Thread(target=self._read_device, args=(dev,), daemon=True)
            thread.start()
            self._threads.append(thread)

        # Keep running
        while self._running:
            time.sleep(0.1)

    def stop(self) -> None:
        """Stop the daemon."""
        self._running = False
        # Stop movement and scroll threads
        self.movement.stop_all()
        self.scroll.stop_all()
        time.sleep(0.1)  # Allow threads to exit gracefully
        self.tray.stop()
        # Stop indicator subprocess
        if hasattr(self, "_indicator_proc") and self._indicator_proc:
            self._indicator_proc.terminate()
        # Clean up status file
        try:
            STATUS_FILE.unlink(missing_ok=True)
        except OSError:
            pass
        for dev in self._devices:
            try:
                dev.close()
            except OSError:
                pass
        self.logger.info("Daemon stopped.")
        print("\nDaemon stopped.")
