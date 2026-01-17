"""Continuous mouse movement with diagonal support and acceleration."""

import threading
import time
from typing import Protocol


class MouseProtocol(Protocol):
    """Protocol for mouse controllers (UInput or ydotool)."""

    def move(self, dx: int, dy: int) -> None:
        """Move mouse by relative delta."""
        ...


class MovementController:
    """Handle continuous mouse movement with acceleration and diagonal support.

    Features:
    - Multi-key diagonal movement (hold KP8+KP4 = up-left)
    - Dedicated diagonal keys (KP7, KP9, KP1, KP3)
    - Exponential acceleration curve matching Windows AHK version
    - Configurable base speed, acceleration rate, max speed
    """

    def __init__(self, config, mouse: MouseProtocol) -> None:
        """Initialize MovementController.

        Args:
            config: ConfigManager instance for reading movement settings
            mouse: Mouse controller (UinputMouse or YdotoolMouse)
        """
        self._config = config
        self._mouse = mouse
        self._current_speed = 1.0
        self._move_thread: threading.Thread | None = None
        self._active_dirs: set[str] = set()  # {"up", "left"} = diagonal up-left
        self._running = False
        self._lock = threading.Lock()
        self._move_history: list[tuple[int, int]] = []  # Undo history of (dx, dy)

    def start_direction(self, direction: str) -> None:
        """Start moving in a direction (or add to multi-key diagonal).

        Args:
            direction: "up", "down", "left", or "right"
        """
        with self._lock:
            self._active_dirs.add(direction)
            self._ensure_moving()

    def stop_direction(self, direction: str) -> None:
        """Stop moving in a direction (or remove from multi-key diagonal).

        Args:
            direction: "up", "down", "left", or "right"
        """
        with self._lock:
            self._active_dirs.discard(direction)
            if not self._active_dirs:
                self._current_speed = 1.0  # Reset acceleration on full stop

    def stop_all(self) -> None:
        """Stop all movement immediately."""
        with self._lock:
            self._active_dirs.clear()
            self._current_speed = 1.0
            self._running = False

    def _ensure_moving(self) -> None:
        """Start movement thread if not already running."""
        if self._move_thread is None or not self._move_thread.is_alive():
            self._running = True
            self._move_thread = threading.Thread(target=self._movement_loop, daemon=True)
            self._move_thread.start()

    def _movement_loop(self) -> None:
        """Continuous movement loop (runs in separate thread)."""
        reload_counter = 0
        while self._running:
            # Reload config every ~1s to pick up GUI changes
            reload_counter += 1
            if reload_counter >= 50:
                self._config.reload()
                reload_counter = 0

            with self._lock:
                if not self._active_dirs:
                    self._running = False
                    break

                dx, dy = self._calc_delta()

            # Move mouse (outside lock to avoid blocking input)
            if dx != 0 or dy != 0:
                self._mouse.move(dx, dy)
                self._record_move(dx, dy)

            # Accelerate for next iteration
            self._accelerate()

            # Sleep to control movement speed
            move_delay = self._config.get("movement.move_delay", 10) / 1000.0
            time.sleep(move_delay)

    def _calc_delta(self) -> tuple[int, int]:
        """Calculate movement delta based on active directions and speed.

        Returns:
            (dx, dy) tuple for relative mouse movement
        """
        base = self._config.get("movement.base_speed", 10)
        speed = int(base * self._current_speed)

        dx = dy = 0
        if "left" in self._active_dirs:
            dx -= speed
        if "right" in self._active_dirs:
            dx += speed
        if "up" in self._active_dirs:
            dy -= speed
        if "down" in self._active_dirs:
            dy += speed

        return dx, dy

    def _accelerate(self) -> None:
        """Apply acceleration curve to current speed."""
        curve = self._config.get("movement.curve", "exponential")
        rate = self._config.get("movement.acceleration_rate", 1.02)
        base = self._config.get("movement.base_speed", 10)
        max_speed = self._config.get("movement.max_speed", 100)
        max_mult = max_speed / base

        if curve == "linear":
            # Linear: constant increment each step
            self._current_speed = min(self._current_speed + (rate - 1), max_mult)
        elif curve == "exponential":
            # Exponential: multiply by rate (matches Windows AHK)
            self._current_speed = min(self._current_speed * rate, max_mult)
        elif curve == "s-curve":
            # S-curve: slow start, fast middle, slow end
            t = self._current_speed / max_mult
            increment = rate * (1 - abs(2 * t - 1))
            self._current_speed = min(self._current_speed + increment, max_mult)

    def _record_move(self, dx: int, dy: int) -> None:
        """Record a move for undo history."""
        max_levels = self._config.get("undo.max_levels", 10)
        self._move_history.append((dx, dy))
        # Trim history to max levels
        if len(self._move_history) > max_levels:
            self._move_history = self._move_history[-max_levels:]

    def undo(self) -> bool:
        """Undo last movement by reversing the delta.

        Returns:
            True if undo performed, False if history empty.
        """
        if not self._move_history:
            return False
        dx, dy = self._move_history.pop()
        # Move in opposite direction
        self._mouse.move(-dx, -dy)
        return True
