"""X11 helper functions for keyboard handling."""

from pynput.keyboard import Key, KeyCode

# Numpad keycode mapping (KeyCode.vk values for numpad keys)
NUMPAD_KEYS = {
    # NumLock OFF keycodes (navigation keys)
    65438: "kp_0",  # KP_Insert
    65436: "kp_1",  # KP_End
    65433: "kp_2",  # KP_Down
    65435: "kp_3",  # KP_Page_Down
    65430: "kp_4",  # KP_Left
    65437: "kp_5",  # KP_Begin
    65432: "kp_6",  # KP_Right
    65429: "kp_7",  # KP_Home
    65431: "kp_8",  # KP_Up
    65434: "kp_9",  # KP_Page_Up
    65439: "kp_decimal",  # KP_Delete
    65421: "kp_enter",  # KP_Enter
    65451: "kp_add",  # KP_Add (+)
    65453: "kp_subtract",  # KP_Subtract (-)
    65450: "kp_multiply",  # KP_Multiply (*)
    65455: "kp_divide",  # KP_Divide (/)
}


def identify_key(key: Key | KeyCode) -> str | None:
    """Identify key name from Key or KeyCode.

    Args:
        key: Key object

    Returns:
        Key name string or None
    """
    if isinstance(key, Key):
        return key.name

    if isinstance(key, KeyCode) and key.vk is not None:
        return NUMPAD_KEYS.get(key.vk)

    return None


def get_active_modifiers(pressed_keys: set[Key | KeyCode]) -> list[str]:
    """Get currently pressed modifier keys.

    Args:
        pressed_keys: Set of currently pressed keys

    Returns:
        List of modifier names
    """
    modifiers = []
    for key in pressed_keys:
        if isinstance(key, Key):
            if key in (Key.ctrl_l, Key.ctrl_r, Key.ctrl):
                if "ctrl" not in modifiers:
                    modifiers.append("ctrl")
            elif key in (Key.shift_l, Key.shift_r, Key.shift):
                if "shift" not in modifiers:
                    modifiers.append("shift")
            elif key in (Key.alt_l, Key.alt_r, Key.alt, Key.alt_gr):
                if "alt" not in modifiers:
                    modifiers.append("alt")
    return modifiers
