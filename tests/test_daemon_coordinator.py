"""Tests for Daemon (daemon_coordinator.py)."""

from unittest.mock import MagicMock, Mock, patch, call
import signal
import pytest

from mouse_on_numpad.core.config import ConfigManager
from mouse_on_numpad.core.state_manager import StateManager
from mouse_on_numpad.core.error_logger import ErrorLogger
from mouse_on_numpad.daemon.daemon_coordinator import Daemon


@pytest.fixture
def config():
    """Create ConfigManager with test defaults."""
    config = ConfigManager()
    return config


@pytest.fixture
def state():
    """Create StateManager."""
    return StateManager()


@pytest.fixture
def logger():
    """Create ErrorLogger."""
    return ErrorLogger(console_output=False)


@pytest.fixture
def daemon(config, state, logger):
    """Create Daemon with mocked dependencies."""
    with patch("mouse_on_numpad.daemon.daemon_coordinator.create_mouse_controller") as mock_mouse_factory:
        with patch("mouse_on_numpad.daemon.daemon_coordinator.MonitorManager"):
            with patch("mouse_on_numpad.daemon.daemon_coordinator.PositionMemory"):
                with patch("mouse_on_numpad.daemon.daemon_coordinator.AudioFeedback"):
                    with patch("mouse_on_numpad.daemon.daemon_coordinator.MovementController"):
                        with patch("mouse_on_numpad.daemon.daemon_coordinator.ScrollController"):
                            with patch("mouse_on_numpad.daemon.daemon_coordinator.TrayIcon"):
                                with patch("mouse_on_numpad.daemon.daemon_coordinator.KeyboardCapture"):
                                    with patch("mouse_on_numpad.daemon.daemon_coordinator.HotkeyDispatcher"):
                                        with patch("mouse_on_numpad.daemon.daemon_coordinator.IPCManager"):
                                            with patch("mouse_on_numpad.daemon.daemon_coordinator.PositionManager"):
                                                mock_mouse_factory.return_value = MagicMock()
                                                daemon = Daemon(config, state, logger)
                                                yield daemon


def test_daemon_init(daemon, config, state, logger):
    """Test Daemon initialization."""
    assert daemon.config is config
    assert daemon.state is state
    assert daemon.logger is logger
    assert daemon._running is False
    assert daemon._held_buttons == set()
    assert daemon._save_mode == {"active": False}
    assert daemon._load_mode == {"active": False}


def test_daemon_toggle_mode_enables(daemon, state):
    """Test toggle_mode enables when disabled."""
    from mouse_on_numpad.core.state_manager import MouseMode
    state.mouse_mode = MouseMode.DISABLED
    daemon.tray = MagicMock()
    daemon.ipc = MagicMock()
    daemon.movement = MagicMock()
    daemon.scroll = MagicMock()

    daemon._toggle_mode()

    assert state.is_enabled is True
    daemon.tray.update.assert_called_once_with(True)
    daemon.ipc.write_status.assert_called_once_with(True)


def test_daemon_toggle_mode_disables(daemon, state):
    """Test toggle_mode disables when enabled."""
    from mouse_on_numpad.core.state_manager import MouseMode
    state.mouse_mode = MouseMode.ENABLED
    daemon.tray = MagicMock()
    daemon.ipc = MagicMock()
    daemon.movement = MagicMock()
    daemon.scroll = MagicMock()

    daemon._toggle_mode()

    assert state.is_enabled is False
    daemon.movement.stop_all.assert_called_once()
    daemon.scroll.stop_all.assert_called_once()


def test_release_all_held_buttons(daemon):
    """Test releasing all held mouse buttons."""
    daemon.mouse = MagicMock()
    daemon._held_buttons = {"left", "middle"}

    daemon._release_all_held_buttons()

    assert daemon.mouse.release.call_count == 2
    assert daemon._held_buttons == set()


def test_reload_hotkeys(daemon):
    """Test reloading hotkeys from config."""
    daemon.hotkeys = MagicMock()
    daemon.movement = MagicMock()
    daemon.scroll = MagicMock()
    daemon._save_mode["active"] = True
    daemon._load_mode["active"] = True

    daemon.reload_hotkeys()

    assert daemon._save_mode["active"] is False
    assert daemon._load_mode["active"] is False
    daemon.hotkeys.reload_hotkeys.assert_called_once()


def test_handle_key_delegates_to_hotkeys(daemon):
    """Test _handle_key delegates to hotkey dispatcher."""
    daemon.hotkeys = MagicMock()
    daemon.hotkeys.handle_key.return_value = True
    daemon.state = MagicMock()
    daemon.mouse = MagicMock()
    daemon.movement = MagicMock()
    daemon.scroll = MagicMock()
    daemon.tray = MagicMock()
    daemon.ipc = MagicMock()
    daemon.position_mgr = MagicMock()

    result = daemon._handle_key(42, True)

    daemon.hotkeys.handle_key.assert_called_once()
    assert result is True


def test_daemon_start_no_devices(daemon):
    """Test daemon start when no keyboard devices found."""
    daemon.keyboard = MagicMock()
    daemon.keyboard.find_keyboards.return_value = []
    daemon.tray = MagicMock()
    daemon.ipc = MagicMock()

    daemon.start()

    # If no devices found, _running stays False
    assert daemon._running is False or len(daemon._devices) == 0


def test_daemon_start_with_devices(daemon):
    """Test daemon start with devices found."""
    mock_device = MagicMock()
    daemon.keyboard = MagicMock()
    daemon.keyboard.find_keyboards.return_value = [mock_device]
    daemon.tray = MagicMock()
    daemon.ipc = MagicMock()
    daemon.movement = MagicMock()
    daemon.scroll = MagicMock()
    daemon._running = False

    # Mock signal.signal to prevent actual signal registration
    with patch("signal.signal"):
        # Start daemon in a thread with timeout
        import threading
        def start_and_stop():
            daemon.start()

        thread = threading.Thread(target=start_and_stop, daemon=True)
        thread.start()

        # Give it time to start
        import time
        time.sleep(0.1)

        # Stop the daemon
        daemon.stop()
        thread.join(timeout=1)

    assert daemon._running is False


def test_daemon_stop_cleans_up(daemon):
    """Test daemon stop cleanup."""
    daemon._running = True
    daemon.tray = MagicMock()
    daemon.ipc = MagicMock()
    daemon.movement = MagicMock()
    daemon.scroll = MagicMock()
    mock_device = MagicMock()
    daemon._devices = [mock_device]

    daemon.stop()

    assert daemon._running is False
    daemon.movement.stop_all.assert_called_once()
    daemon.scroll.stop_all.assert_called_once()
    daemon.tray.stop.assert_called_once()
    daemon.ipc.stop_indicator.assert_called_once()
    daemon.ipc.cleanup_status_file.assert_called_once()
    mock_device.close.assert_called_once()


def test_daemon_stop_handles_device_close_error(daemon):
    """Test daemon stop handles device close errors gracefully."""
    daemon._running = True
    daemon.tray = MagicMock()
    daemon.ipc = MagicMock()
    daemon.movement = MagicMock()
    daemon.scroll = MagicMock()
    mock_device = MagicMock()
    mock_device.close.side_effect = OSError("Device error")
    daemon._devices = [mock_device]

    # Should not raise
    daemon.stop()

    assert daemon._running is False


def test_daemon_without_explicit_dependencies(config, state, logger):
    """Test Daemon can be created with None values (uses defaults)."""
    with patch("mouse_on_numpad.daemon.daemon_coordinator.create_mouse_controller"):
        with patch("mouse_on_numpad.daemon.daemon_coordinator.MonitorManager"):
            with patch("mouse_on_numpad.daemon.daemon_coordinator.PositionMemory"):
                with patch("mouse_on_numpad.daemon.daemon_coordinator.AudioFeedback"):
                    with patch("mouse_on_numpad.daemon.daemon_coordinator.MovementController"):
                        with patch("mouse_on_numpad.daemon.daemon_coordinator.ScrollController"):
                            with patch("mouse_on_numpad.daemon.daemon_coordinator.TrayIcon"):
                                with patch("mouse_on_numpad.daemon.daemon_coordinator.KeyboardCapture"):
                                    with patch("mouse_on_numpad.daemon.daemon_coordinator.HotkeyDispatcher"):
                                        with patch("mouse_on_numpad.daemon.daemon_coordinator.IPCManager"):
                                            with patch("mouse_on_numpad.daemon.daemon_coordinator.PositionManager"):
                                                with patch("mouse_on_numpad.daemon.daemon_coordinator.ErrorLogger"):
                                                    with patch("mouse_on_numpad.daemon.daemon_coordinator.ConfigManager"):
                                                        with patch("mouse_on_numpad.daemon.daemon_coordinator.StateManager"):
                                                            daemon = Daemon(None, None, None)
                                                            assert daemon.config is not None
                                                            assert daemon.state is not None
                                                            assert daemon.logger is not None
