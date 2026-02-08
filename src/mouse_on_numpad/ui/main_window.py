"""GTK 4 main settings window with tabbed interface."""

import gi  # type: ignore[import-untyped]

gi.require_version("Gtk", "4.0")
from gi.repository import Gtk  # type: ignore[import-untyped]

from ..core.config import ConfigManager
from ..core.state_manager import StateManager
from .movement_tab import MovementTab
from .audio_tab import AudioTab
from .hotkeys_tab import HotkeysTab
from .appearance_tab import AppearanceTab
from .profiles_tab import ProfilesTab
from .advanced_tab import AdvancedTab


class MainWindow(Gtk.ApplicationWindow):  # type: ignore[misc]
    """Main settings window with notebook for configuration tabs.

    MVP Implementation:
    - Tab 1: Movement settings (speed, acceleration)
    - Tab 2: Position memory (9 slots display)

    Uses GTK system theme only (no custom themes per validation).
    """

    def __init__(
        self, app: Gtk.Application, config: ConfigManager, state: StateManager
    ) -> None:
        """Initialize main settings window.

        Args:
            app: GTK Application instance
            config: Configuration manager
            state: State manager
        """
        super().__init__(application=app, title="Mouse on Numpad Settings")
        self._config = config
        self._state = state

        # Window properties
        self.set_default_size(700, 500)
        self.set_resizable(True)

        # Create notebook with tabs
        self._notebook = Gtk.Notebook()
        self._notebook.set_tab_pos(Gtk.PositionType.TOP)

        # Add all tabs
        self._notebook.append_page(MovementTab(config), Gtk.Label(label="Movement"))
        self._notebook.append_page(AudioTab(config), Gtk.Label(label="Audio"))
        self._notebook.append_page(HotkeysTab(config), Gtk.Label(label="Hotkeys"))
        self._notebook.append_page(
            AppearanceTab(config), Gtk.Label(label="Appearance")
        )
        self._notebook.append_page(ProfilesTab(config), Gtk.Label(label="Profiles"))
        self._notebook.append_page(AdvancedTab(config), Gtk.Label(label="Advanced"))

        # Set notebook as window content
        self.set_child(self._notebook)
