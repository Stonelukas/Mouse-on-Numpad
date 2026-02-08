"""Movement settings tab with speed and acceleration controls."""

import gi  # type: ignore[import-untyped]

gi.require_version("Gtk", "4.0")
from gi.repository import Gtk  # type: ignore[import-untyped]

from ..core.config import ConfigManager


class MovementTab(Gtk.Box):  # type: ignore[misc]
    """Movement configuration tab with speed and acceleration settings."""

    def __init__(self, config: ConfigManager) -> None:
        """Initialize movement tab.

        Args:
            config: Configuration manager for reading/writing movement settings
        """
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        self._config = config

        self.set_margin_top(20)
        self.set_margin_bottom(20)
        self.set_margin_start(20)
        self.set_margin_end(20)

        # Title label
        title = Gtk.Label(label="Movement Settings")
        title.add_css_class("title-2")
        self.append(title)

        # Base Speed setting
        speed_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        speed_label = Gtk.Label(label="Base Speed")
        speed_label.set_halign(Gtk.Align.START)
        speed_box.append(speed_label)

        speed_scale = Gtk.Scale.new_with_range(
            orientation=Gtk.Orientation.HORIZONTAL, min=1, max=100, step=1
        )
        speed_scale.set_value(self._config.get("movement.base_speed", 15))
        speed_scale.set_draw_value(True)
        speed_scale.set_value_pos(Gtk.PositionType.RIGHT)
        speed_scale.connect("value-changed", self._on_speed_changed)
        speed_box.append(speed_scale)
        self.append(speed_box)

        # Max Speed setting
        max_speed_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        max_speed_label = Gtk.Label(label="Max Speed")
        max_speed_label.set_halign(Gtk.Align.START)
        max_speed_box.append(max_speed_label)

        max_speed_scale = Gtk.Scale.new_with_range(
            orientation=Gtk.Orientation.HORIZONTAL, min=10, max=200, step=5
        )
        max_speed_scale.set_value(self._config.get("movement.max_speed", 150))
        max_speed_scale.set_draw_value(True)
        max_speed_scale.set_value_pos(Gtk.PositionType.RIGHT)
        max_speed_scale.connect("value-changed", self._on_max_speed_changed)
        max_speed_box.append(max_speed_scale)
        self.append(max_speed_box)

        # Acceleration Rate setting
        accel_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        accel_label = Gtk.Label(label="Acceleration Rate")
        accel_label.set_halign(Gtk.Align.START)
        accel_box.append(accel_label)

        accel_scale = Gtk.Scale.new_with_range(
            orientation=Gtk.Orientation.HORIZONTAL, min=1.0, max=3.0, step=0.05
        )
        accel_scale.set_value(self._config.get("movement.acceleration_rate", 1.15))
        accel_scale.set_draw_value(True)
        accel_scale.set_value_pos(Gtk.PositionType.RIGHT)
        accel_scale.set_digits(2)
        accel_scale.connect("value-changed", self._on_acceleration_changed)
        accel_box.append(accel_scale)
        self.append(accel_box)

        # Move Delay setting
        delay_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        delay_label = Gtk.Label(label="Move Delay (ms)")
        delay_label.set_halign(Gtk.Align.START)
        delay_box.append(delay_label)

        delay_scale = Gtk.Scale.new_with_range(
            orientation=Gtk.Orientation.HORIZONTAL, min=5, max=50, step=1
        )
        delay_scale.set_value(self._config.get("movement.move_delay", 20))
        delay_scale.set_draw_value(True)
        delay_scale.set_value_pos(Gtk.PositionType.RIGHT)
        delay_scale.connect("value-changed", self._on_move_delay_changed)
        delay_box.append(delay_scale)
        self.append(delay_box)

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
        self.append(curve_box)

    def _on_speed_changed(self, scale: Gtk.Scale) -> None:
        """Handle base speed slider changes."""
        value = int(scale.get_value())
        self._config.set("movement.base_speed", value)

    def _on_max_speed_changed(self, scale: Gtk.Scale) -> None:
        """Handle max speed slider changes."""
        value = int(scale.get_value())
        self._config.set("movement.max_speed", value)

    def _on_acceleration_changed(self, scale: Gtk.Scale) -> None:
        """Handle acceleration rate slider changes."""
        value = round(scale.get_value(), 2)
        self._config.set("movement.acceleration_rate", value)

    def _on_move_delay_changed(self, scale: Gtk.Scale) -> None:
        """Handle move delay slider changes."""
        value = int(scale.get_value())
        self._config.set("movement.move_delay", value)

    def _on_curve_changed(self, dropdown: Gtk.DropDown, _param: object) -> None:
        """Handle acceleration curve dropdown changes."""
        selected = dropdown.get_selected()
        curves = ["linear", "exponential", "s-curve"]
        if 0 <= selected < len(curves):
            self._config.set("movement.curve", curves[selected])
