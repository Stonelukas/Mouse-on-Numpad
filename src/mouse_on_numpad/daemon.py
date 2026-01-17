"""Daemon that connects hotkeys to mouse actions."""

import signal
import subprocess
import time
import threading
import evdev

from .core import ConfigManager, StateManager, ErrorLogger
from .input import MonitorManager, PositionMemory, AudioFeedback


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
            subprocess.run(["ydotool", "mousemove", "--wheel", "-y", str(dy * 15)], check=False)

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

    NUMPAD_ACTIONS = {
        76: "click",       # KEY_KP5 - left click
        82: "right",       # KEY_KP0 - right click
        96: "middle",      # KEY_KPENTER - middle click
        72: "up",          # KEY_KP8 - move up
        80: "down",        # KEY_KP2 - move down
        75: "left",        # KEY_KP4 - move left
        77: "right_dir",   # KEY_KP6 - move right
        71: "up_left",     # KEY_KP7 - diagonal
        73: "up_right",    # KEY_KP9 - diagonal
        79: "down_left",   # KEY_KP1 - diagonal
        81: "down_right",  # KEY_KP3 - diagonal
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
        self._running = False
        self._devices: list[evdev.InputDevice] = []
        self._threads: list[threading.Thread] = []
        self._held_keys: set[int] = set()

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
            self.logger.info("Mouse mode: %s", "enabled" if enabled else "disabled")
            print(f"Mouse mode: {'ENABLED' if enabled else 'DISABLED'}")
            return True  # Suppress this key

        # Only process movement/click keys when enabled
        if not self.state.is_enabled:
            return False  # Let key pass through

        # Check if this is a numpad key we handle
        if keycode not in self.NUMPAD_ACTIONS:
            return False

        if pressed:
            self._held_keys.add(keycode)
            # Process movement on press AND repeat
        else:
            self._held_keys.discard(keycode)
            return True  # Suppress release too

        action = self.NUMPAD_ACTIONS.get(keycode)
        if action is None:
            return False

        speed = self.config.get("movement.base_speed", 10)

        if action == "click":
            self.mouse.click("left")
        elif action == "right":
            self.mouse.click("right")
        elif action == "middle":
            self.mouse.click("middle")
        elif action == "up":
            self.mouse.move(0, -speed)
        elif action == "down":
            self.mouse.move(0, speed)
        elif action == "left":
            self.mouse.move(-speed, 0)
        elif action == "right_dir":
            self.mouse.move(speed, 0)
        elif action == "up_left":
            self.mouse.move(-speed, -speed)
        elif action == "up_right":
            self.mouse.move(speed, -speed)
        elif action == "down_left":
            self.mouse.move(-speed, speed)
        elif action == "down_right":
            self.mouse.move(speed, speed)

        return True  # Suppress numpad keys when mouse mode enabled

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

        self.logger.info("Daemon started. Mouse mode: DISABLED")
        print("Mouse on Numpad daemon started (evdev backend).")
        print("Press Numpad+ to toggle mouse mode ON/OFF")
        print(f"Monitoring {len(self._devices)} keyboard(s)")
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
        for dev in self._devices:
            try:
                dev.close()
            except OSError:
                pass
        self.logger.info("Daemon stopped.")
        print("\nDaemon stopped.")
