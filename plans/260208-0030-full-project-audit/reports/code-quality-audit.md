# Code Quality & Architecture Audit

## Summary
Python codebase with ~4,800 LOC across 31 files. Generally good architecture with clear module boundaries. **Critical issues**: 2 files exceed 200-line limit (daemon.py at 505 lines, main_window.py at 413 lines). Type hints mostly present but incomplete. Thread safety well-implemented in core modules. Dead code and unused imports minimal.

## Critical Issues
- **daemon.py (505 lines)**: Violates 200-line standard by 2.5x. God class pattern - handles evdev I/O, hotkey dispatch, mouse control, tray icon, IPC, position memory, monitor management. Extract into coordinator + subsystems.
- **main_window.py (413 lines)**: Exceeds limit by 2x. Procedural tab creation with repetitive patterns. Extract tab logic into separate modules.
- **Type hints incomplete**: `profiles_tab.py:165` uses `callable` (lowercase) instead of `Callable[[str], None]`. Missing generics in several files.

## High Priority
- **Broad exception handling**: `daemon.py:421` catches `OSError` without specificity (could hide permission vs. device issues).
- **Magic numbers**: `daemon.py:19` hardcodes `YDOTOOL_SCROLL_MULTIPLIER = 15` without explanation or config option.
- **Subprocess without check**: `daemon.py:27,39,359` runs `ydotool`/`xdotool` with `check=False`, silently ignoring failures.
- **File I/O in hot path**: `daemon.py:192` writes status file on every toggle (no error handling or async).
- **Global mutable state**: `error_logger.py:133` uses global `_default_logger` (not thread-safe init).
- **Missing type annotations**: Several protocol classes and callbacks lack full type coverage.

## Medium Priority
- **Config reload in loop**: `movement_controller.py:83` reloads config every 50 iterations (~1s) - wasteful I/O, use inotify or signal.
- **Flush after every log**: `error_logger.py:101-111` calls `_flush()` after every log write - performance impact under load.
- **No input validation**: `config.py:227` sanitizes profile names but doesn't validate input ranges for speed/acceleration.
- **Hardcoded keycodes**: `daemon.py:114-158` uses numeric keycodes (78, 55, 74) - magic numbers without named constants.
- **Thread.join() not called**: `daemon.py:476` starts threads but never joins them on cleanup (relies on daemon=True).
- **Tight coupling**: `daemon.py` directly imports `TrayIcon`, `AudioFeedback`, `MonitorManager` - no dependency injection.

## Low Priority
- **Unused imports**: `tray_icon.py:3` imports `Callable` but uses `Callable[[], None] | None` - could simplify.
- **TODOs without context**: No TODO comments found (good adherence to standards).
- **Docstring coverage**: ~85% - missing on some private methods and protocol implementations.
- **Comment quality**: Good "why" comments, minimal "what" redundancy.

## Architecture Assessment

### Module Structure: **GOOD**
```
src/mouse_on_numpad/
├── core/          ✅ Clean separation (config, state, logging)
├── backends/      ✅ Backend abstraction with base class
├── input/         ✅ Focused modules (movement, scroll, hotkeys, audio)
├── ui/            ⚠️  main_window.py too large, needs splitting
└── daemon.py      ❌ God class - violates SRP
```

### Backend Abstraction: **EXCELLENT**
- `base.py` defines clear `InputBackend` protocol
- Three implementations: `x11_backend.py`, `wayland_backend.py`, `evdev_backend.py`
- Proper `NotImplementedError` for unsupported features (evdev hotkeys)
- **Issue**: Daemon bypasses backend abstraction (uses evdev directly, not via backend interface)

### Daemon Design: **NEEDS REFACTOR**
**Current**: Monolithic 505-line class handling:
- Keyboard event capture (evdev)
- Hotkey dispatch (keycodes → actions)
- Mouse control (UInput/ydotool fallback)
- Position memory (save/load slots)
- Monitor management (cycle monitors)
- IPC (status file write)
- UI coordination (tray icon, indicator subprocess)

**Recommended**: Extract to:
- `KeyboardCapture` - evdev device management + key event emission
- `HotkeyDispatcher` - keycode → action mapping + callback routing
- `SessionCoordinator` - lifecycle management (start/stop/cleanup)
- `IPCManager` - status file + indicator process management

### Thread Safety: **EXCELLENT**
- `state_manager.py`: RLock guards with notifications outside lock (deadlock prevention)
- `movement_controller.py`: Lock only for state access, actions outside lock
- `scroll_controller.py`: Same pattern as movement
- **Best practice**: Short critical sections, no I/O under lock

## File-by-File Notes

| File | Lines | Issues | Severity |
|------|-------|--------|----------|
| daemon.py | 505 | God class, exceeds limit 2.5x, tight coupling | CRITICAL |
| main_window.py | 413 | Exceeds limit 2x, repetitive patterns | CRITICAL |
| config.py | 280 | Exceeds limit 1.4x, but acceptable for data-heavy | MEDIUM |
| backends/x11_backend.py | 249 | Exceeds limit 1.2x, complex but focused | MEDIUM |
| input/monitor_manager.py | 242 | Exceeds limit 1.2x, could extract X11/Wayland logic | MEDIUM |
| core/state_manager.py | 196 | Clean, well-documented, near limit | GOOD |
| core/error_logger.py | 141 | Flush on every log impacts perf | MEDIUM |
| input/movement_controller.py | 166 | Config reload every 1s wasteful | MEDIUM |
| tray_icon.py | 110 | Clean, focused, good separation | GOOD |
| app.py | 61 | Clean entry point | GOOD |
| main.py | 134 | Clear CLI handling | GOOD |

## Recommendations

### Priority 1 - Refactor Daemon (505 → 4 files of <150 lines each)
1. Extract `KeyboardCapture` class (evdev device management, event loop)
2. Extract `HotkeyDispatcher` class (keycode mapping, action callbacks)
3. Extract `IPCManager` class (status file, indicator subprocess)
4. Keep `Daemon` as coordinator (~100 lines)

### Priority 2 - Split main_window.py (413 → 3 files)
1. Extract `MovementTab` class (~80 lines)
2. Extract `AudioTab` class (~50 lines)
3. Extract `AppearanceTab` class (~80 lines)
4. Keep `MainWindow` as notebook container (~100 lines)

### Priority 3 - Fix Type Hints
- `profiles_tab.py:165`: Change `callable` → `Callable[[str], None]`
- Add missing return types to protocol methods
- Enable mypy strict mode checks

### Priority 4 - Performance & Robustness
- Replace config reload loop with inotify/signal pattern
- Add subprocess error handling (ydotool/xdotool failures)
- Reduce log flush frequency (buffer or async)
- Add input validation for numeric config values

### Priority 5 - Code Quality
- Extract magic numbers to named constants (keycodes, multipliers)
- Add daemon thread cleanup (join with timeout)
- Inject dependencies instead of direct imports in daemon
- Add thread pool for parallel device monitoring

## Edge Cases Found
- **Permission denied on /dev/uinput**: Handled with fallback to ydotool (daemon.py:62)
- **No keyboard devices found**: Warning printed but doesn't exit gracefully (daemon.py:438)
- **Config file corruption**: Falls back to defaults but overwrites user config silently (config.py:119)
- **Monitor detection failure**: `xdotool` dependency not checked before use (daemon.py:342)
- **Concurrent hotkey rebind**: No lock on `_load_hotkeys()` - race condition if GUI + daemon reload simultaneously

## Positive Observations
- **Consistent patterns**: Movement and scroll controllers share same threading model
- **XDG compliance**: Config and logs properly use XDG directories
- **Fallback strategy**: UInput → ydotool, evdev → X11/Wayland backends
- **Thread safety**: Core components use locks correctly with short critical sections
- **Error logging**: Structured logging with rotation and timestamps
- **Type hints**: ~80% coverage (above average for Python)
- **Docstrings**: Google-style docstrings on public APIs
- **No hardcoded paths**: All paths use Path objects and XDG env vars

## Metrics Summary
- **Total LOC**: 4,775
- **Files**: 31 Python files
- **Avg file size**: 154 lines (within standard)
- **Files exceeding 200 lines**: 5 (16%)
- **Files exceeding 300 lines**: 2 (6%)
- **Type hint coverage**: ~80%
- **Docstring coverage**: ~85%
- **Thread-safe modules**: 4/4 core modules (100%)
- **Magic numbers**: ~20 (mostly keycodes)
- **God classes**: 1 (daemon.py)

## Security Considerations
- **File permissions**: Config files properly set to 0o600 (owner-only)
- **Input sanitization**: Profile names sanitized (config.py:228)
- **Subprocess injection**: No user input passed to shell commands (safe)
- **Log secrets**: No evidence of password/key logging
- **Exception leaks**: Error messages don't expose sensitive paths

## Unresolved Questions
- Should daemon.py backend selection logic use factory pattern?
- Is config reload every 1s acceptable for embedded systems?
- Should status indicator use D-Bus instead of file IPC?
