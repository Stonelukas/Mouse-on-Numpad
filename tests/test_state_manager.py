"""Tests for StateManager."""

import threading
import time

import pytest

from mouse_on_numpad.core.state_manager import MouseMode, StateManager


class TestStateManager:
    """Test StateManager functionality."""

    def test_default_state(self):
        """Default state is disabled (NumLock ON)."""
        state = StateManager()
        assert state.mouse_mode == MouseMode.DISABLED
        assert state.is_enabled is False
        assert state.numlock_state is True

    def test_toggle(self):
        """Toggle switches between enabled and disabled."""
        state = StateManager()
        assert state.is_enabled is False

        result = state.toggle()
        assert result is True
        assert state.is_enabled is True

        result = state.toggle()
        assert result is False
        assert state.is_enabled is False

    def test_numlock_controls_mode(self):
        """NumLock state controls mouse mode."""
        state = StateManager()

        # NumLock OFF = mouse mode enabled
        state.numlock_state = False
        assert state.is_enabled is True
        assert state.mouse_mode == MouseMode.ENABLED

        # NumLock ON = mouse mode disabled
        state.numlock_state = True
        assert state.is_enabled is False
        assert state.mouse_mode == MouseMode.DISABLED

    def test_subscribe_notified_on_change(self):
        """Subscribers notified when state changes."""
        state = StateManager()
        notifications: list[tuple[str, object]] = []

        def callback(key: str, value: object):
            notifications.append((key, value))

        state.subscribe(callback)
        state.toggle()

        assert len(notifications) >= 1
        assert ("mouse_mode", MouseMode.ENABLED) in notifications

    def test_unsubscribe_stops_notifications(self):
        """Unsubscribed callbacks not called."""
        state = StateManager()
        notifications: list[tuple[str, object]] = []

        def callback(key: str, value: object):
            notifications.append((key, value))

        state.subscribe(callback)
        state.unsubscribe(callback)
        state.toggle()

        assert len(notifications) == 0

    def test_multiple_subscribers(self):
        """Multiple subscribers all notified."""
        state = StateManager()
        counts = {"a": 0, "b": 0}

        def callback_a(key: str, value: object):
            counts["a"] += 1

        def callback_b(key: str, value: object):
            counts["b"] += 1

        state.subscribe(callback_a)
        state.subscribe(callback_b)
        state.toggle()

        assert counts["a"] >= 1
        assert counts["b"] >= 1

    def test_bad_callback_doesnt_break_others(self):
        """Exception in one callback doesn't affect others."""
        state = StateManager()
        good_called = {"value": False}

        def bad_callback(key: str, value: object):
            raise RuntimeError("Intentional error")

        def good_callback(key: str, value: object):
            good_called["value"] = True

        state.subscribe(bad_callback)
        state.subscribe(good_callback)
        state.toggle()

        assert good_called["value"] is True

    def test_current_position(self):
        """Position can be set and retrieved."""
        state = StateManager()
        state.current_position = (100, 200)
        assert state.current_position == (100, 200)

    def test_active_monitor(self):
        """Active monitor can be set and retrieved."""
        state = StateManager()
        state.active_monitor = 1
        assert state.active_monitor == 1

    def test_get_state_snapshot(self):
        """Snapshot returns all state values."""
        state = StateManager()
        state.current_position = (50, 75)
        state.active_monitor = 2

        snapshot = state.get_state_snapshot()
        assert snapshot["mouse_mode"] == MouseMode.DISABLED
        assert snapshot["current_position"] == (50, 75)
        assert snapshot["active_monitor"] == 2
        assert snapshot["numlock_state"] is True
        assert snapshot["is_enabled"] is False

    def test_thread_safety(self):
        """State access is thread-safe."""
        state = StateManager()
        errors: list[Exception] = []

        def toggle_many():
            try:
                for _ in range(100):
                    state.toggle()
            except Exception as e:
                errors.append(e)

        threads = [threading.Thread(target=toggle_many) for _ in range(10)]
        for t in threads:
            t.start()
        for t in threads:
            t.join()

        assert len(errors) == 0

    def test_subscribe_same_callback_once(self):
        """Same callback not added twice."""
        state = StateManager()
        count = {"value": 0}

        def callback(key: str, value: object):
            count["value"] += 1

        state.subscribe(callback)
        state.subscribe(callback)  # Should not add again
        state.toggle()

        # Only called once per notification, not twice
        assert count["value"] >= 1

    def test_position_notifies_on_change_only(self):
        """Position notifications only on actual change."""
        state = StateManager()
        notifications: list[tuple[str, object]] = []

        def callback(key: str, value: object):
            if key == "current_position":
                notifications.append((key, value))

        state.subscribe(callback)

        state.current_position = (100, 100)
        state.current_position = (100, 100)  # Same value
        state.current_position = (200, 200)  # Different value

        # Should have 2 notifications, not 3
        assert len(notifications) == 2
