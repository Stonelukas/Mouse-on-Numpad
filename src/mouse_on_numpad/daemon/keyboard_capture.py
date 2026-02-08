"""Keyboard device discovery and event reading for evdev."""

import threading
import evdev

from ..core import ErrorLogger


# Modifier keycodes
KEY_LEFTALT = 56
KEY_RIGHTALT = 100

# Numpad detection keycodes
KEY_KP5 = 76
KEY_KP8 = 72

# Key event values
KEY_PRESSED = 1
KEY_REPEAT = 2


class KeyboardCapture:
    """Handles keyboard device discovery and event reading."""

    def __init__(self, logger: ErrorLogger) -> None:
        self.logger = logger
        self._running = False
        self._devices: list[evdev.InputDevice] = []
        self._threads: list[threading.Thread] = []

    def find_keyboards(self) -> list[evdev.InputDevice]:
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
                    if KEY_KP5 in keys or KEY_KP8 in keys:
                        keyboards.append(dev)
                        self.logger.info("Found keyboard: %s", dev.name)
            except (OSError, IOError):
                continue
        return keyboards

    def read_device(
        self, device: evdev.InputDevice, handle_key_callback, running_check
    ) -> None:
        """Read events from a device in a thread.

        Args:
            device: evdev InputDevice to read from
            handle_key_callback: Function(keycode, pressed) -> bool for handling key events
            running_check: Function() -> bool to check if daemon is still running
        """
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
                if not running_check():
                    break
                if event.type == evdev.ecodes.EV_KEY:
                    pressed = event.value in (KEY_PRESSED, KEY_REPEAT)
                    suppress = handle_key_callback(event.code, pressed)
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
