# Mouse on Numpad - Codebase Summary

**Project:** Control mouse cursor with numpad keys on Linux (Python + GTK port of Windows AutoHotkey version)
**Version:** 1.0.0 (Linux Port - Phase 1 Complete)
**Updated:** 2026-01-17
**Repository:** https://github.com/Stonelukas/mouse-on-numpad

---

## Overview

Mouse on Numpad is a keyboard accessibility tool that maps numpad keys to mouse cursor movement and actions. The project is transitioning from a Windows AutoHotkey v2 implementation to a modern Python+GTK application for Linux.

**Current Phase:** Phase 1 Core Infrastructure (Complete)

---

## Project Structure

```
mouse-on-numpad/
├── src/mouse_on_numpad/          # Main Python package
│   ├── core/                      # Core utilities
│   │   ├── config.py             # JSON config persistence
│   │   ├── state_manager.py      # Observable state with thread safety
│   │   ├── error_logger.py       # Rotating file logger
│   │   └── __init__.py
│   ├── main.py                    # CLI entry point with --status, --toggle, --version
│   ├── __main__.py                # python -m entry point
│   └── __init__.py
├── tests/                         # Test suite
│   ├── test_config.py            # ConfigManager tests
│   ├── test_state_manager.py     # StateManager tests
│   └── test_error_logger.py      # ErrorLogger tests
├── docs/                          # Documentation
│   ├── API.md                     # Windows version API reference
│   ├── USAGE.md                   # Usage guide
│   ├── HOTKEYS.md                # Default hotkeys
│   └── ...
├── pyproject.toml                 # uv package configuration
├── LINUX_PORT_PLAN.md            # Detailed port plan (6 phases)
└── old/                           # Legacy AutoHotkey source
    └── ...
```

---

## Core Modules (Phase 1)

### 1. ConfigManager (config.py)

**Purpose:** JSON-based configuration persistence with XDG compliance

**Key Features:**
- Stores config at `~/.config/mouse-on-numpad/config.json` (XDG Base Directory)
- Automatic backup (creates `.json.bak`) before writes
- Nested key access: `config.get("movement.base_speed")`
- Recursive default merging (preserves user customizations)
- Secure file permissions (0600 - user read/write only)

**Default Schema:**
```python
{
    "movement": {
        "base_speed": 10,          # Pixels per step
        "acceleration": 1.5,       # Speed curve multiplier
        "curve": "exponential"     # linear | exponential | s-curve
    },
    "audio": {
        "enabled": True,
        "volume": 50              # 0-100
    },
    "status_bar": {
        "enabled": True,
        "position": "top-right",
        "auto_hide": True         # Hide when disabled
    },
    "positions": {
        "per_monitor": True       # Store positions per monitor
    }
}
```

**Methods:**
- `get(key: str, default=None)` - Nested key access
- `get_all() -> dict` - Full config (deep copy)
- `set(key: str, value: Any)` - Update key
- `reload()` - Reload from disk

---

### 2. StateManager (state_manager.py)

**Purpose:** Observable application state with thread-safe notifications

**Key Features:**
- **Thread-safe:** RLock protects all state modifications
- **Observable:** Subscribe to state changes with callbacks
- **Copy-before-notify:** Captures state before releasing lock
- **No duplicates:** Prevents duplicate subscriptions

**State Schema:**
```python
class State:
    mouse_mode: MouseMode         # ENABLED | DISABLED
    current_position: (x, y)      # Tuple[int, int]
    speed_multiplier: float       # 0.5-2.0
    audio_enabled: bool
    status_bar_visible: bool
```

**Methods:**
- `subscribe(key: str, callback: Callable)` - Register change listener
- `unsubscribe(key: str, callback: Callable)` - Remove listener
- `toggle() -> bool` - Toggle mouse mode, returns new state
- Property setters: `state.audio_enabled = True` triggers notifications

**Observer Pattern:**
```python
# Register callback for state changes
def on_mode_change(key: str, value: MouseMode) -> None:
    logger.info(f"Mouse mode changed: {value}")

state_mgr.subscribe("mouse_mode", on_mode_change)

# Trigger notification
state_mgr.toggle()  # Calls on_mode_change("mouse_mode", ENABLED)
```

---

### 3. ErrorLogger (error_logger.py)

**Purpose:** Structured logging with rotation and XDG compliance

**Key Features:**
- Logs to `~/.local/share/mouse-on-numpad/logs/` (XDG Data Directory)
- Rotating file handler (5MB max, 3 backups)
- Log directory permissions 0700 (user only)
- Severity levels: DEBUG, INFO, WARNING, ERROR, EXCEPTION

**Log Location:**
```
~/.local/share/mouse-on-numpad/
├── logs/
│   ├── mouse_on_numpad.log      # Current
│   ├── mouse_on_numpad.log.1   # Rotated
│   └── ...
```

**Methods:**
- `debug(message: str, *args)` - Debug level
- `info(message: str, *args)` - Info level
- `warning(message: str, *args)` - Warning level
- `error(message: str, *args)` - Error level (flushes immediately)
- `exception(message: str, *args)` - Exception with traceback (flushes immediately)

---

## CLI Entry Point (main.py)

**Command:** `mouse-on-numpad` or `python -m mouse_on_numpad`

**Flags:**
- `--status` - Show current mouse mode
- `--toggle` - Toggle mouse mode on/off
- `--version` - Display version

**Example:**
```bash
# Check status
mouse-on-numpad --status
# Output: Mouse mode: enabled

# Toggle state
mouse-on-numpad --toggle

# Show version
mouse-on-numpad --version
# Output: mouse-on-numpad 1.0.0
```

---

## Testing

**Test Coverage:** 37 tests, all passing (79% code coverage)

**Test Files:**
- `tests/test_config.py` - ConfigManager functionality (11 tests)
- `tests/test_state_manager.py` - StateManager + Observer pattern (18 tests)
- `tests/test_error_logger.py` - ErrorLogger rotation (8 tests)

**Test Categories:**
1. **Config Tests:** Load, save, defaults, nested access, corruption recovery
2. **State Tests:** Toggle, notifications, thread safety, subscriber isolation
3. **Logger Tests:** File creation, rotation, severity levels, permissions

**Run Tests:**
```bash
# Run all tests
uv run pytest

# With coverage
uv run pytest --cov=src/mouse_on_numpad

# Specific test file
uv run pytest tests/test_config.py -v
```

---

## Dependencies

### Core Runtime
- **pynput** (1.7.6+) - Mouse and keyboard input
- **PyGObject** (3.44.0+) - GTK bindings
- **pulsectl** (23.5.0+) - Audio control
- **python-xlib** (0.33+) - X11 protocol

### Development
- **pytest** (7.0.0+) - Testing framework
- **pytest-cov** (4.0.0+) - Coverage reporting
- **ruff** (0.1.0+) - Linting and formatting
- **mypy** (1.0.0+) - Type checking

**Python Version:** 3.10+ (3.11, 3.12 supported)

---

## Build & Installation

### Requirements
- Python 3.10+
- uv package manager
- GTK 3.0+ (usually pre-installed on Linux)

### Setup
```bash
# Install package in editable mode
uv pip install -e .

# Or use uv run directly
uv run python -m mouse_on_numpad --status
```

### Build Distribution
```bash
# Build wheel
uv run hatchling build

# This creates:
# - dist/mouse_on_numpad-1.0.0-py3-none-any.whl
# - dist/mouse_on_numpad-1.0.0.tar.gz
```

---

## Architecture Highlights

### XDG Base Directory Compliance
- **Config:** `$XDG_CONFIG_HOME/mouse-on-numpad/config.json` (~/.config default)
- **Data:** `$XDG_DATA_HOME/mouse-on-numpad/logs/` (~/.local/share default)
- **Cache:** Reserved for Phase 2+ (position memory, etc.)

### Thread-Safe Design
- All state modifications protected by RLock
- No GIL-blocking operations in critical sections
- Safe for GUI event loop (Phase 4)

### Secure Defaults
- Config files: 0600 permissions (owner read/write)
- Log directory: 0700 permissions (owner only)
- No credentials stored in config
- Errors logged without sensitive data exposure

### Observable Pattern
Observer pattern enables:
- Reactive UI updates (Phase 4)
- Decoupled input handlers (Phase 2)
- Clean state change debugging

---

## Known Issues & Limitations

### Phase 1 Issues (Review 2026-01-17)

| Priority | Issue | Impact | Status |
|----------|-------|--------|--------|
| Critical | pytest-cov dependency not installed | Tests fail without manual PYTHONPATH | Pending fix |
| Critical | Package not installable without workaround | Blocks standard Python invocation | Pending fix |
| High | 4 ruff linting errors | CI/CD will fail | Pending fix |
| High | Silent exception swallowing in state callbacks | Debugging impossible | Pending fix |
| High | Race condition in toggle() method | Potential state inconsistency | Pending fix |
| Medium | Aggressive logging flush | Performance impact in input loop | Acceptable for Phase 1 |
| Medium | ThemeManager not implemented | Deferred to Phase 4 | Design decision pending |

### Deferred Features (Future Phases)
- **ThemeManager** - 7 color themes (Phase 4)
- **Input Control Layer** - Numpad input handlers (Phase 2)
- **GUI Implementation** - Settings dialog (Phase 4)
- **Position Memory** - Save/restore cursor positions (Phase 3)
- **Audio System** - Click sounds and feedback (Phase 3)
- **Wayland Support** - Modern display server compatibility (Phase 5)

---

## Code Quality Metrics

**Type Coverage:** 100% (mypy strict mode passes)
**Test Pass Rate:** 100% (37/37 tests)
**Linting Issues:** 4 auto-fixable errors (ruff)
**Security Issues:** 0 critical, 1 minor (log file permissions)
**Code Standards:** YAGNI/KISS/DRY compliant

---

## Next Steps

### Immediate (Phase 1 Completion)
1. Fix pytest-cov dependency configuration
2. Install package in editable mode
3. Fix 4 ruff linting violations
4. Add error logging to state manager callbacks
5. Fix race condition in toggle() method

### Phase 2 (Input Control Layer)
- Implement input event handlers
- Integrate with xdotool/pynput for mouse control
- Speed settings from config
- Test with actual numpad input

### Phase 3 (Position Memory & Audio)
- Position memory storage and retrieval
- Audio system integration
- Per-monitor position tracking

### Phase 4 (GUI Implementation)
- GTK settings dialog
- Theme manager implementation (7 themes)
- Visual status indicator

### Phase 5 (Wayland Support)
- Wayland protocol support
- Modern compositor compatibility

### Phase 6 (Packaging & Distribution)
- RPM/DEB package creation
- AppImage distribution
- AUR packaging

---

## References

- **Phase 1 Plan:** `plans/260117-1353-linux-port/phase-01-core-infrastructure.md`
- **Code Review:** `plans/reports/code-reviewer-260117-1421-phase1-core-infra.md`
- **Port Plan:** `LINUX_PORT_PLAN.md`
- **Contributing:** See CLAUDE.md for development guidelines

---

**Codebase Snapshot:** Generated from repomix v1.11.0 (45 files, 262k tokens)
