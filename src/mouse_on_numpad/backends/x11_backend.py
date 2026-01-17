"""X11 backend using pynput for full-featured input control.

This backend provides complete functionality on X11 sessions:
- Global hotkey capture
- Mouse position queries
- Absolute and relative movement
- All mouse buttons and scrolling
"""

from __future__ import annotations

import logging
from collections.abc import Callable

from pynput import keyboard
from pynput.keyboard import Key, KeyCode
from pynput.mouse import Button, Controller

from .base import InputBackend

_logger = logging.getLogger(__name__)


class X11Backend(InputBackend):
    """X11 input backend using pynput.

    Full-featured backend for X11 sessions. Uses pynput's platform-specific
    X11 implementation for complete mouse and keyboard control.

    Thread Safety:
        pynput's Controller is thread-safe for mouse operations.
        Hotkey callbacks execute in pynput's listener thread.
    """

    # Numpad keycode mapping (KeyCode.vk values for numpad keys)
    NUMPAD_KEYS = {
        # NumLock OFF keycodes (navigation keys)
        65438: "kp_0",  # KP_Insert
        65436: "kp_1",  # KP_End
        65433: "kp_2",  # KP_Down
        65435: "kp_3",  # KP_Page_Down
        65430: "kp_4",  # KP_Left
        65437: "kp_5",  # KP_Begin
        65432: "kp_6",  # KP_Right
        65429: "kp_7",  # KP_Home
        65431: "kp_8",  # KP_Up
        65434: "kp_9",  # KP_Page_Up
        65439: "kp_decimal",  # KP_Delete
        65421: "kp_enter",  # KP_Enter
        65451: "kp_add",  # KP_Add (+)
        65453: "kp_subtract",  # KP_Subtract (-)
        65450: "kp_multiply",  # KP_Multiply (*)
        65455: "kp_divide",  # KP_Divide (/)
    }

    def __init__(self) -> None:
        """Initialize X11 backend."""
        self._mouse = Controller()
        self._callbacks: dict[str, Callable[[], None]] = {}
        self._listener: keyboard.Listener | None = None
        self._pressed_keys: set[Key | KeyCode] = set()
        _logger.info("X11Backend initialized")

    def move_mouse(self, x: int, y: int) -> None:
        """Move mouse to absolute coordinates.

        Args:
            x: X coordinate
            y: Y coordinate
        """
        self._mouse.position = (x, y)

    def move_mouse_relative(self, dx: int, dy: int) -> None:
        """Move mouse relative to current position.

        Args:
            dx: Horizontal offset
            dy: Vertical offset
        """
        current_x, current_y = self._mouse.position
        self._mouse.position = (current_x + dx, current_y + dy)

    def click(self, button: str) -> None:
        """Perform mouse click.

        Args:
            button: Button to click ("left", "right", "middle")

        Raises:
            ValueError: If button name is invalid
        """
        button_map = {
            "left": Button.left,
            "right": Button.right,
            "middle": Button.middle,
        }

        if button not in button_map:
            raise ValueError(f"Invalid button: {button}")

        self._mouse.click(button_map[button])

    def scroll(self, dx: int, dy: int) -> None:
        """Scroll mouse wheel.

        Args:
            dx: Horizontal scroll (positive = right)
            dy: Vertical scroll (positive = up)
        """
        self._mouse.scroll(dx, dy)

    def get_position(self) -> tuple[int, int]:
        """Get current mouse position.

        Returns:
            Tuple of (x, y) coordinates
        """
        pos = self._mouse.position
        return (int(pos[0]), int(pos[1]))

    def register_hotkey(
        self,
        key: str,
        callback: Callable[[], None],
        modifiers: list[str] | None = None,
    ) -> None:
        """Register global hotkey.

        Args:
            key: Key name (e.g., "kp_5")
            callback: Function to call when pressed
            modifiers: Optional modifiers (["ctrl", "shift", "alt"])
        """
        if modifiers is None:
            modifiers = []

        # Create key signature with modifiers
        key_sig = "+".join(sorted(modifiers) + [key]) if modifiers else key
        self._callbacks[key_sig] = callback
        _logger.debug("Registered hotkey: %s", key_sig)

    def unregister_hotkey(self, key: str) -> None:
        """Unregister hotkey.

        Args:
            key: Key name to unregister
        """
        if key in self._callbacks:
            del self._callbacks[key]
            _logger.debug("Unregistered hotkey: %s", key)

    def start_listening(self) -> None:
        """Start hotkey listener."""
        if self._listener is not None:
            return

        self._listener = keyboard.Listener(
            on_press=self._on_press,
            on_release=self._on_release,
        )
        self._listener.start()
        _logger.info("X11 hotkey listener started")

    def stop_listening(self) -> None:
        """Stop hotkey listener."""
        if self._listener is None:
            return

        self._listener.stop()
        self._listener = None
        self._pressed_keys.clear()
        _logger.info("X11 hotkey listener stopped")

    def _on_press(self, key: Key | KeyCode | None) -> None:
        """Handle key press event.

        Args:
            key: Pressed key
        """
        if key is None:
            return

        self._pressed_keys.add(key)

        # Identify key name
        key_name = self._identify_key(key)
        if key_name is None:
            return

        # Build modifier list
        modifiers = self._get_active_modifiers()

        # Create key signature
        key_sig = "+".join(sorted(modifiers) + [key_name]) if modifiers else key_name

        # Execute callback
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
            key: Key object

        Returns:
            Key name string or None
        """
        if isinstance(key, Key):
            return key.name

        if isinstance(key, KeyCode) and key.vk is not None:
            return self.NUMPAD_KEYS.get(key.vk)

        return None

    def _get_active_modifiers(self) -> list[str]:
        """Get currently pressed modifier keys.

        Returns:
            List of modifier names
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
