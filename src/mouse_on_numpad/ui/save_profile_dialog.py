"""Dialog for saving a configuration profile with a name."""

from typing import Callable

import gi  # type: ignore[import-untyped]

gi.require_version("Gtk", "4.0")
from gi.repository import Gtk  # type: ignore[import-untyped]

from ..core.config import ConfigManager


class SaveProfileDialog(Gtk.Window):  # type: ignore[misc]
    """Dialog for saving a profile with a name."""

    def __init__(
        self, config: ConfigManager, on_complete: Callable[[str], None]
    ) -> None:
        super().__init__(title="Save Profile")
        self._config = config
        self._on_complete = on_complete

        self.set_default_size(300, 150)
        self.set_modal(True)

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        box.set_margin_top(20)
        box.set_margin_bottom(20)
        box.set_margin_start(20)
        box.set_margin_end(20)

        label = Gtk.Label(label="Enter profile name:")
        label.set_halign(Gtk.Align.START)
        box.append(label)

        self._entry = Gtk.Entry()
        self._entry.set_placeholder_text("e.g., gaming, precision")
        self._entry.connect("activate", self._on_save)
        box.append(self._entry)

        buttons_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        buttons_box.set_halign(Gtk.Align.END)
        buttons_box.set_margin_top(10)

        cancel_btn = Gtk.Button(label="Cancel")
        cancel_btn.connect("clicked", lambda _: self.close())
        buttons_box.append(cancel_btn)

        save_btn = Gtk.Button(label="Save")
        save_btn.add_css_class("suggested-action")
        save_btn.connect("clicked", self._on_save)
        buttons_box.append(save_btn)

        box.append(buttons_box)
        self.set_child(box)

    def _on_save(self, _widget: Gtk.Widget) -> None:
        """Handle save button or enter key."""
        name = self._entry.get_text().strip()
        if not name:
            return

        self._config.save_profile(name)
        self._on_complete(name)
        self.close()
