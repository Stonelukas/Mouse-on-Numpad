"""Display server detection and monitor querying logic."""

import logging
from typing import TypedDict

from Xlib import display
from Xlib.ext import randr

_logger = logging.getLogger(__name__)


class MonitorInfo(TypedDict):
    """Monitor information dictionary."""

    index: int
    name: str
    x: int
    y: int
    width: int
    height: int
    is_primary: bool


def query_monitors_xrandr(
    disp: display.Display, screen, root
) -> list[MonitorInfo]:
    """Query monitors using Xrandr.

    Args:
        disp: X11 display connection
        screen: X11 screen object
        root: Root window

    Returns:
        List of MonitorInfo dictionaries
    """
    try:
        # Get screen resources
        resources = randr.get_screen_resources(root)

        # Get primary output
        primary_output = randr.get_output_primary(root).output

        monitors = []
        for i, output in enumerate(resources.outputs):
            try:
                output_info = randr.get_output_info(
                    root, output, resources.config_timestamp
                )

                # Skip disconnected outputs
                if output_info.connection != randr.Connected:
                    continue

                # Get CRTC info for geometry
                if output_info.crtc:
                    crtc_info = randr.get_crtc_info(
                        root, output_info.crtc, resources.config_timestamp
                    )

                    monitor: MonitorInfo = {
                        "index": i,
                        "name": output_info.name,
                        "x": crtc_info.x,
                        "y": crtc_info.y,
                        "width": crtc_info.width,
                        "height": crtc_info.height,
                        "is_primary": output == primary_output,
                    }
                    monitors.append(monitor)

            except Exception:
                _logger.exception("Failed to query output %d", i)

        if monitors:
            _logger.info("Detected %d monitors", len(monitors))
            return monitors

        # Fallback if no monitors detected
        _logger.warning("No monitors detected, using fallback")
        return [create_fallback_monitor(screen)]

    except Exception:
        _logger.exception("Failed to query monitors, using fallback")
        return [create_fallback_monitor(screen)]


def create_fallback_monitor(screen) -> MonitorInfo:
    """Create fallback monitor info from screen dimensions.

    Args:
        screen: X11 screen object

    Returns:
        MonitorInfo dictionary with screen dimensions
    """
    return {
        "index": 0,
        "name": "default",
        "x": 0,
        "y": 0,
        "width": screen.width_in_pixels,
        "height": screen.height_in_pixels,
        "is_primary": True,
    }
