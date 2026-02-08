"""Advanced settings tab with scroll and reset options."""

import gi  # type: ignore[import-untyped]

gi.require_version("Gtk", "4.0")
from gi.repository import Gtk  # type: ignore[import-untyped]

from ..core.config import ConfigManager


class AdvancedTab(Gtk.Box):  # type: ignore[misc]
    """Advanced configuration tab with scroll settings and reset button."""

    def __init__(self, config: ConfigManager) -> None:
        """Initialize advanced tab.

        Args:
            config: Configuration manager for reading/writing advanced settings
        """
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        self._config = config

        self.set_margin_top(20)
        self.set_margin_bottom(20)
        self.set_margin_start(20)
        self.set_margin_end(20)

        # Title label
        title = Gtk.Label(label="Advanced Settings")
        title.add_css_class("title-2")
        self.append(title)

        # Scroll step setting
        scroll_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        scroll_label = Gtk.Label(label="Scroll Step")
        scroll_label.set_halign(Gtk.Align.START)
        scroll_box.append(scroll_label)

        scroll_scale = Gtk.Scale.new_with_range(
            orientation=Gtk.Orientation.HORIZONTAL, min=1, max=10, step=1
        )
        scroll_scale.set_value(3)  # Default scroll step
        scroll_scale.set_draw_value(True)
        scroll_scale.set_value_pos(Gtk.PositionType.RIGHT)
        scroll_box.append(scroll_scale)
        self.append(scroll_box)

        # Scroll acceleration setting
        scroll_accel_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        scroll_accel_label = Gtk.Label(label="Scroll Acceleration Rate")
        scroll_accel_label.set_halign(Gtk.Align.START)
        scroll_accel_box.append(scroll_accel_label)

        scroll_accel_scale = Gtk.Scale.new_with_range(
            orientation=Gtk.Orientation.HORIZONTAL, min=1.0, max=2.0, step=0.1
        )
        scroll_accel_scale.set_value(1.5)  # Default scroll acceleration
        scroll_accel_scale.set_draw_value(True)
        scroll_accel_scale.set_value_pos(Gtk.PositionType.RIGHT)
        scroll_accel_scale.set_digits(1)
        scroll_accel_box.append(scroll_accel_scale)
        self.append(scroll_accel_box)

        # Reset to defaults button
        reset_button = Gtk.Button(label="Reset All Settings to Defaults")
        reset_button.set_halign(Gtk.Align.CENTER)
        reset_button.set_margin_top(20)
        reset_button.connect("clicked", self._on_reset_defaults)
        self.append(reset_button)

    def _on_reset_defaults(self, _button: Gtk.Button) -> None:
        """Handle reset to defaults button click."""
        self._config.reset()
        dialog = Gtk.AlertDialog(message="Settings reset to defaults")
        parent = self.get_root()
        if parent:
            dialog.show(parent)
