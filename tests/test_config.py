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
        assert config.get("movement.base_speed") == 5

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
        assert config.get("movement.acceleration_rate") == 1.08
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
        assert config.get("movement.base_speed") == 5

    def test_get_all_returns_copy(self, temp_config_dir: Path):
        """get_all returns a copy, not the original."""
        config = ConfigManager(config_dir=temp_config_dir)
        all_config = config.get_all()
        all_config["movement"]["base_speed"] = 999

        # Original unchanged
        assert config.get("movement.base_speed") == 5

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
        assert config.get("movement.base_speed") == 5

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
        assert config.get("movement.base_speed") == 5

        # After reload
        config.reload()
        assert config.get("movement.base_speed") == 42


class TestConfigProfiles:
    """Test profile management functionality."""

    def test_list_profiles_empty(self, temp_config_dir: Path):
        """Returns empty list when no profiles exist."""
        config = ConfigManager(config_dir=temp_config_dir)
        assert config.list_profiles() == []

    def test_save_and_list_profile(self, temp_config_dir: Path):
        """Can save a profile and list it."""
        config = ConfigManager(config_dir=temp_config_dir)
        config.save_profile("gaming")

        profiles = config.list_profiles()
        assert "gaming" in profiles

    def test_save_profile_creates_directory(self, temp_config_dir: Path):
        """Profiles directory created on first save."""
        config = ConfigManager(config_dir=temp_config_dir)
        assert not config.profiles_dir.exists()

        config.save_profile("test")
        assert config.profiles_dir.exists()

    def test_save_profile_sanitizes_name(self, temp_config_dir: Path):
        """Profile names are sanitized for filesystem safety."""
        config = ConfigManager(config_dir=temp_config_dir)
        config.save_profile("my profile!@#$%")

        profiles = config.list_profiles()
        assert "myprofile" in profiles

    def test_load_profile(self, temp_config_dir: Path):
        """Load profile restores saved settings."""
        config = ConfigManager(config_dir=temp_config_dir)

        # Modify and save
        config.set("movement.base_speed", 50)
        config.save_profile("fast")

        # Change again
        config.set("movement.base_speed", 5)
        assert config.get("movement.base_speed") == 5

        # Load profile
        result = config.load_profile("fast")
        assert result is True
        assert config.get("movement.base_speed") == 50

    def test_load_nonexistent_profile(self, temp_config_dir: Path):
        """Returns False for non-existent profile."""
        config = ConfigManager(config_dir=temp_config_dir)
        result = config.load_profile("nonexistent")
        assert result is False

    def test_delete_profile(self, temp_config_dir: Path):
        """Can delete an existing profile."""
        config = ConfigManager(config_dir=temp_config_dir)
        config.save_profile("toDelete")
        assert "toDelete" in config.list_profiles()

        result = config.delete_profile("toDelete")
        assert result is True
        assert "toDelete" not in config.list_profiles()

    def test_delete_nonexistent_profile(self, temp_config_dir: Path):
        """Returns False when deleting non-existent profile."""
        config = ConfigManager(config_dir=temp_config_dir)
        result = config.delete_profile("nonexistent")
        assert result is False

    def test_profile_includes_all_settings(self, temp_config_dir: Path):
        """Profile includes all configuration sections."""
        config = ConfigManager(config_dir=temp_config_dir)

        # Modify multiple settings
        config.set("movement.base_speed", 30)
        config.set("audio.volume", 75)
        config.set("status_bar.theme", "dark")
        config.save_profile("complete")

        # Reset and load
        config.reset()
        config.load_profile("complete")

        assert config.get("movement.base_speed") == 30
        assert config.get("audio.volume") == 75
        assert config.get("status_bar.theme") == "dark"

    def test_multiple_profiles(self, temp_config_dir: Path):
        """Can manage multiple profiles."""
        config = ConfigManager(config_dir=temp_config_dir)

        config.set("movement.base_speed", 10)
        config.save_profile("slow")

        config.set("movement.base_speed", 50)
        config.save_profile("fast")

        profiles = config.list_profiles()
        assert "slow" in profiles
        assert "fast" in profiles

        # Load slow
        config.load_profile("slow")
        assert config.get("movement.base_speed") == 10

        # Load fast
        config.load_profile("fast")
        assert config.get("movement.base_speed") == 50
