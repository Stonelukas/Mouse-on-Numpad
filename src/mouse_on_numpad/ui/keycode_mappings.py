"""Evdev keycode mappings and translations for hotkey configuration.

Provides bidirectional mapping between evdev keycodes and:
- Human-readable key names for GUI display
- GDK keyvals for GTK key capture
"""

import gi  # type: ignore[import-untyped]

gi.require_version("Gdk", "4.0")
from gi.repository import Gdk  # type: ignore[import-untyped]

# Evdev keycode to human-readable name mapping
KEYCODE_NAMES: dict[int, str] = {
    # Numpad keys
    71: "Numpad 7", 72: "Numpad 8", 73: "Numpad 9",
    75: "Numpad 4", 76: "Numpad 5", 77: "Numpad 6",
    79: "Numpad 1", 80: "Numpad 2", 81: "Numpad 3",
    82: "Numpad 0", 83: "Numpad .",
    78: "Numpad +", 74: "Numpad -",
    55: "Numpad *", 98: "Numpad /",
    96: "Numpad Enter",
    # Function keys
    59: "F1", 60: "F2", 61: "F3", 62: "F4",
    63: "F5", 64: "F6", 65: "F7", 66: "F8",
    67: "F9", 68: "F10", 87: "F11", 88: "F12",
    # Common keys
    1: "Escape", 14: "Backspace", 15: "Tab",
    28: "Enter", 57: "Space",
}

# GDK keyval to evdev keycode mapping (for GTK key capture)
GDK_TO_EVDEV: dict[int, int] = {
    Gdk.KEY_KP_7: 71, Gdk.KEY_KP_8: 72, Gdk.KEY_KP_9: 73,
    Gdk.KEY_KP_4: 75, Gdk.KEY_KP_5: 76, Gdk.KEY_KP_6: 77,
    Gdk.KEY_KP_1: 79, Gdk.KEY_KP_2: 80, Gdk.KEY_KP_3: 81,
    Gdk.KEY_KP_0: 82, Gdk.KEY_KP_Decimal: 83,
    Gdk.KEY_KP_Add: 78, Gdk.KEY_KP_Subtract: 74,
    Gdk.KEY_KP_Multiply: 55, Gdk.KEY_KP_Divide: 98,
    Gdk.KEY_KP_Enter: 96,
    Gdk.KEY_F1: 59, Gdk.KEY_F2: 60, Gdk.KEY_F3: 61, Gdk.KEY_F4: 62,
    Gdk.KEY_F5: 63, Gdk.KEY_F6: 64, Gdk.KEY_F7: 65, Gdk.KEY_F8: 66,
    Gdk.KEY_F9: 67, Gdk.KEY_F10: 68, Gdk.KEY_F11: 87, Gdk.KEY_F12: 88,
    Gdk.KEY_Escape: 1, Gdk.KEY_BackSpace: 14, Gdk.KEY_Tab: 15,
    Gdk.KEY_Return: 28, Gdk.KEY_space: 57,
}

# Hotkey action labels for GUI display
HOTKEY_LABELS: dict[str, str] = {
    "toggle_mode": "Toggle Mouse Mode",
    "save_mode": "Save Position Mode",
    "load_mode": "Load Position Mode",
    "undo": "Undo Movement",
    "left_click": "Left Click",
    "right_click": "Right Click",
    "middle_click": "Middle Click",
    "hold_left": "Hold Left (Drag)",
    "move_up": "Move Up",
    "move_down": "Move Down",
    "move_left": "Move Left",
    "move_right": "Move Right",
    "scroll_up": "Scroll Up",
    "scroll_down": "Scroll Down",
    "scroll_right": "Scroll Right",
    "scroll_left": "Scroll Left",
}

# Slot key labels (separate from regular hotkeys for conflict detection)
SLOT_KEY_LABELS: dict[str, str] = {
    "slot_1": "Position Slot 1",
    "slot_2": "Position Slot 2",
    "slot_3": "Position Slot 3",
    "slot_4": "Position Slot 4",
    "slot_5": "Position Slot 5",
}

# All configurable hotkey names (for conflict detection)
ALL_HOTKEY_NAMES: set[str] = set(HOTKEY_LABELS.keys()) | set(SLOT_KEY_LABELS.keys())


def get_key_name(keycode: int) -> str:
    """Get human-readable name for an evdev keycode."""
    return KEYCODE_NAMES.get(keycode, f"Key {keycode}")


def gdk_keyval_to_evdev(keyval: int) -> int | None:
    """Convert GDK keyval to evdev keycode.

    Args:
        keyval: GDK keyval from key event

    Returns:
        Evdev keycode or None if not supported
    """
    return GDK_TO_EVDEV.get(keyval)
