"""Tests for HotkeyDispatcher."""

from unittest.mock import MagicMock, Mock, patch
import pytest

from mouse_on_numpad.core.config import ConfigManager
from mouse_on_numpad.core.error_logger import ErrorLogger
from mouse_on_numpad.daemon.hotkey_dispatcher import HotkeyDispatcher
from mouse_on_numpad.daemon.keyboard_capture import KEY_LEFTALT, KEY_RIGHTALT

# Evdev keycodes (from keyboard_capture module defaults)
KEY_KP_PLUS = 78      # KP_Plus (toggle)
KEY_UP = 72           # KP_Up (move_up)
KEY_DOWN = 80         # KP_Down (move_down)
KEY_LEFT = 75         # KP_Left (move_left)
KEY_RIGHT = 77        # KP_Right (move_right)


@pytest.fixture
def config():
    """Create ConfigManager with test defaults."""
    config = ConfigManager()
    return config


@pytest.fixture
def logger():
    """Create ErrorLogger."""
    return ErrorLogger(console_output=False)


@pytest.fixture
def dispatcher(config, logger):
    """Create HotkeyDispatcher."""
    with patch("mouse_on_numpad.daemon.hotkey_dispatcher.HotkeyConfig"):
        dispatcher = HotkeyDispatcher(config, logger)
        dispatcher.keys = MagicMock()
        # Set default key mappings (using actual evdev keycodes)
        dispatcher.keys.key_toggle = KEY_KP_PLUS       # 78
        dispatcher.keys.key_save_mode = 55             # Default from hotkey_config
        dispatcher.keys.key_load_mode = 74             # Default from hotkey_config
        dispatcher.keys.slot_keys = {75: 1, 76: 2}    # slot_1 (75), slot_2 (76)
        dispatcher.keys.click_actions = {76: "left", 82: "right"}  # Default keycodes
        dispatcher.keys.movement_keys = {
            72: ("up",),     # KP_Up
            80: ("down",),   # KP_Down
            75: ("left",),   # KP_Left
            77: ("right",),  # KP_Right
        }
        dispatcher.keys.scroll_keys = {71: ("up",), 79: ("down",)}  # KP_Home, KP_PageDown
        dispatcher.keys.hold_keys = {83: "left"}       # Hold left button
        dispatcher.keys.key_secondary_monitor = 73     # Default from hotkey_config
        dispatcher.keys.key_undo = 98                  # Default from hotkey_config
        return dispatcher


def test_dispatcher_init(dispatcher, config, logger):
    """Test HotkeyDispatcher initialization."""
    assert dispatcher.logger is logger
    assert dispatcher._held_keys == set()


def test_reload_hotkeys(dispatcher):
    """Test reloading hotkeys."""
    movement = MagicMock()
    scroll = MagicMock()
    release_callback = MagicMock()

    dispatcher.reload_hotkeys(movement, scroll, release_callback)

    movement.stop_all.assert_called_once()
    scroll.stop_all.assert_called_once()
    release_callback.assert_called_once()
    dispatcher.keys.reload.assert_called_once()


def test_handle_key_toggle_mode_when_disabled(dispatcher):
    """Test toggling mouse mode on when disabled."""
    state = MagicMock(is_enabled=False)
    state.toggle.return_value = True  # Enable
    mouse = MagicMock()
    movement = MagicMock()
    scroll = MagicMock()
    tray = MagicMock()
    write_status = MagicMock()
    held_buttons = set()
    save_mode = {"active": False}
    load_mode = {"active": False}

    result = dispatcher.handle_key(
        KEY_KP_PLUS,  # Toggle key
        True,  # Pressed
        state,
        mouse,
        movement,
        scroll,
        tray,
        write_status,
        held_buttons,
        save_mode,
        load_mode,
        MagicMock(),  # save_position_callback
        MagicMock(),  # load_position_callback
        MagicMock(),  # cycle_monitor_callback
    )

    assert result is True  # Key should be suppressed
    state.toggle.assert_called_once()
    tray.update.assert_called_once_with(True)
    write_status.assert_called_once_with(True)


def test_handle_key_toggle_mode_when_enabled(dispatcher):
    """Test toggling mouse mode off when enabled."""
    state = MagicMock(is_enabled=True)
    state.toggle.return_value = False  # Disable
    mouse = MagicMock()
    movement = MagicMock()
    scroll = MagicMock()
    tray = MagicMock()
    write_status = MagicMock()
    held_buttons = {"left"}
    save_mode = {"active": False}
    load_mode = {"active": False}

    result = dispatcher.handle_key(
        KEY_KP_PLUS,
        True,
        state,
        mouse,
        movement,
        scroll,
        tray,
        write_status,
        held_buttons,
        save_mode,
        load_mode,
        MagicMock(),
        MagicMock(),
        MagicMock(),
    )

    assert result is True
    movement.stop_all.assert_called_once()
    scroll.stop_all.assert_called_once()
    assert held_buttons == set()
    mouse.release.assert_called_once_with("left")


def test_handle_key_alt_modifier(dispatcher):
    """Test Alt modifier key tracking."""
    state = MagicMock(is_enabled=False)
    mouse = MagicMock()

    # Press Alt
    result = dispatcher.handle_key(
        KEY_LEFTALT,
        True,
        state,
        mouse,
        MagicMock(),
        MagicMock(),
        MagicMock(),
        MagicMock(),
        set(),
        {},
        {},
        MagicMock(),
        MagicMock(),
        MagicMock(),
    )

    assert result is False  # Don't suppress modifier keys
    assert KEY_LEFTALT in dispatcher._held_keys

    # Release Alt
    result = dispatcher.handle_key(
        KEY_LEFTALT,
        False,
        state,
        mouse,
        MagicMock(),
        MagicMock(),
        MagicMock(),
        MagicMock(),
        set(),
        {},
        {},
        MagicMock(),
        MagicMock(),
        MagicMock(),
    )

    assert result is False
    assert KEY_LEFTALT not in dispatcher._held_keys


def test_handle_key_ignores_non_toggle_when_disabled(dispatcher):
    """Test that non-toggle keys are ignored when disabled."""
    state = MagicMock(is_enabled=False)
    mouse = MagicMock()

    # Try to move
    result = dispatcher.handle_key(
        KEY_UP,
        True,
        state,
        mouse,
        MagicMock(),
        MagicMock(),
        MagicMock(),
        MagicMock(),
        set(),
        {},
        {},
        MagicMock(),
        MagicMock(),
        MagicMock(),
    )

    assert result is False  # Key not suppressed, passed through


def test_handle_key_movement(dispatcher):
    """Test movement key handling."""
    state = MagicMock(is_enabled=True)
    mouse = MagicMock()
    movement = MagicMock()

    # Start moving up (using keycode 72)
    result = dispatcher.handle_key(
        72,  # KEY_UP
        True,
        state,
        mouse,
        movement,
        MagicMock(),
        MagicMock(),
        MagicMock(),
        set(),
        {},
        {},
        MagicMock(),
        MagicMock(),
        MagicMock(),
    )

    assert result is True  # Key suppressed
    movement.start_direction.assert_called_once_with("up")

    # Stop moving up
    movement.reset_mock()
    result = dispatcher.handle_key(
        72,  # KEY_UP
        False,
        state,
        mouse,
        movement,
        MagicMock(),
        MagicMock(),
        MagicMock(),
        set(),
        {},
        {},
        MagicMock(),
        MagicMock(),
        MagicMock(),
    )

    assert result is True
    movement.stop_direction.assert_called_once_with("up")


def test_handle_key_click(dispatcher):
    """Test click key handling."""
    state = MagicMock(is_enabled=True)
    mouse = MagicMock()

    result = dispatcher.handle_key(
        76,  # Click left key (from click_actions)
        True,
        state,
        mouse,
        MagicMock(),
        MagicMock(),
        MagicMock(),
        MagicMock(),
        set(),
        {"active": False},
        {"active": False},
        MagicMock(),
        MagicMock(),
        MagicMock(),
    )

    assert result is True
    mouse.click.assert_called_once_with("left")


def test_handle_key_scroll(dispatcher):
    """Test scroll key handling."""
    state = MagicMock(is_enabled=True)
    mouse = MagicMock()
    scroll = MagicMock()

    # Start scrolling up (keycode 71 from scroll_keys)
    result = dispatcher.handle_key(
        71,  # Scroll up key
        True,
        state,
        mouse,
        MagicMock(),
        scroll,
        MagicMock(),
        MagicMock(),
        set(),
        {},
        {},
        MagicMock(),
        MagicMock(),
        MagicMock(),
    )

    assert result is True
    scroll.start_direction.assert_called_once_with("up")


def test_handle_key_hold_button(dispatcher):
    """Test hold key for dragging."""
    state = MagicMock(is_enabled=True)
    mouse = MagicMock()
    held_buttons = set()

    # Press and hold left button (keycode 83 from hold_keys)
    result = dispatcher.handle_key(
        83,  # Hold left key
        True,
        state,
        mouse,
        MagicMock(),
        MagicMock(),
        MagicMock(),
        MagicMock(),
        held_buttons,
        {},
        {},
        MagicMock(),
        MagicMock(),
        MagicMock(),
    )

    assert result is True
    mouse.press.assert_called_once_with("left")
    assert "left" in held_buttons

    # Release hold (toggle off)
    mouse.reset_mock()
    result = dispatcher.handle_key(
        83,
        True,
        state,
        mouse,
        MagicMock(),
        MagicMock(),
        MagicMock(),
        MagicMock(),
        held_buttons,
        {},
        {},
        MagicMock(),
        MagicMock(),
        MagicMock(),
    )

    assert result is True
    mouse.release.assert_called_once_with("left")
    assert "left" not in held_buttons


def test_handle_key_save_mode(dispatcher):
    """Test save mode activation."""
    state = MagicMock(is_enabled=True)
    mouse = MagicMock()
    save_mode = {"active": False}
    load_mode = {"active": False}

    result = dispatcher.handle_key(
        55,  # Save mode key (default from hotkey_config)
        True,
        state,
        mouse,
        MagicMock(),
        MagicMock(),
        MagicMock(),
        MagicMock(),
        set(),
        save_mode,
        load_mode,
        MagicMock(),
        MagicMock(),
        MagicMock(),
    )

    assert result is True
    assert save_mode["active"] is True
    assert load_mode["active"] is False  # Mutual exclusion


def test_handle_key_slot_save(dispatcher):
    """Test saving position to slot."""
    state = MagicMock(is_enabled=True)
    mouse = MagicMock()
    save_callback = MagicMock()
    save_mode = {"active": True}
    load_mode = {"active": False}

    result = dispatcher.handle_key(
        75,  # Slot 1 key (from dispatcher.keys.slot_keys)
        True,
        state,
        mouse,
        MagicMock(),
        MagicMock(),
        MagicMock(),
        MagicMock(),
        set(),
        save_mode,
        load_mode,
        save_callback,
        MagicMock(),
        MagicMock(),
    )

    assert result is True
    save_callback.assert_called_once_with(1)
    assert save_mode["active"] is False  # Deactivate after save


def test_handle_key_slot_load(dispatcher):
    """Test loading position from slot."""
    state = MagicMock(is_enabled=True)
    mouse = MagicMock()
    load_callback = MagicMock()
    save_mode = {"active": False}
    load_mode = {"active": True}

    result = dispatcher.handle_key(
        76,  # Slot 2 key
        True,
        state,
        mouse,
        MagicMock(),
        MagicMock(),
        MagicMock(),
        MagicMock(),
        set(),
        save_mode,
        load_mode,
        MagicMock(),
        load_callback,
        MagicMock(),
    )

    assert result is True
    load_callback.assert_called_once_with(2)
    assert load_mode["active"] is False


def test_handle_key_undo(dispatcher):
    """Test undo key."""
    state = MagicMock(is_enabled=True)
    mouse = MagicMock()
    movement = MagicMock()

    result = dispatcher.handle_key(
        98,  # Undo key (default from hotkey_config)
        True,
        state,
        mouse,
        movement,
        MagicMock(),
        MagicMock(),
        MagicMock(),
        set(),
        {},
        {},
        MagicMock(),
        MagicMock(),
        MagicMock(),
    )

    assert result is True
    movement.undo.assert_called_once()


def test_handle_key_cycle_monitor_with_alt(dispatcher):
    """Test cycling monitor with Alt+secondary_monitor key."""
    state = MagicMock(is_enabled=True)
    mouse = MagicMock()
    cycle_callback = MagicMock()

    # Press Alt first
    dispatcher.handle_key(
        KEY_LEFTALT,
        True,
        state,
        mouse,
        MagicMock(),
        MagicMock(),
        MagicMock(),
        MagicMock(),
        set(),
        {},
        {},
        MagicMock(),
        MagicMock(),
        MagicMock(),
    )

    # Now press secondary_monitor with Alt held (keycode 73)
    result = dispatcher.handle_key(
        73,  # secondary_monitor key (default from hotkey_config)
        True,
        state,
        mouse,
        MagicMock(),
        MagicMock(),
        MagicMock(),
        MagicMock(),
        set(),
        {},
        {},
        MagicMock(),
        MagicMock(),
        cycle_callback,
    )

    assert result is True
    cycle_callback.assert_called_once()
