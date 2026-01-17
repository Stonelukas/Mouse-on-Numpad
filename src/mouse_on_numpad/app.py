"""GTK Application for Mouse on Numpad Enhanced."""

import gi  # type: ignore[import-untyped]

gi.require_version("Gtk", "4.0")
from gi.repository import Gio, Gtk  # type: ignore[import-untyped]

from .core.config import ConfigManager
from .core.state_manager import StateManager
from .ui.main_window import MainWindow
from .ui.status_indicator import StatusIndicator
from .ui.tray_icon import TrayIcon


class Application(Gtk.Application):  # type: ignore[misc]
    """GTK Application integrating all GUI components.

    Manages lifecycle of:
    - Settings window (MainWindow)
    - System tray icon (TrayIcon)
    - Status indicator (StatusIndicator)
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

        # UI components (initialized in do_startup)
        self._main_window: MainWindow | None = None
        self._tray_icon: TrayIcon | None = None
        self._status_indicator: StatusIndicator | None = None

    def do_startup(self) -> None:
        """Called once when application starts.

        Initialize UI components that persist for app lifetime.
        """
        Gtk.Application.do_startup(self)

        # Create status indicator (always present but auto-hides)
        self._status_indicator = StatusIndicator(self._state)

        # Create system tray icon
        self._tray_icon = TrayIcon(self, self._state)
        self._tray_icon.show()

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
