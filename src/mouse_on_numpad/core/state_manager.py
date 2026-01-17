"""Thread-safe state management with observer pattern."""

import logging
import threading
from collections.abc import Callable
from dataclasses import dataclass
from enum import Enum, auto

# Module logger for callback error reporting
_logger = logging.getLogger(__name__)


class MouseMode(Enum):
    """Mouse control mode states."""
    DISABLED = auto()  # NumLock ON - normal numpad numbers
    ENABLED = auto()   # NumLock OFF - mouse control active


@dataclass
class AppState:
    """Application state container."""
    mouse_mode: MouseMode = MouseMode.DISABLED
    current_position: tuple[int, int] = (0, 0)
    active_monitor: int = 0
    numlock_state: bool = True  # True = ON (numbers), False = OFF (mouse)


# Type alias for state change callbacks
StateCallback = Callable[[str, object], None]


class StateManager:
    """Thread-safe state manager with observer pattern.

    Features:
    - Observable state changes for reactive UI
    - Thread-safe access with locks
    - Convenience toggle methods
    """

    def __init__(self) -> None:
        """Initialize StateManager with default state."""
        self._state = AppState()
        self._lock = threading.RLock()
        self._subscribers: list[StateCallback] = []

    def subscribe(self, callback: StateCallback) -> None:
        """Subscribe to state changes.

        Args:
            callback: Function called with (key, new_value) on state change
        """
        with self._lock:
            if callback not in self._subscribers:
                self._subscribers.append(callback)

    def unsubscribe(self, callback: StateCallback) -> None:
        """Unsubscribe from state changes.

        Args:
            callback: Previously registered callback
        """
        with self._lock:
            if callback in self._subscribers:
                self._subscribers.remove(callback)

    def _notify(self, key: str, value: object) -> None:
        """Notify all subscribers of state change.

        Args:
            key: State property that changed
            value: New value
        """
        # Copy list to avoid issues if callback modifies subscribers
        with self._lock:
            subscribers = self._subscribers.copy()
        for callback in subscribers:
            try:
                callback(key, value)
            except Exception:
                # Log but don't let one bad callback break others
                _logger.exception("State callback failed for key '%s'", key)

    @property
    def mouse_mode(self) -> MouseMode:
        """Get current mouse mode."""
        with self._lock:
            return self._state.mouse_mode

    @mouse_mode.setter
    def mouse_mode(self, value: MouseMode) -> None:
        """Set mouse mode and notify subscribers."""
        changed = False
        with self._lock:
            if self._state.mouse_mode != value:
                self._state.mouse_mode = value
                changed = True
        if changed:
            self._notify("mouse_mode", value)

    @property
    def is_enabled(self) -> bool:
        """Check if mouse control is enabled."""
        with self._lock:
            return self._state.mouse_mode == MouseMode.ENABLED

    @property
    def current_position(self) -> tuple[int, int]:
        """Get current cursor position."""
        with self._lock:
            return self._state.current_position

    @current_position.setter
    def current_position(self, value: tuple[int, int]) -> None:
        """Set current cursor position."""
        changed = False
        with self._lock:
            if self._state.current_position != value:
                self._state.current_position = value
                changed = True
        if changed:
            self._notify("current_position", value)

    @property
    def active_monitor(self) -> int:
        """Get active monitor index."""
        with self._lock:
            return self._state.active_monitor

    @active_monitor.setter
    def active_monitor(self, value: int) -> None:
        """Set active monitor index."""
        changed = False
        with self._lock:
            if self._state.active_monitor != value:
                self._state.active_monitor = value
                changed = True
        if changed:
            self._notify("active_monitor", value)

    @property
    def numlock_state(self) -> bool:
        """Get NumLock state. True=ON (numbers), False=OFF (mouse)."""
        with self._lock:
            return self._state.numlock_state

    @numlock_state.setter
    def numlock_state(self, value: bool) -> None:
        """Set NumLock state and update mouse mode accordingly.

        NumLock OFF = mouse mode enabled
        NumLock ON = mouse mode disabled (normal numpad)
        """
        changed = False
        new_mode = None
        with self._lock:
            if self._state.numlock_state != value:
                self._state.numlock_state = value
                # Update mouse mode based on NumLock
                new_mode = MouseMode.DISABLED if value else MouseMode.ENABLED
                self._state.mouse_mode = new_mode
                changed = True
        if changed:
            self._notify("numlock_state", value)
            self._notify("mouse_mode", new_mode)

    def toggle(self) -> bool:
        """Toggle mouse mode on/off.

        Returns:
            True if now enabled, False if disabled
        """
        with self._lock:
            if self._state.mouse_mode == MouseMode.ENABLED:
                self._state.mouse_mode = MouseMode.DISABLED
            else:
                self._state.mouse_mode = MouseMode.ENABLED
            new_mode = self._state.mouse_mode  # Capture inside lock
            enabled = new_mode == MouseMode.ENABLED
        self._notify("mouse_mode", new_mode)  # Use captured value
        return enabled

    def get_state_snapshot(self) -> dict[str, object]:
        """Get a snapshot of all state values.

        Returns:
            Dictionary of current state values
        """
        with self._lock:
            return {
                "mouse_mode": self._state.mouse_mode,
                "current_position": self._state.current_position,
                "active_monitor": self._state.active_monitor,
                "numlock_state": self._state.numlock_state,
                "is_enabled": self._state.mouse_mode == MouseMode.ENABLED,
            }
