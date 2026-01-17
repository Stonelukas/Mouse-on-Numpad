"""Backend abstraction for X11/Wayland input control.

This module provides a unified interface for mouse and keyboard control
across different display servers (X11, Wayland) with appropriate fallbacks.
"""

from __future__ import annotations

import logging
import os

from .base import InputBackend
from .evdev_backend import EvdevBackend
from .wayland_backend import WaylandBackend
from .x11_backend import X11Backend

_logger = logging.getLogger(__name__)

__all__ = [
    "InputBackend",
    "X11Backend",
    "WaylandBackend",
    "EvdevBackend",
    "get_backend",
]


def get_backend() -> InputBackend:
    """Auto-detect and return appropriate input backend.

    Detection order:
    1. Check XDG_SESSION_TYPE environment variable
    2. Check WAYLAND_DISPLAY for Wayland session
    3. Fallback to X11 backend
    4. If all fail, use evdev backend

    Returns:
        InputBackend instance appropriate for current session

    Example:
        >>> backend = get_backend()
        >>> backend.move_mouse(100, 100)
    """
    session_type = os.environ.get("XDG_SESSION_TYPE", "").lower()
    wayland_display = os.environ.get("WAYLAND_DISPLAY", "")

    # X11 session detected
    if session_type == "x11":
        _logger.info("X11 session detected, using X11Backend")
        return X11Backend()

    # Wayland session detected
    if session_type == "wayland" or wayland_display:
        _logger.warning(
            "Wayland session detected, falling back to XWayland compatibility mode. "
            "Some features may be limited. See docs/wayland-support.md for details."
        )
        # Force GDK to use X11 backend for GTK apps
        os.environ["GDK_BACKEND"] = "x11"
        return WaylandBackend()

    # Unknown session, try X11 backend
    _logger.warning(
        "Unknown session type '%s', attempting X11Backend. "
        "If this fails, evdev backend will be used.",
        session_type,
    )
    try:
        return X11Backend()
    except Exception as e:
        _logger.error("X11Backend failed: %s, falling back to evdev", e)
        return EvdevBackend()
