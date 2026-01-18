"""Floating status indicator using Wayland layer shell."""

from pathlib import Path

import gi  # type: ignore[import-untyped]

gi.require_version("Gtk", "4.0")
gi.require_version("Gtk4LayerShell", "1.0")
from gi.repository import Gtk, GLib, Gdk, Gtk4LayerShell  # type: ignore[import-untyped]

from ..core.config import ConfigManager

STATUS_FILE = Path("/tmp/mouse-on-numpad-status")

# Size presets: font-size in px
SIZE_PRESETS = {"small": 11, "medium": 14, "large": 20}

# Theme color presets: (bg_color, text_color)
THEME_PRESETS = {
    "default": ("#22c55e", "#ffffff"),      # Green/white
    "dark": ("#374151", "#f3f4f6"),         # Dark gray/light
    "light": ("#e5e7eb", "#1f2937"),        # Light gray/dark
    "high-contrast": ("#000000", "#ffff00"), # Black/yellow
}


class StatusIndicator(Gtk.Window):  # type: ignore[misc]
    """Layer shell overlay indicator for mouse mode status."""

    def __init__(self) -> None:
        super().__init__()
        self._enabled = False
        self._config = ConfigManager()

        # Layer shell setup - MUST be before window is realized
        Gtk4LayerShell.init_for_window(self)
        Gtk4LayerShell.set_namespace(self, "mouse-on-numpad")
        Gtk4LayerShell.set_layer(self, Gtk4LayerShell.Layer.OVERLAY)
        Gtk4LayerShell.set_exclusive_zone(self, -1)
        Gtk4LayerShell.set_keyboard_mode(self, Gtk4LayerShell.KeyboardMode.NONE)

        # Apply position from config
        self._apply_position()

        # UI
        self._label = Gtk.Label(label="Mouse: ON")
        self._label.set_margin_top(8)
        self._label.set_margin_bottom(8)
        self._label.set_margin_start(14)
        self._label.set_margin_end(14)
        self.set_child(self._label)

        self._apply_styles()

        # Start polling
        GLib.timeout_add(100, self._poll_status)

    def _apply_position(self) -> None:
        """Apply position from config."""
        pos = self._config.get("status_bar.position", "top-right")
        margin = 10

        # Reset anchors
        for edge in [Gtk4LayerShell.Edge.TOP, Gtk4LayerShell.Edge.BOTTOM,
                     Gtk4LayerShell.Edge.LEFT, Gtk4LayerShell.Edge.RIGHT]:
            Gtk4LayerShell.set_anchor(self, edge, False)

        # Set position anchors
        if "top" in pos:
            Gtk4LayerShell.set_anchor(self, Gtk4LayerShell.Edge.TOP, True)
            Gtk4LayerShell.set_margin(self, Gtk4LayerShell.Edge.TOP, margin)
        else:
            Gtk4LayerShell.set_anchor(self, Gtk4LayerShell.Edge.BOTTOM, True)
            Gtk4LayerShell.set_margin(self, Gtk4LayerShell.Edge.BOTTOM, margin)

        if "right" in pos:
            Gtk4LayerShell.set_anchor(self, Gtk4LayerShell.Edge.RIGHT, True)
            Gtk4LayerShell.set_margin(self, Gtk4LayerShell.Edge.RIGHT, margin)
        else:
            Gtk4LayerShell.set_anchor(self, Gtk4LayerShell.Edge.LEFT, True)
            Gtk4LayerShell.set_margin(self, Gtk4LayerShell.Edge.LEFT, margin)

    def _apply_styles(self) -> None:
        """Apply size, opacity and theme from config."""
        size = self._config.get("status_bar.size", "medium")
        opacity = self._config.get("status_bar.opacity", 80) / 100.0
        theme = self._config.get("status_bar.theme", "default")
        font_size = SIZE_PRESETS.get(size, 14)
        bg_color, text_color = THEME_PRESETS.get(theme, THEME_PRESETS["default"])

        # Convert hex to rgba
        r, g, b = int(bg_color[1:3], 16), int(bg_color[3:5], 16), int(bg_color[5:7], 16)

        css = Gtk.CssProvider()
        css.load_from_data(f"""
            window {{
                background-color: rgba({r}, {g}, {b}, {opacity});
                border-radius: 8px;
            }}
            label {{
                color: {text_color};
                font-weight: bold;
                font-size: {font_size}px;
            }}
        """.encode())
        display = Gdk.Display.get_default()
        if display:
            Gtk.StyleContext.add_provider_for_display(
                display, css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            )

    def _poll_status(self) -> bool:
        try:
            if STATUS_FILE.exists():
                enabled = STATUS_FILE.read_text().strip() == "enabled"
            else:
                enabled = False
            self._update(enabled)
        except OSError:
            pass
        return True

    def _update(self, enabled: bool) -> None:
        if enabled == self._enabled:
            return
        self._enabled = enabled
        self._label.set_label("Mouse: ON" if enabled else "Mouse: OFF")
        self.set_visible(enabled)
