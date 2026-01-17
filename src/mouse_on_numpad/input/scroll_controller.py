"""Continuous scroll with acceleration support."""

import threading
import time
from typing import Protocol


class ScrollableProtocol(Protocol):
    """Protocol for scrollable controllers."""

    def scroll(self, dx: int, dy: int) -> None:
        """Scroll by relative delta (dy>0=up, dx>0=right)."""
        ...


class ScrollController:
    """Handle continuous scrolling with acceleration.

    Features:
    - Vertical scroll (Numpad 7=up, 1=down)
    - Horizontal scroll (Numpad 9=left, 3=right)
    - Exponential acceleration matching movement controller
    """

    def __init__(self, config, mouse: ScrollableProtocol) -> None:
        """Initialize ScrollController.

        Args:
            config: ConfigManager instance for reading scroll settings
            mouse: Mouse controller with scroll method
        """
        self._config = config
        self._mouse = mouse
        self._current_speed = 1.0
        self._scroll_thread: threading.Thread | None = None
        self._active_dirs: set[str] = set()  # {"up"}, {"down"}, {"left"}, {"right"}
        self._running = False
        self._lock = threading.Lock()

    def start_direction(self, direction: str) -> None:
        """Start scrolling in a direction.

        Args:
            direction: "up", "down", "left", or "right"
        """
        with self._lock:
            self._active_dirs.add(direction)
            self._ensure_scrolling()

    def stop_direction(self, direction: str) -> None:
        """Stop scrolling in a direction.

        Args:
            direction: "up", "down", "left", or "right"
        """
        with self._lock:
            self._active_dirs.discard(direction)
            if not self._active_dirs:
                self._current_speed = 1.0  # Reset acceleration on full stop

    def stop_all(self) -> None:
        """Stop all scrolling immediately."""
        with self._lock:
            self._active_dirs.clear()
            self._current_speed = 1.0
            self._running = False

    def _ensure_scrolling(self) -> None:
        """Start scroll thread if not already running."""
        if self._scroll_thread is None or not self._scroll_thread.is_alive():
            self._running = True
            self._scroll_thread = threading.Thread(target=self._scroll_loop, daemon=True)
            self._scroll_thread.start()

    def _scroll_loop(self) -> None:
        """Continuous scroll loop (runs in separate thread)."""
        while self._running:
            with self._lock:
                if not self._active_dirs:
                    self._running = False
                    break

                dx, dy = self._calc_delta()

            # Scroll mouse (outside lock to avoid blocking input)
            if dx != 0 or dy != 0:
                self._mouse.scroll(dx, dy)

            # Accelerate for next iteration
            self._accelerate()

            # Sleep to control scroll speed
            delay = self._config.get("scroll.delay", 30) / 1000.0
            time.sleep(delay)

    def _calc_delta(self) -> tuple[int, int]:
        """Calculate scroll delta based on active directions and speed.

        Returns:
            (dx, dy) tuple for scroll. dy>0=up, dx>0=right

        Note:
            Opposite directions cancel out (e.g., up+down = 0).
            This is intentional for consistent behavior.
        """
        step = self._config.get("scroll.step", 3)
        speed = int(step * self._current_speed)

        dx = dy = 0
        if "up" in self._active_dirs:
            dy += speed  # Positive = scroll up
        if "down" in self._active_dirs:
            dy -= speed  # Negative = scroll down
        if "left" in self._active_dirs:
            dx -= speed  # Negative = scroll left
        if "right" in self._active_dirs:
            dx += speed  # Positive = scroll right

        return dx, dy

    def _accelerate(self) -> None:
        """Apply exponential acceleration to scroll speed."""
        rate = self._config.get("scroll.acceleration_rate", 1.1)
        step = self._config.get("scroll.step", 3)
        max_speed = self._config.get("scroll.max_speed", 10)
        # Guard against division by zero or invalid config
        max_mult = max(max_speed / step, 1.0) if step > 0 else 1.0

        self._current_speed = min(self._current_speed * rate, max_mult)
