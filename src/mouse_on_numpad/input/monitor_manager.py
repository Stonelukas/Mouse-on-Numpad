"""Multi-monitor management using X11/Xrandr."""

import logging

from Xlib import display

from .display_detection import MonitorInfo, create_fallback_monitor, query_monitors_xrandr

_logger = logging.getLogger(__name__)


class MonitorManager:
    """Manage multi-monitor setup via X11/Xrandr.

    Features:
    - Query all connected monitors
    - Get primary monitor
    - Find monitor at specific coordinates
    - Clamp coordinates to visible screen area
    """

    def __init__(self) -> None:
        """Initialize MonitorManager."""
        self._display = display.Display()
        self._screen = self._display.screen()
        self._root = self._screen.root
        self._monitors: list[MonitorInfo] = []
        self._refresh_monitors()

    def _refresh_monitors(self) -> None:
        """Refresh monitor list from Xrandr."""
        self._monitors = query_monitors_xrandr(self._display, self._screen, self._root)

    def get_monitors(self) -> list[MonitorInfo]:
        """Get list of all connected monitors.

        Returns:
            List of monitor info dictionaries
        """
        self._refresh_monitors()
        return self._monitors.copy()

    def get_primary(self) -> MonitorInfo:
        """Get primary monitor.

        Returns:
            Primary monitor info dictionary
        """
        self._refresh_monitors()
        for monitor in self._monitors:
            if monitor["is_primary"]:
                return monitor

        # Fallback to first monitor
        if self._monitors:
            return self._monitors[0]

        # Ultimate fallback
        return create_fallback_monitor(self._screen)

    def get_monitor_at(self, x: int, y: int) -> MonitorInfo | None:
        """Find monitor containing the given coordinates.

        Args:
            x: X coordinate
            y: Y coordinate

        Returns:
            Monitor info or None if not found
        """
        self._refresh_monitors()
        for monitor in self._monitors:
            if (
                monitor["x"] <= x < monitor["x"] + monitor["width"]
                and monitor["y"] <= y < monitor["y"] + monitor["height"]
            ):
                return monitor
        return None

    def get_next_monitor_center(self, x: int, y: int) -> tuple[int, int] | None:
        """Get center coordinates of next monitor (cycling).

        Args:
            x: Current X coordinate
            y: Current Y coordinate

        Returns:
            (center_x, center_y) of next monitor, or None if only one monitor
        """
        self._refresh_monitors()
        if len(self._monitors) < 2:
            return None

        # Find current monitor
        current = self.get_monitor_at(x, y)
        if current is None:
            # Not on any monitor, go to primary
            primary = self.get_primary()
            return (
                primary["x"] + primary["width"] // 2,
                primary["y"] + primary["height"] // 2,
            )

        # Find index of current monitor
        current_idx = -1
        for i, m in enumerate(self._monitors):
            if m["index"] == current["index"]:
                current_idx = i
                break

        # Get next monitor (cycling)
        next_idx = (current_idx + 1) % len(self._monitors)
        next_mon = self._monitors[next_idx]

        return (
            next_mon["x"] + next_mon["width"] // 2,
            next_mon["y"] + next_mon["height"] // 2,
        )

    def clamp_to_screens(self, x: int, y: int) -> tuple[int, int]:
        """Clamp coordinates to visible screen area.

        Args:
            x: X coordinate
            y: Y coordinate

        Returns:
            Clamped (x, y) coordinates
        """
        if not self._monitors:
            self._refresh_monitors()

        # Find bounding box of all monitors
        if not self._monitors:
            return (x, y)

        min_x = min(m["x"] for m in self._monitors)
        max_x = max(m["x"] + m["width"] for m in self._monitors)
        min_y = min(m["y"] for m in self._monitors)
        max_y = max(m["y"] + m["height"] for m in self._monitors)

        # Clamp to bounds
        clamped_x = max(min_x, min(x, max_x - 1))
        clamped_y = max(min_y, min(y, max_y - 1))

        return (clamped_x, clamped_y)

    def __del__(self) -> None:
        """Cleanup X11 display connection."""
        try:
            self._display.close()
        except Exception:
            pass
