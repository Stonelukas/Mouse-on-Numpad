"""Profiles tab for saving and loading configuration profiles."""

import gi  # type: ignore[import-untyped]

gi.require_version("Gtk", "4.0")
from gi.repository import Gtk  # type: ignore[import-untyped]

from ..core.config import ConfigManager


class ProfilesTab(Gtk.Box):  # type: ignore[misc]
    """Tab widget for managing configuration profiles."""

    def __init__(self, config: ConfigManager) -> None:
        """Initialize profiles tab.

        Args:
            config: Configuration manager instance
        """
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        self._config = config

        self.set_margin_top(20)
        self.set_margin_bottom(20)
        self.set_margin_start(20)
        self.set_margin_end(20)

        # Title
        title = Gtk.Label(label="Configuration Profiles")
        title.add_css_class("title-2")
        self.append(title)

        # Description
        desc = Gtk.Label(
            label="Save your settings as profiles for different use cases"
        )
        desc.add_css_class("dim-label")
        self.append(desc)

        # Profile selector section
        selector_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        selector_box.set_margin_top(10)

        selector_label = Gtk.Label(label="Active Profile:")
        selector_label.set_halign(Gtk.Align.START)
        selector_box.append(selector_label)

        self._profile_dropdown = Gtk.DropDown()
        self._profile_dropdown.set_hexpand(True)
        self._refresh_profiles_list()
        self._profile_dropdown.connect("notify::selected", self._on_profile_selected)
        selector_box.append(self._profile_dropdown)

        self.append(selector_box)

        # Action buttons row
        buttons_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        buttons_box.set_halign(Gtk.Align.CENTER)
        buttons_box.set_margin_top(20)

        save_btn = Gtk.Button(label="Save As...")
        save_btn.connect("clicked", self._on_save_clicked)
        buttons_box.append(save_btn)

        delete_btn = Gtk.Button(label="Delete")
        delete_btn.add_css_class("destructive-action")
        delete_btn.connect("clicked", self._on_delete_clicked)
        buttons_box.append(delete_btn)

        self.append(buttons_box)

        # Info section
        info_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        info_box.set_margin_top(30)

        info_title = Gtk.Label(label="Profile Tips")
        info_title.set_halign(Gtk.Align.START)
        info_title.add_css_class("heading")
        info_box.append(info_title)

        tips = [
            "• Create a 'gaming' profile with higher speeds",
            "• Use 'precision' for detailed work",
            "• Profiles include all settings (movement, hotkeys, etc.)",
        ]
        for tip in tips:
            tip_label = Gtk.Label(label=tip)
            tip_label.set_halign(Gtk.Align.START)
            tip_label.add_css_class("dim-label")
            info_box.append(tip_label)

        self.append(info_box)

    def _refresh_profiles_list(self) -> None:
        """Refresh the profiles dropdown with current profiles."""
        profiles = self._config.list_profiles()
        if not profiles:
            profiles = ["(No profiles saved)"]
            model = Gtk.StringList.new(profiles)
            self._profile_dropdown.set_model(model)
            self._profile_dropdown.set_sensitive(False)
        else:
            model = Gtk.StringList.new(profiles)
            self._profile_dropdown.set_model(model)
            self._profile_dropdown.set_sensitive(True)

    def _on_profile_selected(
        self, dropdown: Gtk.DropDown, _param: object
    ) -> None:
        """Handle profile selection from dropdown."""
        profiles = self._config.list_profiles()
        if not profiles:
            return

        selected_idx = dropdown.get_selected()
        if 0 <= selected_idx < len(profiles):
            profile_name = profiles[selected_idx]
            if self._config.load_profile(profile_name):
                self._show_message(f"Loaded profile: {profile_name}")
            else:
                self._show_message(f"Failed to load profile: {profile_name}")

    def _on_save_clicked(self, _button: Gtk.Button) -> None:
        """Handle Save As button click."""
        dialog = SaveProfileDialog(self._config, self._on_save_complete)
        dialog.set_transient_for(self.get_root())
        dialog.present()

    def _on_save_complete(self, name: str) -> None:
        """Called when profile is saved."""
        self._refresh_profiles_list()
        # Select the newly saved profile
        profiles = self._config.list_profiles()
        if name in profiles:
            self._profile_dropdown.set_selected(profiles.index(name))
        self._show_message(f"Saved profile: {name}")

    def _on_delete_clicked(self, _button: Gtk.Button) -> None:
        """Handle Delete button click."""
        profiles = self._config.list_profiles()
        if not profiles:
            return

        selected_idx = self._profile_dropdown.get_selected()
        if 0 <= selected_idx < len(profiles):
            profile_name = profiles[selected_idx]
            if self._config.delete_profile(profile_name):
                self._show_message(f"Deleted profile: {profile_name}")
                self._refresh_profiles_list()
            else:
                self._show_message(f"Failed to delete: {profile_name}")

    def _show_message(self, message: str) -> None:
        """Show a brief message to the user."""
        dialog = Gtk.AlertDialog(message=message)
        root = self.get_root()
        if root:
            dialog.show(root)


class SaveProfileDialog(Gtk.Window):  # type: ignore[misc]
    """Dialog for saving a profile with a name."""

    def __init__(
        self, config: ConfigManager, on_complete: callable
    ) -> None:
        """Initialize save profile dialog.

        Args:
            config: Configuration manager
            on_complete: Callback with profile name when saved
        """
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
