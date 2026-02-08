"""Comprehensive tests for MovementController."""

from unittest.mock import MagicMock, Mock, patch
import threading
import time
import pytest

from mouse_on_numpad.core.config import ConfigManager
from mouse_on_numpad.input.movement_controller import MovementController


@pytest.fixture
def config():
    """Create ConfigManager with movement defaults."""
    config = ConfigManager()
    config.set("movement.base_speed", 10)
    config.set("movement.acceleration_rate", 1.02)
    config.set("movement.curve", "exponential")
    config.set("movement.move_delay", 10)
    config.set("movement.max_speed", 100)
    config.set("undo.max_levels", 10)
    return config


@pytest.fixture
def mock_mouse():
    """Create mocked mouse controller."""
    return MagicMock()


@pytest.fixture
def movement_controller(config, mock_mouse):
    """Create MovementController instance."""
    return MovementController(config, mock_mouse)


def test_movement_controller_init(movement_controller, config, mock_mouse):
    """Test MovementController initialization."""
    assert movement_controller._config is config
    assert movement_controller._mouse is mock_mouse
    assert movement_controller._current_speed == 1.0
    assert movement_controller._active_dirs == set()
    assert movement_controller._running is False
    assert movement_controller._move_history == []


def test_start_direction_single(movement_controller, mock_mouse):
    """Test starting movement in a single direction."""
    movement_controller.start_direction("up")

    assert "up" in movement_controller._active_dirs
    # Give thread time to start
    time.sleep(0.05)
    assert movement_controller._running is True


def test_start_direction_multiple_diagonal(movement_controller):
    """Test diagonal movement (multiple directions)."""
    movement_controller.start_direction("up")
    movement_controller.start_direction("left")

    assert movement_controller._active_dirs == {"up", "left"}


def test_stop_direction_single(movement_controller):
    """Test stopping movement in a direction."""
    movement_controller.start_direction("up")
    time.sleep(0.05)

    movement_controller.stop_direction("up")

    assert "up" not in movement_controller._active_dirs
    assert movement_controller._current_speed == 1.0


def test_stop_direction_one_of_many(movement_controller):
    """Test stopping one direction while others active."""
    movement_controller.start_direction("up")
    movement_controller.start_direction("left")
    time.sleep(0.05)

    movement_controller.stop_direction("up")

    assert movement_controller._active_dirs == {"left"}
    # Speed should not reset if still moving
    assert movement_controller._current_speed >= 1.0


def test_stop_all(movement_controller):
    """Test stopping all movement."""
    movement_controller.start_direction("up")
    movement_controller.start_direction("right")
    movement_controller._current_speed = 2.5
    time.sleep(0.05)

    movement_controller.stop_all()

    assert movement_controller._active_dirs == set()
    assert movement_controller._current_speed == 1.0
    assert movement_controller._running is False


def test_calc_delta_up(movement_controller):
    """Test calculating delta for upward movement."""
    movement_controller._active_dirs = {"up"}
    movement_controller._current_speed = 1.0

    dx, dy = movement_controller._calc_delta()

    assert dx == 0
    assert dy < 0  # Upward is negative


def test_calc_delta_diagonal(movement_controller):
    """Test calculating delta for diagonal movement."""
    movement_controller._active_dirs = {"up", "right"}
    movement_controller._current_speed = 1.0

    dx, dy = movement_controller._calc_delta()

    assert dx > 0  # Right
    assert dy < 0  # Up


def test_calc_delta_with_acceleration(movement_controller):
    """Test that delta scales with acceleration."""
    movement_controller._active_dirs = {"right"}
    movement_controller._current_speed = 1.0

    dx1, _ = movement_controller._calc_delta()

    movement_controller._current_speed = 2.0
    dx2, _ = movement_controller._calc_delta()

    # Double speed should roughly double delta
    assert abs(dx2) > abs(dx1)


def test_accelerate_exponential(movement_controller, config):
    """Test exponential acceleration curve."""
    config.set("movement.curve", "exponential")
    movement_controller._current_speed = 1.0
    initial_speed = movement_controller._current_speed

    movement_controller._accelerate()

    assert movement_controller._current_speed > initial_speed


def test_accelerate_linear(movement_controller, config):
    """Test linear acceleration curve."""
    config.set("movement.curve", "linear")
    movement_controller._current_speed = 1.0
    rate = config.get("movement.acceleration_rate", 1.02)
    expected_increment = rate - 1

    movement_controller._accelerate()

    assert movement_controller._current_speed == pytest.approx(1.0 + expected_increment)


def test_accelerate_s_curve(movement_controller, config):
    """Test S-curve acceleration."""
    config.set("movement.curve", "s-curve")
    movement_controller._current_speed = 1.0

    movement_controller._accelerate()

    assert movement_controller._current_speed > 1.0


def test_accelerate_respects_max_speed(movement_controller, config):
    """Test that acceleration respects max speed."""
    config.set("movement.max_speed", 50)
    config.set("movement.base_speed", 10)
    max_mult = 50 / 10  # 5.0

    movement_controller._current_speed = 4.9
    movement_controller._accelerate()

    assert movement_controller._current_speed <= max_mult


def test_record_move_adds_to_history(movement_controller):
    """Test that moves are recorded for undo."""
    movement_controller._record_move(10, -5)

    assert (10, -5) in movement_controller._move_history


def test_record_move_respects_max_levels(movement_controller, config):
    """Test that undo history respects max levels."""
    config.set("undo.max_levels", 3)
    movement_controller._record_move(1, 2)
    movement_controller._record_move(3, 4)
    movement_controller._record_move(5, 6)
    movement_controller._record_move(7, 8)

    assert len(movement_controller._move_history) <= 3


def test_undo_reverses_last_move(movement_controller, mock_mouse):
    """Test undo reverses the last move."""
    movement_controller._record_move(20, -15)

    result = movement_controller.undo()

    assert result is True
    # Should move in opposite direction
    mock_mouse.move.assert_called_once_with(-20, 15)
    assert len(movement_controller._move_history) == 0


def test_undo_with_empty_history(movement_controller, mock_mouse):
    """Test undo with empty history returns False."""
    result = movement_controller.undo()

    assert result is False
    mock_mouse.move.assert_not_called()


def test_undo_multiple_times(movement_controller, mock_mouse):
    """Test undoing multiple moves."""
    movement_controller._record_move(10, 0)
    movement_controller._record_move(0, 10)

    result1 = movement_controller.undo()
    result2 = movement_controller.undo()
    result3 = movement_controller.undo()

    assert result1 is True
    assert result2 is True
    assert result3 is False  # Empty after 2 undos
    assert mock_mouse.move.call_count == 2


def test_movement_loop_respects_move_delay(movement_controller, config, mock_mouse):
    """Test that movement loop respects configured delay."""
    config.set("movement.move_delay", 20)
    movement_controller.start_direction("right")

    # Let it run for a short time
    time.sleep(0.15)

    # With 20ms delay per move, should have ~7 moves in 150ms
    # (might be slightly less due to overhead)
    call_count = mock_mouse.move.call_count
    assert call_count >= 5  # At least some moves


def test_movement_loop_reloads_config(movement_controller, config, mock_mouse):
    """Test that movement loop reloads config periodically."""
    config.set("movement.base_speed", 10)
    movement_controller.start_direction("right")

    time.sleep(0.05)
    first_call_count = mock_mouse.move.call_count

    # Change config
    config.set("movement.base_speed", 20)

    time.sleep(0.15)
    second_call_count = mock_mouse.move.call_count

    # Should have made more moves with config reload
    assert second_call_count > first_call_count


def test_movement_thread_cleanup_on_stop(movement_controller):
    """Test that movement thread cleans up properly."""
    movement_controller.start_direction("up")
    time.sleep(0.05)

    thread = movement_controller._move_thread
    assert thread is not None
    assert thread.is_alive()

    movement_controller.stop_all()
    time.sleep(0.1)

    assert not thread.is_alive()


def test_concurrent_direction_changes(movement_controller, mock_mouse):
    """Test rapid direction changes."""
    movement_controller.start_direction("up")
    time.sleep(0.02)

    movement_controller.stop_direction("up")
    movement_controller.start_direction("down")
    time.sleep(0.02)

    movement_controller.stop_direction("down")
    movement_controller.start_direction("left")
    movement_controller.start_direction("right")
    time.sleep(0.05)

    # Should handle rapid changes without crashing
    assert movement_controller._active_dirs == {"left", "right"}
    assert mock_mouse.move.call_count > 0


def test_lock_protection(movement_controller):
    """Test that lock protects shared state."""
    # This is a basic test to ensure locking doesn't deadlock
    def change_directions():
        for _ in range(10):
            movement_controller.start_direction("up")
            time.sleep(0.01)
            movement_controller.stop_direction("up")

    thread = threading.Thread(target=change_directions, daemon=True)
    thread.start()

    # Main thread also changes directions
    for _ in range(10):
        movement_controller.start_direction("down")
        time.sleep(0.01)
        movement_controller.stop_direction("down")

    thread.join(timeout=2)
    assert not thread.is_alive()


def test_all_cardinal_directions(movement_controller):
    """Test all four cardinal directions."""
    for direction in ["up", "down", "left", "right"]:
        movement_controller._active_dirs.clear()
        movement_controller._active_dirs.add(direction)

        dx, dy = movement_controller._calc_delta()

        if direction == "up":
            assert dy < 0 and dx == 0
        elif direction == "down":
            assert dy > 0 and dx == 0
        elif direction == "left":
            assert dx < 0 and dy == 0
        elif direction == "right":
            assert dx > 0 and dy == 0


def test_speed_reset_on_full_stop(movement_controller):
    """Test that speed resets when all directions stop."""
    movement_controller.start_direction("up")
    time.sleep(0.05)
    movement_controller._current_speed = 3.0  # Simulate acceleration

    movement_controller.stop_direction("up")

    assert movement_controller._current_speed == 1.0


def test_speed_not_reset_with_multiple_directions(movement_controller):
    """Test that speed doesn't reset if some directions still active."""
    movement_controller.start_direction("up")
    movement_controller.start_direction("left")
    time.sleep(0.05)
    movement_controller._current_speed = 2.5

    movement_controller.stop_direction("up")

    # Speed should not reset since left is still active
    assert movement_controller._current_speed == 2.5
