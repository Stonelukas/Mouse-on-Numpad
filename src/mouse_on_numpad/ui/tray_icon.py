"""System tray icon placeholder (GTK 4 compatible implementation)."""

import gi  # type: ignore[import-untyped]

gi.require_version("Gtk", "4.0")
from gi.repository import Gtk  # type: ignore[import-untyped]

from ..core.state_manager import StateManager


class TrayIcon:
    """System tray icon placeholder for GTK 4.

    Note: GTK 4 removed GtkStatusIcon and AppIndicator3 requires GTK 3.
    This is a minimal implementation for Phase 4 MVP.
    Full tray support will be added in Phase 5 using a different approach
    (e.g., KStatusNotifierItem via DBus or libappindicator-gtk4).
    """

    def __init__(self, app: Gtk.Application, state: StateManager) -> None:
        """Initialize tray icon placeholder.

        Args:
            app: GTK Application instance
            state: State manager for mouse mode control
        """
        self._app = app
        self._state = state
        self._visible = False

        # Subscribe to state changes
        self._state.subscribe(self._on_state_changed)

        # Note: No actual tray icon created in Phase 4 MVP
        # This will be implemented in Phase 5 with proper GTK 4/Wayland support

    def _on_state_changed(self, key: str, _value: object) -> None:
        """Handle state changes (placeholder).

        Args:
            key: State property that changed
            _value: New value (unused)
        """
        # Placeholder for future implementation
        pass

    def show(self) -> None:
        """Show the tray icon (placeholder)."""
        self._visible = True

    def hide(self) -> None:
        """Hide the tray icon (placeholder)."""
        self._visible = False

    def set_enabled(self, enabled: bool) -> None:
        """Set the enabled state and update icon.

        Args:
            enabled: True to enable mouse control, False to disable
        """
        if enabled != self._state.is_enabled:
            self._state.toggle()
