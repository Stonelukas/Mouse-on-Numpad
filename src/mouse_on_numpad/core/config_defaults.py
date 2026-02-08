"""Default configuration schema and validation for mouse-on-numpad."""

from typing import Any

DEFAULT_CONFIG: dict[str, Any] = {
    "movement": {
        "base_speed": 5,  # Lower default for smoother control
        "acceleration_rate": 1.08,  # Gentler acceleration
        "max_speed": 40,  # Lower cap for precision
        "move_delay": 20,  # Matches Windows MoveDelay=20ms
        "curve": "exponential",  # linear, exponential, s-curve
    },
    "audio": {
        "enabled": True,
        "volume": 50,
    },
    "status_bar": {
        "enabled": True,
        "position": "top-right",  # top-left, top-right, bottom-left, bottom-right
        "size": "medium",  # small, medium, large
        "opacity": 80,  # 0-100
        "auto_hide": True,  # Hide when mouse mode disabled
        "theme": "default",  # default, dark, light, high-contrast
    },
    "positions": {
        "per_monitor": True,  # Store positions per monitor config
    },
    "scroll": {
        "step": 3,  # Base scroll amount per tick
        "acceleration_rate": 1.1,
        "max_speed": 10,
        "delay": 30,  # ms between scroll ticks
    },
    "undo": {
        "max_levels": 10,  # Max undo history entries
    },
    "hotkeys": {
        # Evdev keycodes for numpad keys
        "toggle_mode": 78,  # KEY_KPPLUS
        "save_mode": 55,  # KEY_KPASTERISK
        "load_mode": 74,  # KEY_KPMINUS
        "undo": 98,  # KEY_KPSLASH
        "left_click": 76,  # KEY_KP5
        "right_click": 82,  # KEY_KP0
        "middle_click": 96,  # KEY_KPENTER
        "hold_left": 83,  # KEY_KPDOT
        "move_up": 72,  # KEY_KP8
        "move_down": 80,  # KEY_KP2
        "move_left": 75,  # KEY_KP4
        "move_right": 77,  # KEY_KP6
        "scroll_up": 71,  # KEY_KP7
        "scroll_down": 79,  # KEY_KP1
        "scroll_right": 73,  # KEY_KP9
        "scroll_left": 81,  # KEY_KP3
        # Position memory slots (in save/load mode)
        "slot_1": 75,  # KEY_KP4
        "slot_2": 76,  # KEY_KP5
        "slot_3": 77,  # KEY_KP6
        "slot_4": 72,  # KEY_KP8
        "slot_5": 82,  # KEY_KP0
        # Modifier combos (Alt + key)
        "secondary_monitor": 73,  # KEY_KP9 (with Alt held)
    },
}
