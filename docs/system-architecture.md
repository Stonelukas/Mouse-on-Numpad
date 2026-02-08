# System Architecture - Mouse on Numpad

**Document Version:** 3.0
**Updated:** 2026-02-08
**Status:** Phases 1-5 COMPLETE, production-ready architecture

---

## Executive Summary

Mouse on Numpad is a feature-complete Linux application providing keyboard-controlled mouse access via numpad keys. Architecture emphasizes modularity, thread-safety, and Wayland/X11 compatibility through clean separation of concerns and dependency injection.

**Design Principles:**
- **Modularity**: Isolated components with single responsibilities
- **Thread-Safety**: RLock protects all shared state
- **Display Independence**: Works with X11, Wayland, and hybrid systems via evdev
- **Type Safety**: Full Python type hints throughout codebase
- **XDG Compliance**: Follows Linux directory standards

---

## Layered Architecture

```
┌────────────────────────────────────┐
│  Presentation Layer (Phase 4)      │
│  GTK4 GUI: Settings, Tabs, Dialogs│
├────────────────────────────────────┤
│ Application Layer (Phase 2-3)      │
│ Movement, Scroll, Position Memory  │
│ Audio, Monitor Detection           │
├────────────────────────────────────┤
│ Daemon Layer (Phase 1)             │
│ Keyboard Capture, Hotkey Dispatch  │
│ IPC, System Tray                   │
├────────────────────────────────────┤
│ Core Layer                         │
│ Config, State, Logging             │
├────────────────────────────────────┤
│ Backend Layer (Phase 5)            │
│ X11, Wayland, evdev Detection      │
└────────────────────────────────────┘
```

---

## Module Breakdown

### Core Package (`core/`)

**config.py** - Configuration management with XDG compliance
- Loads/saves JSON from `~/.config/mouse-on-numpad/config.json`
- Type-safe nested dict access with defaults
- Auto-saves on changes
- Thread-safe via RLock

**state_manager.py** - Runtime state with observer pattern
- Tracks: `is_enabled`, `numlock_state`, `current_position`, `active_monitor`
- Observable: callers can subscribe to state changes
- Thread-safe snapshot operations
- Persistence hooks for daemon/GUI sync

**error_logger.py** - Structured logging with rotation
- Logs to `~/.local/share/mouse-on-numpad/app.log`
- Rotating file handler (8 files, 1MB each)
- Console output in debug mode
- Structured format with timestamps

### Daemon Package (`daemon/`)

**daemon_coordinator.py** - Main orchestrator
- Starts keyboard monitoring threads
- Manages hotkey dispatch callbacks
- Runs system tray icon
- Handles graceful shutdown (SIGINT, SIGTERM)
- Tracks held mouse buttons and mode state

**keyboard_capture.py** - evdev keyboard event reading
- Finds and opens all keyboard devices (works on Wayland)
- Non-blocking event loop per device
- Handles device disconnection/reconnection gracefully
- Thread-per-device architecture

**hotkey_dispatcher.py** - Key-to-action mapping
- Routes keycodes to handlers: movement, scroll, clicks, modes
- Supports modifiers: ctrl, shift, alt combinations
- Config-driven via evdev keycodes
- Extensible callback pattern

**ipc_manager.py** - Inter-process communication
- Writes daemon status to `/tmp/mouse-on-numpad.status`
- Spawns status indicator subprocess
- Communicates with GUI via socket/named pipes

**position_manager.py** - Position memory per monitor
- Saves/loads cursor positions to 5 slots per monitor
- Persists to `~/.config/mouse-on-numpad/positions.json`
- Handles monitor config changes
- Per-monitor storage enables multi-display workflows

**mouse_factory.py** - Mouse controller abstraction
- Tries uinput first (native input device, no X11 required)
- Falls back to ydotool (works with Wayland/X11)
- Abstracts away display server differences

### Input Package (`input/`)

**movement_controller.py** - Numpad movement (8 directions)
- Thread-safe direction queue
- Exponential acceleration with configurable curve
- Adjustable base speed, max speed, acceleration rate
- Smooth diagonal movement support

**scroll_controller.py** - Mouse wheel emulation
- Numpad 7/9/1/3 for up/right/down/left scroll
- Configurable step size and acceleration
- Simultaneous multi-direction scrolling
- Acceleration parameter matching movement

**mouse_controller.py** - Low-level mouse operations
- Move cursor to absolute position
- Perform clicks (left/right/middle)
- Hold/release buttons for drag operations
- Display server agnostic via backend abstraction

**monitor_manager.py** - Multi-monitor detection
- Uses X11 RandR (if available) or fallback
- Detects monitor geometry, orientation, primary display
- Supports hybrid X11/Wayland setups
- Updates on RANDR events

**position_memory.py** - Cursor position storage
- JSON persistence with per-monitor indexing
- Maps physical position to monitor-relative offset
- Handles portrait/landscape orientations
- Atomic write operations (no corruption on crash)

**audio_feedback.py** - Audio playback
- PulseAudio/ALSA abstraction via ossaudiodev
- Sine wave tone generation in Python (no external files)
- Configurable volume (0-100%)
- Handles missing audio hardware gracefully

**hotkey_manager.py** - High-level hotkey configuration
- Loads from config.json into memory
- Reverse mapping: keycode -> action
- Validates hotkey bindings
- Enables runtime hotkey customization

**uinput_mouse.py** - uinput device wrapper
- Opens `/dev/uinput` for synthetic mouse events
- Handles device capabilities negotiation
- Fallback-safe if uinput unavailable

### UI Package (`ui/`)

**main_window.py** - GTK4 application window
- Tabbed interface for settings
- Loads/saves via ConfigManager
- Real-time setting validation
- Status display and daemon control

**movement_tab.py** - Movement speed/acceleration settings
- Base speed slider (1-50)
- Acceleration curve selector (linear/exponential/s-curve)
- Max speed limit
- Preview/test movement

**scroll_tab.py** - Scroll parameters
- Step size configuration
- Acceleration settings
- Delay adjustment

**hotkeys_tab.py** - Hotkey remapping
- Key capture button for each action
- Visual layout matching numpad
- Conflict detection
- Reset to defaults option

**profiles_tab.py** - Profile save/load
- Save current config as named profile
- Load/delete saved profiles
- Profile list with metadata
- Import/export functionality

**appearance_tab.py** - Visual customization
- Theme selection (default/dark/light/high-contrast)
- Status indicator position (4 corners)
- Status indicator size (small/medium/large)
- Opacity slider (0-100%)

**advanced_tab.py** - Advanced options
- Enable/disable position memory per monitor
- Log level selection
- Cache cleanup
- Experimental features

**status_indicator.py** - Floating overlay window
- GTK Layer Shell integration (works on Wayland)
- Persistent on top, no focus stealing
- Configurable position and size
- Auto-hide when mode disabled

**key_capture_button.py** - Reusable hotkey input widget
- Press to assign next keypress
- Visual feedback during capture
- Timeout handling
- Real-time preview

**save_profile_dialog.py** - Profile save dialog
- Modal dialog for new profile name
- Validation and confirmation

### Backends Package (`backends/`)

**base.py** - Abstract backend interface
- Common interface for display servers
- Mouse movement, clicking, monitoring

**x11_backend.py** - X11 support
- XTest extension for mouse events
- RandR for monitor detection
- XKB for keyboard handling
- Fallback for minimal X11 systems

**wayland_backend.py** - Wayland support
- wl-paste for clipboard (if available)
- DBus interfaces for screensaver/power
- Portal APIs for data access

**evdev_backend.py** - Event device interface
- Direct /dev/input/event* reading
- Cross-server event capture
- Handles device hotplug

---

## Data Flow

### Hotkey Execution Flow

```
1. KeyboardCapture (thread per device)
   └─> reads /dev/input/event*
   └─> returns (keycode, pressed) tuple

2. Daemon._handle_key()
   └─> calls HotkeyDispatcher.handle_key()
   └─> looks up keycode in config

3. HotkeyDispatcher routes to handler:
   └─> Movement: MovementController.start_direction()
   └─> Scroll: ScrollController.start_direction()
   └─> Click: MouseController.click()
   └─> Mode: StateManager.toggle()

4. Handler executes:
   └─> Movement/Scroll: background thread moves mouse
   └─> Click: immediate mouse operation
   └─> Mode: updates state, notifies subscribers

5. Subscribers notified:
   └─> TrayIcon updates display
   └─> StatusIndicator updates overlay
   └─> IPCManager writes status file
```

### Configuration Flow

```
1. User changes setting in GUI (Settings tab)
   └─> writes to ConfigManager
   └─> ConfigManager.save() -> ~/.config/mouse-on-numpad/config.json

2. Daemon detects config change (via file watcher or IPC)
   └─> calls Daemon.reload_hotkeys()
   └─> HotkeyDispatcher reloads from ConfigManager
   └─> next keypress uses new mapping

3. GUI updates Settings from file
   └─> watches ~.config/ for external changes
   └─> reloads and reflects in UI
```

### Multi-Monitor Support

```
Current Position: (640, 480)
Active Monitor: HDMI-1 @ offset (1920, 0)

When saving to slot:
  └─> PositionMemory.save_position()
  └─> Detects current monitor via MonitorManager
  └─> Stores relative to monitor: (640-1920, 480-0) = (-1280, 480)
  └─> Persists to positions.json keyed by monitor ID

When loading from slot:
  └─> PositionMemory.load_position(slot)
  └─> Gets current monitor config
  └─> Applies offset: (-1280, 480) + (1920, 0) = (640, 480)
  └─> MouseController.move(640, 480)
```

---

## Threading Model

| Thread | Purpose | Lifecycle |
|--------|---------|-----------|
| **Main** | GUI event loop, configuration | Process lifetime |
| **KeyboardCapture (1+)** | Read device events (per device) | Daemon start -> stop |
| **MovementController** | Execute movement at interval | Created on first movement, reused |
| **ScrollController** | Execute scroll at interval | Created on first scroll, reused |
| **TrayIcon** | System tray icon and menu | Daemon start -> stop |

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
| Systemd user | `~/.config/systemd/user/mouse-on-numpad.service` | .service |

---

## Key Design Decisions

### Why evdev for keyboard?
- Works on Wayland without X11 compatibility layer
- Direct kernel event stream, lowest latency
- Requires input group membership, handled in docs

### Why uinput for mouse?
- Display server agnostic (Wayland/X11/hybrid)
- Native input device, minimal dependencies
- Fallback to ydotool if uinput unavailable

### Why thread-per-device for keyboard?
- Allows monitoring multiple keyboards simultaneously
- Isolates device disconnection to single thread
- Scales better than single-threaded event loop

### Why GTK4 + Layer Shell?
- Modern toolkit with Wayland support
- Layer Shell enables always-on-top overlay
- Type-safe Gtk bindings via GObject introspection

### Why JSON over INI?
- Nested configuration (movement, audio, hotkeys)
- Native Python dict serialization
- Better tooling and IDE support
- Atomic write operations

---

## Error Handling

| Component | Error | Recovery |
|-----------|-------|----------|
| KeyboardCapture | No devices found | Fail fast with user message |
| KeyboardCapture | Device disconnected | Silently exit thread |
| MouseController | uinput unavailable | Fallback to ydotool |
| ConfigManager | File corrupted | Load defaults, preserve backup |
| AudioFeedback | PulseAudio unavailable | Skip audio, log warning |
| MonitorManager | No monitors detected | Use fallback (0,0 as primary) |

---

## Performance Targets

| Metric | Target | Method |
|--------|--------|--------|
| Input latency | <10ms | Direct evdev, no processing delay |
| Idle CPU | <5% | Blocking reads, no polling |
| Memory | <50MB | Minimal dependencies, efficient state |
| Config load | <100ms | Lazy loading, cached values |
| GUI startup | <1s | Lazy import of UI modules |

---

## Future Extensibility

### Adding a new input type (e.g., game controller)
1. Create `input/gamepad_controller.py`
2. Add to hotkey dispatcher routes
3. Add configuration options
4. Update GUI with new tab

### Adding a new display server backend
1. Create `backends/wayland_ext_backend.py`
2. Implement mouse_move(), click(), get_monitors()
3. Register in backends/__init__.py
4. Auto-detection in mouse_factory.py

### Adding a new position memory strategy
1. Create `input/position_memory_variant.py`
2. Implement same public interface
3. Inject via PositionMemory constructor
4. Add to advanced_tab GUI options
