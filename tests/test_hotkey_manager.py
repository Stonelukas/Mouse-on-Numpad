"""Tests for HotkeyManager."""

from unittest.mock import MagicMock, patch

import pytest
from pynput.keyboard import Key, KeyCode

from mouse_on_numpad.core.state_manager import MouseMode, StateManager
from mouse_on_numpad.input.hotkey_manager import HotkeyManager


@pytest.fixture
def state():
    """Create StateManager."""
    return StateManager()


@pytest.fixture
def hotkey_manager(state):
    """Create HotkeyManager with mocked listener."""
    with patch("mouse_on_numpad.input.hotkey_manager.keyboard.Listener"):
        manager = HotkeyManager(state)
        yield manager


def test_register_simple_key(hotkey_manager):
    """Test registering a simple hotkey."""
    callback = MagicMock()
    hotkey_manager.register("kp_5", callback)

    assert "kp_5" in hotkey_manager._callbacks


def test_register_with_modifiers(hotkey_manager):
    """Test registering hotkey with modifiers."""
    callback = MagicMock()
    hotkey_manager.register("kp_5", callback, modifiers=["ctrl", "shift"])

    # Modifiers and key should be sorted alphabetically
    assert "ctrl+shift+kp_5" in hotkey_manager._callbacks


def test_unregister_key(hotkey_manager):
    """Test unregistering a hotkey."""
    callback = MagicMock()
    hotkey_manager.register("kp_5", callback)
    hotkey_manager.unregister("kp_5")

    assert "kp_5" not in hotkey_manager._callbacks


def test_start_listener(hotkey_manager):
    """Test starting the listener."""
    hotkey_manager.start()
    assert hotkey_manager._running is True


def test_stop_listener(hotkey_manager):
    """Test stopping the listener."""
    hotkey_manager.start()
    hotkey_manager.stop()

    assert hotkey_manager._running is False
    assert hotkey_manager._listener is None


def test_key_press_when_enabled(hotkey_manager, state):
    """Test key press triggers callback when mouse mode enabled."""
    callback = MagicMock()
    hotkey_manager.register("kp_5", callback)

    # Enable mouse mode (NumLock OFF)
    state.mouse_mode = MouseMode.ENABLED

    # Simulate keypress for numpad 5 (keycode 65437)
    key = KeyCode(vk=65437)
    hotkey_manager._on_press(key)

    callback.assert_called_once()


def test_key_press_when_disabled(hotkey_manager, state):
    """Test key press ignored when mouse mode disabled."""
    callback = MagicMock()
    hotkey_manager.register("kp_5", callback)

    # Disable mouse mode (NumLock ON)
    state.mouse_mode = MouseMode.DISABLED

    # Simulate keypress
    key = KeyCode(vk=65437)
    hotkey_manager._on_press(key)

    callback.assert_not_called()


def test_identify_numpad_key(hotkey_manager):
    """Test identifying numpad keys."""
    # Numpad 5 (KP_Begin)
    key = KeyCode(vk=65437)
    name = hotkey_manager._identify_key(key)
    assert name == "kp_5"

    # Numpad 8 (KP_Up)
    key = KeyCode(vk=65431)
    name = hotkey_manager._identify_key(key)
    assert name == "kp_8"

    # Numpad + (KP_Add)
    key = KeyCode(vk=65451)
    name = hotkey_manager._identify_key(key)
    assert name == "kp_add"


def test_identify_special_key(hotkey_manager):
    """Test identifying special keys."""
    key = Key.ctrl_l
    name = hotkey_manager._identify_key(key)
    # Key.name returns the base name without left/right suffix
    assert name == "ctrl"


def test_identify_unknown_key(hotkey_manager):
    """Test identifying unknown key returns None."""
    key = KeyCode(vk=9999)
    name = hotkey_manager._identify_key(key)
    assert name is None


def test_get_active_modifiers(hotkey_manager):
    """Test getting active modifier keys."""
    # Simulate pressing Ctrl + Shift
    hotkey_manager._pressed_keys.add(Key.ctrl_l)
    hotkey_manager._pressed_keys.add(Key.shift_r)

    modifiers = hotkey_manager._get_active_modifiers()

    assert "ctrl" in modifiers
    assert "shift" in modifiers
    assert len(modifiers) == 2


def test_modifier_combination(hotkey_manager, state):
    """Test hotkey with modifier combination."""
    callback = MagicMock()
    hotkey_manager.register("kp_5", callback, modifiers=["ctrl"])

    state.mouse_mode = MouseMode.ENABLED

    # Press Ctrl first
    hotkey_manager._on_press(Key.ctrl_l)

    # Then press numpad 5
    key = KeyCode(vk=65437)
    hotkey_manager._on_press(key)

    callback.assert_called_once()


def test_key_release_tracking(hotkey_manager):
    """Test key release removes from pressed keys."""
    key = Key.ctrl_l
    hotkey_manager._pressed_keys.add(key)

    hotkey_manager._on_release(key)

    assert key not in hotkey_manager._pressed_keys


def test_callback_exception_handling(hotkey_manager, state):
    """Test callback exception doesn't crash manager."""
    def bad_callback():
        raise RuntimeError("Test error")

    hotkey_manager.register("kp_5", bad_callback)
    state.mouse_mode = MouseMode.ENABLED

    # Should not raise
    key = KeyCode(vk=65437)
    hotkey_manager._on_press(key)


def test_all_numpad_keys_mapped(hotkey_manager):
    """Test all numpad keys are in the mapping."""
    expected_keys = [
        "kp_0", "kp_1", "kp_2", "kp_3", "kp_4",
        "kp_5", "kp_6", "kp_7", "kp_8", "kp_9",
        "kp_decimal", "kp_enter", "kp_add",
        "kp_subtract", "kp_multiply", "kp_divide",
    ]

    mapped_keys = set(hotkey_manager.NUMPAD_KEYS.values())

    for key in expected_keys:
        assert key in mapped_keys


def test_multiple_callbacks(hotkey_manager, state):
    """Test multiple different hotkeys work independently."""
    callback1 = MagicMock()
    callback2 = MagicMock()

    hotkey_manager.register("kp_5", callback1)
    hotkey_manager.register("kp_8", callback2)

    state.mouse_mode = MouseMode.ENABLED

    # Press kp_5
    hotkey_manager._on_press(KeyCode(vk=65437))
    callback1.assert_called_once()
    callback2.assert_not_called()

    # Press kp_8
    hotkey_manager._on_press(KeyCode(vk=65431))
    assert callback1.call_count == 1
    callback2.assert_called_once()
