"""Evdev backend for direct kernel input simulation.

This is a fallback backend that uses evdev for direct input device control.
It requires the user to be in the 'input' group for device access and uses
uinput for virtual device creation.

Limitations:
- NO global hotkey support (cannot capture keys system-wide)
- Requires input group membership (usermod -a -G input $USER)
- Mouse position queries not supported
- Intended as last-resort fallback only

Use Cases:
- Systems without X11 or XWayland
- Headless systems
- Testing input simulation
"""

from __future__ import annotations

import logging
import os
from collections.abc import Callable

from .base import InputBackend

_logger = logging.getLogger(__name__)


class EvdevBackend(InputBackend):
    """Evdev backend for direct kernel input control.

    Uses python-evdev to create virtual input devices and simulate
    mouse movements/clicks. Does NOT support hotkey capture.

    Requirements:
        - python-evdev package
        - User in 'input' group
        - uinput kernel module loaded

    Limitations:
        - NO hotkey support (register_hotkey raises NotImplementedError)
        - NO position queries (get_position raises NotImplementedError)
        - Requires elevated permissions

    Setup:
        sudo usermod -a -G input $USER
        sudo modprobe uinput
    """

    def __init__(self) -> None:
        """Initialize evdev backend.

        Raises:
            RuntimeError: If evdev is not available or permissions insufficient
        """
        try:
            import evdev  # type: ignore[import-untyped]
            from evdev import UInput, ecodes  # type: ignore[import-untyped]

            self._evdev = evdev
            self._ecodes = ecodes
            self._UInput = UInput
        except ImportError as e:
            raise RuntimeError(
                "python-evdev not installed. Install with: pip install evdev"
            ) from e

        # Check uinput permissions
        if not os.path.exists("/dev/uinput"):
            raise RuntimeError(
                "/dev/uinput not found. Load uinput module: sudo modprobe uinput"
            )

        if not os.access("/dev/uinput", os.W_OK):
            raise RuntimeError(
                "No write permission to /dev/uinput. "
                "Add user to input group: sudo usermod -a -G input $USER"
            )

        # Create virtual mouse device
        try:
            self._ui = self._UInput(
                events={
                    self._ecodes.EV_REL: [
                        self._ecodes.REL_X,
                        self._ecodes.REL_Y,
                        self._ecodes.REL_WHEEL,
                        self._ecodes.REL_HWHEEL,
                    ],
                    self._ecodes.EV_KEY: [
                        self._ecodes.BTN_LEFT,
                        self._ecodes.BTN_RIGHT,
                        self._ecodes.BTN_MIDDLE,
                    ],
                },
                name="mouse-on-numpad-virtual",
            )
        except Exception as e:
            raise RuntimeError(f"Failed to create virtual input device: {e}") from e

        _logger.warning(
            "EvdevBackend initialized. Hotkey support DISABLED. "
            "This is a fallback backend with limited functionality."
        )

    def move_mouse(self, x: int, y: int) -> None:
        """Move mouse to absolute coordinates.

        Args:
            x: X coordinate
            y: Y coordinate

        Raises:
            NotImplementedError: Absolute positioning not supported by evdev
        """
        raise NotImplementedError(
            "Absolute mouse positioning not supported by evdev backend. "
            "Use move_mouse_relative() instead."
        )

    def move_mouse_relative(self, dx: int, dy: int) -> None:
        """Move mouse relative to current position.

        Args:
            dx: Horizontal offset
            dy: Vertical offset
        """
        self._ui.write(self._ecodes.EV_REL, self._ecodes.REL_X, dx)
        self._ui.write(self._ecodes.EV_REL, self._ecodes.REL_Y, dy)
        self._ui.syn()

    def click(self, button: str) -> None:
        """Perform mouse click.

        Args:
            button: Button to click ("left", "right", "middle")

        Raises:
            ValueError: If button name is invalid
        """
        button_map = {
            "left": self._ecodes.BTN_LEFT,
            "right": self._ecodes.BTN_RIGHT,
            "middle": self._ecodes.BTN_MIDDLE,
        }

        if button not in button_map:
            raise ValueError(f"Invalid button: {button}")

        btn_code = button_map[button]

        # Press
        self._ui.write(self._ecodes.EV_KEY, btn_code, 1)
        self._ui.syn()

        # Release
        self._ui.write(self._ecodes.EV_KEY, btn_code, 0)
        self._ui.syn()

    def scroll(self, dx: int, dy: int) -> None:
        """Scroll mouse wheel.

        Args:
            dx: Horizontal scroll
            dy: Vertical scroll
        """
        if dy != 0:
            self._ui.write(self._ecodes.EV_REL, self._ecodes.REL_WHEEL, dy)
        if dx != 0:
            self._ui.write(self._ecodes.EV_REL, self._ecodes.REL_HWHEEL, dx)
        self._ui.syn()

    def get_position(self) -> tuple[int, int]:
        """Get current mouse position.

        Raises:
            NotImplementedError: Position queries not supported by evdev
        """
        raise NotImplementedError(
            "Mouse position queries not supported by evdev backend. "
            "Use X11 or Wayland backend for position tracking."
        )

    def register_hotkey(
        self,
        key: str,
        callback: Callable[[], None],
        modifiers: list[str] | None = None,
    ) -> None:
        """Register global hotkey.

        Raises:
            NotImplementedError: Hotkeys not supported by evdev backend
        """
        raise NotImplementedError(
            "Global hotkey capture not supported by evdev backend. "
            "Use X11 or Wayland (with XWayland) backend for hotkeys."
        )

    def unregister_hotkey(self, key: str) -> None:
        """Unregister hotkey.

        Raises:
            NotImplementedError: Hotkeys not supported by evdev backend
        """
        raise NotImplementedError("Hotkeys not supported by evdev backend")

    def start_listening(self) -> None:
        """Start hotkey listener.

        Raises:
            NotImplementedError: Hotkeys not supported by evdev backend
        """
        raise NotImplementedError("Hotkeys not supported by evdev backend")

    def stop_listening(self) -> None:
        """Stop hotkey listener.

        Raises:
            NotImplementedError: Hotkeys not supported by evdev backend
        """
        raise NotImplementedError("Hotkeys not supported by evdev backend")

    def __del__(self) -> None:
        """Clean up virtual input device."""
        if hasattr(self, "_ui"):
            try:
                self._ui.close()
            except Exception:
                pass
