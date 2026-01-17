"""Wayland backend using XWayland compatibility mode.

This backend runs on Wayland sessions but uses XWayland for compatibility.
It provides the same functionality as X11Backend by forcing GTK to use X11
backend and relying on XWayland for X11 protocol support.

Limitations:
- Requires XWayland to be installed and running
- Some Wayland compositors may restrict certain features
- Native Wayland protocols are not used (future enhancement)
"""

from __future__ import annotations

import logging
import os

from .x11_backend import X11Backend

_logger = logging.getLogger(__name__)


class WaylandBackend(X11Backend):
    """Wayland backend with XWayland fallback.

    This backend inherits from X11Backend and forces GDK to use X11 mode,
    effectively running the app under XWayland on Wayland sessions.

    Environment Variables:
        GDK_BACKEND=x11: Forces GTK to use X11 backend
        QT_QPA_PLATFORM=xcb: Forces Qt to use X11 (if needed)

    Compatibility:
        - GNOME Wayland: Supported via XWayland
        - KDE Plasma Wayland: Supported via XWayland
        - Sway: Supported via XWayland
        - Other compositors: Depends on XWayland support

    Future:
        Native Wayland support via compositor-specific protocols
        (e.g., wlr-layer-shell, KDE protocols) is planned for v2.
    """

    def __init__(self) -> None:
        """Initialize Wayland backend with XWayland fallback.

        Sets environment variables to force X11 compatibility mode
        before initializing the parent X11Backend.
        """
        # Force GDK to use X11 backend for GTK apps
        os.environ["GDK_BACKEND"] = "x11"

        # Log Wayland detection and fallback
        _logger.warning(
            "Running in XWayland compatibility mode on Wayland session. "
            "This provides full functionality but may have slight latency. "
            "Native Wayland support is planned for future versions."
        )

        # Initialize parent X11Backend (uses pynput under XWayland)
        super().__init__()
        _logger.info("WaylandBackend initialized (using XWayland)")

    def start_listening(self) -> None:
        """Start hotkey listener with XWayland compatibility check."""
        try:
            super().start_listening()
        except Exception as e:
            _logger.error(
                "Failed to start hotkey listener on Wayland. "
                "Ensure XWayland is installed and running. Error: %s",
                e,
            )
            raise RuntimeError(
                "XWayland not available. Install xwayland package and restart compositor."
            ) from e

    def get_position(self) -> tuple[int, int]:
        """Get mouse position with XWayland compatibility note.

        Returns:
            Tuple of (x, y) coordinates

        Note:
            Under XWayland, position queries work correctly.
            On pure Wayland (without XWayland), this would fail.
        """
        try:
            return super().get_position()
        except Exception as e:
            _logger.error("Failed to get mouse position. XWayland may not be running: %s", e)
            raise RuntimeError("Cannot query mouse position without XWayland") from e
