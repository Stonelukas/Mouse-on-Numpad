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
            "position": "top-right",
            "auto_hide": True,  # Hide when mouse mode disabled
        },
        "positions": {
            "per_monitor": True,  # Store positions per monitor config
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

    def reload(self) -> None:
        """Reload configuration from disk."""
        self._load()
