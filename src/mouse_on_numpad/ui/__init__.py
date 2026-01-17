"""GTK 4 GUI components for Mouse on Numpad."""

from .main_window import MainWindow
from .status_indicator import StatusIndicator
from .hotkeys_tab import HotkeysTab
from .key_capture_button import KeyCaptureButton
from .keycode_mappings import get_key_name, HOTKEY_LABELS, SLOT_KEY_LABELS

__all__ = [
    "MainWindow",
    "StatusIndicator",
    "HotkeysTab",
    "KeyCaptureButton",
    "get_key_name",
    "HOTKEY_LABELS",
    "SLOT_KEY_LABELS",
]

# TrayIcon uses pystray (GTK 3) and lives in mouse_on_numpad.tray_icon
# to avoid GTK version conflict. Import directly:
# from mouse_on_numpad.tray_icon import TrayIcon
