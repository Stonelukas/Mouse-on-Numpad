"""Tests for position memory system."""

import json
import tempfile
from pathlib import Path
from unittest.mock import MagicMock

import pytest

from mouse_on_numpad.core.config import ConfigManager
from mouse_on_numpad.input.monitor_manager import MonitorInfo
from mouse_on_numpad.input.position_memory import PositionMemory


@pytest.fixture
def temp_config_dir(tmp_path: Path) -> Path:
    """Create temporary config directory."""
    return tmp_path / "config"


@pytest.fixture
def mock_monitor_manager() -> MagicMock:
    """Create mock MonitorManager."""
    mock = MagicMock()

    # Single monitor setup
    monitor: MonitorInfo = {
        "index": 0,
        "name": "HDMI-1",
        "x": 0,
        "y": 0,
        "width": 1920,
        "height": 1080,
        "is_primary": True,
    }

    mock.get_monitors.return_value = [monitor]
    mock.clamp_to_screens.side_effect = lambda x, y: (
        max(0, min(x, 1919)),
        max(0, min(y, 1079)),
    )

    return mock


@pytest.fixture
def config_manager(temp_config_dir: Path) -> ConfigManager:
    """Create ConfigManager with temp directory."""
    return ConfigManager(config_dir=temp_config_dir)


@pytest.fixture
def position_memory(
    config_manager: ConfigManager, mock_monitor_manager: MagicMock
) -> PositionMemory:
    """Create PositionMemory instance."""
    return PositionMemory(config_manager, mock_monitor_manager)


def test_init_creates_positions_file(position_memory: PositionMemory) -> None:
    """Test initialization creates positions file."""
    assert position_memory._positions_file.parent.exists()


def test_save_position(position_memory: PositionMemory) -> None:
    """Test saving a position to a slot."""
    position_memory.save_position(1, 100, 200)

    # Verify position was saved
    loaded = position_memory.load_position(1)
    assert loaded == (100, 200)


def test_save_position_invalid_slot(position_memory: PositionMemory) -> None:
    """Test saving to invalid slot raises ValueError."""
    with pytest.raises(ValueError, match="Slot must be 1-9"):
        position_memory.save_position(0, 100, 200)

    with pytest.raises(ValueError, match="Slot must be 1-9"):
        position_memory.save_position(10, 100, 200)


def test_load_position_empty_slot(position_memory: PositionMemory) -> None:
    """Test loading from empty slot returns None."""
    result = position_memory.load_position(1)
    assert result is None


def test_load_position_invalid_slot(position_memory: PositionMemory) -> None:
    """Test loading from invalid slot raises ValueError."""
    with pytest.raises(ValueError, match="Slot must be 1-9"):
        position_memory.load_position(0)

    with pytest.raises(ValueError, match="Slot must be 1-9"):
        position_memory.load_position(10)


def test_clear_slot(position_memory: PositionMemory) -> None:
    """Test clearing a position slot."""
    # Save position
    position_memory.save_position(1, 100, 200)
    assert position_memory.load_position(1) is not None

    # Clear slot
    position_memory.clear_slot(1)
    assert position_memory.load_position(1) is None


def test_clear_slot_invalid(position_memory: PositionMemory) -> None:
    """Test clearing invalid slot raises ValueError."""
    with pytest.raises(ValueError, match="Slot must be 1-9"):
        position_memory.clear_slot(0)


def test_clear_empty_slot(position_memory: PositionMemory) -> None:
    """Test clearing empty slot does nothing."""
    # Should not raise error
    position_memory.clear_slot(1)


def test_get_all_slots(position_memory: PositionMemory) -> None:
    """Test getting all saved positions."""
    # Save multiple positions
    position_memory.save_position(1, 100, 200)
    position_memory.save_position(3, 300, 400)
    position_memory.save_position(5, 500, 600)

    # Get all slots
    slots = position_memory.get_all_slots()

    assert len(slots) == 3
    assert slots[1] == (100, 200)
    assert slots[3] == (300, 400)
    assert slots[5] == (500, 600)


def test_get_all_slots_empty(position_memory: PositionMemory) -> None:
    """Test getting all slots when empty."""
    slots = position_memory.get_all_slots()
    assert slots == {}


def test_persistence(
    config_manager: ConfigManager, mock_monitor_manager: MagicMock
) -> None:
    """Test positions persist across instances."""
    # Create first instance and save position
    pm1 = PositionMemory(config_manager, mock_monitor_manager)
    pm1.save_position(1, 100, 200)

    # Create second instance (simulates restart)
    pm2 = PositionMemory(config_manager, mock_monitor_manager)
    loaded = pm2.load_position(1)

    assert loaded == (100, 200)


def test_monitor_config_hash_consistency(
    config_manager: ConfigManager, mock_monitor_manager: MagicMock
) -> None:
    """Test monitor config hash is consistent."""
    pm = PositionMemory(config_manager, mock_monitor_manager)

    hash1 = pm.get_monitor_config_hash()
    hash2 = pm.get_monitor_config_hash()

    assert hash1 == hash2


def test_monitor_config_hash_changes_with_monitors(
    config_manager: ConfigManager, mock_monitor_manager: MagicMock
) -> None:
    """Test monitor config hash changes when monitors change."""
    pm = PositionMemory(config_manager, mock_monitor_manager)

    hash1 = pm.get_monitor_config_hash()

    # Change monitor configuration
    new_monitor: MonitorInfo = {
        "index": 1,
        "name": "DP-1",
        "x": 1920,
        "y": 0,
        "width": 1920,
        "height": 1080,
        "is_primary": False,
    }
    mock_monitor_manager.get_monitors.return_value = [
        mock_monitor_manager.get_monitors()[0],
        new_monitor,
    ]

    hash2 = pm.get_monitor_config_hash()

    assert hash1 != hash2


def test_position_clamping(
    config_manager: ConfigManager, mock_monitor_manager: MagicMock
) -> None:
    """Test positions are clamped to valid screen area."""
    pm = PositionMemory(config_manager, mock_monitor_manager)

    # Save position outside screen bounds
    pm.save_position(1, 5000, 5000)

    # Load should clamp to screen bounds
    loaded = pm.load_position(1)
    assert loaded == (1919, 1079)  # Clamped to monitor bounds


def test_per_monitor_config_isolation(
    config_manager: ConfigManager, mock_monitor_manager: MagicMock
) -> None:
    """Test positions are isolated per monitor configuration."""
    pm = PositionMemory(config_manager, mock_monitor_manager)

    # Save position in first config
    pm.save_position(1, 100, 200)

    # Change monitor configuration
    new_monitor: MonitorInfo = {
        "index": 1,
        "name": "DP-1",
        "x": 1920,
        "y": 0,
        "width": 1920,
        "height": 1080,
        "is_primary": False,
    }
    mock_monitor_manager.get_monitors.return_value = [
        mock_monitor_manager.get_monitors()[0],
        new_monitor,
    ]

    # Position should not exist in new config
    loaded = pm.load_position(1)
    assert loaded is None


def test_json_format(
    config_manager: ConfigManager, mock_monitor_manager: MagicMock
) -> None:
    """Test JSON file format is correct."""
    pm = PositionMemory(config_manager, mock_monitor_manager)

    # Save positions
    pm.save_position(1, 100, 200)
    pm.save_position(2, 300, 400)

    # Read JSON file directly
    with open(pm._positions_file, encoding="utf-8") as f:
        data = json.load(f)

    # Should have one monitor hash key
    assert len(data) == 1

    # Get the positions for the monitor hash
    monitor_hash = pm.get_monitor_config_hash()
    assert monitor_hash in data

    slots = data[monitor_hash]
    assert "1" in slots
    assert "2" in slots
    assert slots["1"] == {"x": 100, "y": 200}
    assert slots["2"] == {"x": 300, "y": 400}


def test_corrupted_json_recovery(
    temp_config_dir: Path, mock_monitor_manager: MagicMock
) -> None:
    """Test recovery from corrupted positions file."""
    config_manager = ConfigManager(config_dir=temp_config_dir)

    # Create corrupted JSON file
    positions_file = temp_config_dir / "positions.json"
    positions_file.parent.mkdir(parents=True, exist_ok=True)
    positions_file.write_text("invalid json {{{")

    # Should recover gracefully
    pm = PositionMemory(config_manager, mock_monitor_manager)
    assert pm.load_position(1) is None
