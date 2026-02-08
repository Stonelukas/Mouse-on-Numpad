"""Mouse controller factory for creating UInput or ydotool fallback."""

import subprocess
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from ..core import ErrorLogger

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


def create_mouse_controller(logger: "ErrorLogger") -> "YdotoolMouse | UinputMouse":
    """Create best available mouse controller (UInput preferred, ydotool fallback).

    Args:
        logger: Error logger for status messages.

    Returns:
        UinputMouse if available, otherwise YdotoolMouse fallback.
    """
    try:
        from ..input.uinput_mouse import UinputMouse

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
from ..input.uinput_mouse import UinputMouse
