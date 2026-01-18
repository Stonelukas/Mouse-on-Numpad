"""Configuration management with JSON persistence and XDG compliance."""

import copy
import json
import os
import shutil
from pathlib import Path
from typing import Any


class ConfigManager:
    """Manage application configuration with JSON persistence.

    Features:
    - XDG Base Directory compliance (~/.config/mouse-on-numpad/)
    - Automatic backup before write
    - Nested key access (e.g., "movement.base_speed")
    - Default values with schema validation
    """

    # Default configuration schema
    DEFAULT_CONFIG: dict[str, Any] = {
        "movement": {
            "base_speed": 5,   # Lower default for smoother control
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
            "size": "medium",         # small, medium, large
            "opacity": 80,            # 0-100
            "auto_hide": True,        # Hide when mouse mode disabled
            "theme": "default",       # default, dark, light, high-contrast
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
            "toggle_mode": 78,      # KEY_KPPLUS
            "save_mode": 55,        # KEY_KPASTERISK
            "load_mode": 74,        # KEY_KPMINUS
            "undo": 98,             # KEY_KPSLASH
            "left_click": 76,       # KEY_KP5
            "right_click": 82,      # KEY_KP0
            "middle_click": 96,     # KEY_KPENTER
            "hold_left": 83,        # KEY_KPDOT
            "move_up": 72,          # KEY_KP8
            "move_down": 80,        # KEY_KP2
            "move_left": 75,        # KEY_KP4
            "move_right": 77,       # KEY_KP6
            "scroll_up": 71,        # KEY_KP7
            "scroll_down": 79,      # KEY_KP1
            "scroll_right": 73,     # KEY_KP9
            "scroll_left": 81,      # KEY_KP3
            # Position memory slots (in save/load mode)
            "slot_1": 75,           # KEY_KP4
            "slot_2": 76,           # KEY_KP5
            "slot_3": 77,           # KEY_KP6
            "slot_4": 72,           # KEY_KP8
            "slot_5": 82,           # KEY_KP0
            # Modifier combos (Alt + key)
            "secondary_monitor": 73,  # KEY_KP9 (with Alt held)
        },
    }

    def __init__(self, config_dir: Path | None = None) -> None:
        """Initialize ConfigManager.

        Args:
            config_dir: Custom config directory. Defaults to XDG_CONFIG_HOME.
        """
        if config_dir is None:
            xdg_config = os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config"))
            self._config_dir = Path(xdg_config) / "mouse-on-numpad"
        else:
            self._config_dir = config_dir

        self._config_file = self._config_dir / "config.json"
        self._config: dict[str, Any] = {}
        self._load()

    @property
    def config_dir(self) -> Path:
        """Return the configuration directory path."""
        return self._config_dir

    @property
    def config_file(self) -> Path:
        """Return the configuration file path."""
        return self._config_file

    def _load(self) -> None:
        """Load configuration from disk or create defaults."""
        if self._config_file.exists():
            try:
                with open(self._config_file, encoding="utf-8") as f:
                    self._config = json.load(f)
                # Merge with defaults to handle new keys
                self._config = self._merge_defaults(self._config, self.DEFAULT_CONFIG)
            except (json.JSONDecodeError, OSError):
                # Corrupted file, use defaults
                self._config = copy.deepcopy(self.DEFAULT_CONFIG)
                self._save()
        else:
            self._config = copy.deepcopy(self.DEFAULT_CONFIG)
            self._save()

    def _merge_defaults(
        self, config: dict[str, Any], defaults: dict[str, Any]
    ) -> dict[str, Any]:
        """Deep merge config with defaults, preserving user values."""
        result = defaults.copy()
        for key, value in config.items():
            if key in result and isinstance(result[key], dict) and isinstance(value, dict):
                result[key] = self._merge_defaults(value, result[key])
            else:
                result[key] = value
        return result

    def _save(self) -> None:
        """Save configuration to disk with backup."""
        # Ensure directory exists with secure permissions
        self._config_dir.mkdir(parents=True, exist_ok=True)
        os.chmod(self._config_dir, 0o700)

        # Backup existing config before write
        if self._config_file.exists():
            backup_path = self._config_file.with_suffix(".json.bak")
            shutil.copy2(self._config_file, backup_path)

        # Write new config with secure permissions
        with open(self._config_file, "w", encoding="utf-8") as f:
            json.dump(self._config, f, indent=2)
        os.chmod(self._config_file, 0o600)

    def reload(self) -> None:
        """Reload config from file (picks up external changes)."""
        self._load()

    def get(self, key: str, default: Any = None) -> Any:
        """Get config value by dot-notation key.

        Args:
            key: Dot-notation key (e.g., "movement.base_speed")
            default: Default value if key not found

        Returns:
            Config value or default
        """
        keys = key.split(".")
        value: Any = self._config
        for k in keys:
            if isinstance(value, dict) and k in value:
                value = value[k]
            else:
                return default
        return value

    def set(self, key: str, value: Any) -> None:
        """Set config value by dot-notation key.

        Args:
            key: Dot-notation key (e.g., "movement.base_speed")
            value: Value to set
        """
        keys = key.split(".")
        config = self._config
        for k in keys[:-1]:
            if k not in config:
                config[k] = {}
            config = config[k]
        config[keys[-1]] = value
        self._save()

    def get_all(self) -> dict[str, Any]:
        """Return a deep copy of the entire configuration."""
        return copy.deepcopy(self._config)

    def reset(self) -> None:
        """Reset configuration to defaults."""
        self._config = copy.deepcopy(self.DEFAULT_CONFIG)
        self._save()
