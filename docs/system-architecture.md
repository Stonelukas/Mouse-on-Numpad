# System Architecture - Mouse on Numpad

**Document Version:** 1.0
**Updated:** 2026-01-17
**Phase:** 1 (Core Infrastructure Complete)

---

## Executive Summary

Mouse on Numpad is a multi-phase Linux port of a Windows AutoHotkey accessibility tool. The architecture emphasizes thread-safety, testability, and XDG compliance with a layered design enabling incremental development.

**Design Principles:**
- **Separation of Concerns:** Config, state, logging, input, GUI are isolated
- **Observable Pattern:** State changes trigger async notifications
- **XDG Compliance:** Respects Linux directory conventions
- **Thread-Safe:** RLock protects all mutable state
- **Testable:** Core modules fully unit-tested before integration

---

## Layered Architecture

```
┌─────────────────────────────────────────┐
│       GUI Layer (Phase 4)               │
│   Settings Dialog, Status Indicator     │
├─────────────────────────────────────────┤
│    Application Layer (Phase 2-3)        │
│ Input Control, Position Memory, Audio   │
├─────────────────────────────────────────┤
│     State & Config Layer (Phase 1)      │
│ StateManager, ConfigManager, ErrorLogger│
├─────────────────────────────────────────┤
│      System Layer (Linux APIs)          │
│ X11/Wayland, Pulse Audio, Filesystem   │
└─────────────────────────────────────────┘
```

---

## Phase 1: Core Infrastructure

### Component Diagram

```
                          main.py
                        (CLI entry)
                             │
                ┌────────────┼────────────┐
                │            │            │
            --status    --toggle    --version
                │            │            │
                └────────────┼────────────┘
                             │
                     StateManager
                    (Observable)
                    ┌──────────┐
                    │ Position │
                    │ Mode     │◄────────┐
                    │ Audio    │         │
                    └──────────┘         │
                         │              │
                    callbacks            │
                         │              │
                    ┌────────────────────┘
                    │
            ┌───────┴──────┬──────────┬─────────┐
            │              │          │         │
       ConfigManager  ErrorLogger  (Phase 2+  Input Layer,
       (JSON file)   (Log file)   Audio, GUI)
            │              │
            ▼              ▼
    ~/.config/...  ~/.local/share/...
```

### Core Module Interactions

```python
# Initialization sequence
1. ConfigManager loads ~/.config/mouse-on-numpad/config.json
   - Creates default config if missing
   - Validates and merges with schema
   - Permissions: 0600 (owner only)

2. ErrorLogger initializes ~/.local/share/mouse-on-numpad/logs/
   - Creates directory with 0700 permissions
   - Sets up rotating file handler (5MB, 3 backups)
   - Ready for debug output

3. StateManager created with initial state
   - Subscribes to ConfigManager changes (Phase 2+)
   - Observers registered for all state changes
   - Ready for GUI/input layers
```

---

## Data Flow

### Configuration Flow

```
User Config File
(~/.config/mouse-on-numpad/config.json)
            │
            ▼
      ConfigManager.load()
            │
            ├─→ JSON.decode
            ├─→ Merge defaults
            └─→ Validate schema
            │
            ▼
  config.get("movement.base_speed")
            │
            ▼
    Application Layer
    (uses config values)
            │
            ▼
       StateManager
  (speed_multiplier)
```

### State Change Flow

```
External Trigger
(toggle button, hotkey)
            │
            ▼
    StateManager.toggle()
            │
            ├─→ Acquire lock
            ├─→ Update internal state
            └─→ Release lock
            │
            ▼
   _notify(key, value)
            │
            ├─→ Copy state value (inside lock)
            └─→ Release lock
            │
            ▼
   Iterate subscribers
            │
            ├─→ Call callback(key, value)
            ├─→ Call callback(key, value)
            └─→ ...
            │
            ▼
     GUI updates
  (Phase 4)
```

---

## Component Details

### 1. ConfigManager

**Responsibility:** JSON persistence, schema validation, XDG compliance

**Key Design Decisions:**

1. **XDG Compliance**
   ```
   Config file location:
   $XDG_CONFIG_HOME/mouse-on-numpad/config.json

   Default: ~/.config/mouse-on-numpad/config.json
   ```

2. **Backup Strategy**
   ```
   Before write:
   - Copy current config.json to config.json.bak
   - Write new config.json atomically
   - Rollback available if write fails
   ```

3. **Default Merging**
   ```
   User config:     {"movement": {"base_speed": 15}}
   Defaults:        {"movement": {...}, "audio": {...}}
   Result:          {"movement": {...}, "audio": {...}}
               with base_speed=15, other keys=default
   ```

4. **Nested Access**
   ```python
   config.get("movement.base_speed")  # Returns user value
   config.set("audio.volume", 75)     # Nested update
   ```

**Thread-Safety:** Single-threaded (Phase 1), values copied by StateManager

**Failure Modes:**
- Corrupted JSON → Restore defaults, resave
- Missing file → Create with defaults
- Permission denied → Logged, exception raised

---

### 2. StateManager

**Responsibility:** Observable state, thread-safe updates, change notifications

**Key Design Decisions:**

1. **RLock Protection**
   ```python
   _lock = threading.RLock()

   # All state changes atomic:
   with self._lock:
       self._state.mouse_mode = new_mode
   ```

2. **Observer Pattern**
   ```python
   # Register observer
   state_mgr.subscribe("mouse_mode", on_change_callback)

   # Trigger notification
   state_mgr.toggle()  # Internally calls _notify()

   # Callback signature
   def on_change_callback(key: str, value: Any) -> None:
       print(f"{key} changed to {value}")
   ```

3. **Copy-Before-Notify**
   ```python
   def _notify(self, key: str, value: Any) -> None:
       with self._lock:
           state_snapshot = copy.copy(self._state)

       # Notify outside lock (prevents deadlock)
       for callback in self._subscribers.get(key, []):
           callback(key, state_snapshot)
   ```

4. **Duplicate Prevention**
   ```python
   subscribers = {
       "mouse_mode": [callback1, callback2]
   }

   subscribe("mouse_mode", callback1)  # OK
   subscribe("mouse_mode", callback1)  # Silently ignored
   ```

**Thread-Safety Guarantees:**
- State reads are consistent (RLock protected)
- Notifications never hold lock (prevents deadlock)
- Callbacks can safely modify config/state (won't deadlock)

**Failure Modes:**
- Callback raises exception → Logged, other callbacks still run
- Callback modifies state → New change triggers new notification

---

### 3. ErrorLogger

**Responsibility:** Structured logging with rotation and XDG compliance

**Key Design Decisions:**

1. **XDG Data Directory**
   ```
   Log location:
   $XDG_DATA_HOME/mouse-on-numpad/logs/mouse_on_numpad.log

   Default: ~/.local/share/mouse-on-numpad/logs/
   ```

2. **Rotating File Handler**
   ```
   MaxBytes: 5 MB per file
   BackupCount: 3 rotated files

   Result:
   - mouse_on_numpad.log (current, < 5 MB)
   - mouse_on_numpad.log.1 (previous)
   - mouse_on_numpad.log.2
   - mouse_on_numpad.log.3
   ```

3. **Directory Permissions**
   ```
   /home/user/.local/share/mouse-on-numpad/
   └── logs/ (mode 0700 = rwx------)
   ```

4. **Severity Levels**
   ```
   ERROR, EXCEPTION → Flush immediately (critical visibility)
   WARNING, INFO, DEBUG → Buffer (I/O efficiency)
   ```

**Integration Points:**
- ConfigManager logs load/save operations
- StateManager logs callback failures
- Phase 2+ input layer logs key events

---

## Thread Model

### Phase 1: Single-Threaded

```
Main thread
    │
    ├─→ ConfigManager (load config)
    ├─→ ErrorLogger (setup logging)
    ├─→ StateManager (initialize state)
    └─→ CLI main loop
         │
         └─→ Handle --status, --toggle, --version
```

### Phase 2+: Multi-Threaded

```
Main thread (GTK event loop)
    │
    ├─→ Input thread
    │   ├─→ Read numpad keys
    │   ├─→ StateManager.toggle() [thread-safe]
    │   └─→ Notify observers
    │
    └─→ GUI thread
        └─→ Receive notifications
            └─→ Update widgets
```

### Lock Strategy

```
StateManager lock:
- SHORT critical section (read/modify state)
- LONG non-critical section (notify callbacks)
- Prevents callback → state → callback deadlock

ConfigManager lock:
- Not needed (Phase 1 single-threaded)
- Phase 2+: Would need lock if config hot-reload enabled
```

---

## File System Layout

### XDG Directories

```
User Home
│
├── .config/
│   └── mouse-on-numpad/
│       └── config.json              (0600, user R/W)
│           config.json.bak          (backup)
│
├── .local/
│   └── share/
│       └── mouse-on-numpad/
│           ├── logs/                (0700, user-only access)
│           │   ├── mouse_on_numpad.log
│           │   ├── mouse_on_numpad.log.1
│           │   └── mouse_on_numpad.log.2
│           │
│           └── (Phase 3+) positions/    (position memory)
│               └── positions.db
│
└── .cache/
    └── mouse-on-numpad/
        └── (Phase 3+) thumbnails/    (if needed)
```

### File Permissions

| Path | Mode | Purpose |
|------|------|---------|
| config/ | 0755 | Directory must exist |
| config/config.json | 0600 | User-only access |
| logs/ | 0700 | User-only access |
| logs/*.log | 0644 | Readable by process |

---

## Error Handling Strategy

### Configuration Errors

```
Scenario: JSON file corrupted
├─→ json.JSONDecodeError caught
├─→ Logged: "Corrupted config, using defaults"
├─→ Defaults restored and saved
└─→ Application continues with defaults

Scenario: Permission denied on config file
├─→ OSError caught
├─→ Logged: "Cannot read config"
└─→ Application continues with defaults
```

### State Errors

```
Scenario: Callback raises exception
├─→ Exception caught in _notify()
├─→ Logged: "State callback failed: {exc}"
├─→ Other callbacks still executed
└─→ Application continues running
```

### Logging Errors

```
Scenario: Log directory doesn't exist
├─→ Created with mkdir -p
├─→ Permissions set to 0700
└─→ Logger initializes normally

Scenario: Disk full
├─→ RotatingFileHandler raises OSError
├─→ Logging disabled (stderr fallback Phase 2+)
└─→ Application continues (graceful degradation)
```

---

## Testing Strategy

### Unit Tests (Phase 1)

```
test_config.py
├─→ Load/save JSON
├─→ Default merging
├─→ Nested key access
├─→ Corruption recovery
└─→ File permissions

test_state_manager.py
├─→ State initialization
├─→ Toggle operation
├─→ Observer notifications
├─→ Thread-safety under load
└─→ Duplicate subscription prevention

test_error_logger.py
├─→ Logger initialization
├─→ File rotation
├─→ Permission enforcement
└─→ Severity level handling
```

### Integration Tests (Phase 2+)

```
test_integration.py
├─→ ConfigManager → StateManager
├─→ CLI commands (--status, --toggle)
├─→ Input handlers → State changes
└─→ State changes → GUI updates
```

### Performance Tests (Phase 2+)

```
test_performance.py
├─→ StateManager throughput (messages/sec)
├─→ Lock contention (input loop)
└─→ Memory usage (subscriber leaks)
```

---

## Scalability Considerations

### Phase 1 (Current)
- Single process, single thread
- Static configuration
- ~1000 lines of code
- ~37 test cases

### Phase 2-3 (Input + Position)
- Multi-threaded (input + GUI)
- Dynamic state changes (~100/sec)
- RLock contention manageable
- ~500 lines of new code

### Phase 4 (GUI)
- GTK main event loop
- Thread-safe state notifications
- Position memory database
- ~2000 lines of GUI code

### Phase 5 (Wayland)
- Conditional X11/Wayland support
- Protocol abstraction layer
- No architectural changes needed

---

## Deployment Model

### Development
```bash
uv pip install -e .
python -m mouse_on_numpad --status
```

### Distribution Packages (Phase 6)
```
- Wheel: dist/mouse_on_numpad-1.0.0-py3-none-any.whl
- Source: dist/mouse_on_numpad-1.0.0.tar.gz
- RPM: mouse-on-numpad-1.0.0-1.fc39.noarch.rpm
- DEB: mouse-on-numpad_1.0.0_all.deb
- AUR: mouse-on-numpad-git
```

---

## Security Considerations

### Data Protection

| Data | Storage | Protection |
|------|---------|-----------|
| Config | JSON file | 0600 permissions |
| Logs | Text file | 0700 directory |
| Positions | Database | 0600 permissions |
| Passwords | ❌ | Not stored |

### Input Validation
- No user input processed in Phase 1
- Phase 2+: Numpad event validation (whitelist allowed keys)
- No shell commands executed

### Privilege Requirements
- Runs as unprivileged user
- Accesses only user home directory
- X11/Wayland access via existing user session

---

## Known Limitations

### Phase 1
- Single-threaded (input blocked during JSON load)
- Theme colors hard-coded (deferred to Phase 4)
- No persistence of cursor position

### Phase 2
- X11 only (Wayland deferred to Phase 5)
- No multi-monitor support (Phase 3)
- No position memory (Phase 3)

### Future Improvements
1. Replace XDG fallback with `platformdirs` library
2. Async state changes (event-driven instead of polling)
3. Database for position memory (SQLite)
4. Hot config reload without restart

---

## References

- **Phase Plans:** `plans/260117-1353-linux-port/`
- **Code Review:** `plans/reports/code-reviewer-260117-1421-phase1-core-infra.md`
- **Port Plan:** `LINUX_PORT_PLAN.md`
- **Development Rules:** `CLAUDE.md`

---

**Architecture Diagram Version:** 1.0
**Last Updated:** 2026-01-17
**Phase Status:** Phase 1 Core Infrastructure - Complete (pending fixes)
