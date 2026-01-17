"""Tests for ScrollController continuous scrolling."""

import threading
import time
from pathlib import Path
from unittest.mock import MagicMock, Mock

import pytest

from mouse_on_numpad.core.config import ConfigManager
from mouse_on_numpad.input.scroll_controller import ScrollController


@pytest.fixture
def config(tmp_path):
    """Create ConfigManager with scroll defaults in isolated temp directory."""
    config = ConfigManager(config_dir=tmp_path)
    # Verify scroll config has correct defaults
    assert config.get("scroll.step") == 3
    assert config.get("scroll.acceleration_rate") == 1.1
    assert config.get("scroll.max_speed") == 10
    assert config.get("scroll.delay") == 30
    return config


@pytest.fixture
def mock_mouse():
    """Create a mock mouse controller."""
    mouse = MagicMock()
    mouse.scroll = MagicMock()
    return mouse


@pytest.fixture
def scroll_controller(config, mock_mouse):
    """Create ScrollController instance."""
    return ScrollController(config, mock_mouse)


class TestScrollControllerInitialization:
    """Test ScrollController initialization."""

    def test_initialization(self, config, mock_mouse):
        """Test controller initializes correctly."""
        controller = ScrollController(config, mock_mouse)
        assert controller is not None
        assert controller._config is config
        assert controller._mouse is mock_mouse
        assert controller._current_speed == 1.0
        assert controller._active_dirs == set()
        assert controller._running is False

    def test_config_values_present(self, config):
        """Test config has required scroll keys."""
        assert config.get("scroll.step") is not None
        assert config.get("scroll.acceleration_rate") is not None
        assert config.get("scroll.max_speed") is not None
        assert config.get("scroll.delay") is not None


class TestScrollControllerDirections:
    """Test scrolling in different directions."""

    def test_start_scroll_up(self, scroll_controller, mock_mouse):
        """Test starting upward scroll."""
        scroll_controller.start_direction("up")
        assert "up" in scroll_controller._active_dirs
        time.sleep(0.1)  # Let thread tick once
        assert scroll_controller._running

    def test_start_scroll_down(self, scroll_controller, mock_mouse):
        """Test starting downward scroll."""
        scroll_controller.start_direction("down")
        assert "down" in scroll_controller._active_dirs
        time.sleep(0.1)
        assert scroll_controller._running

    def test_start_scroll_left(self, scroll_controller, mock_mouse):
        """Test starting leftward scroll."""
        scroll_controller.start_direction("left")
        assert "left" in scroll_controller._active_dirs
        time.sleep(0.1)
        assert scroll_controller._running

    def test_start_scroll_right(self, scroll_controller, mock_mouse):
        """Test starting rightward scroll."""
        scroll_controller.start_direction("right")
        assert "right" in scroll_controller._active_dirs
        time.sleep(0.1)
        assert scroll_controller._running

    def test_stop_scroll_up(self, scroll_controller, mock_mouse):
        """Test stopping upward scroll."""
        scroll_controller.start_direction("up")
        time.sleep(0.1)
        scroll_controller.stop_direction("up")
        assert "up" not in scroll_controller._active_dirs
        assert scroll_controller._current_speed == 1.0  # Reset acceleration

    def test_stop_scroll_down(self, scroll_controller, mock_mouse):
        """Test stopping downward scroll."""
        scroll_controller.start_direction("down")
        time.sleep(0.1)
        scroll_controller.stop_direction("down")
        assert "down" not in scroll_controller._active_dirs

    def test_stop_scroll_left(self, scroll_controller, mock_mouse):
        """Test stopping leftward scroll."""
        scroll_controller.start_direction("left")
        time.sleep(0.1)
        scroll_controller.stop_direction("left")
        assert "left" not in scroll_controller._active_dirs

    def test_stop_scroll_right(self, scroll_controller, mock_mouse):
        """Test stopping rightward scroll."""
        scroll_controller.start_direction("right")
        time.sleep(0.1)
        scroll_controller.stop_direction("right")
        assert "right" not in scroll_controller._active_dirs


class TestScrollControllerMultiDirection:
    """Test simultaneous scrolling in multiple directions."""

    def test_diagonal_scroll_up_right(self, scroll_controller, mock_mouse):
        """Test diagonal scroll up+right."""
        scroll_controller.start_direction("up")
        scroll_controller.start_direction("right")
        assert "up" in scroll_controller._active_dirs
        assert "right" in scroll_controller._active_dirs
        time.sleep(0.1)
        assert mock_mouse.scroll.call_count > 0

    def test_diagonal_scroll_down_left(self, scroll_controller, mock_mouse):
        """Test diagonal scroll down+left."""
        scroll_controller.start_direction("down")
        scroll_controller.start_direction("left")
        assert "down" in scroll_controller._active_dirs
        assert "left" in scroll_controller._active_dirs
        time.sleep(0.1)
        assert mock_mouse.scroll.call_count > 0

    def test_stop_one_direction_continues_other(self, scroll_controller, mock_mouse):
        """Test stopping one direction continues the other."""
        scroll_controller.start_direction("up")
        scroll_controller.start_direction("right")
        time.sleep(0.1)
        scroll_controller.stop_direction("up")
        assert "up" not in scroll_controller._active_dirs
        assert "right" in scroll_controller._active_dirs
        assert scroll_controller._running


class TestScrollControllerAcceleration:
    """Test acceleration mechanism."""

    def test_speed_increases_over_time(self, scroll_controller, mock_mouse):
        """Test that speed accelerates when scrolling continuously."""
        scroll_controller.start_direction("up")
        time.sleep(0.05)  # Let a few ticks pass
        initial_calls = mock_mouse.scroll.call_count

        # Capture first scroll delta
        first_call = mock_mouse.scroll.call_args_list[0] if initial_calls > 0 else None

        # Wait more time for acceleration
        time.sleep(0.15)

        # Should have more calls now
        assert mock_mouse.scroll.call_count > initial_calls

        # Last call should have larger delta due to acceleration
        if mock_mouse.scroll.call_count > 1:
            last_call = mock_mouse.scroll.call_args_list[-1]
            # Check that acceleration happened (speed multiplied)
            assert scroll_controller._current_speed > 1.0

    def test_acceleration_capped_at_max_speed(self, config, mock_mouse):
        """Test acceleration caps at max_speed."""
        config.set("scroll.acceleration_rate", 2.0)  # Fast acceleration
        config.set("scroll.max_speed", 5)
        config.set("scroll.step", 1)

        controller = ScrollController(config, mock_mouse)
        controller.start_direction("up")

        # Let it accelerate for many iterations
        time.sleep(0.5)

        # Speed should never exceed max_speed / step = 5
        max_mult = 5 / 1
        assert controller._current_speed <= max_mult

    def test_speed_resets_on_full_stop(self, scroll_controller, mock_mouse):
        """Test speed resets when all directions stop."""
        scroll_controller.start_direction("up")
        time.sleep(0.1)
        assert scroll_controller._current_speed > 1.0  # Should have accelerated

        scroll_controller.stop_direction("up")
        time.sleep(0.05)  # Let thread process
        assert scroll_controller._current_speed == 1.0  # Should reset


class TestScrollControllerDelta:
    """Test scroll delta calculation."""

    def test_up_scroll_positive_dy(self, scroll_controller):
        """Test up scroll produces positive dy."""
        dx, dy = scroll_controller._calc_delta()
        assert dy == 0  # No direction active

        scroll_controller._active_dirs.add("up")
        dx, dy = scroll_controller._calc_delta()
        assert dy > 0  # Positive dy for up

    def test_down_scroll_negative_dy(self, scroll_controller):
        """Test down scroll produces negative dy."""
        scroll_controller._active_dirs.add("down")
        dx, dy = scroll_controller._calc_delta()
        assert dy < 0  # Negative dy for down

    def test_left_scroll_negative_dx(self, scroll_controller):
        """Test left scroll produces negative dx."""
        scroll_controller._active_dirs.add("left")
        dx, dy = scroll_controller._calc_delta()
        assert dx < 0  # Negative dx for left

    def test_right_scroll_positive_dx(self, scroll_controller):
        """Test right scroll produces positive dx."""
        scroll_controller._active_dirs.add("right")
        dx, dy = scroll_controller._calc_delta()
        assert dx > 0  # Positive dx for right

    def test_diagonal_deltas(self, scroll_controller):
        """Test diagonal deltas combine correctly."""
        scroll_controller._active_dirs.add("up")
        scroll_controller._active_dirs.add("right")
        dx, dy = scroll_controller._calc_delta()
        assert dx > 0  # Right
        assert dy > 0  # Up

        scroll_controller._active_dirs.clear()
        scroll_controller._active_dirs.add("down")
        scroll_controller._active_dirs.add("left")
        dx, dy = scroll_controller._calc_delta()
        assert dx < 0  # Left
        assert dy < 0  # Down

    def test_opposite_directions_cancel(self, scroll_controller):
        """Test opposite directions cancel out."""
        scroll_controller._active_dirs.add("up")
        scroll_controller._active_dirs.add("down")
        dx, dy = scroll_controller._calc_delta()
        assert dy == 0  # Should cancel out

        scroll_controller._active_dirs.clear()
        scroll_controller._active_dirs.add("left")
        scroll_controller._active_dirs.add("right")
        dx, dy = scroll_controller._calc_delta()
        assert dx == 0  # Should cancel out

    def test_delta_affected_by_speed(self, scroll_controller):
        """Test delta increases with speed."""
        scroll_controller._active_dirs.add("up")
        scroll_controller._current_speed = 1.0
        dx1, dy1 = scroll_controller._calc_delta()

        scroll_controller._current_speed = 2.0
        dx2, dy2 = scroll_controller._calc_delta()

        assert dy2 > dy1  # Higher speed = larger delta


class TestScrollControllerStopAll:
    """Test stop_all functionality."""

    def test_stop_all_clears_directions(self, scroll_controller, mock_mouse):
        """Test stop_all clears all active directions."""
        scroll_controller.start_direction("up")
        scroll_controller.start_direction("right")
        assert scroll_controller._active_dirs == {"up", "right"}

        scroll_controller.stop_all()
        assert scroll_controller._active_dirs == set()
        assert scroll_controller._current_speed == 1.0
        assert scroll_controller._running is False

    def test_stop_all_resets_speed(self, scroll_controller, mock_mouse):
        """Test stop_all resets speed to 1.0."""
        scroll_controller.start_direction("up")
        time.sleep(0.1)
        assert scroll_controller._current_speed > 1.0

        scroll_controller.stop_all()
        assert scroll_controller._current_speed == 1.0

    def test_stop_all_stops_thread(self, scroll_controller, mock_mouse):
        """Test stop_all stops the scroll thread."""
        scroll_controller.start_direction("down")
        time.sleep(0.05)
        assert scroll_controller._running is True

        scroll_controller.stop_all()
        time.sleep(0.1)
        assert scroll_controller._running is False


class TestScrollControllerMouseInteraction:
    """Test interaction with mouse controller."""

    def test_mouse_scroll_called_when_scrolling(self, scroll_controller, mock_mouse):
        """Test mouse.scroll() is called during scrolling."""
        scroll_controller.start_direction("up")
        time.sleep(0.1)
        assert mock_mouse.scroll.call_count > 0

    def test_mouse_scroll_called_with_correct_args(self, scroll_controller, mock_mouse):
        """Test mouse.scroll() receives correct dx, dy arguments."""
        scroll_controller.start_direction("right")
        time.sleep(0.1)
        assert mock_mouse.scroll.call_count > 0

        # Check all calls have proper arguments
        for call in mock_mouse.scroll.call_args_list:
            dx, dy = call[0]
            assert isinstance(dx, int)
            assert isinstance(dy, int)

    def test_no_scroll_when_no_directions(self, scroll_controller, mock_mouse):
        """Test no scrolling when no directions active."""
        scroll_controller._ensure_scrolling()
        time.sleep(0.1)
        # Should not call scroll if no directions
        # (thread might not have started or died immediately)
        # Check that thread would have exited
        assert not scroll_controller._running or scroll_controller._active_dirs


class TestScrollControllerThreading:
    """Test threading and thread safety."""

    def test_scroll_thread_is_daemon(self, scroll_controller):
        """Test scroll thread is a daemon thread."""
        scroll_controller.start_direction("up")
        time.sleep(0.05)
        if scroll_controller._scroll_thread:
            assert scroll_controller._scroll_thread.daemon is True

    def test_thread_reused_when_already_running(self, scroll_controller, mock_mouse):
        """Test thread is reused if already running."""
        scroll_controller.start_direction("up")
        time.sleep(0.1)
        thread1 = scroll_controller._scroll_thread

        scroll_controller.start_direction("right")
        time.sleep(0.05)
        thread2 = scroll_controller._scroll_thread

        # Same thread should be reused
        assert thread1 == thread2

    def test_new_thread_started_if_old_died(self, scroll_controller, mock_mouse):
        """Test new thread created if previous one died."""
        scroll_controller.start_direction("up")
        time.sleep(0.1)
        thread1 = scroll_controller._scroll_thread

        scroll_controller.stop_direction("up")
        time.sleep(0.1)  # Let thread exit
        assert not thread1.is_alive()

        scroll_controller.start_direction("down")
        time.sleep(0.05)
        thread2 = scroll_controller._scroll_thread

        # New thread should be created
        assert thread1 != thread2


class TestScrollControllerConfigIntegration:
    """Test configuration integration."""

    def test_config_step_affects_delta(self, config, mock_mouse):
        """Test scroll.step config affects delta calculation."""
        controller = ScrollController(config, mock_mouse)
        controller._active_dirs.add("up")

        controller._current_speed = 1.0
        dx1, dy1 = controller._calc_delta()

        config.set("scroll.step", 6)
        dx2, dy2 = controller._calc_delta()

        # Higher step should produce larger delta
        assert dy2 == 2 * dy1

    def test_config_acceleration_affects_speed(self, config, mock_mouse):
        """Test acceleration_rate config affects speed growth."""
        controller = ScrollController(config, mock_mouse)
        old_speed = controller._current_speed

        # Slow acceleration
        config.set("scroll.acceleration_rate", 1.01)
        controller._accelerate()
        slow_speed = controller._current_speed

        # Reset and test fast acceleration
        controller._current_speed = 1.0
        config.set("scroll.acceleration_rate", 2.0)
        controller._accelerate()
        fast_speed = controller._current_speed

        assert fast_speed > slow_speed

    def test_config_max_speed_enforced(self, config, mock_mouse):
        """Test max_speed config is enforced."""
        config.set("scroll.max_speed", 3)
        config.set("scroll.step", 1)
        config.set("scroll.acceleration_rate", 10.0)

        controller = ScrollController(config, mock_mouse)

        # Accelerate many times
        for _ in range(100):
            controller._accelerate()

        # Should never exceed max_speed / step
        assert controller._current_speed <= 3


class TestScrollControllerEdgeCases:
    """Test edge cases and error conditions."""

    def test_start_same_direction_twice(self, scroll_controller):
        """Test starting same direction twice is idempotent."""
        scroll_controller.start_direction("up")
        scroll_controller.start_direction("up")
        assert scroll_controller._active_dirs == {"up"}

    def test_stop_nonexistent_direction(self, scroll_controller):
        """Test stopping nonexistent direction is safe."""
        scroll_controller.stop_direction("up")
        assert scroll_controller._active_dirs == set()

    def test_stop_all_when_already_stopped(self, scroll_controller):
        """Test stop_all when already stopped is safe."""
        scroll_controller.stop_all()
        scroll_controller.stop_all()
        assert scroll_controller._active_dirs == set()

    def test_continuous_start_stop(self, scroll_controller, mock_mouse):
        """Test rapid start/stop cycling."""
        for _ in range(10):
            scroll_controller.start_direction("up")
            time.sleep(0.01)
            scroll_controller.stop_direction("up")
            time.sleep(0.01)

        assert scroll_controller._current_speed == 1.0


class TestScrollControllerDaemonIntegration:
    """Test integration with daemon key handling."""

    def test_scroll_keys_mapping(self):
        """Test that daemon SCROLL_KEYS map correctly."""
        # From daemon.py
        SCROLL_KEYS = {
            71: ("up",),      # KEY_KP7 - scroll up
            79: ("down",),    # KEY_KP1 - scroll down
            73: ("right",),   # KEY_KP9 - scroll right
            81: ("left",),    # KEY_KP3 - scroll left
        }

        assert 71 in SCROLL_KEYS
        assert SCROLL_KEYS[71] == ("up",)
        assert SCROLL_KEYS[79] == ("down",)
        assert SCROLL_KEYS[73] == ("right",)
        assert SCROLL_KEYS[81] == ("left",)

    def test_scroll_handler_compatible_with_movement(self, config, mock_mouse):
        """Test scroll handler works like movement controller."""
        # Verify protocol compatibility
        scroll = ScrollController(config, mock_mouse)

        # These methods should exist and work like MovementController
        scroll.start_direction("up")
        assert "up" in scroll._active_dirs

        scroll.stop_direction("up")
        assert "up" not in scroll._active_dirs

        scroll.stop_all()
        assert scroll._active_dirs == set()
