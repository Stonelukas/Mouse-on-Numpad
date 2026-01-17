"""Tests for ConfigManager."""

import json
import os
import tempfile
from pathlib import Path

import pytest

from mouse_on_numpad.core.config import ConfigManager


@pytest.fixture
def temp_config_dir():
    """Create a temporary config directory for testing."""
    with tempfile.TemporaryDirectory() as tmpdir:
        yield Path(tmpdir)


class TestConfigManager:
    """Test ConfigManager functionality."""

    def test_creates_default_config(self, temp_config_dir: Path):
        """Config file created with defaults on first run."""
        config = ConfigManager(config_dir=temp_config_dir)
        assert config.config_file.exists()
        assert config.get("movement.base_speed") == 10

    def test_loads_existing_config(self, temp_config_dir: Path):
        """Loads values from existing config file."""
        # Create config file manually
        config_file = temp_config_dir / "config.json"
        temp_config_dir.mkdir(parents=True, exist_ok=True)
        with open(config_file, "w") as f:
            json.dump({"movement": {"base_speed": 25}}, f)

        config = ConfigManager(config_dir=temp_config_dir)
        assert config.get("movement.base_speed") == 25

    def test_merges_with_defaults(self, temp_config_dir: Path):
        """New default keys added to existing config."""
        config_file = temp_config_dir / "config.json"
        temp_config_dir.mkdir(parents=True, exist_ok=True)
        with open(config_file, "w") as f:
            json.dump({"movement": {"base_speed": 15}}, f)

        config = ConfigManager(config_dir=temp_config_dir)
        # User value preserved
        assert config.get("movement.base_speed") == 15
        # Default values added
        assert config.get("audio.enabled") is True

    def test_nested_get(self, temp_config_dir: Path):
        """Dot-notation get works for nested keys."""
        config = ConfigManager(config_dir=temp_config_dir)
        assert config.get("movement.acceleration") == 1.5
        assert config.get("audio.volume") == 50

    def test_get_default_for_missing(self, temp_config_dir: Path):
        """Returns default for non-existent keys."""
        config = ConfigManager(config_dir=temp_config_dir)
        assert config.get("nonexistent.key") is None
        assert config.get("nonexistent.key", "fallback") == "fallback"

    def test_set_nested_value(self, temp_config_dir: Path):
        """Set updates nested values and persists."""
        config = ConfigManager(config_dir=temp_config_dir)
        config.set("movement.base_speed", 20)

        # Verify in memory
        assert config.get("movement.base_speed") == 20

        # Verify persisted
        config2 = ConfigManager(config_dir=temp_config_dir)
        assert config2.get("movement.base_speed") == 20

    def test_set_creates_nested_keys(self, temp_config_dir: Path):
        """Set creates intermediate keys if needed."""
        config = ConfigManager(config_dir=temp_config_dir)
        config.set("new.nested.key", "value")
        assert config.get("new.nested.key") == "value"

    def test_creates_backup_on_save(self, temp_config_dir: Path):
        """Backup file created before save."""
        config = ConfigManager(config_dir=temp_config_dir)
        config.set("test", "value1")
        config.set("test", "value2")

        backup_file = config.config_file.with_suffix(".json.bak")
        assert backup_file.exists()

    def test_reset_restores_defaults(self, temp_config_dir: Path):
        """Reset restores default configuration."""
        config = ConfigManager(config_dir=temp_config_dir)
        config.set("movement.base_speed", 99)
        assert config.get("movement.base_speed") == 99

        config.reset()
        assert config.get("movement.base_speed") == 10

    def test_get_all_returns_copy(self, temp_config_dir: Path):
        """get_all returns a copy, not the original."""
        config = ConfigManager(config_dir=temp_config_dir)
        all_config = config.get_all()
        all_config["movement"]["base_speed"] = 999

        # Original unchanged
        assert config.get("movement.base_speed") == 10

    def test_secure_permissions(self, temp_config_dir: Path):
        """Config file has secure permissions (0600)."""
        config = ConfigManager(config_dir=temp_config_dir)
        config.set("test", "value")

        file_stat = os.stat(config.config_file)
        file_mode = file_stat.st_mode & 0o777
        assert file_mode == 0o600

    def test_handles_corrupted_json(self, temp_config_dir: Path):
        """Handles corrupted JSON by using defaults."""
        config_file = temp_config_dir / "config.json"
        temp_config_dir.mkdir(parents=True, exist_ok=True)
        with open(config_file, "w") as f:
            f.write("not valid json {{{")

        config = ConfigManager(config_dir=temp_config_dir)
        # Falls back to defaults
        assert config.get("movement.base_speed") == 10

    def test_reload_from_disk(self, temp_config_dir: Path):
        """Reload picks up external changes."""
        config = ConfigManager(config_dir=temp_config_dir)

        # Modify file externally
        with open(config.config_file, "r") as f:
            data = json.load(f)
        data["movement"]["base_speed"] = 42
        with open(config.config_file, "w") as f:
            json.dump(data, f)

        # Before reload
        assert config.get("movement.base_speed") == 10

        # After reload
        config.reload()
        assert config.get("movement.base_speed") == 42
