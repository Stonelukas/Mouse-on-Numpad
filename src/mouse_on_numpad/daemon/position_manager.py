"""Position management for mouse position save/load/cycle."""

import subprocess
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from ..input import MonitorManager, PositionMemory


class PositionManager:
    """Handles mouse position operations (get, move, save, load, cycle monitors)."""

    def __init__(self, monitors: "MonitorManager", positions: "PositionMemory") -> None:
        self.monitors = monitors
        self.positions = positions

    def get_mouse_position(self) -> tuple[int, int] | None:
        """Get current mouse position using xdotool (X11/XWayland)."""
        try:
            result = subprocess.run(
                ["xdotool", "getmouselocation", "--shell"],
                capture_output=True,
                text=True,
                check=True,
            )
            # Parse "X=123\nY=456\n..."
            pos = {}
            for line in result.stdout.strip().split("\n"):
                if "=" in line:
                    k, v = line.split("=", 1)
                    pos[k] = int(v)
            return (pos.get("X", 0), pos.get("Y", 0))
        except (subprocess.CalledProcessError, FileNotFoundError, ValueError):
            return None

    def move_to_position(self, x: int, y: int) -> None:
        """Move mouse to absolute position using xdotool."""
        subprocess.run(["xdotool", "mousemove", str(x), str(y)], check=False)

    def save_position_to_slot(self, slot: int) -> None:
        """Save current mouse position to slot."""
        pos = self.get_mouse_position()
        if pos:
            self.positions.save_position(slot, pos[0], pos[1])
            print(f"Saved position {pos} to slot {slot}")
        else:
            print("Cannot get mouse position (xdotool required)")

    def load_position_from_slot(self, slot: int) -> None:
        """Load and move to position from slot."""
        pos = self.positions.load_position(slot)
        if pos:
            self.move_to_position(pos[0], pos[1])
            print(f"Moved to slot {slot}: {pos}")
        else:
            print(f"No position saved in slot {slot}")

    def cycle_monitor(self) -> None:
        """Move cursor to center of next monitor (cycling)."""
        pos = self.get_mouse_position()
        if not pos:
            print("Cannot get mouse position (xdotool required)")
            return

        next_center = self.monitors.get_next_monitor_center(pos[0], pos[1])
        if next_center:
            self.move_to_position(next_center[0], next_center[1])
            print(f"Moved to next monitor: {next_center}")
        else:
            print("Only one monitor detected")
