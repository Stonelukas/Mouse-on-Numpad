"""GTK 4 Hotkeys tab for customizable keybindings.

Provides a settings tab with interactive key capture buttons
for all configurable hotkeys in the daemon.
"""

import gi  # type: ignore[import-untyped]

gi.require_version("Gtk", "4.0")
from gi.repository import Gtk  # type: ignore[import-untyped]

from ..core.config import ConfigManager
from .keycode_mappings import get_key_name, HOTKEY_LABELS, SLOT_KEY_LABELS
from .key_capture_button import KeyCaptureButton


class HotkeysTab(Gtk.Box):  # type: ignore[misc]
    """Hotkeys configuration tab with key capture buttons.

    Displays all configurable hotkeys with interactive buttons that
    allow users to reassign keys by pressing them. Includes:
    - Conflict detection between hotkeys
    - Reset to defaults button
    - Escape to cancel key capture
    """

    def __init__(self, config: ConfigManager) -> None:
        """Initialize hotkeys tab.

        Args:
            config: Configuration manager for reading/writing keycodes
        """
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        self._config = config
        self._capture_buttons: dict[str, KeyCaptureButton] = {}

        self.set_margin_top(20)
        self.set_margin_bottom(20)
        self.set_margin_start(20)
        self.set_margin_end(20)

        # Title
        title = Gtk.Label(label="Hotkey Configuration")
        title.add_css_class("title-2")
        self.append(title)

        # Info label
        info = Gtk.Label(label="Click a key button to reassign. Press Escape to cancel.")
        info.set_wrap(True)
        self.append(info)

        # Scrolled window for hotkeys grid
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_vexpand(True)
        scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)

        # Grid for hotkey mappings
        grid = Gtk.Grid()
        grid.set_row_spacing(8)
        grid.set_column_spacing(20)
        grid.set_margin_top(10)

        # Create capture buttons for main hotkeys
        row = 0
        for action, label in HOTKEY_LABELS.items():
            row = self._add_hotkey_row(grid, row, action, label)

        # Add separator before slot keys
        separator = Gtk.Separator()
        separator.set_margin_top(10)
        separator.set_margin_bottom(10)
        grid.attach(separator, 0, row, 2, 1)
        row += 1

        # Section label for slots
        slots_label = Gtk.Label(label="Position Slots (used in Save/Load mode)")
        slots_label.set_halign(Gtk.Align.START)
        slots_label.add_css_class("dim-label")
        grid.attach(slots_label, 0, row, 2, 1)
        row += 1

        # Create capture buttons for slot keys
        for action, label in SLOT_KEY_LABELS.items():
            row = self._add_hotkey_row(grid, row, action, label)

        scrolled.set_child(grid)
        self.append(scrolled)

        # Reset button
        reset_button = Gtk.Button(label="Reset Hotkeys to Defaults")
        reset_button.set_halign(Gtk.Align.CENTER)
        reset_button.set_margin_top(12)
        reset_button.connect("clicked", self._on_reset_hotkeys)
        self.append(reset_button)

    def _add_hotkey_row(
        self, grid: Gtk.Grid, row: int, action: str, label: str
    ) -> int:
        """Add a hotkey row to the grid.

        Args:
            grid: The grid to add to
            row: Current row index
            action: Config key name
            label: Human-readable label

        Returns:
            Next row index
        """
        action_label = Gtk.Label(label=label)
        action_label.set_halign(Gtk.Align.START)
        grid.attach(action_label, 0, row, 1, 1)

        capture_btn = KeyCaptureButton(
            self._config, action, self._show_conflict_dialog
        )
        capture_btn.set_hexpand(False)
        capture_btn.set_size_request(120, -1)
        self._capture_buttons[action] = capture_btn
        grid.attach(capture_btn, 1, row, 1, 1)

        return row + 1

    def _show_conflict_dialog(
        self, action1: str, action2: str, keycode: int
    ) -> None:
        """Show dialog when key conflict is detected."""
        key_name = get_key_name(keycode)
        # Look up label in both dicts
        action2_label = HOTKEY_LABELS.get(action2) or SLOT_KEY_LABELS.get(
            action2, action2
        )

        dialog = Gtk.AlertDialog(
            message="Key Conflict",
            detail=f'"{key_name}" is already assigned to "{action2_label}".\n'
            "Please choose a different key.",
        )
        # Get parent window
        parent = self.get_root()
        if parent:
            dialog.show(parent)

    def _on_reset_hotkeys(self, _button: Gtk.Button) -> None:
        """Reset all hotkeys to defaults."""
        defaults = ConfigManager.DEFAULT_CONFIG.get("hotkeys", {})
        for action, keycode in defaults.items():
            self._config.set(f"hotkeys.{action}", keycode)

        # Refresh all buttons
        for btn in self._capture_buttons.values():
            btn.refresh()

        # Show confirmation
        dialog = Gtk.AlertDialog(message="Hotkeys reset to defaults")
        parent = self.get_root()
        if parent:
            dialog.show(parent)
