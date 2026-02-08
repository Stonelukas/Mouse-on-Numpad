"""Hotkey mapping and dispatch logic."""

from typing import TYPE_CHECKING

from ..core import ErrorLogger
from .hotkey_config import HotkeyConfig

if TYPE_CHECKING:
    from ..core import ConfigManager
    from ..input.movement_controller import MovementController
    from ..input.scroll_controller import ScrollController
    from .keyboard_capture import KEY_LEFTALT, KEY_RIGHTALT


class HotkeyDispatcher:
    """Handles hotkey mappings and key event dispatching."""

    def __init__(self, config: "ConfigManager", logger: ErrorLogger) -> None:
        self.logger = logger
        self._held_keys: set[int] = set()
        self.keys = HotkeyConfig(config)

    def reload_hotkeys(
        self, movement, scroll, release_all_held_buttons_callback
    ) -> None:
        """Reload hotkeys from config (called after settings change).

        Args:
            movement: MovementController instance
            scroll: ScrollController instance
            release_all_held_buttons_callback: Callback to release held mouse buttons
        """
        # Stop active movement/scroll to prevent orphaned state
        movement.stop_all()
        scroll.stop_all()
        release_all_held_buttons_callback()

        # Reload config and update key mappings
        self.keys.reload()
        self.logger.info("Hotkeys reloaded from config")

    def _is_alt_held(self) -> bool:
        """Check if Alt modifier is currently held."""
        from .keyboard_capture import KEY_LEFTALT, KEY_RIGHTALT

        return KEY_LEFTALT in self._held_keys or KEY_RIGHTALT in self._held_keys

    def handle_key(
        self,
        keycode: int,
        pressed: bool,
        state,
        mouse,
        movement,
        scroll,
        tray,
        write_status_callback,
        held_buttons: set[str],
        save_mode: dict,
        load_mode: dict,
        save_position_callback,
        load_position_callback,
        cycle_monitor_callback,
    ) -> bool:
        """Handle a key event. Returns True if key should be suppressed.

        Args:
            keycode: evdev keycode
            pressed: True if pressed, False if released
            state: StateManager instance
            mouse: Mouse controller instance
            movement: MovementController instance
            scroll: ScrollController instance
            tray: TrayIcon instance
            write_status_callback: Callback to write status file
            held_buttons: Set of currently held mouse buttons
            save_mode: Dict with 'active' key for save mode state
            load_mode: Dict with 'active' key for load mode state
            save_position_callback: Callback(slot) to save position
            load_position_callback: Callback(slot) to load position
            cycle_monitor_callback: Callback to cycle monitor
        """
        from .keyboard_capture import KEY_LEFTALT, KEY_RIGHTALT

        # Track modifier keys (Alt)
        if keycode in (KEY_LEFTALT, KEY_RIGHTALT):
            if pressed:
                self._held_keys.add(keycode)
            else:
                self._held_keys.discard(keycode)
            return False  # Don't suppress modifier keys

        # Toggle mouse mode with configured key (default: Numpad+)
        if keycode == self.keys.key_toggle and pressed:
            enabled = state.toggle()
            if not enabled:
                # Stop all movement, scroll, and release held buttons when disabling
                movement.stop_all()
                scroll.stop_all()
                self._release_all_held_buttons(mouse, held_buttons)
            # Update tray icon and status file
            tray.update(enabled)
            write_status_callback(enabled)
            self.logger.info("Mouse mode: %s", "enabled" if enabled else "disabled")
            print(f"Mouse mode: {'ENABLED' if enabled else 'DISABLED'}")
            return True  # Suppress this key

        # Only process movement/click keys when enabled
        if not state.is_enabled:
            return False  # Let key pass through

        # Handle position memory modes
        if keycode == self.keys.key_save_mode and pressed:
            save_mode["active"] = not save_mode["active"]
            load_mode["active"] = False  # Mutual exclusion
            print(f"Save mode: {'ON' if save_mode['active'] else 'OFF'}")
            return True

        if keycode == self.keys.key_load_mode and pressed:
            load_mode["active"] = not load_mode["active"]
            save_mode["active"] = False  # Mutual exclusion
            print(f"Load mode: {'ON' if load_mode['active'] else 'OFF'}")
            return True

        # Handle slot keys when in save/load mode
        if keycode in self.keys.slot_keys and pressed:
            if save_mode["active"]:
                save_position_callback(self.keys.slot_keys[keycode])
                save_mode["active"] = False
                return True
            elif load_mode["active"]:
                load_position_callback(self.keys.slot_keys[keycode])
                load_mode["active"] = False
                return True

        # Handle click actions
        if keycode in self.keys.click_actions:
            if pressed:
                button = self.keys.click_actions[keycode]
                mouse.click(button)
            return True  # Suppress click keys

        # Handle movement keys
        if keycode in self.keys.movement_keys:
            directions = self.keys.movement_keys[keycode]
            if pressed:
                # Start moving in direction(s)
                for direction in directions:
                    movement.start_direction(direction)
            else:
                # Stop moving in direction(s)
                for direction in directions:
                    movement.stop_direction(direction)
            return True  # Suppress movement keys

        # Handle Alt+secondary_monitor to cycle monitors (before scroll check)
        if keycode == self.keys.key_secondary_monitor and pressed and self._is_alt_held():
            cycle_monitor_callback()
            return True  # Suppress this key

        # Handle scroll keys (only if Alt not held for secondary_monitor key)
        if keycode in self.keys.scroll_keys:
            # Skip if this is secondary_monitor key with Alt (handled above)
            if keycode == self.keys.key_secondary_monitor and self._is_alt_held():
                return True
            directions = self.keys.scroll_keys[keycode]
            if pressed:
                for direction in directions:
                    scroll.start_direction(direction)
            else:
                for direction in directions:
                    scroll.stop_direction(direction)
            return True  # Suppress scroll keys

        # Handle hold keys (toggle mouse button hold for drag operations)
        if keycode in self.keys.hold_keys and pressed:
            button = self.keys.hold_keys[keycode]
            if button in held_buttons:
                # Release the button
                mouse.release(button)
                held_buttons.discard(button)
            else:
                # Press and hold the button
                mouse.press(button)
                held_buttons.add(button)
            return True  # Suppress hold keys

        # Handle undo with configured key (default: NumpadSlash)
        if keycode == self.keys.key_undo and pressed:
            movement.undo()
            return True  # Suppress undo key

        return False  # Don't suppress other keys

    def _release_all_held_buttons(self, mouse, held_buttons: set[str]) -> None:
        """Release all held mouse buttons."""
        for button in list(held_buttons):
            mouse.release(button)
        held_buttons.clear()
