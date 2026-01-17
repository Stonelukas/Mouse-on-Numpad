"""Abstract base class for input backends.

Defines the interface that all input backends must implement
for mouse control, keyboard input, and hotkey registration.
"""

from __future__ import annotations

from abc import ABC, abstractmethod
from collections.abc import Callable


class InputBackend(ABC):
    """Abstract interface for input control backends.

    All backends (X11, Wayland, evdev) must implement these methods
    to provide mouse movement, clicking, scrolling, position queries,
    and hotkey registration.

    Thread Safety:
        Implementations must be thread-safe. Multiple threads may call
        these methods concurrently.
    """

    @abstractmethod
    def move_mouse(self, x: int, y: int) -> None:
        """Move mouse cursor to absolute screen coordinates.

        Args:
            x: X coordinate (pixels from left edge)
            y: Y coordinate (pixels from top edge)

        Raises:
            RuntimeError: If backend cannot move cursor
        """
        pass

    @abstractmethod
    def move_mouse_relative(self, dx: int, dy: int) -> None:
        """Move mouse cursor relative to current position.

        Args:
            dx: Horizontal offset (positive = right)
            dy: Vertical offset (positive = down)

        Raises:
            RuntimeError: If backend cannot move cursor
        """
        pass

    @abstractmethod
    def click(self, button: str) -> None:
        """Perform mouse click.

        Args:
            button: Button to click ("left", "right", "middle")

        Raises:
            ValueError: If button name is invalid
            RuntimeError: If backend cannot click
        """
        pass

    @abstractmethod
    def scroll(self, dx: int, dy: int) -> None:
        """Scroll mouse wheel.

        Args:
            dx: Horizontal scroll amount (positive = right)
            dy: Vertical scroll amount (positive = up)

        Raises:
            RuntimeError: If backend cannot scroll
        """
        pass

    @abstractmethod
    def get_position(self) -> tuple[int, int]:
        """Get current mouse cursor position.

        Returns:
            Tuple of (x, y) coordinates

        Raises:
            RuntimeError: If backend cannot query position

        Note:
            On Wayland (pure), this may only work when app has focus.
            XWayland fallback provides full position query support.
        """
        pass

    @abstractmethod
    def register_hotkey(
        self,
        key: str,
        callback: Callable[[], None],
        modifiers: list[str] | None = None,
    ) -> None:
        """Register a global hotkey callback.

        Args:
            key: Key name (e.g., "kp_5", "kp_add")
            callback: Function to call when hotkey is pressed
            modifiers: Optional modifier keys (["ctrl", "shift", "alt"])

        Raises:
            ValueError: If key name is invalid
            RuntimeError: If backend cannot register hotkeys

        Note:
            Global hotkeys are NOT supported on native Wayland.
            XWayland fallback provides full hotkey support.
        """
        pass

    @abstractmethod
    def unregister_hotkey(self, key: str) -> None:
        """Unregister a hotkey callback.

        Args:
            key: Key name to unregister

        Raises:
            RuntimeError: If backend cannot unregister hotkeys
        """
        pass

    @abstractmethod
    def start_listening(self) -> None:
        """Start listening for hotkeys.

        Must be called before hotkeys will trigger callbacks.

        Raises:
            RuntimeError: If backend cannot start listener
        """
        pass

    @abstractmethod
    def stop_listening(self) -> None:
        """Stop listening for hotkeys.

        After calling, hotkeys will no longer trigger callbacks.

        Raises:
            RuntimeError: If backend cannot stop listener
        """
        pass
