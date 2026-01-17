"""Key capture button widget for hotkey assignment.

Provides an interactive button that captures key presses and stores
the evdev keycode in config. Includes conflict detection.
"""

from typing import Callable

import gi  # type: ignore[import-untyped]

gi.require_version("Gtk", "4.0")
gi.require_version("Gdk", "4.0")
from gi.repository import Gtk, Gdk, GLib  # type: ignore[import-untyped]

from ..core.config import ConfigManager
from .keycode_mappings import (
    get_key_name,
    gdk_keyval_to_evdev,
    ALL_HOTKEY_NAMES,
)

# Timeout for "Unsupported key" message in milliseconds
UNSUPPORTED_KEY_TIMEOUT_MS = 1500


class KeyCaptureButton(Gtk.Button):  # type: ignore[misc]
    """Button that captures key presses for hotkey assignment.

    Usage:
        button = KeyCaptureButton(config, "toggle_mode", on_conflict_callback)
        # User clicks button -> shows "Press a key..."
        # User presses numpad key -> saves keycode to config
        # Press Escape to cancel
    """

    def __init__(
        self,
        config: ConfigManager,
        hotkey_name: str,
        on_conflict: Callable[[str, str, int], None],
    ) -> None:
        """Initialize key capture button.

        Args:
            config: Configuration manager for storing keycodes
            hotkey_name: Config key name (e.g., "toggle_mode")
            on_conflict: Callback when key conflict detected (action1, action2, keycode)
        """
        super().__init__()
        self._config = config
        self._hotkey_name = hotkey_name
        self._on_conflict = on_conflict
        self._capturing = False

        # Set initial label from config
        keycode = self._config.get(f"hotkeys.{hotkey_name}", 0)
        self.set_label(get_key_name(keycode))
        self.add_css_class("monospace")

        # Connect click to start capture
        self.connect("clicked", self._start_capture)

        # Set up key event controller for capture
        self._key_controller = Gtk.EventControllerKey()
        self._key_controller.connect("key-pressed", self._on_key_pressed)
        self.add_controller(self._key_controller)

    def _start_capture(self, _button: Gtk.Button) -> None:
        """Start capturing key press."""
        self._capturing = True
        self.set_label("Press a key...")
        self.add_css_class("suggested-action")
        self.grab_focus()

    def _on_key_pressed(
        self,
        _controller: Gtk.EventControllerKey,
        keyval: int,
        keycode: int,
        state: Gdk.ModifierType,
    ) -> bool:
        """Handle key press during capture."""
        if not self._capturing:
            return False

        self._capturing = False
        self.remove_css_class("suggested-action")

        # Cancel on Escape
        if keyval == Gdk.KEY_Escape:
            current = self._config.get(f"hotkeys.{self._hotkey_name}", 0)
            self.set_label(get_key_name(current))
            return True

        # Convert GDK keyval to evdev keycode
        evdev_code = gdk_keyval_to_evdev(keyval)
        if evdev_code is None:
            # Key not in mapping, show error briefly
            self.set_label("Unsupported key")
            current = self._config.get(f"hotkeys.{self._hotkey_name}", 0)
            GLib.timeout_add(
                UNSUPPORTED_KEY_TIMEOUT_MS,
                lambda: self.set_label(get_key_name(current)) or False,
            )
            return True

        # Check for conflicts with other hotkeys
        conflict = self._check_conflict(evdev_code)
        if conflict:
            self._on_conflict(self._hotkey_name, conflict, evdev_code)
            current = self._config.get(f"hotkeys.{self._hotkey_name}", 0)
            self.set_label(get_key_name(current))
            return True

        # Save new keycode
        self._config.set(f"hotkeys.{self._hotkey_name}", evdev_code)
        self.set_label(get_key_name(evdev_code))
        return True

    def _check_conflict(self, new_keycode: int) -> str | None:
        """Check if keycode conflicts with another hotkey.

        Args:
            new_keycode: The keycode to check for conflicts

        Returns:
            Conflicting action name or None if no conflict
        """
        for action in ALL_HOTKEY_NAMES:
            if action == self._hotkey_name:
                continue
            existing = self._config.get(f"hotkeys.{action}", 0)
            if existing == new_keycode:
                return action
        return None

    def refresh(self) -> None:
        """Refresh button label from config."""
        keycode = self._config.get(f"hotkeys.{self._hotkey_name}", 0)
        self.set_label(get_key_name(keycode))
