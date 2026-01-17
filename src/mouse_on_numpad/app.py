"""GTK 4 Application for Mouse on Numpad Settings GUI.

Note: TrayIcon uses pystray (GTK 3) and runs in daemon.py separately.
This module is GTK 4 only - do not import pystray/TrayIcon here.
"""

import gi  # type: ignore[import-untyped]

gi.require_version("Gtk", "4.0")
from gi.repository import Gio, Gtk  # type: ignore[import-untyped]

from .core.config import ConfigManager
from .core.state_manager import StateManager
from .ui.main_window import MainWindow


class Application(Gtk.Application):  # type: ignore[misc]
    """GTK 4 Application for settings window only.

    Note: TrayIcon and StatusIndicator are managed by daemon.py
    to avoid GTK 3/4 version conflicts.
    """

    def __init__(self) -> None:
        """Initialize GTK Application."""
        super().__init__(
            application_id="com.github.mouse-on-numpad",
            flags=Gio.ApplicationFlags.DEFAULT_FLAGS,
        )

        # Core components
        self._config = ConfigManager()
        self._state = StateManager()

        # UI components (initialized in do_activate)
        self._main_window: MainWindow | None = None

    def do_startup(self) -> None:
        """Called once when application starts."""
        Gtk.Application.do_startup(self)

    def do_activate(self) -> None:
        """Called when application is activated (e.g., settings requested).

        Shows or creates the settings window.
        """
        # Create main window if it doesn't exist
        if self._main_window is None:
            self._main_window = MainWindow(self, self._config, self._state)

        # Present the window (create if needed, raise if already exists)
        self._main_window.present()

    def get_config(self) -> ConfigManager:
        """Get the configuration manager instance."""
        return self._config

    def get_state(self) -> StateManager:
        """Get the state manager instance."""
        return self._state
