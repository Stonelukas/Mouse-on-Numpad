"""Configuration management with JSON persistence and XDG compliance."""

import copy
import json
import os
import shutil
from pathlib import Path
from typing import Any

from .config_defaults import DEFAULT_CONFIG


class ConfigManager:
    """Manage application configuration with JSON persistence (XDG-compliant)."""

    def __init__(self, config_dir: Path | None = None) -> None:
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
                self._config = self._merge_defaults(self._config, DEFAULT_CONFIG)
            except (json.JSONDecodeError, OSError):
                # Corrupted file, use defaults
                self._config = copy.deepcopy(DEFAULT_CONFIG)
                self._save()
        else:
            self._config = copy.deepcopy(DEFAULT_CONFIG)
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
        """Get config value by dot-notation key (e.g., 'movement.base_speed')."""
        keys = key.split(".")
        value: Any = self._config
        for k in keys:
            if isinstance(value, dict) and k in value:
                value = value[k]
            else:
                return default
        return value

    def set(self, key: str, value: Any) -> None:
        """Set config value by dot-notation key and persist to disk."""
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
        self._config = copy.deepcopy(DEFAULT_CONFIG)
        self._save()

    # Profile management — delegated to ProfileManager mixin

    @property
    def profiles_dir(self) -> Path:
        """Return the profiles directory path."""
        return self._config_dir / "profiles"

    def list_profiles(self) -> list[str]:
        """List available profile names."""
        return _list_profiles(self.profiles_dir)

    def save_profile(self, name: str) -> None:
        """Save current configuration as a named profile."""
        _save_profile(self.profiles_dir, name, self._config)

    def load_profile(self, name: str) -> bool:
        """Load a named profile as current configuration."""
        loaded = _load_profile(self.profiles_dir, name)
        if loaded is None:
            return False
        self._config = self._merge_defaults(loaded, DEFAULT_CONFIG)
        self._save()
        return True

    def delete_profile(self, name: str) -> bool:
        """Delete a named profile."""
        return _delete_profile(self.profiles_dir, name)


def _list_profiles(profiles_dir: Path) -> list[str]:
    """List available profile names (without .json extension)."""
    if not profiles_dir.exists():
        return []
    return sorted(f.stem for f in profiles_dir.glob("*.json"))


def _save_profile(profiles_dir: Path, name: str, config: dict[str, Any]) -> None:
    """Save config dict as a named profile."""
    safe_name = "".join(c for c in name if c.isalnum() or c in "-_") or "profile"
    profiles_dir.mkdir(parents=True, exist_ok=True)
    os.chmod(profiles_dir, 0o700)
    profile_path = profiles_dir / f"{safe_name}.json"
    with open(profile_path, "w", encoding="utf-8") as f:
        json.dump(config, f, indent=2)
    os.chmod(profile_path, 0o600)


def _load_profile(profiles_dir: Path, name: str) -> dict[str, Any] | None:
    """Load a named profile. Returns config dict or None."""
    profile_path = profiles_dir / f"{name}.json"
    if not profile_path.exists():
        return None
    try:
        with open(profile_path, encoding="utf-8") as f:
            return json.load(f)
    except (json.JSONDecodeError, OSError):
        return None


def _delete_profile(profiles_dir: Path, name: str) -> bool:
    """Delete a named profile. Returns True if deleted."""
    profile_path = profiles_dir / f"{name}.json"
    if not profile_path.exists():
        return False
    try:
        profile_path.unlink()
        return True
    except OSError:
        return False
