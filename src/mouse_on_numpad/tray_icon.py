"""System tray icon for mouse mode status indication using GTK4 + Gio.Notification."""

from typing import Callable

import gi  # type: ignore[import-untyped]

gi.require_version("Gtk", "4.0")
from gi.repository import Gio  # type: ignore[import-untyped]


class TrayIcon:
    """System tray notification for mouse mode state.

    Uses Gio.Notification (GTK4-native, no pystray/GTK3 conflict).
    Shows desktop notifications on state change.
    """

    NOTIFICATION_ID = "mouse-on-numpad-status"

    def __init__(
        self,
        on_toggle: Callable[[], None] | None = None,
        on_quit: Callable[[], None] | None = None,
    ) -> None:
        self._enabled = False
        self._on_toggle = on_toggle
        self._on_quit = on_quit
        self._app: Gio.Application | None = None

    def _get_app(self) -> Gio.Application | None:
        """Get the default GApplication for sending notifications."""
        if self._app:
            return self._app
        self._app = Gio.Application.get_default()
        return self._app

    def update(self, enabled: bool) -> None:
        """Update state and send desktop notification.

        Args:
            enabled: New mouse mode state
        """
        self._enabled = enabled
        app = self._get_app()
        if not app:
            return

        try:
            notification = Gio.Notification.new("Mouse on Numpad")
            status = "ENABLED" if enabled else "DISABLED"
            icon_name = "input-mouse" if enabled else "input-mouse-symbolic"
            notification.set_body(f"Mouse mode: {status}")
            notification.set_icon(Gio.ThemedIcon.new(icon_name))
            notification.set_priority(Gio.NotificationPriority.LOW)
            app.send_notification(self.NOTIFICATION_ID, notification)
        except Exception:
            pass  # Notification not critical

    def start(self) -> None:
        """Start tray icon (no-op — notifications sent on demand)."""
        pass

    def stop(self) -> None:
        """Withdraw any active notification."""
        app = self._get_app()
        if app:
            try:
                app.withdraw_notification(self.NOTIFICATION_ID)
            except Exception:
                pass
