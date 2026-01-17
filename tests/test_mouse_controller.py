"""Tests for MouseController."""

from unittest.mock import MagicMock, Mock, patch

import pytest

from mouse_on_numpad.core.config import ConfigManager
from mouse_on_numpad.core.state_manager import StateManager
from mouse_on_numpad.input.mouse_controller import MouseController


@pytest.fixture
def config():
    """Create ConfigManager with test defaults."""
    config = ConfigManager()
    config.set("movement.base_speed", 10)
    config.set("movement.acceleration", 1.5)
    config.set("movement.curve", "exponential")
    return config


@pytest.fixture
def state():
    """Create StateManager."""
    return StateManager()


@pytest.fixture
def mouse_controller(config, state):
    """Create MouseController with mocked pynput."""
    with patch("mouse_on_numpad.input.mouse_controller.Controller") as mock_ctrl:
        mock_instance = MagicMock()
        mock_instance.position = (100, 100)
        mock_ctrl.return_value = mock_instance

        controller = MouseController(config, state)
        controller._controller = mock_instance
        yield controller


def test_move_to_absolute(mouse_controller, state):
    """Test absolute mouse movement."""
    mouse_controller.move_to(200, 300)

    assert mouse_controller._controller.position == (200, 300)
    assert state.current_position == (200, 300)


def test_move_relative_linear(config, state):
    """Test relative movement with linear acceleration."""
    config.set("movement.curve", "linear")

    with patch("mouse_on_numpad.input.mouse_controller.Controller") as mock_ctrl:
        mock_instance = MagicMock()
        mock_instance.position = (100, 100)
        mock_ctrl.return_value = mock_instance

        controller = MouseController(config, state)
        controller._controller = mock_instance

        # Move right by 1 unit
        controller.move_relative(1, 0)

        # Should move by base_speed * 1 = 10 pixels
        new_pos = mock_instance.position
        assert new_pos == (110, 100)


def test_move_relative_exponential(mouse_controller, state):
    """Test relative movement with exponential acceleration."""
    # Initial position
    mouse_controller._controller.position = (100, 100)

    # First movement
    mouse_controller.move_relative(1, 0)
    first_pos = mouse_controller._controller.position

    # Movement should be at least base_speed
    assert first_pos[0] >= 110


def test_click_left(mouse_controller):
    """Test left mouse click."""
    mouse_controller.click("left")
    mouse_controller._controller.click.assert_called_once()


def test_click_right(mouse_controller):
    """Test right mouse click."""
    mouse_controller.click("right")
    mouse_controller._controller.click.assert_called_once()


def test_click_middle(mouse_controller):
    """Test middle mouse click."""
    mouse_controller.click("middle")
    mouse_controller._controller.click.assert_called_once()


def test_click_invalid_button(mouse_controller):
    """Test click with invalid button does nothing."""
    mouse_controller.click("invalid")
    mouse_controller._controller.click.assert_not_called()


def test_scroll_vertical(mouse_controller):
    """Test vertical scrolling."""
    mouse_controller.scroll(dy=5)
    mouse_controller._controller.scroll.assert_called_once_with(0, 5)


def test_scroll_horizontal(mouse_controller):
    """Test horizontal scrolling."""
    mouse_controller.scroll(dx=3)
    mouse_controller._controller.scroll.assert_called_once_with(3, 0)


def test_scroll_both(mouse_controller):
    """Test scrolling both directions (vertical takes precedence)."""
    mouse_controller.scroll(dx=3, dy=5)
    mouse_controller._controller.scroll.assert_called_once_with(3, 5)


def test_get_position(mouse_controller):
    """Test getting current position."""
    mouse_controller._controller.position = (250, 350)
    pos = mouse_controller.get_position()
    assert pos == (250, 350)


def test_acceleration_s_curve(config, state):
    """Test S-curve acceleration calculation."""
    config.set("movement.curve", "s-curve")

    with patch("mouse_on_numpad.input.mouse_controller.Controller") as mock_ctrl:
        mock_instance = MagicMock()
        mock_instance.position = (100, 100)
        mock_ctrl.return_value = mock_instance

        controller = MouseController(config, state)
        controller._controller = mock_instance

        # Test acceleration calculation
        multiplier = controller._calculate_acceleration("s-curve", 0.1, 1.5)
        assert multiplier >= 1.0


def test_state_position_sync(mouse_controller, state):
    """Test position synchronization with state manager."""
    mouse_controller.move_to(500, 600)

    assert state.current_position == (500, 600)


def test_config_updates(config, state):
    """Test configuration changes affect movement."""
    with patch("mouse_on_numpad.input.mouse_controller.Controller") as mock_ctrl:
        mock_instance = MagicMock()
        mock_instance.position = (100, 100)
        mock_ctrl.return_value = mock_instance

        controller = MouseController(config, state)
        controller._controller = mock_instance

        # Change base speed
        config.set("movement.base_speed", 20)

        # Movement should use new speed
        controller.move_relative(1, 0)
        new_pos = mock_instance.position
        # Should move by at least new base_speed
        assert new_pos[0] >= 120
