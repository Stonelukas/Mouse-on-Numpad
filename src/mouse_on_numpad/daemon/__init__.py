"""Daemon package for mouse-on-numpad.

Provides backward compatibility for existing imports:
    from .daemon import Daemon
"""

from .daemon_coordinator import Daemon

__all__ = ["Daemon"]
