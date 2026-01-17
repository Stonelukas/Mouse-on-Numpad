"""Mouse control with acceleration curves and multi-monitor support."""

import math
import time
from typing import Literal

from pynput.mouse import Button, Controller

from mouse_on_numpad.core.config import ConfigManager
from mouse_on_numpad.core.state_manager import StateManager

AccelerationCurve = Literal["linear", "exponential", "s-curve"]


class MouseController:
    """Control mouse cursor with configurable acceleration curves.

    Features:
    - Absolute and relative mouse movement
    - Configurable acceleration (linear, exponential, S-curve)
    - Multi-monitor coordinate support
    - Left/Right/Middle click
    - Horizontal and vertical scrolling
    """

    def __init__(self, config: ConfigManager, state: StateManager) -> None:
        """Initialize MouseController.

        Args:
            config: Configuration manager for speed/acceleration settings
            state: State manager for position tracking
        """
        self._config = config
        self._state = state
        self._controller = Controller()
        self._last_move_time = time.time()

    def move_to(self, x: int, y: int) -> None:
        """Move cursor to absolute screen coordinates.

        Args:
            x: X coordinate
            y: Y coordinate
        """
        self._controller.position = (x, y)
        self._state.current_position = (x, y)

    def move_relative(self, dx: int, dy: int) -> None:
        """Move cursor relative to current position with acceleration.

        Args:
            dx: Horizontal offset (positive = right)
            dy: Vertical offset (positive = down)
        """
        current_time = time.time()
        time_delta = current_time - self._last_move_time
        self._last_move_time = current_time

        # Apply acceleration curve
        curve = self._config.get("movement.curve", "exponential")
        base_speed = self._config.get("movement.base_speed", 10)
        accel_factor = self._config.get("movement.acceleration", 1.5)

        multiplier = self._calculate_acceleration(curve, time_delta, accel_factor)
        adjusted_dx = int(dx * base_speed * multiplier)
        adjusted_dy = int(dy * base_speed * multiplier)

        # Get current position and calculate new position
        current_x, current_y = self._controller.position
        new_x = current_x + adjusted_dx
        new_y = current_y + adjusted_dy

        # Update position
        self._controller.position = (new_x, new_y)
        self._state.current_position = (new_x, new_y)

    def _calculate_acceleration(
        self, curve: AccelerationCurve, time_delta: float, accel_factor: float
    ) -> float:
        """Calculate acceleration multiplier based on curve type.

        Args:
            curve: Acceleration curve type
            time_delta: Time since last movement (seconds)
            accel_factor: Acceleration factor from config

        Returns:
            Multiplier for movement speed (1.0 = base speed)
        """
        # Short time = continuous movement = accelerate
        # Long time = initial movement = no acceleration
        if time_delta > 0.5:
            return 1.0

        if curve == "linear":
            return 1.0  # No acceleration

        elif curve == "exponential":
            # Exponential growth based on continuous movement
            # time_delta small = high multiplier
            t = max(0.0, 0.5 - time_delta) * 2  # Normalize to 0-1
            return 1.0 + (accel_factor - 1.0) * t

        elif curve == "s-curve":
            # Smooth S-curve: slow start, fast middle, slow end
            # Using sigmoid function
            t = max(0.0, 0.5 - time_delta) * 2
            sigmoid = 1 / (1 + math.exp(-10 * (t - 0.5)))
            return 1.0 + (accel_factor - 1.0) * sigmoid

        return 1.0

    def click(self, button: str = "left") -> None:
        """Perform mouse click.

        Args:
            button: Button to click ("left", "right", "middle")
        """
        btn_map = {
            "left": Button.left,
            "right": Button.right,
            "middle": Button.middle,
        }

        if button not in btn_map:
            return

        self._controller.click(btn_map[button])

    def scroll(self, dx: int = 0, dy: int = 0) -> None:
        """Scroll mouse wheel.

        Args:
            dx: Horizontal scroll amount (positive = right)
            dy: Vertical scroll amount (positive = up)
        """
        if dy != 0:
            self._controller.scroll(dx, dy)
        elif dx != 0:
            # pynput scroll takes (dx, dy) format
            self._controller.scroll(dx, 0)

    def get_position(self) -> tuple[int, int]:
        """Get current cursor position.

        Returns:
            Tuple of (x, y) coordinates
        """
        pos = self._controller.position
        return (int(pos[0]), int(pos[1]))
