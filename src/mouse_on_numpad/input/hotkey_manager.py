"""Global hotkey management for numpad keys."""

import logging
from collections.abc import Callable
from threading import Thread

from pynput import keyboard
from pynput.keyboard import Key, KeyCode

from mouse_on_numpad.core.state_manager import StateManager

_logger = logging.getLogger(__name__)


class HotkeyManager:
    """Manage global numpad hotkeys with NumLock handling.

    Features:
    - Global hotkey capture (works when app not focused)
    - Numpad key mapping with/without NumLock
    - Modifier support (Ctrl, Shift, Alt)
    - Per-key callback registration
    """

    # Numpad keycode mapping (KeyCode.vk values for numpad keys)
    NUMPAD_KEYS = {
        # NumLock OFF keycodes (navigation keys)
        65438: "kp_0",      # KP_Insert
        65436: "kp_1",      # KP_End
        65433: "kp_2",      # KP_Down
        65435: "kp_3",      # KP_Page_Down
        65430: "kp_4",      # KP_Left
        65437: "kp_5",      # KP_Begin
        65432: "kp_6",      # KP_Right
        65429: "kp_7",      # KP_Home
        65431: "kp_8",      # KP_Up
        65434: "kp_9",      # KP_Page_Up
        65439: "kp_decimal",  # KP_Delete
        65421: "kp_enter",  # KP_Enter
        65451: "kp_add",    # KP_Add (+)
        65453: "kp_subtract",  # KP_Subtract (-)
        65450: "kp_multiply",  # KP_Multiply (*)
        65455: "kp_divide",  # KP_Divide (/)
    }

    def __init__(self, state: StateManager) -> None:
        """Initialize HotkeyManager.

        Args:
            state: State manager for NumLock state tracking
        """
        self._state = state
        self._callbacks: dict[str, Callable[[], None]] = {}
        self._listener: keyboard.Listener | None = None
        self._running = False
        self._pressed_keys: set[Key | KeyCode] = set()

    def register(
        self,
        key: str,
        callback: Callable[[], None],
        modifiers: list[str] | None = None,
    ) -> None:
        """Register a hotkey callback.

        Args:
            key: Key name (e.g., "kp_5", "kp_add")
            callback: Function to call when hotkey is pressed
            modifiers: Optional modifier keys (["ctrl", "shift", "alt"])
        """
        if modifiers is None:
            modifiers = []

        # Create key signature with modifiers
        key_sig = "+".join(sorted(modifiers) + [key]) if modifiers else key
        self._callbacks[key_sig] = callback
        _logger.debug("Registered hotkey: %s", key_sig)

    def unregister(self, key: str) -> None:
        """Unregister a hotkey callback.

        Args:
            key: Key name to unregister
        """
        if key in self._callbacks:
            del self._callbacks[key]
            _logger.debug("Unregistered hotkey: %s", key)

    def start(self) -> None:
        """Start listening for hotkeys."""
        if self._running:
            return

        self._running = True
        self._listener = keyboard.Listener(
            on_press=self._on_press,
            on_release=self._on_release,
        )
        self._listener.start()
        _logger.info("Hotkey listener started")

    def stop(self) -> None:
        """Stop listening for hotkeys."""
        if not self._running:
            return

        self._running = False
        if self._listener:
            self._listener.stop()
            self._listener = None
        self._pressed_keys.clear()
        _logger.info("Hotkey listener stopped")

    def _on_press(self, key: Key | KeyCode | None) -> None:
        """Handle key press event.

        Args:
            key: Pressed key
        """
        if key is None:
            return

        # Track pressed keys for modifier combinations
        self._pressed_keys.add(key)

        # Only process when mouse mode is enabled (NumLock OFF)
        if not self._state.is_enabled:
            return

        # Identify the key
        key_name = self._identify_key(key)
        if key_name is None:
            return

        # Build current modifiers
        modifiers = self._get_active_modifiers()

        # Create key signature
        key_sig = "+".join(sorted(modifiers) + [key_name]) if modifiers else key_name

        # Execute callback if registered
        if key_sig in self._callbacks:
            try:
                self._callbacks[key_sig]()
            except Exception:
                _logger.exception("Hotkey callback failed for %s", key_sig)

    def _on_release(self, key: Key | KeyCode | None) -> None:
        """Handle key release event.

        Args:
            key: Released key
        """
        if key is None:
            return

        self._pressed_keys.discard(key)

    def _identify_key(self, key: Key | KeyCode) -> str | None:
        """Identify key name from Key or KeyCode.

        Args:
            key: Pressed key object

        Returns:
            Key name string or None if not recognized
        """
        # Handle special keys
        if isinstance(key, Key):
            return key.name

        # Handle numpad keys by virtual keycode
        if isinstance(key, KeyCode) and key.vk is not None:
            return self.NUMPAD_KEYS.get(key.vk)

        return None

    def _get_active_modifiers(self) -> list[str]:
        """Get list of currently pressed modifier keys.

        Returns:
            List of modifier names (["ctrl", "shift", "alt"])
        """
        modifiers = []
        for key in self._pressed_keys:
            if isinstance(key, Key):
                if key in (Key.ctrl_l, Key.ctrl_r, Key.ctrl):
                    if "ctrl" not in modifiers:
                        modifiers.append("ctrl")
                elif key in (Key.shift_l, Key.shift_r, Key.shift):
                    if "shift" not in modifiers:
                        modifiers.append("shift")
                elif key in (Key.alt_l, Key.alt_r, Key.alt, Key.alt_gr):
                    if "alt" not in modifiers:
                        modifiers.append("alt")
        return modifiers
