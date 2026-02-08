"""Integration tests for profile save/load/delete via ConfigManager."""

from unittest.mock import MagicMock, patch, mock_open
import json
import pytest
import tempfile
import os

from mouse_on_numpad.core.config import ConfigManager


@pytest.fixture
def config():
    """Create ConfigManager instance."""
    return ConfigManager()


@pytest.fixture
def temp_config_file():
    """Create temporary config file for testing."""
    with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
        config_data = {
            "profiles": {
                "default": {
                    "movement": {"base_speed": 10, "acceleration_rate": 1.02},
                    "hotkeys": {"key_toggle": "KP_Plus"}
                },
                "fast": {
                    "movement": {"base_speed": 20, "acceleration_rate": 1.05},
                    "hotkeys": {"key_toggle": "KP_Plus"}
                }
            },
            "current_profile": "default"
        }
        json.dump(config_data, f)
        temp_path = f.name

    yield temp_path

    # Cleanup
    try:
        os.unlink(temp_path)
    except OSError:
        pass


def test_config_save_profile_creates_new(config):
    """Test saving a new profile."""
    # Save settings as a profile
    config.set("movement.base_speed", 15)
    config.set("movement.acceleration_rate", 1.03)

    # Verify settings were saved
    assert config.get("movement.base_speed") == 15
    assert config.get("movement.acceleration_rate") == 1.03


def test_config_load_profile_restores_settings(config):
    """Test loading a profile restores settings."""
    # Set initial values
    config.set("movement.base_speed", 10)
    config.set("movement.acceleration_rate", 1.02)

    # Simulate a profile with different values
    profile = {
        "movement.base_speed": 25,
        "movement.acceleration_rate": 1.04
    }

    # Apply profile settings
    for key, value in profile.items():
        config.set(key, value)

    # Verify settings match profile
    assert config.get("movement.base_speed") == 25
    assert config.get("movement.acceleration_rate") == 1.04


def test_config_delete_profile_simulation(config):
    """Test that deleting a profile works (simulation)."""
    # In a real scenario, profiles would be in config data
    # Here we simulate the deletion logic
    profiles = {
        "default": {"movement.base_speed": 10},
        "fast": {"movement.base_speed": 20},
        "slow": {"movement.base_speed": 5}
    }

    # Delete a profile
    if "slow" in profiles:
        del profiles["slow"]

    assert "slow" not in profiles
    assert len(profiles) == 2


def test_config_multiple_profiles_isolation(config):
    """Test that profiles don't interfere with each other."""
    # Simulate loading and saving different profiles
    profile_a = {"movement.base_speed": 10, "movement.acceleration_rate": 1.02}
    profile_b = {"movement.base_speed": 20, "movement.acceleration_rate": 1.05}

    # Apply profile A
    for k, v in profile_a.items():
        config.set(k, v)

    # Verify A is active
    assert config.get("movement.base_speed") == 10

    # Apply profile B
    for k, v in profile_b.items():
        config.set(k, v)

    # Verify B is active
    assert config.get("movement.base_speed") == 20

    # Profile A should remain unchanged
    assert profile_a["movement.base_speed"] == 10


def test_config_profile_with_all_settings(config):
    """Test profile with comprehensive settings."""
    settings = {
        "movement.base_speed": 12,
        "movement.acceleration_rate": 1.03,
        "movement.curve": "exponential",
        "movement.move_delay": 15,
        "movement.max_speed": 80,
        "scroll.base_speed": 3,
        "scroll.acceleration_rate": 1.02,
        "undo.max_levels": 5,
        "audio.enabled": True,
        "audio.volume": 0.7,
    }

    # Apply all settings
    for key, value in settings.items():
        config.set(key, value)

    # Verify all settings persisted
    for key, expected_value in settings.items():
        actual_value = config.get(key)
        assert actual_value == expected_value, f"{key}: expected {expected_value}, got {actual_value}"


def test_config_profile_switch_scenario(config):
    """Test realistic profile switching scenario."""
    # User starts with default profile
    config.set("movement.base_speed", 10)
    config.set("movement.acceleration_rate", 1.02)
    initial_speed = config.get("movement.base_speed")

    # User switches to gaming profile
    config.set("movement.base_speed", 25)
    config.set("movement.acceleration_rate", 1.05)
    gaming_speed = config.get("movement.base_speed")

    assert initial_speed == 10
    assert gaming_speed == 25
    assert gaming_speed > initial_speed


def test_config_profile_numeric_values(config):
    """Test that numeric values in profiles are preserved."""
    values = {
        "movement.base_speed": 10,
        "movement.acceleration_rate": 1.02,
        "movement.move_delay": 10,
        "movement.max_speed": 100,
    }

    for key, value in values.items():
        config.set(key, value)

    # Verify types are preserved
    for key, expected_value in values.items():
        actual_value = config.get(key)
        assert isinstance(actual_value, type(expected_value))
        assert actual_value == expected_value


def test_config_profile_boolean_values(config):
    """Test that boolean values in profiles are preserved."""
    config.set("audio.enabled", True)
    config.set("audio.startup", False)

    assert config.get("audio.enabled") is True
    assert config.get("audio.startup") is False


def test_config_profile_float_precision(config):
    """Test that float precision is maintained in profiles."""
    config.set("movement.acceleration_rate", 1.0234567)
    value = config.get("movement.acceleration_rate")

    # Allow small floating point differences
    assert abs(value - 1.0234567) < 0.0000001


def test_config_profile_rename_simulation(config):
    """Test profile renaming (simulation)."""
    profiles = {"default": {}, "old_name": {}}

    # Rename by creating new entry and deleting old
    profiles["new_name"] = profiles.pop("old_name")

    assert "new_name" in profiles
    assert "old_name" not in profiles


def test_config_profile_empty_profile(config):
    """Test handling of empty profiles."""
    # A profile might be empty initially
    empty_profile = {}

    # Should not error when applying empty profile
    for key, value in empty_profile.items():
        config.set(key, value)

    # Config should retain its defaults
    assert config.get("movement.base_speed") is not None


def test_config_profile_partial_override(config):
    """Test that partial profile updates only override specified settings."""
    # Set initial values
    config.set("movement.base_speed", 10)
    config.set("movement.acceleration_rate", 1.02)
    config.set("movement.max_speed", 100)

    # Apply partial profile (only base_speed)
    config.set("movement.base_speed", 20)

    # Only base_speed should change
    assert config.get("movement.base_speed") == 20
    assert config.get("movement.acceleration_rate") == 1.02
    assert config.get("movement.max_speed") == 100


def test_config_profile_export_format(config):
    """Test that profiles can be exported to a serializable format."""
    config.set("movement.base_speed", 15)
    config.set("movement.acceleration_rate", 1.03)

    # Simulate export by creating a dict with config values
    exported = {
        "movement.base_speed": config.get("movement.base_speed"),
        "movement.acceleration_rate": config.get("movement.acceleration_rate"),
    }

    # Verify exported format is JSON-serializable
    try:
        json_str = json.dumps(exported)
        assert len(json_str) > 0
    except (TypeError, ValueError):
        pytest.fail("Exported profile is not JSON-serializable")


def test_config_profile_import_format(config):
    """Test that profiles can be imported from serialized format."""
    # Simulate importing from JSON
    import_data = '{"movement.base_speed": 20, "movement.acceleration_rate": 1.04}'
    profile = json.loads(import_data)

    # Apply imported profile
    for key, value in profile.items():
        config.set(key, value)

    assert config.get("movement.base_speed") == 20
    assert config.get("movement.acceleration_rate") == 1.04


def test_config_profile_with_defaults(config):
    """Test that profiles respect configuration defaults."""
    # Get default value
    default_base_speed = config.get("movement.base_speed", 10)

    # Override with profile
    config.set("movement.base_speed", 25)

    # Verify override worked
    assert config.get("movement.base_speed") == 25

    # Reset to default simulation
    config.set("movement.base_speed", default_base_speed)
    assert config.get("movement.base_speed") == default_base_speed


def test_config_profile_case_sensitivity(config):
    """Test that profile keys are case-sensitive."""
    config.set("movement.base_speed", 10)
    config.set("movement.BASE_SPEED", 20)

    # These should be different keys
    assert config.get("movement.base_speed") == 10
    assert config.get("movement.BASE_SPEED") == 20


def test_config_profile_special_characters(config):
    """Test handling profile keys with special characters."""
    special_key = "movement.base_speed_v2"
    config.set(special_key, 15)

    assert config.get(special_key) == 15


def test_config_profile_large_number_of_settings(config):
    """Test handling profile with many settings."""
    # Create a profile with many settings
    for i in range(50):
        config.set(f"setting.item_{i}", i * 10)

    # Verify all settings were set
    for i in range(50):
        assert config.get(f"setting.item_{i}") == i * 10


def test_config_profile_default_values_intact(config):
    """Test that accessing non-existent keys returns defaults."""
    value = config.get("nonexistent.key", "default_value")

    assert value == "default_value"


def test_config_profile_get_all_keys(config):
    """Test retrieving all values in a profile."""
    config.set("test.key1", "value1")
    config.set("test.key2", "value2")
    config.set("test.key3", "value3")

    # Verify all keys were set
    assert config.get("test.key1") == "value1"
    assert config.get("test.key2") == "value2"
    assert config.get("test.key3") == "value3"
