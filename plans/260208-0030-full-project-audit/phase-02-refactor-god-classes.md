# Phase 2: Refactor God Classes

## Context
- Parent plan: [plan.md](plan.md)
- Depends on: [Phase 1](phase-01-fix-build-blockers.md)
- Source: [Code Quality Audit](reports/code-quality-audit.md)

## Overview
- **Priority:** Critical
- **Effort:** 8h
- **Status:** completed
- **Description:** Break daemon.py (505 LOC) and main_window.py (413 LOC) into focused modules under 200 lines each

## Key Insights
- `daemon.py` is a god class handling 8+ responsibilities: evdev capture, hotkey dispatch, mouse control, position memory, monitor management, IPC, UI coordination, tray icon
- `main_window.py` has repetitive tab creation patterns (6 tabs built inline)
- 3 other files slightly exceed 200 lines: config.py (280), x11_backend.py (249), monitor_manager.py (242)
- Thread safety patterns are correct — refactor must preserve lock discipline

## Requirements
- All files under 200 lines after refactor
- No behavioral changes (pure structural refactor)
- Thread safety preserved (short critical sections, no I/O under lock)
- All existing tests continue to pass

## Architecture

### daemon.py (505 → 4 files)
```
daemon.py (current: 505 lines)
├── daemon/keyboard_capture.py   (~120 lines) - evdev device management, event loop
├── daemon/hotkey_dispatcher.py  (~100 lines) - keycode → action mapping, callbacks
├── daemon/ipc_manager.py        (~80 lines)  - status file, indicator subprocess
└── daemon.py                    (~100 lines) - coordinator, lifecycle management
```

### main_window.py (413 → 4 files)
```
main_window.py (current: 413 lines)
├── ui/movement_tab.py    (~80 lines)  - speed/acceleration settings
├── ui/audio_tab.py       (~50 lines)  - volume/feedback settings
├── ui/appearance_tab.py  (~80 lines)  - themes, status indicator config
└── ui/main_window.py     (~100 lines) - notebook container, tab assembly
```

### Secondary refactors (if needed)
- `config.py` (280 lines): Extract schema/defaults to `config_defaults.py` if >200 post-cleanup
- `x11_backend.py` (249 lines): Extract helper functions if clearly separable
- `monitor_manager.py` (242 lines): Extract X11/Wayland detection logic

## Related Code Files
- `src/mouse_on_numpad/daemon.py` — primary refactor target
- `src/mouse_on_numpad/ui/main_window.py` — secondary refactor target
- `src/mouse_on_numpad/core/config.py` — potential split
- `src/mouse_on_numpad/backends/x11_backend.py` — potential split
- `src/mouse_on_numpad/input/monitor_manager.py` — potential split

## Implementation Steps

### Part A: Daemon Refactor
1. Read daemon.py fully, map responsibilities to methods
2. Create `src/mouse_on_numpad/daemon/` package with `__init__.py`
3. Extract `KeyboardCapture` class (evdev device find, open, read loop)
4. Extract `HotkeyDispatcher` class (keycode map, action routing)
5. Extract `IPCManager` class (status file write, indicator subprocess)
6. Slim `Daemon` class to coordinator (~100 lines)
7. Update imports across codebase
8. Run tests, verify behavior unchanged

### Part B: MainWindow Refactor
9. Read main_window.py, identify tab creation boundaries
10. Extract `MovementTab(Gtk.Box)` to `ui/movement_tab.py`
11. Extract `AudioTab(Gtk.Box)` to `ui/audio_tab.py`
12. Extract `AppearanceTab(Gtk.Box)` to `ui/appearance_tab.py`
13. Slim `MainWindow` to notebook assembly (~100 lines)
14. Run tests, verify UI unchanged

### Part C: Secondary (if time permits)
15. Check if config.py, x11_backend.py, monitor_manager.py still exceed 200 lines
16. Extract only if clear separation boundaries exist

## Todo List
- [ ] Extract KeyboardCapture from daemon.py
- [ ] Extract HotkeyDispatcher from daemon.py
- [ ] Extract IPCManager from daemon.py
- [ ] Slim Daemon coordinator to <150 lines
- [ ] Extract MovementTab from main_window.py
- [ ] Extract AudioTab from main_window.py
- [ ] Extract AppearanceTab from main_window.py
- [ ] Slim MainWindow to <150 lines
- [ ] Update all imports
- [ ] Verify all tests pass
- [ ] Check secondary files (config, x11_backend, monitor_manager)

## Success Criteria
- 0 files exceed 200 lines
- All existing tests pass
- `ruff check src/` clean
- No behavioral changes
- Thread safety preserved (verify lock patterns in extracted modules)

## Risk Assessment
- **Medium**: Daemon refactor touches critical input handling path
- **Mitigation**: Run full test suite after each extraction step
- **Mitigation**: Keep daemon thread model unchanged (daemon=True threads)
- Circular imports possible when extracting — use lazy imports if needed

## Security Considerations
- Preserve evdev device permission checks during extraction
- Keep subprocess calls with explicit args (no shell=True)
- Maintain config file permission enforcement (0o600)

## Next Steps
- Phase 4 (tests) should add integration tests for the refactored daemon
