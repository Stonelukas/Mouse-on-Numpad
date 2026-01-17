"""Floating status indicator window showing mouse mode state."""

import gi  # type: ignore[import-untyped]

gi.require_version("Gtk", "4.0")
from gi.repository import Gtk  # type: ignore[import-untyped]

from ..core.state_manager import MouseMode, StateManager


class StatusIndicator(Gtk.Window):  # type: ignore[misc]
    """Floating status indicator showing current mouse mode.

    Auto-hides when mouse mode is disabled per validation requirements.
    Uses GTK system theme only (no custom styling).
    """

    def __init__(self, state: StateManager) -> None:
        """Initialize status indicator window.

        Args:
            state: State manager for tracking mouse mode
        """
        super().__init__()
        self._state = state

        # Window properties - floating, no decorations
        self.set_decorated(False)
        self.set_default_size(200, 50)
        self.set_resizable(False)

        # Create status label
        self._label = Gtk.Label()
        self._label.set_margin_top(10)
        self._label.set_margin_bottom(10)
        self._label.set_margin_start(15)
        self._label.set_margin_end(15)
        self._label.add_css_class("title-4")

        self.set_child(self._label)

        # Subscribe to state changes
        self._state.subscribe(self._on_state_changed)

        # Update initial state
        self._update_status()

    def _update_status(self) -> None:
        """Update status label based on current mouse mode."""
        mode = self._state.mouse_mode
        if mode == MouseMode.ENABLED:
            self._label.set_label("Mouse Mode: ON")
        else:
            self._label.set_label("Mouse Mode: OFF")

        # Auto-hide when disabled per validation
        if mode == MouseMode.DISABLED:
            self.set_visible(False)
        else:
            self.set_visible(True)

    def _on_state_changed(self, key: str, _value: object) -> None:
        """Handle state changes to update status display.

        Args:
            key: State property that changed
            _value: New value (unused)
        """
        if key == "mouse_mode":
            self._update_status()

    def show(self) -> None:
        """Show the status indicator if mouse mode is enabled."""
        if self._state.mouse_mode == MouseMode.ENABLED:
            self.set_visible(True)

    def hide(self) -> None:
        """Hide the status indicator."""
        self.set_visible(False)
