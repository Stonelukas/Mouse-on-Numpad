"""Hotkey configuration loader."""

from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from ..core import ConfigManager


class HotkeyConfig:
    """Loads and manages hotkey mappings from config."""

    def __init__(self, config: "ConfigManager") -> None:
        self.config = config
        self._load()

    def _load(self) -> None:
        """Load hotkey mappings from config."""
        # Mode toggle keys
        self.key_toggle = self.config.get("hotkeys.toggle_mode", 78)
        self.key_save_mode = self.config.get("hotkeys.save_mode", 55)
        self.key_load_mode = self.config.get("hotkeys.load_mode", 74)
        self.key_undo = self.config.get("hotkeys.undo", 98)

        # Click actions - build reverse map from keycode to action
        self.click_actions: dict[int, str] = {
            self.config.get("hotkeys.left_click", 76): "left",
            self.config.get("hotkeys.right_click", 82): "right",
            self.config.get("hotkeys.middle_click", 96): "middle",
        }

        # Movement keys - map keycode to direction tuple
        self.movement_keys: dict[int, tuple[str, ...]] = {
            self.config.get("hotkeys.move_up", 72): ("up",),
            self.config.get("hotkeys.move_down", 80): ("down",),
            self.config.get("hotkeys.move_left", 75): ("left",),
            self.config.get("hotkeys.move_right", 77): ("right",),
        }

        # Scroll keys
        self.scroll_keys: dict[int, tuple[str, ...]] = {
            self.config.get("hotkeys.scroll_up", 71): ("up",),
            self.config.get("hotkeys.scroll_down", 79): ("down",),
            self.config.get("hotkeys.scroll_right", 73): ("right",),
            self.config.get("hotkeys.scroll_left", 81): ("left",),
        }

        # Hold keys
        self.hold_keys: dict[int, str] = {
            self.config.get("hotkeys.hold_left", 83): "left",
        }

        # Position slots
        self.slot_keys: dict[int, int] = {
            self.config.get("hotkeys.slot_1", 75): 1,
            self.config.get("hotkeys.slot_2", 76): 2,
            self.config.get("hotkeys.slot_3", 77): 3,
            self.config.get("hotkeys.slot_4", 72): 4,
            self.config.get("hotkeys.slot_5", 82): 5,
        }

        # Modifier combo keys (require Alt held)
        self.key_secondary_monitor = self.config.get("hotkeys.secondary_monitor", 73)

    def reload(self) -> None:
        """Reload hotkey mappings from config."""
        self.config.reload()
        self._load()
