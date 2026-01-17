# Python API Reference

**Document Version:** 1.0
**Updated:** 2026-01-18

This reference documents the public Python API for the Mouse on Numpad project. These classes and methods are designed for use in the daemon and testing.

## Core Modules

### ConfigManager (`mouse_on_numpad.core.config`)

Manages JSON configuration with XDG compliance and nested key access.

```python
from mouse_on_numpad.core import ConfigManager

config = ConfigManager()
```

**Methods:**
- `get(key: str, default: Any = None) -> Any` — Get value by dot notation
  ```python
  speed = config.get("movement.base_speed")  # Returns 5
  value = config.get("nonexistent", default=0)  # Returns 0
  ```

- `set(key: str, value: Any) -> None` — Set value by dot notation
  ```python
  config.set("scroll.step", 5)  # Updates and saves
  ```

- `get_all() -> dict[str, Any]` — Return deep copy of entire config

- `reset() -> None` — Reset to defaults and save

- `reload() -> None` — Reload from disk (picks up external changes)

**Properties:**
- `config_dir: Path` — Configuration directory
- `config_file: Path` — Configuration file path

**Default Configuration:**
```python
{
    "movement": {
        "base_speed": 5,
        "acceleration_rate": 1.08,
        "max_speed": 40,
        "move_delay": 20,
        "curve": "exponential"
    },
    "scroll": {
        "step": 3,
        "acceleration_rate": 1.1,
        "max_speed": 10,
        "delay": 30
    },
    "audio": {
        "enabled": True,
        "volume": 50
    },
    "status_bar": {
        "enabled": True,
        "position": "top-right",
        "auto_hide": True
    }
}
```

---

### StateManager (`mouse_on_numpad.core.state_manager`)

Thread-safe observable state management with RLock protection.

```python
from mouse_on_numpad.core import StateManager

state = StateManager()
```

**Methods:**
- `toggle() -> bool` — Toggle mouse mode and notify observers
  ```python
  enabled = state.toggle()
  ```

- `subscribe(key: str, callback: Callable) -> None` — Register observer
  ```python
  def on_mode_change(key: str, value: Any) -> None:
      print(f"{key} = {value}")

  state.subscribe("mouse_mode", on_mode_change)
  ```

- `unsubscribe(key: str, callback: Callable) -> None` — Remove observer

**Properties:**
- `is_enabled: bool` — Check if mouse mode is enabled
- `audio_enabled: bool` — Check if audio is enabled
- `save_mode: bool` — Check if in save mode
- `load_mode: bool` — Check if in load mode

**Thread-Safety:** All state changes are atomic and protected by RLock. Notifications occur outside lock to prevent deadlock.

---

### ErrorLogger (`mouse_on_numpad.core.error_logger`)

Structured logging with file rotation and XDG compliance.

```python
from mouse_on_numpad.core import ErrorLogger

logger = ErrorLogger(console_output=True)
```

**Methods:**
- `info(msg: str, *args: Any) -> None` — Log info level
- `warning(msg: str, *args: Any) -> None` — Log warning level
- `error(msg: str, *args: Any) -> None` — Log error level
- `exception(msg: str, *args: Any) -> None` — Log exception with traceback
- `debug(msg: str, *args: Any) -> None` — Log debug level

**Example:**
```python
try:
    dangerous_operation()
except Exception as e:
    logger.exception("Operation failed: %s", e)
```

---

## Input Layer

### ScrollController (`mouse_on_numpad.input.scroll_controller`)

Continuous scrolling with exponential acceleration support.

```python
from mouse_on_numpad.input import ScrollController
from mouse_on_numpad.core import ConfigManager

config = ConfigManager()
scroll = ScrollController(config, mouse_controller)
```

**Methods:**
- `start_direction(direction: str) -> None` — Start scrolling
  ```python
  scroll.start_direction("up")      # Begin scrolling up
  scroll.start_direction("down")    # Can scroll up+down simultaneously
  ```

- `stop_direction(direction: str) -> None` — Stop scrolling in direction
  ```python
  scroll.stop_direction("up")  # Stop up, continue down if active
  ```

- `stop_all() -> None` — Stop all scrolling immediately
  ```python
  scroll.stop_all()  # Reset acceleration and clear directions
  ```

**Directions:** `"up"`, `"down"`, `"left"`, `"right"`

**Configuration:**
```python
{
    "scroll": {
        "step": 3,                    # Base amount per tick
        "acceleration_rate": 1.1,     # Exponential multiplier
        "max_speed": 10,              # Maximum multiplier
        "delay": 30                   # ms between ticks
    }
}
```

**Behavior:**
- Runs in daemon thread for continuous scrolling
- Resets acceleration when all directions stop
- Supports multi-direction simultaneous scrolling
- Opposite directions cancel out (up + down = 0)

---

### MovementController (`mouse_on_numpad.input.movement_controller`)

Continuous mouse movement with exponential acceleration.

```python
from mouse_on_numpad.input import MovementController

movement = MovementController(config, mouse_controller)
```

**Methods:**
- `start_direction(direction: str) -> None` — Start movement
- `stop_direction(direction: str) -> None` — Stop movement
- `stop_all() -> None` — Stop all movement

**Directions:** `"up"`, `"down"`, `"left"`, `"right"`

---

### MonitorManager (`mouse_on_numpad.input.monitor_manager`)

Multi-monitor support and display detection.

```python
from mouse_on_numpad.input import MonitorManager

monitors = MonitorManager()
```

---

### PositionMemory (`mouse_on_numpad.input.position_memory`)

Save and restore mouse positions per monitor.

```python
from mouse_on_numpad.input import PositionMemory

positions = PositionMemory(config, monitors)
```

---

### AudioFeedback (`mouse_on_numpad.input.audio_feedback`)

Audio feedback for mode toggles.

```python
from mouse_on_numpad.input import AudioFeedback

audio = AudioFeedback(config)
```

---

## Mouse Controllers

### UinputMouse (`mouse_on_numpad.input.uinput_mouse`)

High-performance mouse controller using UInput (preferred).

```python
from mouse_on_numpad.input.uinput_mouse import UinputMouse

mouse = UinputMouse()
mouse.move(dx=10, dy=20)
mouse.click(button="left")
mouse.scroll(dx=0, dy=3)
mouse.close()
```

**Methods:**
- `move(dx: int, dy: int) -> None` — Move mouse relative
- `click(button: str = "left") -> None` — Click button
- `scroll(dx: int, dy: int) -> None` — Scroll wheel

**Buttons:** `"left"`, `"right"`, `"middle"`

---

### YdotoolMouse (`mouse_on_numpad.daemon`)

Fallback mouse controller using ydotool (when UInput unavailable).

Same interface as UinputMouse.

---

## Daemon

### Daemon (`mouse_on_numpad.daemon.Daemon`)

Main daemon connecting numpad keys to mouse control.

```python
from mouse_on_numpad.daemon import Daemon

daemon = Daemon()
daemon.start()
```

**Methods:**
- `start() -> None` — Start listening for events
- `stop() -> None` — Stop daemon gracefully

**Key Mappings:**
| Function | Keycode | Numpad |
|----------|---------|--------|
| Toggle mode | 78 | + |
| Save mode | 55 | * |
| Load mode | 74 | - |
| Movement keys | 71-80 | 7,8,9,4,6,1,2,3 |
| Scroll keys | 71,73,79,81 | 7,9,1,3 |
| Click keys | 76,82,96 | 5,0,Enter |

---

## Protocol Objects

### ScrollableProtocol

```python
from typing import Protocol

class ScrollableProtocol(Protocol):
    """Protocol for objects supporting scrolling."""

    def scroll(self, dx: int, dy: int) -> None:
        """Scroll by relative delta."""
        ...
```

Both UinputMouse and YdotoolMouse implement this protocol.

---

## Common Patterns

### Initialize Daemon

```python
from mouse_on_numpad.core import ConfigManager, StateManager, ErrorLogger
from mouse_on_numpad.daemon import Daemon

config = ConfigManager()
state = StateManager()
logger = ErrorLogger(console_output=True)

daemon = Daemon(config=config, state=state, logger=logger)
daemon.start()
```

### Listen for State Changes

```python
def on_mode_toggle(key: str, value: Any) -> None:
    if key == "mouse_mode":
        print(f"Mouse mode: {value}")

state.subscribe("mouse_mode", on_mode_toggle)
state.toggle()  # Triggers callback
```

### Adjust Scroll Speed at Runtime

```python
config.set("scroll.step", 5)
config.set("scroll.max_speed", 15)
# Changes picked up on next scroll key press
```

### Test ScrollController

```python
def mock_scroll(dx: int, dy: int) -> None:
    print(f"Scroll: dx={dx}, dy={dy}")

class MockMouse:
    def scroll(self, dx: int, dy: int) -> None:
        mock_scroll(dx, dy)

scroll = ScrollController(config, MockMouse())
scroll.start_direction("up")
# Mock receives scroll events in background thread
```

---

## Error Handling

**Configuration Errors:**
- Missing config file → Creates with defaults
- Corrupted JSON → Restored from backup or recreated
- Permission denied → Logged, exception raised

**State Errors:**
- Callback raises exception → Logged, other callbacks still run
- State modification in callback → New change triggers notification

**Input Errors:**
- Device grab failed → Logged, continues with other devices
- Invalid keycode → Silently ignored

---

## Thread Safety

All public methods are thread-safe:
- ConfigManager: Single-threaded (Phase 1)
- StateManager: RLock protected
- ScrollController: Thread-safe multi-direction handling
- MovementController: Thread-safe multi-direction handling

**Rules:**
1. Don't hold locks across I/O operations
2. Callbacks can safely modify state (won't deadlock)
3. All state changes are atomic

---

## Performance Considerations

- **Memory:** ~30-50 MB resident with daemon running
- **CPU:** ~2-5% idle, varies with scroll/movement activity
- **I/O:** Config loaded once at startup, hot-reload via `reload()`
- **Latency:** evdev provides <1ms input latency

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-18 | Initial API docs with scroll support |

---

## See Also

- [USAGE.md](./USAGE.md) - User-facing usage guide
- [HOTKEYS.md](./HOTKEYS.md) - Hotkey reference
- [system-architecture.md](./system-architecture.md) - Architecture overview
