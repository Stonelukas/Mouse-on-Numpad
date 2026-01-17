"""Daemon that connects hotkeys to mouse actions."""

import signal
import subprocess
import time
import threading
from pathlib import Path

import evdev

from .core import ConfigManager, StateManager, ErrorLogger
from .input import MonitorManager, PositionMemory, AudioFeedback, ScrollController
from .input.movement_controller import MovementController
from .tray_icon import TrayIcon

# Status file for IPC with GUI indicator
STATUS_FILE = Path("/tmp/mouse-on-numpad-status")
# ydotool scroll multiplier - ydotool uses larger values than UInput for visible scrolling
YDOTOOL_SCROLL_MULTIPLIER = 15


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
        self._running = False
        self._devices: list[evdev.InputDevice] = []
        self._threads: list[threading.Thread] = []
        self._held_keys: set[int] = set()
        self._held_buttons: set[str] = set()  # Mouse buttons held via toggle (left, middle)
        self._save_mode = False  # Position save mode active
        self._load_mode = False  # Position load mode active
        self._indicator_proc: subprocess.Popen[bytes] | None = None

        # Build key mappings from config (allows customization)
        self._load_hotkeys()

    def _load_hotkeys(self) -> None:
        """Load hotkey mappings from config."""
        # Mode toggle keys
        self._key_toggle = self.config.get("hotkeys.toggle_mode", 78)
        self._key_save_mode = self.config.get("hotkeys.save_mode", 55)
        self._key_load_mode = self.config.get("hotkeys.load_mode", 74)
        self._key_undo = self.config.get("hotkeys.undo", 98)

        # Click actions - build reverse map from keycode to action
        self._click_actions: dict[int, str] = {
            self.config.get("hotkeys.left_click", 76): "left",
            self.config.get("hotkeys.right_click", 82): "right",
            self.config.get("hotkeys.middle_click", 96): "middle",
        }

        # Movement keys - map keycode to direction tuple
        self._movement_keys: dict[int, tuple[str, ...]] = {
            self.config.get("hotkeys.move_up", 72): ("up",),
            self.config.get("hotkeys.move_down", 80): ("down",),
            self.config.get("hotkeys.move_left", 75): ("left",),
            self.config.get("hotkeys.move_right", 77): ("right",),
        }

        # Scroll keys
        self._scroll_keys: dict[int, tuple[str, ...]] = {
            self.config.get("hotkeys.scroll_up", 71): ("up",),
            self.config.get("hotkeys.scroll_down", 79): ("down",),
            self.config.get("hotkeys.scroll_right", 73): ("right",),
            self.config.get("hotkeys.scroll_left", 81): ("left",),
        }

        # Hold keys
        self._hold_keys: dict[int, str] = {
            self.config.get("hotkeys.hold_left", 83): "left",
        }

        # Position slots
        self._slot_keys: dict[int, int] = {
            self.config.get("hotkeys.slot_1", 75): 1,
            self.config.get("hotkeys.slot_2", 76): 2,
            self.config.get("hotkeys.slot_3", 77): 3,
            self.config.get("hotkeys.slot_4", 72): 4,
            self.config.get("hotkeys.slot_5", 82): 5,
        }

        # Modifier combo keys (require Alt held)
        self._key_secondary_monitor = self.config.get("hotkeys.secondary_monitor", 73)

    def reload_hotkeys(self) -> None:
        """Reload hotkeys from config (called after settings change).

        Safely stops any active movement/scroll before updating key mappings
        to prevent orphaned movement threads.
        """
        # Stop active movement/scroll to prevent orphaned state
        self.movement.stop_all()
        self.scroll.stop_all()
        self._release_all_held_buttons()
        self._save_mode = False
        self._load_mode = False

        # Reload config and update key mappings
        self.config.reload()
        self._load_hotkeys()
        self.logger.info("Hotkeys reloaded from config")

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

    # Modifier keycodes
    KEY_LEFTALT = 56
    KEY_RIGHTALT = 100

    def _is_alt_held(self) -> bool:
        """Check if Alt modifier is currently held."""
        return self.KEY_LEFTALT in self._held_keys or self.KEY_RIGHTALT in self._held_keys

    def _handle_key(self, keycode: int, pressed: bool) -> bool:
        """Handle a key event. Returns True if key should be suppressed."""
        # Track modifier keys (Alt)
        if keycode in (self.KEY_LEFTALT, self.KEY_RIGHTALT):
            if pressed:
                self._held_keys.add(keycode)
            else:
                self._held_keys.discard(keycode)
            return False  # Don't suppress modifier keys

        # Toggle mouse mode with configured key (default: Numpad+)
        if keycode == self._key_toggle and pressed:
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

        # Handle position memory modes
        if keycode == self._key_save_mode and pressed:
            self._save_mode = not self._save_mode
            self._load_mode = False  # Mutual exclusion
            print(f"Save mode: {'ON' if self._save_mode else 'OFF'}")
            return True

        if keycode == self._key_load_mode and pressed:
            self._load_mode = not self._load_mode
            self._save_mode = False  # Mutual exclusion
            print(f"Load mode: {'ON' if self._load_mode else 'OFF'}")
            return True

        # Handle slot keys when in save/load mode
        if keycode in self._slot_keys and pressed:
            if self._save_mode:
                self._save_position_to_slot(self._slot_keys[keycode])
                self._save_mode = False
                return True
            elif self._load_mode:
                self._load_position_from_slot(self._slot_keys[keycode])
                self._load_mode = False
                return True

        # Handle click actions
        if keycode in self._click_actions:
            if pressed:
                button = self._click_actions[keycode]
                self.mouse.click(button)
            return True  # Suppress click keys

        # Handle movement keys
        if keycode in self._movement_keys:
            directions = self._movement_keys[keycode]
            if pressed:
                # Start moving in direction(s)
                for direction in directions:
                    self.movement.start_direction(direction)
            else:
                # Stop moving in direction(s)
                for direction in directions:
                    self.movement.stop_direction(direction)
            return True  # Suppress movement keys

        # Handle Alt+secondary_monitor to cycle monitors (before scroll check)
        if keycode == self._key_secondary_monitor and pressed and self._is_alt_held():
            self._cycle_monitor()
            return True  # Suppress this key

        # Handle scroll keys (only if Alt not held for secondary_monitor key)
        if keycode in self._scroll_keys:
            # Skip if this is secondary_monitor key with Alt (handled above)
            if keycode == self._key_secondary_monitor and self._is_alt_held():
                return True
            directions = self._scroll_keys[keycode]
            if pressed:
                for direction in directions:
                    self.scroll.start_direction(direction)
            else:
                for direction in directions:
                    self.scroll.stop_direction(direction)
            return True  # Suppress scroll keys

        # Handle hold keys (toggle mouse button hold for drag operations)
        if keycode in self._hold_keys and pressed:
            button = self._hold_keys[keycode]
            if button in self._held_buttons:
                # Release the button
                self.mouse.release(button)
                self._held_buttons.discard(button)
            else:
                # Press and hold the button
                self.mouse.press(button)
                self._held_buttons.add(button)
            return True  # Suppress hold keys

        # Handle undo with configured key (default: NumpadSlash)
        if keycode == self._key_undo and pressed:
            self.movement.undo()
            return True  # Suppress undo key

        return False  # Don't suppress other keys

    def _release_all_held_buttons(self) -> None:
        """Release all held mouse buttons."""
        for button in list(self._held_buttons):
            self.mouse.release(button)
        self._held_buttons.clear()

    def _get_mouse_position(self) -> tuple[int, int] | None:
        """Get current mouse position using xdotool (X11/XWayland)."""
        try:
            result = subprocess.run(
                ["xdotool", "getmouselocation", "--shell"],
                capture_output=True, text=True, check=True
            )
            # Parse "X=123\nY=456\n..."
            pos = {}
            for line in result.stdout.strip().split("\n"):
                if "=" in line:
                    k, v = line.split("=", 1)
                    pos[k] = int(v)
            return (pos.get("X", 0), pos.get("Y", 0))
        except (subprocess.CalledProcessError, FileNotFoundError, ValueError):
            return None

    def _move_to_position(self, x: int, y: int) -> None:
        """Move mouse to absolute position using xdotool."""
        subprocess.run(["xdotool", "mousemove", str(x), str(y)], check=False)

    def _save_position_to_slot(self, slot: int) -> None:
        """Save current mouse position to slot."""
        pos = self._get_mouse_position()
        if pos:
            self.positions.save_position(slot, pos[0], pos[1])
            print(f"Saved position {pos} to slot {slot}")
        else:
            print("Cannot get mouse position (xdotool required)")

    def _load_position_from_slot(self, slot: int) -> None:
        """Load and move to position from slot."""
        pos = self.positions.load_position(slot)
        if pos:
            self._move_to_position(pos[0], pos[1])
            print(f"Moved to slot {slot}: {pos}")
        else:
            print(f"No position saved in slot {slot}")

    def _cycle_monitor(self) -> None:
        """Move cursor to center of next monitor (cycling)."""
        pos = self._get_mouse_position()
        if not pos:
            print("Cannot get mouse position (xdotool required)")
            return

        next_center = self.monitors.get_next_monitor_center(pos[0], pos[1])
        if next_center:
            self._move_to_position(next_center[0], next_center[1])
            print(f"Moved to next monitor: {next_center}")
        else:
            print("Only one monitor detected")

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
