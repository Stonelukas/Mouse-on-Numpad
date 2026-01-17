"""GTK 4 main settings window with tabbed interface."""

import gi  # type: ignore[import-untyped]

gi.require_version("Gtk", "4.0")
from gi.repository import Gtk  # type: ignore[import-untyped]

from ..core.config import ConfigManager
from ..core.state_manager import StateManager


class MainWindow(Gtk.ApplicationWindow):  # type: ignore[misc]
    """Main settings window with notebook for configuration tabs.

    MVP Implementation:
    - Tab 1: Movement settings (speed, acceleration)
    - Tab 2: Position memory (9 slots display)

    Uses GTK system theme only (no custom themes per validation).
    """

    def __init__(
        self, app: Gtk.Application, config: ConfigManager, state: StateManager
    ) -> None:
        """Initialize main settings window.

        Args:
            app: GTK Application instance
            config: Configuration manager
            state: State manager
        """
        super().__init__(application=app, title="Mouse on Numpad Settings")
        self._config = config
        self._state = state

        # Window properties
        self.set_default_size(600, 400)
        self.set_resizable(True)

        # Create notebook with tabs
        self._notebook = Gtk.Notebook()
        self._notebook.set_tab_pos(Gtk.PositionType.TOP)

        # Add tabs
        self._create_movement_tab()
        self._create_positions_tab()

        # Set notebook as window content
        self.set_child(self._notebook)

    def _create_movement_tab(self) -> None:
        """Create movement settings tab with speed and acceleration controls."""
        # Container for movement settings
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        box.set_margin_top(20)
        box.set_margin_bottom(20)
        box.set_margin_start(20)
        box.set_margin_end(20)

        # Title label
        title = Gtk.Label(label="Movement Settings")
        title.add_css_class("title-2")
        box.append(title)

        # Base Speed setting
        speed_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        speed_label = Gtk.Label(label="Base Speed")
        speed_label.set_halign(Gtk.Align.START)
        speed_box.append(speed_label)

        speed_scale = Gtk.Scale.new_with_range(
            orientation=Gtk.Orientation.HORIZONTAL, min=1, max=100, step=1
        )
        speed_scale.set_value(self._config.get("movement.base_speed", 10))
        speed_scale.set_draw_value(True)
        speed_scale.set_value_pos(Gtk.PositionType.RIGHT)
        speed_scale.connect("value-changed", self._on_speed_changed)
        speed_box.append(speed_scale)

        box.append(speed_box)

        # Acceleration setting
        accel_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        accel_label = Gtk.Label(label="Acceleration Factor")
        accel_label.set_halign(Gtk.Align.START)
        accel_box.append(accel_label)

        accel_scale = Gtk.Scale.new_with_range(
            orientation=Gtk.Orientation.HORIZONTAL, min=1.0, max=3.0, step=0.1
        )
        accel_scale.set_value(self._config.get("movement.acceleration", 1.5))
        accel_scale.set_draw_value(True)
        accel_scale.set_value_pos(Gtk.PositionType.RIGHT)
        accel_scale.set_digits(1)
        accel_scale.connect("value-changed", self._on_acceleration_changed)
        accel_box.append(accel_scale)

        box.append(accel_box)

        # Curve selection
        curve_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        curve_label = Gtk.Label(label="Acceleration Curve")
        curve_label.set_halign(Gtk.Align.START)
        curve_box.append(curve_label)

        curve_dropdown = Gtk.DropDown.new_from_strings(
            ["linear", "exponential", "s-curve"]
        )
        current_curve = self._config.get("movement.curve", "exponential")
        curve_options = ["linear", "exponential", "s-curve"]
        if current_curve in curve_options:
            curve_dropdown.set_selected(curve_options.index(current_curve))
        curve_dropdown.connect("notify::selected", self._on_curve_changed)
        curve_box.append(curve_dropdown)

        box.append(curve_box)

        # Audio toggle
        audio_switch = Gtk.Switch()
        audio_switch.set_active(self._config.get("audio.enabled", True))
        audio_switch.connect("state-set", self._on_audio_toggled)
        audio_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        audio_box.append(Gtk.Label(label="Audio Feedback"))
        audio_box.append(audio_switch)
        box.append(audio_box)

        # Add tab to notebook
        label = Gtk.Label(label="Movement")
        self._notebook.append_page(box, label)

    def _create_positions_tab(self) -> None:
        """Create position memory tab with 3x3 grid display."""
        # Container for positions
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        box.set_margin_top(20)
        box.set_margin_bottom(20)
        box.set_margin_start(20)
        box.set_margin_end(20)

        # Title label
        title = Gtk.Label(label="Position Memory")
        title.add_css_class("title-2")
        box.append(title)

        # Instructions
        instructions = Gtk.Label(
            label="9 position slots available (implementation pending Phase 3)"
        )
        instructions.set_wrap(True)
        box.append(instructions)

        # 3x3 Grid for position slots
        grid = Gtk.Grid()
        grid.set_row_spacing(10)
        grid.set_column_spacing(10)
        grid.set_halign(Gtk.Align.CENTER)

        # Create 3x3 grid of position buttons
        for row in range(3):
            for col in range(3):
                slot_num = row * 3 + col + 1
                button = Gtk.Button(label=f"Slot {slot_num}\n(Empty)")
                button.set_size_request(120, 80)
                grid.attach(button, col, row, 1, 1)

        box.append(grid)

        # Clear all button
        clear_button = Gtk.Button(label="Clear All Positions")
        clear_button.set_halign(Gtk.Align.CENTER)
        clear_button.connect("clicked", self._on_clear_positions)
        box.append(clear_button)

        # Add tab to notebook
        label = Gtk.Label(label="Positions")
        self._notebook.append_page(box, label)

    def _on_speed_changed(self, scale: Gtk.Scale) -> None:
        """Handle base speed slider changes."""
        value = int(scale.get_value())
        self._config.set("movement.base_speed", value)

    def _on_acceleration_changed(self, scale: Gtk.Scale) -> None:
        """Handle acceleration factor slider changes."""
        value = round(scale.get_value(), 1)
        self._config.set("movement.acceleration", value)

    def _on_curve_changed(self, dropdown: Gtk.DropDown, _param: object) -> None:
        """Handle acceleration curve dropdown changes."""
        selected = dropdown.get_selected()
        curves = ["linear", "exponential", "s-curve"]
        if 0 <= selected < len(curves):
            self._config.set("movement.curve", curves[selected])

    def _on_audio_toggled(self, switch: Gtk.Switch, state: bool) -> bool:
        """Handle audio toggle switch changes."""
        self._config.set("audio.enabled", state)
        return False

    def _on_clear_positions(self, _button: Gtk.Button) -> None:
        """Handle clear all positions button click."""
        # Position memory will be implemented in Phase 3
        dialog = Gtk.AlertDialog(message="Position memory not yet implemented")
        dialog.show(self)
