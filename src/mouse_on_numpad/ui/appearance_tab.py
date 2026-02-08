"""Appearance settings tab for status indicator configuration."""

import gi  # type: ignore[import-untyped]

gi.require_version("Gtk", "4.0")
from gi.repository import Gtk  # type: ignore[import-untyped]

from ..core.config import ConfigManager


class AppearanceTab(Gtk.Box):  # type: ignore[misc]
    """Appearance configuration tab for status indicator settings."""

    def __init__(self, config: ConfigManager) -> None:
        """Initialize appearance tab.

        Args:
            config: Configuration manager for reading/writing appearance settings
        """
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        self._config = config

        self.set_margin_top(20)
        self.set_margin_bottom(20)
        self.set_margin_start(20)
        self.set_margin_end(20)

        title = Gtk.Label(label="Status Indicator")
        title.add_css_class("title-2")
        self.append(title)

        # Position dropdown
        pos_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        pos_label = Gtk.Label(label="Position")
        pos_label.set_halign(Gtk.Align.START)
        pos_box.append(pos_label)
        positions = ["top-right", "top-left", "bottom-right", "bottom-left"]
        pos_dropdown = Gtk.DropDown.new_from_strings(positions)
        current_pos = self._config.get("status_bar.position", "top-right")
        if current_pos in positions:
            pos_dropdown.set_selected(positions.index(current_pos))
        pos_dropdown.connect("notify::selected", self._on_position_changed)
        pos_box.append(pos_dropdown)
        self.append(pos_box)

        # Size dropdown
        size_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        size_label = Gtk.Label(label="Size")
        size_label.set_halign(Gtk.Align.START)
        size_box.append(size_label)
        sizes = ["small", "medium", "large"]
        size_dropdown = Gtk.DropDown.new_from_strings(sizes)
        current_size = self._config.get("status_bar.size", "medium")
        if current_size in sizes:
            size_dropdown.set_selected(sizes.index(current_size))
        size_dropdown.connect("notify::selected", self._on_size_changed)
        size_box.append(size_dropdown)
        self.append(size_box)

        # Opacity slider
        opacity_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        opacity_label = Gtk.Label(label="Opacity")
        opacity_label.set_halign(Gtk.Align.START)
        opacity_box.append(opacity_label)
        opacity_scale = Gtk.Scale.new_with_range(
            orientation=Gtk.Orientation.HORIZONTAL, min=20, max=100, step=5
        )
        opacity_scale.set_value(self._config.get("status_bar.opacity", 80))
        opacity_scale.set_draw_value(True)
        opacity_scale.set_value_pos(Gtk.PositionType.RIGHT)
        opacity_scale.connect("value-changed", self._on_opacity_changed)
        opacity_box.append(opacity_scale)
        self.append(opacity_box)

        # Theme dropdown
        theme_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        theme_label = Gtk.Label(label="Theme")
        theme_label.set_halign(Gtk.Align.START)
        theme_box.append(theme_label)
        themes = ["default", "dark", "light", "high-contrast"]
        theme_dropdown = Gtk.DropDown.new_from_strings(themes)
        current_theme = self._config.get("status_bar.theme", "default")
        if current_theme in themes:
            theme_dropdown.set_selected(themes.index(current_theme))
        theme_dropdown.connect("notify::selected", self._on_theme_changed)
        theme_box.append(theme_dropdown)
        self.append(theme_box)

        info = Gtk.Label(label="Note: Restart indicator for changes to apply")
        info.add_css_class("dim-label")
        info.set_margin_top(10)
        self.append(info)

    def _on_position_changed(self, dropdown: Gtk.DropDown, _param: object) -> None:
        """Handle position dropdown change."""
        positions = ["top-right", "top-left", "bottom-right", "bottom-left"]
        selected = dropdown.get_selected()
        if 0 <= selected < len(positions):
            self._config.set("status_bar.position", positions[selected])

    def _on_size_changed(self, dropdown: Gtk.DropDown, _param: object) -> None:
        """Handle size dropdown change."""
        sizes = ["small", "medium", "large"]
        selected = dropdown.get_selected()
        if 0 <= selected < len(sizes):
            self._config.set("status_bar.size", sizes[selected])

    def _on_opacity_changed(self, scale: Gtk.Scale) -> None:
        """Handle opacity slider change."""
        self._config.set("status_bar.opacity", int(scale.get_value()))

    def _on_theme_changed(self, dropdown: Gtk.DropDown, _param: object) -> None:
        """Handle theme dropdown change."""
        themes = ["default", "dark", "light", "high-contrast"]
        selected = dropdown.get_selected()
        if 0 <= selected < len(themes):
            self._config.set("status_bar.theme", themes[selected])
