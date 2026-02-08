"""Position memory system for saving/loading cursor positions."""

import hashlib
import json
import logging
from pathlib import Path
from typing import Any

from mouse_on_numpad.core.config import ConfigManager
from mouse_on_numpad.input.monitor_manager import MonitorInfo, MonitorManager

_logger = logging.getLogger(__name__)


class PositionMemory:
    """Manage 9 position slots with per-monitor-config persistence."""

    SLOT_COUNT = 9  # Numpad 1-9

    def __init__(self, config: ConfigManager, monitor_manager: MonitorManager) -> None:
        self._config = config
        self._monitor_manager = monitor_manager
        self._positions_file = config.config_dir / "positions.json"
        self._positions: dict[str, dict[int, dict[str, int]]] = {}
        self._load()

    def _load(self) -> None:
        """Load positions from disk."""
        if self._positions_file.exists():
            try:
                with open(self._positions_file, encoding="utf-8") as f:
                    data: dict[str, Any] = json.load(f)
                    # Validate structure
                    if isinstance(data, dict):
                        # Convert string keys to int for slots
                        self._positions = {}
                        for monitor_hash, slots in data.items():
                            if isinstance(slots, dict):
                                self._positions[monitor_hash] = {
                                    int(k): v for k, v in slots.items() if isinstance(v, dict)
                                }
                _logger.info("Loaded positions from %s", self._positions_file)
            except (json.JSONDecodeError, OSError, ValueError) as e:
                _logger.warning("Failed to load positions: %s, using empty", e)
                self._positions = {}
        else:
            self._positions = {}
            _logger.info("No existing positions file, starting fresh")

    def _save(self) -> None:
        """Save positions to disk."""
        try:
            # Ensure directory exists
            self._positions_file.parent.mkdir(parents=True, exist_ok=True)

            # Convert to JSON-serializable format
            data = {
                monitor_hash: {str(slot): pos for slot, pos in slots.items()}
                for monitor_hash, slots in self._positions.items()
            }

            with open(self._positions_file, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=2)

            _logger.debug("Saved positions to %s", self._positions_file)
        except OSError as e:
            _logger.error("Failed to save positions: %s", e)

    def get_monitor_config_hash(self) -> str:
        """Get SHA256 hash of current monitor arrangement for keying positions."""
        monitors = self._monitor_manager.get_monitors()

        # Sort by position to ensure consistent ordering
        sorted_monitors = sorted(monitors, key=lambda m: (m["x"], m["y"]))

        # Create deterministic string: name,x,y,w,h;name,x,y,w,h;...
        config_str = ";".join(
            f"{m['name']},{m['x']},{m['y']},{m['width']},{m['height']}"
            for m in sorted_monitors
        )

        # Hash for compact key
        return hashlib.sha256(config_str.encode()).hexdigest()[:16]

    def save_position(self, slot: int, x: int, y: int) -> None:
        """Save cursor position to slot.

        Args:
            slot: Slot number (1-9)
            x: X coordinate
            y: Y coordinate

        Raises:
            ValueError: If slot is out of range
        """
        if not 1 <= slot <= self.SLOT_COUNT:
            raise ValueError(f"Slot must be 1-{self.SLOT_COUNT}, got {slot}")

        monitor_hash = self.get_monitor_config_hash()

        # Initialize monitor config if needed
        if monitor_hash not in self._positions:
            self._positions[monitor_hash] = {}

        # Save position
        self._positions[monitor_hash][slot] = {"x": x, "y": y}
        self._save()

        _logger.info("Saved position slot %d: (%d, %d)", slot, x, y)

    def load_position(self, slot: int) -> tuple[int, int] | None:
        """Load cursor position from slot.

        Args:
            slot: Slot number (1-9)

        Returns:
            (x, y) tuple or None if slot is empty

        Raises:
            ValueError: If slot is out of range
        """
        if not 1 <= slot <= self.SLOT_COUNT:
            raise ValueError(f"Slot must be 1-{self.SLOT_COUNT}, got {slot}")

        monitor_hash = self.get_monitor_config_hash()

        # Check if position exists for current monitor config
        if monitor_hash not in self._positions:
            _logger.debug("No positions for current monitor config")
            return None

        if slot not in self._positions[monitor_hash]:
            _logger.debug("Slot %d is empty", slot)
            return None

        pos = self._positions[monitor_hash][slot]
        x, y = pos["x"], pos["y"]

        # Clamp to current screen area in case monitors changed
        clamped_x, clamped_y = self._monitor_manager.clamp_to_screens(x, y)

        if (clamped_x, clamped_y) != (x, y):
            _logger.warning(
                "Position clamped from (%d, %d) to (%d, %d)", x, y, clamped_x, clamped_y
            )

        _logger.info("Loaded position slot %d: (%d, %d)", slot, clamped_x, clamped_y)
        return (clamped_x, clamped_y)

    def get_all_slots(self) -> dict[int, tuple[int, int]]:
        """Get all saved positions for current monitor config.

        Returns:
            Dict mapping slot number to (x, y) coordinates
        """
        monitor_hash = self.get_monitor_config_hash()

        if monitor_hash not in self._positions:
            return {}

        # Convert to tuple format
        result = {}
        for slot, pos in self._positions[monitor_hash].items():
            x, y = pos["x"], pos["y"]
            # Clamp each position
            result[slot] = self._monitor_manager.clamp_to_screens(x, y)

        return result

    def clear_slot(self, slot: int) -> None:
        """Clear a position slot.

        Args:
            slot: Slot number (1-9)

        Raises:
            ValueError: If slot is out of range
        """
        if not 1 <= slot <= self.SLOT_COUNT:
            raise ValueError(f"Slot must be 1-{self.SLOT_COUNT}, got {slot}")

        monitor_hash = self.get_monitor_config_hash()

        if monitor_hash in self._positions and slot in self._positions[monitor_hash]:
            del self._positions[monitor_hash][slot]
            self._save()
            _logger.info("Cleared position slot %d", slot)
        else:
            _logger.debug("Slot %d was already empty", slot)
