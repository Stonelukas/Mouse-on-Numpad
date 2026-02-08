# Mouse on Numpad Enhanced

A Python/Linux tool that enables precise mouse control using numpad keys with multi-monitor support, Wayland/X11 compatibility, configurable hotkeys, and a GTK4 settings GUI.

## Features

- **Numpad Mouse Control**: Use numpad keys to move mouse, scroll, and click
- **Multi-Monitor Support**: Switch between monitors and store positions per monitor
- **Wayland & X11**: Works with both display servers via evdev keyboard capture
- **Configuration Profiles**: Save and load different control profiles
- **Status Indicator**: Floating overlay showing mouse mode status
- **Audio Feedback**: Optional audio cues for mode toggles and actions
- **Position Memory**: Save/load cursor positions to 5 slots per monitor
- **Daemon Mode**: Runs as background service with system tray integration
- **Configurable Hotkeys**: Remap any numpad key via GUI settings
- **Movement Acceleration**: Smooth acceleration curves for precise control

## Quick Start

### Installation

Requires Python 3.10+, GTK4, and input group access:

```bash
# Install from source
git clone https://github.com/mouse-on-numpad/mouse-on-numpad
cd mouse-on-numpad
uv pip install -e .

# Install system dependencies (Arch)
sudo pacman -S gtk4 libgtk-4-1 libgtk4-layer-shell

# Fedora
sudo dnf install gtk4 libgtk4-layer-shell

# Ubuntu/Debian
sudo apt install libgtk-4-1 libgtk4-layer-shell

# Add user to input group (required for keyboard capture)
sudo usermod -aG input $USER
# Log out and log back in for group change to take effect
```

### Usage

```bash
# Start daemon (background mode with system tray)
mouse-on-numpad --daemon

# Open settings GUI
mouse-on-numpad --settings

# Show current status
mouse-on-numpad --status

# Toggle mouse mode on/off
mouse-on-numpad --toggle

# Show floating status indicator
mouse-on-numpad --indicator

# Enable debug logging
mouse-on-numpad --daemon --debug
```

## Key Bindings

All bindings are customizable in the Settings GUI. Defaults:

### Movement & Scrolling
- Numpad 8/2/4/6: Move mouse up/down/left/right
- Numpad 7/9/1/3: Scroll up/down/right/left
- Numpad+: Toggle mouse control mode
- Numpad*: Enter position save mode

### Clicking
- Numpad 5: Left click
- Numpad 0: Right click
- Numpad Enter: Middle click
- Numpad.: Hold left button (drag)

### Position Memory
- In save mode, press 4/5/6 (top row) or 8/0 to save position to slot 1-5
- In load mode, press same keys to restore saved positions
- Alt+Numpad9: Cycle to next monitor

### Special Actions
- Numpad/: Undo last movement
- Numpad-: Enter position load mode

## Architecture

```
src/mouse_on_numpad/
├── core/              # Configuration & state management
│   ├── config.py      # Settings loading/saving
│   ├── state_manager.py # Runtime state
│   └── error_logger.py  # Logging
│
├── daemon/            # Keyboard capture & hotkey dispatching
│   ├── keyboard_capture.py  # evdev device monitoring
│   ├── hotkey_dispatcher.py # Key action routing
│   ├── daemon_coordinator.py # Main daemon loop
│   └── ipc_manager.py       # Status communication
│
├── input/             # Mouse & cursor control
│   ├── movement_controller.py    # Numpad movement
│   ├── scroll_controller.py      # Scroll wheel
│   ├── monitor_manager.py        # Multi-monitor detection
│   ├── position_memory.py        # Save/load positions
│   ├── audio_feedback.py         # Sound effects
│   └── uinput_mouse.py          # uinput device wrapper
│
├── backends/          # Display server abstraction
│   ├── x11_backend.py     # X11 support
│   ├── wayland_backend.py # Wayland support
│   └── evdev_backend.py   # evdev keyboard capture
│
└── ui/                # GTK4 settings interface
    ├── main_window.py         # Main settings window
    ├── hotkeys_tab.py         # Hotkey configuration
    ├── movement_tab.py        # Movement settings
    ├── profiles_tab.py        # Profile management
    ├── appearance_tab.py      # UI customization
    ├── advanced_tab.py        # Advanced options
    └── status_indicator.py    # Floating overlay indicator
```

## Configuration

Settings stored in `~/.config/mouse-on-numpad/config.json`:

```json
{
  "movement": {
    "base_speed": 5,
    "acceleration_rate": 1.08,
    "max_speed": 40,
    "move_delay": 20,
    "curve": "exponential"
  },
  "audio": {
    "enabled": true,
    "volume": 50
  },
  "status_bar": {
    "enabled": true,
    "position": "top-right",
    "size": "medium",
    "opacity": 80
  },
  "hotkeys": {
    "toggle_mode": 78,
    "move_up": 72,
    "move_down": 80
  }
}
```

## Development

### Build & Test

```bash
# Install dev dependencies
uv sync

# Run tests
python -m pytest tests/

# Run linter
ruff check src/

# Format code
ruff format src/

# Type check
mypy src/
```

### Project Structure Notes

- Uses `uv` as package manager (fast, batteries-included)
- Follows PEP 8 with Black formatting
- Type hints throughout codebase
- Modular design with clear separation of concerns
- No external GUI dependencies except GTK4

## Troubleshooting

### "No keyboard devices found"
- Ensure user is in `input` group: `groups $USER | grep input`
- If missing, run `sudo usermod -aG input $USER` and log out/in

### Mouse not moving
- Check if mouse mode is enabled: `mouse-on-numpad --status`
- Toggle with `mouse-on-numpad --toggle`
- Verify hotkey mappings in settings GUI

### Daemon won't start
- Check logs: `mouse-on-numpad --daemon --debug`
- Ensure GTK4 is installed: `pkg-config --modversion gtk4`
- On Wayland, check `$WAYLAND_DISPLAY` is set

### Settings not applied
- Restart daemon: `killall -9 mouse-on-numpad && mouse-on-numpad --daemon`
- Check config file permissions: `ls -la ~/.config/mouse-on-numpad/`

## Contributing

Contributions welcome! Please:
1. Follow existing code style (Black, ruff lint)
2. Add tests for new features
3. Update documentation
4. Test on both X11 and Wayland

## License

MIT License - see LICENSE file for details

## References

- Main entry point: `src/mouse_on_numpad/main.py`
- Configuration defaults: `src/mouse_on_numpad/core/config_defaults.py`
- Full documentation: See `docs/` directory
