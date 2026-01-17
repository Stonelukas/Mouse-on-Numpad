# Usage and Setup

## Requirements
- Python 3.10+
- Linux (X11/Wayland)
- Numpad keyboard
- Optional: `ydotool` for fallback mouse control (if UInput unavailable)

## Installation

Install from source:
```bash
uv pip install -e .
```

Or system-wide:
```bash
pip install mouse-on-numpad
```

## Quick Start

1. **Start the daemon:**
```bash
mouse-on-numpad --daemon
```

2. **Toggle mouse mode:**
```bash
mouse-on-numpad --toggle
```

3. **Check status:**
```bash
mouse-on-numpad --status
```

## Configuration

Config file location: `~/.config/mouse-on-numpad/config.json`

### Default Configuration
```json
{
  "movement": {
    "base_speed": 5,
    "acceleration_rate": 1.08,
    "max_speed": 40,
    "move_delay": 20
  },
  "scroll": {
    "step": 3,
    "acceleration_rate": 1.1,
    "max_speed": 10,
    "delay": 30
  },
  "audio": {
    "enabled": true,
    "volume": 50
  },
  "status_bar": {
    "enabled": true,
    "position": "top-right",
    "auto_hide": true
  }
}
```

### Scroll Configuration
| Setting | Default | Purpose |
|---------|---------|---------|
| `scroll.step` | 3 | Base scroll amount per tick |
| `scroll.acceleration_rate` | 1.1 | Exponential multiplier while held |
| `scroll.max_speed` | 10 | Maximum scroll speed multiplier |
| `scroll.delay` | 30 | Milliseconds between scroll ticks |

**Note:** Edit config.json directly and the daemon will pick up changes on next key press.

## Usage Examples

### Enable Mouse Mode
```bash
mouse-on-numpad --toggle on
```

### Adjust Scroll Speed
Edit `~/.config/mouse-on-numpad/config.json`:
```json
{
  "scroll": {
    "step": 5,
    "max_speed": 15
  }
}
```

### View Logs
```bash
tail -f ~/.local/share/mouse-on-numpad/logs/mouse_on_numpad.log
```

## Features

### Movement
- Numpad 8/2/4/6: Cardinal direction movement (up/down/left/right)
- Numpad 7/9/1/3: Diagonal movement via multi-key hold
- Exponential acceleration while keys held

### Scrolling (Phase 1)
- Numpad 7: Scroll up
- Numpad 1: Scroll down
- Numpad 9: Scroll right (horizontal)
- Numpad 3: Scroll left (horizontal)
- Exponential acceleration support
- Horizontal scrolling support for compatibility

### Clicking
- Numpad 5: Left click
- Numpad 0: Right click
- Numpad Enter: Middle click

### Position Memory (Phase 2+)
- Numpad *: Enter save mode
- Numpad -: Enter load mode
- Numpad 1-9: Save/load position slots

## File Locations

| Purpose | Path | Permissions |
|---------|------|-------------|
| Configuration | `~/.config/mouse-on-numpad/config.json` | 0600 (user only) |
| Config backup | `~/.config/mouse-on-numpad/config.json.bak` | 0600 |
| Logs | `~/.local/share/mouse-on-numpad/logs/` | 0700 (user only) |
| Status IPC | `/tmp/mouse-on-numpad-status` | 0644 |

## Troubleshooting

**Daemon won't start:**
1. Check logs: `tail ~/.local/share/mouse-on-numpad/logs/mouse_on_numpad.log`
2. Verify evdev access: `ls -la /dev/input/event*`
3. Add user to input group: `sudo usermod -a -G input $USER`

**Scroll not working:**
1. Check scroll config in `~/.config/mouse-on-numpad/config.json`
2. Verify keycode mapping in logs
3. Test ydotool: `ydotool mousemove --wheel -y 5`

**Mouse mode won't toggle:**
1. Check if daemon is running: `ps aux | grep mouse-on-numpad`
2. Restart daemon: `pkill -f mouse-on-numpad; mouse-on-numpad --daemon`

## Initialization Order

The daemon initializes in this order:
1. ConfigManager loads `~/.config/mouse-on-numpad/config.json`
2. ErrorLogger sets up logging to `~/.local/share/mouse-on-numpad/logs/`
3. StateManager initializes observable state
4. Input system (evdev keyboard capture) starts
5. Mouse controller (UInput or ydotool fallback) initializes
6. Tray icon and status indicator (if GTK available)

## Performance Notes

- **Movement:** Uses exponential acceleration (configurable curve)
- **Scroll:** Separate thread for continuous scrolling with acceleration
- **Input:** evdev provides zero-overhead key capture (works on Wayland)
- **Memory:** ~30-50 MB resident (with GTK UI)

## See Also

- [HOTKEYS.md](./HOTKEYS.md) - Complete hotkey reference
- [API.md](./API.md) - Python API documentation
- [system-architecture.md](./system-architecture.md) - Architecture details
