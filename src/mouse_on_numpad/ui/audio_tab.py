"""Audio settings tab with volume and sound controls."""

import gi  # type: ignore[import-untyped]

gi.require_version("Gtk", "4.0")
from gi.repository import Gtk  # type: ignore[import-untyped]

from ..core.config import ConfigManager


class AudioTab(Gtk.Box):  # type: ignore[misc]
    """Audio configuration tab with enable toggle and volume controls."""

    def __init__(self, config: ConfigManager) -> None:
        """Initialize audio tab.

        Args:
            config: Configuration manager for reading/writing audio settings
        """
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        self._config = config

        self.set_margin_top(20)
        self.set_margin_bottom(20)
        self.set_margin_start(20)
        self.set_margin_end(20)

        # Title label
        title = Gtk.Label(label="Audio Settings")
        title.add_css_class("title-2")
        self.append(title)

        # Audio toggle
        audio_switch = Gtk.Switch()
        audio_switch.set_active(self._config.get("audio.enabled", True))
        audio_switch.connect("state-set", self._on_audio_toggled)
        audio_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        audio_label = Gtk.Label(label="Enable Audio Feedback")
        audio_label.set_halign(Gtk.Align.START)
        audio_box.append(audio_label)
        audio_box.append(audio_switch)
        self.append(audio_box)

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
        self.append(volume_box)

    def _on_audio_toggled(self, switch: Gtk.Switch, state: bool) -> bool:
        """Handle audio toggle switch changes."""
        self._config.set("audio.enabled", state)
        return False

    def _on_volume_changed(self, scale: Gtk.Scale) -> None:
        """Handle volume slider changes."""
        value = int(scale.get_value())
        self._config.set("audio.volume", value)
