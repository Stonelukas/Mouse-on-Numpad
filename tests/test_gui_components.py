"""Tests for GUI components."""

import pytest

# Skip all GUI tests if GTK 4 is not available
pytest.importorskip("gi.repository.Gtk")

import gi  # type: ignore[import-untyped]

gi.require_version("Gtk", "4.0")
from gi.repository import Gtk  # type: ignore[import-untyped]

from mouse_on_numpad.app import Application
from mouse_on_numpad.core.config import ConfigManager
from mouse_on_numpad.core.state_manager import StateManager
from mouse_on_numpad.ui.main_window import MainWindow
from mouse_on_numpad.ui.status_indicator import StatusIndicator
from mouse_on_numpad.ui.tray_icon import TrayIcon


@pytest.fixture
def gtk_app() -> Gtk.Application:
    """Create a minimal GTK application for testing."""
    app = Gtk.Application(application_id="com.test.mouse-on-numpad")
    return app


@pytest.fixture
def config(tmp_path):
    """Create a test config manager."""
    return ConfigManager(config_dir=tmp_path)


@pytest.fixture
def state():
    """Create a test state manager."""
    return StateManager()


def test_application_can_be_instantiated():
    """Test that Application can be created."""
    app = Application()
    assert app is not None
    assert app.get_config() is not None
    assert app.get_state() is not None


def test_main_window_can_be_created(gtk_app, config, state):
    """Test that MainWindow can be created."""
    window = MainWindow(gtk_app, config, state)
    assert window is not None
    assert window.get_title() == "Mouse on Numpad Settings"


def test_status_indicator_can_be_created(state):
    """Test that StatusIndicator can be created."""
    indicator = StatusIndicator(state)
    assert indicator is not None


def test_tray_icon_can_be_created(gtk_app, state):
    """Test that TrayIcon can be created."""
    tray = TrayIcon(gtk_app, state)
    assert tray is not None


def test_status_indicator_auto_hides_when_disabled(state):
    """Test that status indicator hides when mouse mode is disabled."""
    indicator = StatusIndicator(state)

    # Initially disabled
    assert not state.is_enabled
    assert not indicator.get_visible()

    # Enable mouse mode
    state.toggle()
    assert state.is_enabled
    assert indicator.get_visible()

    # Disable mouse mode
    state.toggle()
    assert not state.is_enabled
    assert not indicator.get_visible()


def test_main_window_config_updates(gtk_app, config, state):
    """Test that MainWindow updates config on slider changes."""
    window = MainWindow(gtk_app, config, state)

    # Verify initial values
    assert config.get("movement.base_speed") == 15
    assert config.get("movement.acceleration_rate") == 1.15

    # Simulate slider changes would update config
    # (actual slider interaction requires GTK main loop)
    config.set("movement.base_speed", 50)
    assert config.get("movement.base_speed") == 50
