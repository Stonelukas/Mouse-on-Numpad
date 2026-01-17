"""GTK 4 main settings window with tabbed interface."""

import gi  # type: ignore[import-untyped]

gi.require_version("Gtk", "4.0")
from gi.repository import Gtk  # type: ignore[import-untyped]

from ..core.config import ConfigManager
from ..core.state_manager import StateManager
from .hotkeys_tab import HotkeysTab


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
        self.set_default_size(700, 500)
        self.set_resizable(True)

        # Create notebook with tabs
        self._notebook = Gtk.Notebook()
        self._notebook.set_tab_pos(Gtk.PositionType.TOP)

        # Add 4 tabs matching Windows version
        self._create_movement_tab()
        self._create_audio_tab()
        self._create_hotkeys_tab()
        self._create_advanced_tab()

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
        speed_scale.set_value(self._config.get("movement.base_speed", 15))
        speed_scale.set_draw_value(True)
        speed_scale.set_value_pos(Gtk.PositionType.RIGHT)
        speed_scale.connect("value-changed", self._on_speed_changed)
        speed_box.append(speed_scale)
        box.append(speed_box)

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
        box.append(max_speed_box)

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
        box.append(accel_box)

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
        box.append(delay_box)

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

        # Add tab to notebook
        label = Gtk.Label(label="Movement")
        self._notebook.append_page(box, label)

    def _create_audio_tab(self) -> None:
        """Create audio settings tab with volume and sound controls."""
        # Container for audio settings
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        box.set_margin_top(20)
        box.set_margin_bottom(20)
        box.set_margin_start(20)
        box.set_margin_end(20)

        # Title label
        title = Gtk.Label(label="Audio Settings")
        title.add_css_class("title-2")
        box.append(title)

        # Audio toggle
        audio_switch = Gtk.Switch()
        audio_switch.set_active(self._config.get("audio.enabled", True))
        audio_switch.connect("state-set", self._on_audio_toggled)
        audio_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        audio_label = Gtk.Label(label="Enable Audio Feedback")
        audio_label.set_halign(Gtk.Align.START)
        audio_box.append(audio_label)
        audio_box.append(audio_switch)
        box.append(audio_box)

        # Volume setting
        volume_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        volume_label = Gtk.Label(label="Volume")
        volume_label.set_halign(Gtk.Align.START)
        volume_box.append(volume_label)

        volume_scale = Gtk.Scale.new_with_range(
            orientation=Gtk.Orientation.HORIZONTAL, min=0, max=100, step=5
        )
        volume_scale.set_value(self._config.get("audio.volume", 50))
        volume_scale.set_draw_value(True)
        volume_scale.set_value_pos(Gtk.PositionType.RIGHT)
        volume_scale.connect("value-changed", self._on_volume_changed)
        volume_box.append(volume_scale)
        box.append(volume_box)

        # Add tab to notebook
        label = Gtk.Label(label="Audio")
        self._notebook.append_page(box, label)

    def _create_hotkeys_tab(self) -> None:
        """Create hotkeys tab with customizable key mappings."""
        hotkeys_tab = HotkeysTab(self._config)
        label = Gtk.Label(label="Hotkeys")
        self._notebook.append_page(hotkeys_tab, label)

    def _create_advanced_tab(self) -> None:
        """Create advanced settings tab with scroll and reset options."""
        # Container for advanced settings
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        box.set_margin_top(20)
        box.set_margin_bottom(20)
        box.set_margin_start(20)
        box.set_margin_end(20)

        # Title label
        title = Gtk.Label(label="Advanced Settings")
        title.add_css_class("title-2")
        box.append(title)

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
        box.append(scroll_box)

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
        box.append(scroll_accel_box)

        # Reset to defaults button
        reset_button = Gtk.Button(label="Reset All Settings to Defaults")
        reset_button.set_halign(Gtk.Align.CENTER)
        reset_button.set_margin_top(20)
        reset_button.connect("clicked", self._on_reset_defaults)
        box.append(reset_button)

        # Add tab to notebook
        label = Gtk.Label(label="Advanced")
        self._notebook.append_page(box, label)

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

    def _on_audio_toggled(self, switch: Gtk.Switch, state: bool) -> bool:
        """Handle audio toggle switch changes."""
        self._config.set("audio.enabled", state)
        return False

    def _on_volume_changed(self, scale: Gtk.Scale) -> None:
        """Handle volume slider changes."""
        value = int(scale.get_value())
        self._config.set("audio.volume", value)

    def _on_reset_defaults(self, _button: Gtk.Button) -> None:
        """Handle reset to defaults button click."""
        self._config.reset()
        dialog = Gtk.AlertDialog(message="Settings reset to defaults")
        dialog.show(self)
