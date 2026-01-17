"""UInput-based mouse controller for zero-overhead mouse control."""

import os
from evdev import UInput, ecodes


class UinputMouse:
    """Mouse controller using UInput (works on Wayland, zero subprocess overhead).

    Provides move, click, scroll operations via direct kernel writes.
    Requires /dev/uinput access (input group membership or udev rule).
    """

    BUTTONS = {
        "left": ecodes.BTN_LEFT,
        "right": ecodes.BTN_RIGHT,
        "middle": ecodes.BTN_MIDDLE,
    }

    def __init__(self) -> None:
        """Initialize UInput device for mouse control.

        Raises:
            PermissionError: If /dev/uinput is not accessible.
            OSError: If UInput device creation fails.
        """
        if not os.path.exists("/dev/uinput"):
            raise OSError("/dev/uinput not found - kernel module not loaded")

        if not os.access("/dev/uinput", os.W_OK):
            raise PermissionError(
                "/dev/uinput not writable. Add user to 'input' group: "
                "sudo usermod -aG input $USER && reboot"
            )

        # Include PID in name to prevent collisions with multiple instances
        self._ui = UInput(
            events={
                ecodes.EV_REL: [ecodes.REL_X, ecodes.REL_Y, ecodes.REL_WHEEL, ecodes.REL_HWHEEL],
                ecodes.EV_KEY: [ecodes.BTN_LEFT, ecodes.BTN_RIGHT, ecodes.BTN_MIDDLE],
            },
            name=f"mouse-on-numpad-mouse-{os.getpid()}",
        )

    def move(self, dx: int, dy: int) -> None:
        """Move mouse by relative offset."""
        if dx != 0:
            self._ui.write(ecodes.EV_REL, ecodes.REL_X, dx)
        if dy != 0:
            self._ui.write(ecodes.EV_REL, ecodes.REL_Y, dy)
        self._ui.syn()

    def click(self, button: str = "left") -> None:
        """Click mouse button (press and release)."""
        btn = self.BUTTONS.get(button, ecodes.BTN_LEFT)
        self._ui.write(ecodes.EV_KEY, btn, 1)  # Press
        self._ui.syn()
        self._ui.write(ecodes.EV_KEY, btn, 0)  # Release
        self._ui.syn()

    def press(self, button: str = "left") -> None:
        """Press and hold mouse button."""
        btn = self.BUTTONS.get(button, ecodes.BTN_LEFT)
        self._ui.write(ecodes.EV_KEY, btn, 1)
        self._ui.syn()

    def release(self, button: str = "left") -> None:
        """Release mouse button."""
        btn = self.BUTTONS.get(button, ecodes.BTN_LEFT)
        self._ui.write(ecodes.EV_KEY, btn, 0)
        self._ui.syn()

    def scroll(self, dx: int, dy: int) -> None:
        """Scroll mouse wheel. dy>0 = up, dy<0 = down."""
        if dy != 0:
            self._ui.write(ecodes.EV_REL, ecodes.REL_WHEEL, dy)
        if dx != 0:
            self._ui.write(ecodes.EV_REL, ecodes.REL_HWHEEL, dx)
        self._ui.syn()

    def close(self) -> None:
        """Close the UInput device."""
        if hasattr(self, "_ui") and self._ui:
            self._ui.close()

    def __enter__(self) -> "UinputMouse":
        """Context manager entry."""
        return self

    def __exit__(self, *args: object) -> None:
        """Context manager exit - ensures cleanup."""
        self.close()

    def __del__(self) -> None:
        """Cleanup on destruction."""
        self.close()
