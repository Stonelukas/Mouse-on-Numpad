# Mouse on Numpad - Codebase Summary

**Project:** Control mouse cursor with numpad keys on Linux (Python + GTK4)
**Version:** 5.0.0 (Full-featured Linux implementation)
**Updated:** 2026-02-08
**Status:** Phases 1-5 COMPLETE (83%), Phase 6 Ready
**Repository:** https://github.com/Stonelukas/mouse-on-numpad

---

## Overview

Mouse on Numpad is a feature-complete Linux keyboard accessibility tool that maps numpad keys to mouse cursor movement, scrolling, and clicking. Written in Python 3.10+ with GTK4 GUI, evdev keyboard capture, and full Wayland/X11 support.

**Core Features:**
- evdev keyboard capture (works on Wayland/X11)
- Mouse movement with exponential acceleration
- Click handling (left/right/middle/drag)
- Scroll wheel emulation
- Per-monitor position memory
- Audio feedback system
- GTK4 settings GUI with 6 tabs
- Profile save/load system
- Status indicator overlay
- Multi-monitor support

---

## Project Structure

```
mouse-on-numpad/
├── src/mouse_on_numpad/           # Main Python package
│   ├── __init__.py                 # Package metadata
│   ├── __main__.py                 # python -m entry point
│   ├── main.py                     # CLI entry point
│   ├── app.py                      # GTK application coordinator
│   ├── tray_icon.py                # System tray icon
│   │
│   ├── core/                       # Configuration & state (Phase 1)
│   │   ├── __init__.py
│   │   ├── config.py              # JSON config persistence
│   │   ├── config_defaults.py     # Default config schema
│   │   ├── state_manager.py       # Observable state (thread-safe)
│   │   └── error_logger.py        # Rotating file logger
│   │
│   ├── daemon/                     # Keyboard & hotkey (Phase 1-2)
│   │   ├── __init__.py
│   │   ├── daemon_coordinator.py  # Main orchestrator
│   │   ├── keyboard_capture.py    # evdev event reader
│   │   ├── hotkey_dispatcher.py   # Key-to-action router
│   │   ├── hotkey_config.py       # Hotkey configuration
│   │   ├── ipc_manager.py         # Inter-process communication
│   │   ├── position_manager.py    # Position memory integration
│   │   └── mouse_factory.py       # Mouse controller abstraction
│   │
│   ├── input/                      # Mouse & audio control (Phase 2-3)
│   │   ├── __init__.py
│   │   ├── movement_controller.py # Numpad movement with acceleration
│   │   ├── scroll_controller.py   # Scroll wheel emulation
│   │   ├── mouse_controller.py    # Low-level mouse operations
│   │   ├── monitor_manager.py     # Multi-monitor detection
│   │   ├── display_detection.py   # Display server detection
│   │   ├── position_memory.py     # Cursor position storage
│   │   ├── audio_feedback.py      # Sine wave audio generation
│   │   ├── hotkey_manager.py      # Hotkey configuration interface
│   │   └── uinput_mouse.py        # uinput device wrapper
│   │
│   ├── backends/                   # Display server abstraction (Phase 5)
│   │   ├── __init__.py
│   │   ├── base.py                # Abstract backend interface
│   │   ├── x11_backend.py         # X11 implementation
│   │   ├── x11_helpers.py         # X11 helper functions
│   │   ├── wayland_backend.py     # Wayland implementation
│   │   └── evdev_backend.py       # Event device layer
│   │
│   └── ui/                         # GTK4 interface (Phase 4)
│       ├── __init__.py
│       ├── main_window.py         # Main settings window
│       ├── movement_tab.py        # Movement speed/acceleration
│       ├── audio_tab.py           # Audio settings
│       ├── hotkeys_tab.py         # Hotkey customization
│       ├── profiles_tab.py        # Profile save/load
│       ├── appearance_tab.py      # Theme & visual options
│       ├── advanced_tab.py        # Advanced options
│       ├── status_indicator.py    # Floating overlay window
│       ├── key_capture_button.py  # Hotkey capture widget
│       ├── keycode_mappings.py    # Keycode constants & names
│       └── save_profile_dialog.py # New profile dialog
│
├── tests/                          # Test suite
│   ├── test_config.py             # ConfigManager tests
│   ├── test_state_manager.py      # StateManager tests
│   ├── test_monitor_manager.py    # Monitor detection tests
│   └── ...                         # Additional tests
│
├── docs/                           # Documentation
│   ├── project-overview-pdr.md    # Product Development Requirements
│   ├── system-architecture.md     # Architecture documentation
│   ├── codebase-summary.md        # This file
│   ├── code-standards.md          # Code style & conventions
│   ├── README.md                  # User guide
│   ├── USAGE.md                   # Usage examples
│   ├── HOTKEYS.md                 # Hotkey reference
│   └── ...                         # Additional docs
│
├── pyproject.toml                  # uv package configuration
├── uv.lock                         # Dependency lock file
├── README.md                       # Main README
└── LICENSE                         # MIT License
```

---

## Core Modules

### Core Package (Phase 1)

#### config.py
**Purpose:** JSON-based configuration persistence with XDG compliance

**Key Features:**
- Stores config at `~/.config/mouse-on-numpad/config.json` (XDG Base Directory)
- Automatic backup (creates `.json.bak`) before writes
- Nested key access: `config.get("movement.base_speed")`
- Recursive default merging (preserves user customizations)
- Secure file permissions (0600 - user read/write only)
- Thread-safe via RLock

**Default Schema:**
```json
{
  "movement": {"base_speed": 5, "acceleration_rate": 1.08, "max_speed": 40},
  "audio": {"enabled": true, "volume": 50},
  "scroll": {"step": 3, "acceleration_rate": 1.1, "max_speed": 10},
  "status_bar": {"enabled": true, "position": "top-right", "opacity": 80},
  "hotkeys": {"toggle_mode": 78, "move_up": 72, ...},
  "profiles": {}
}
```

**Methods:**
- `get(key: str, default=None)` - Nested key access
- `set(key: str, value: Any)` - Update key with auto-save
- `get_all() -> dict` - Full config (deep copy)
- `reload()` - Reload from disk

#### config_defaults.py
Default configuration schema with all keys and types.

#### state_manager.py
**Purpose:** Observable application state with thread-safe notifications

**State Schema:**
- `is_enabled: bool` - Mouse mode on/off
- `numlock_state: bool` - NumLock key state
- `current_position: Tuple[int, int]` - Current mouse position
- `active_monitor: str` - Active monitor identifier
- `speed_multiplier: float` - Speed scale factor

**Methods:**
- `subscribe(key: str, callback: Callable)` - Register listener
- `unsubscribe(key: str, callback: Callable)` - Remove listener
- `toggle() -> bool` - Toggle mouse mode
- `get_snapshot() -> dict` - Thread-safe state snapshot

#### error_logger.py
**Purpose:** Structured logging with rotation and XDG compliance

**Features:**
- Logs to `~/.local/share/mouse-on-numpad/` (XDG Data Directory)
- Rotating file handler (5MB max, 3 backups)
- Log directory permissions 0700 (user only)
- Severity levels: DEBUG, INFO, WARNING, ERROR, EXCEPTION

**Methods:**
- `debug(message: str, *args)` - Debug level
- `info(message: str, *args)` - Info level
- `warning(message: str, *args)` - Warning level
- `error(message: str, *args)` - Error level (flushes immediately)
- `exception(message: str, *args)` - Exception with traceback

---

### Daemon Package (Phase 1-2)

#### daemon_coordinator.py
**Purpose:** Main orchestrator for keyboard monitoring and hotkey dispatching

**Key Features:**
- Starts keyboard capture threads (per device)
- Manages hotkey dispatch callbacks
- Tracks held mouse buttons and mode state
- Handles graceful shutdown (SIGINT, SIGTERM)
- System tray integration via tray_icon.py

**Lifecycle:**
```
start() → KeyboardCapture threads → HotkeyDispatcher callbacks
  ↓
Main loop (event loop, signal handling)
  ↓
stop() → Join threads, cleanup resources
```

#### keyboard_capture.py
**Purpose:** evdev keyboard event reading (works on Wayland/X11)

**Key Features:**
- Finds all keyboard devices in /dev/input/event*
- Thread-per-device architecture (isolates disconnections)
- Non-blocking event loop
- Handles device hotplug gracefully
- Input group permissions required

**Event Flow:**
```
/dev/input/event* → KeyboardCapture → (keycode, pressed) tuple → callback
```

#### hotkey_dispatcher.py
**Purpose:** Route keycodes to action handlers

**Key Features:**
- Config-driven keycodes (from config.json)
- Routes to: movement, scroll, clicks, mode toggles
- Support for modifiers (Ctrl, Shift, Alt)
- Extensible callback pattern

**Handlers:**
- Movement: MovementController.start_direction()
- Scroll: ScrollController.start_direction()
- Click: MouseController.click()
- Mode: StateManager.toggle()

#### hotkey_config.py
Hotkey configuration and keycode mapping utilities.

#### ipc_manager.py
**Purpose:** Inter-process communication

**Features:**
- Writes daemon status to `/tmp/mouse-on-numpad.status`
- Spawns status indicator subprocess
- Communicates daemon state to GUI

#### position_manager.py
**Purpose:** Position memory integration with daemon

**Features:**
- Integrates PositionMemory with keyboard capture
- Handles save/load hotkey actions
- Multi-slot support (5 slots per monitor)

#### mouse_factory.py
**Purpose:** Mouse controller abstraction

**Hierarchy:**
1. Try uinput device (native input, no X11 required)
2. Fallback to ydotool (works on Wayland/X11)
3. Display server detection

---

### Input Package (Phase 2-3)

#### movement_controller.py
**Purpose:** Numpad movement (8 directions)

**Key Features:**
- Thread-safe direction queue
- Exponential acceleration with configurable curve
- Adjustable base speed, max speed, acceleration rate
- Smooth diagonal movement support
- Movement loop with configurable delay

#### scroll_controller.py
**Purpose:** Mouse wheel emulation

**Key Features:**
- Numpad 7/9/1/3 for scroll directions
- Configurable step size and acceleration
- Simultaneous multi-direction scrolling
- Acceleration curve matching movement

#### mouse_controller.py
**Purpose:** Low-level mouse operations

**Methods:**
- `move_to(x: int, y: int)` - Absolute position
- `click(button: str, count: int)` - Click actions
- `hold_button(button: str)` - Start drag
- `release_button(button: str)` - End drag

**Display Server Agnostic:** Uses backend abstraction

#### monitor_manager.py
**Purpose:** Multi-monitor detection and management

**Key Features:**
- X11 RandR support (if available)
- Fallback to xrandr command output
- Monitor geometry (position, size, orientation)
- Primary display detection
- RANDR event tracking for dynamic config

**Methods:**
- `get_monitors() -> list[Monitor]` - All connected monitors
- `get_active_monitor() -> Monitor` - Current monitor
- `get_monitor_at_position(x, y) -> Monitor` - Monitor containing position

#### display_detection.py
**Purpose:** Display server detection (X11 vs Wayland)

**Features:**
- Detect WAYLAND_DISPLAY env var
- Check DISPLAY for X11
- Test XDG_SESSION_TYPE variable
- Return backend selector

#### position_memory.py
**Purpose:** Cursor position storage per-monitor

**Key Features:**
- JSON persistence (in ~/.config/)
- Per-monitor storage with unique IDs
- Monitor-relative offset storage
- Handles portrait/landscape orientations
- Atomic write operations (crash-safe)

**Data Structure:**
```json
{
  "HDMI-1": {"slot_1": [640, 480], "slot_2": [320, 240], ...},
  "DP-2": {"slot_1": [1920, 1080], ...}
}
```

#### audio_feedback.py
**Purpose:** Audio playback and sound generation

**Key Features:**
- Sine wave generation in Python (no external files)
- PulseAudio/ALSA abstraction via ossaudiodev
- Configurable volume (0-100%)
- Graceful fallback if audio unavailable
- Thread-safe playback

**Methods:**
- `play_tone(frequency: float, duration: float)` - Play sine wave
- `set_volume(volume: int)` - Set output volume
- `is_available() -> bool` - Check audio hardware

#### hotkey_manager.py
**Purpose:** High-level hotkey configuration interface

**Features:**
- Loads hotkey mappings from config.json
- Reverse mapping: keycode -> action
- Validates hotkey bindings
- Enables runtime hotkey customization

#### uinput_mouse.py
**Purpose:** uinput device wrapper for synthetic mouse events

**Features:**
- Opens `/dev/uinput` for mouse events
- Device capabilities negotiation
- Fallback-safe if uinput unavailable

---

### Backends Package (Phase 5)

#### base.py
**Purpose:** Abstract backend interface

**Methods (must implement):**
- `get_mouse_position() -> Tuple[int, int]` - Current cursor position
- `move_mouse(x: int, y: int)` - Move cursor
- `click(button: str, count: int)` - Click actions
- `get_monitors() -> list[Monitor]` - Connected monitors

#### x11_backend.py
**Purpose:** X11 support

**Features:**
- XTest extension for mouse events
- RandR for monitor detection
- XKB for keyboard handling
- Fallback for minimal X11 systems

#### x11_helpers.py
X11 helper functions (RandR parsing, XTest utilities).

#### wayland_backend.py
**Purpose:** Wayland support

**Features:**
- Portal APIs for data access
- DBus interfaces for system integration
- wl-paste for clipboard (if available)

#### evdev_backend.py
**Purpose:** Event device interface

**Features:**
- Direct /dev/input/event* reading
- Cross-server event capture
- Device hotplug handling

---

### UI Package (Phase 4)

#### main_window.py
**Purpose:** GTK4 application window coordinator

**Features:**
- Tabbed interface for settings (6 tabs)
- Window persistence (size, position)
- Real-time setting validation
- Daemon status display

#### movement_tab.py
Movement speed and acceleration settings UI.

**Controls:**
- Base speed slider (1-50 pixels/step)
- Acceleration curve selector (linear/exponential/s-curve)
- Max speed limit slider
- Preview/test movement button

#### audio_tab.py
Audio settings UI.

**Controls:**
- Enable/disable toggle
- Volume slider (0-100%)
- Test sound button

#### hotkeys_tab.py
Hotkey customization UI.

**Features:**
- Interactive key capture buttons
- Visual numpad layout
- Conflict detection
- Reset to defaults button

#### profiles_tab.py
Profile management UI.

**Features:**
- Save current config as named profile
- Load/delete saved profiles
- Profile list with metadata
- Import/export functionality

#### appearance_tab.py
Visual customization UI.

**Controls:**
- Theme selection (4+ themes)
- Status indicator position (4 corners)
- Status indicator size (small/medium/large)
- Opacity slider (0-100%)

#### advanced_tab.py
Advanced options UI.

**Controls:**
- Enable/disable per-monitor position memory
- Log level selection
- Cache cleanup button
- Experimental features

#### status_indicator.py
Floating overlay window (always on top).

**Features:**
- GTK Layer Shell integration (Wayland/X11)
- Persistent on top, no focus stealing
- Configurable position and size
- Auto-hide when mode disabled
- Real-time mode status display

#### key_capture_button.py
Reusable hotkey input widget.

**Features:**
- Toggle between display and capture modes
- Visual feedback during capture
- Displays keycode and human-readable key name
- Conflict detection on key release
- Escape key to cancel

#### keycode_mappings.py
Central registry of numpad keycodes and display names.

**Contents:**
- `HOTKEY_LABELS: dict` - Action names to UI labels
- `SLOT_KEY_LABELS: dict` - Position slots to labels
- `get_key_name(keycode: int) -> str` - Human-readable key name
- `KEY_DISPLAY_NAMES: dict` - Keycode to display name mappings

#### save_profile_dialog.py
Modal dialog for creating new profiles.

**Features:**
- Text input for profile name
- Validation and confirmation
- Cancel button

---

### Entry Points

#### main.py
CLI entry point with argument parsing.

**Flags:**
- `--daemon` - Start background daemon
- `--settings` - Open settings GUI
- `--status` - Show current mouse mode
- `--toggle` - Toggle mouse mode on/off
- `--indicator` - Show floating status indicator
- `--debug` - Enable debug logging
- `--version` - Display version
- `--help` - Show help

#### __main__.py
Python module entry point for `python -m mouse_on_numpad`.

#### app.py
GTK application coordinator.

#### tray_icon.py
System tray icon integration.

---

## Threading Model

| Thread | Purpose | Lifecycle |
|--------|---------|-----------|
| **Main** | GUI event loop, configuration | Process lifetime |
| **KeyboardCapture (1+)** | Read device events (per device) | Daemon start → stop |
| **MovementController** | Execute movement at interval | Created on first movement, reused |
| **ScrollController** | Execute scroll at interval | Created on first scroll, reused |
| **StatusIndicator** | Overlay window rendering | GUI start → stop |

All threads synchronized via:
- `threading.RLock` on state access
- `threading.Event` for direction changes
- Graceful shutdown with flag checks

---

## File Locations

| Purpose | Location | Type |
|---------|----------|------|
| Config | `~/.config/mouse-on-numpad/config.json` | JSON |
| Positions | `~/.config/mouse-on-numpad/positions.json` | JSON |
| Logs | `~/.local/share/mouse-on-numpad/app.log` | Rotating text |
| Status IPC | `/tmp/mouse-on-numpad.status` | Text (ephemeral) |
| Desktop entry | `~/.local/share/applications/mouse-on-numpad.desktop` | .desktop |

---

## Dependencies

### Core Runtime (pyproject.toml)
- **PyGObject** (3.44.0+) - GTK4 bindings
- **evdev** (1.6.0+) - Keyboard input capture
- **python-xlib** (0.33+) - X11 protocol access
- **pulsectl** (23.5.0+) - Audio control (optional)

### Development
- **pytest** (7.0.0+) - Testing framework
- **pytest-cov** (4.0.0+) - Coverage reporting
- **ruff** (0.1.0+) - Linting and formatting
- **mypy** (1.0.0+) - Type checking
- **hatchling** (1.10.0+) - Build system

**Python Version:** 3.10+ (3.11, 3.12 tested)

---

## Testing

**Test Coverage:** 80%+ across all modules

**Test Files:**
- `tests/test_config.py` - ConfigManager functionality
- `tests/test_state_manager.py` - StateManager & observer pattern
- `tests/test_monitor_manager.py` - Monitor detection

**Run Tests:**
```bash
uv run pytest                          # All tests
uv run pytest --cov=src/              # With coverage
uv run pytest tests/test_config.py -v # Specific file
```

---

## Build & Installation

### From Source
```bash
# Install package in editable mode
uv pip install -e .

# Or use uv run directly
uv run python -m mouse_on_numpad --status
```

### Build Distribution
```bash
# Build wheel
uv build

# Creates:
# - dist/mouse_on_numpad-*.whl
# - dist/mouse_on_numpad-*.tar.gz
```

---

## Key Design Decisions

**Why evdev for keyboard?**
- Works on Wayland without X11 compatibility layer
- Direct kernel event stream, lowest latency
- Requires input group membership

**Why uinput for mouse?**
- Display server agnostic (Wayland/X11/hybrid)
- Native input device, minimal dependencies

**Why thread-per-device?**
- Allows monitoring multiple keyboards simultaneously
- Isolates device disconnection to single thread

**Why GTK4 + Layer Shell?**
- Modern toolkit with Wayland support
- Layer Shell enables always-on-top overlay

**Why JSON over INI/TOML?**
- Nested configuration support
- Native Python dict serialization
- Atomic write operations

---

## Error Handling

| Component | Error | Recovery |
|-----------|-------|----------|
| KeyboardCapture | No devices found | Fail fast with user message |
| KeyboardCapture | Device disconnected | Exit thread silently |
| MouseController | uinput unavailable | Fallback to ydotool |
| ConfigManager | File corrupted | Load defaults, preserve backup |
| AudioFeedback | PulseAudio unavailable | Skip audio, log warning |
| MonitorManager | No monitors detected | Use fallback (0,0 as primary) |

---

## Performance Targets

| Metric | Target | Status |
|--------|--------|--------|
| Input latency | <10ms | ✓ Achieved via evdev |
| Idle CPU | <5% | ✓ Blocking reads |
| Memory | <50MB | ✓ Minimal deps |
| Config load | <100ms | ✓ Lazy loading |
| GUI startup | <1s | ✓ Lazy imports |

---

## Known Issues & Limitations

None known for core functionality (Phases 1-5 complete).

**Phase 6 (Distribution) Planned:**
- RPM/DEB package creation
- AppImage build
- AUR packaging
- Release versioning

---

## Code Quality Metrics

- **Type Coverage:** 100% (mypy strict mode)
- **Test Pass Rate:** 100% (80%+ code coverage)
- **Linting:** Clean (ruff)
- **Security:** No critical issues
- **Standards:** YAGNI/KISS/DRY compliant

---

## References

- **README:** User guide and quick start
- **System Architecture:** `docs/system-architecture.md`
- **PDR (Requirements):** `docs/project-overview-pdr.md`
- **Code Standards:** `docs/code-standards.md`
- **HOTKEYS Reference:** `docs/HOTKEYS.md`

---

**Last Generated:** 2026-02-08
**Total LOC:** ~4,500 (src/) + ~500 (tests/) + ~800 (docs/)
