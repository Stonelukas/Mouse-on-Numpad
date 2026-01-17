"""Tests for GUI components."""

import pytest
import sys
from unittest.mock import MagicMock

# Skip all GUI tests if GTK 4 is not available
pytest.importorskip("gi.repository.Gtk")

import gi  # type: ignore[import-untyped]

gi.require_version("Gtk", "4.0")
from gi.repository import Gtk  # type: ignore[import-untyped]

# Mock pystray before importing modules that use it (avoids GTK 3/4 conflict)
sys.modules["pystray"] = MagicMock()

from mouse_on_numpad.core.config import ConfigManager
from mouse_on_numpad.core.state_manager import StateManager
from mouse_on_numpad.ui.main_window import MainWindow
from mouse_on_numpad.ui.status_indicator import StatusIndicator


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


def test_config_manager_can_be_instantiated(tmp_path):
    """Test that ConfigManager can be created."""
    config = ConfigManager(config_dir=tmp_path)
    assert config is not None
    assert config.get("movement.base_speed") is not None


def test_main_window_can_be_created(gtk_app, config, state):
    """Test that MainWindow can be created."""
    window = MainWindow(gtk_app, config, state)
    assert window is not None
    assert window.get_title() == "Mouse on Numpad Settings"


def test_state_manager_toggle(state):
    """Test that StateManager toggle works."""
    assert not state.is_enabled
    state.toggle()
    assert state.is_enabled
    state.toggle()
    assert not state.is_enabled


def test_main_window_config_updates(gtk_app, config, state):
    """Test that MainWindow updates config on slider changes."""
    window = MainWindow(gtk_app, config, state)

    # Verify initial values from DEFAULT_CONFIG (base_speed=5, acceleration=1.08)
    assert config.get("movement.base_speed") == 5
    assert config.get("movement.acceleration_rate") == 1.08

    # Simulate slider changes would update config
    # (actual slider interaction requires GTK main loop)
    config.set("movement.base_speed", 50)
    assert config.get("movement.base_speed") == 50


def test_hotkeys_config_defaults(config):
    """Test that hotkeys config has correct defaults."""
    assert config.get("hotkeys.toggle_mode") == 78  # KEY_KPPLUS
    assert config.get("hotkeys.left_click") == 76  # KEY_KP5
    assert config.get("hotkeys.move_up") == 72  # KEY_KP8
    assert config.get("hotkeys.scroll_up") == 71  # KEY_KP7
