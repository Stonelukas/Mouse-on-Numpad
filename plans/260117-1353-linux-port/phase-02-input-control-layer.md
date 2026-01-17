---
phase: 2
title: "Input Control Layer"
status: completed
priority: P1
effort: 10h
---

# Phase 2: Input Control Layer

## Context

- Parent: [plan.md](./plan.md)
- Source: [LINUX_PORT_PLAN.md](../../LINUX_PORT_PLAN.md) Section 3 Phase 2
- Dependencies: Phase 1 (ConfigManager, StateManager)

## Overview

Implement mouse and keyboard control for X11 using pynput. This is the critical path - core functionality depends on this phase.

## Key Insights

- pynput handles X11 automatically, provides cross-platform API
- Numpad keycodes differ between Windows/Linux (KP_* vs Numpad*)
- NumLock state affects keycode mapping
- Acceleration curves from Windows: linear, exponential, S-curve

## Requirements

### Functional
- Absolute and relative mouse movement
- Left/Right/Middle click
- Scroll wheel (vertical + horizontal)
- Global numpad hotkey capture
- Multi-monitor coordinate handling
- Configurable acceleration curves

### Non-Functional
- Input latency <10ms
- CPU usage <1% when idle
- Handle NumLock states gracefully

## Architecture

```
src/input/
  __init__.py
  mouse_controller.py    # MouseController (pynput wrapper)
  hotkey_manager.py      # HotkeyManager (global hotkeys)
  monitor_manager.py     # MonitorManager (Xrandr)
```

### Key Code Mapping

| Windows (AHK) | X11 Keysym | pynput Key |
|---------------|------------|------------|
| Numpad0 | KP_Insert/KP_0 | Key.kp_insert |
| Numpad5 | KP_Begin/KP_5 | KeyCode(65437) |
| NumpadAdd | KP_Add | KeyCode(0xffab) |
| NumpadMult | KP_Multiply | KeyCode(0xffaa) |
| NumpadDiv | KP_Divide | KeyCode(0xffaf) |

## Related Code Files

### Create
- `src/input/__init__.py`
- `src/input/mouse_controller.py`
- `src/input/hotkey_manager.py`
- `src/input/monitor_manager.py`
- `tests/test_mouse_controller.py`
- `tests/test_hotkey_manager.py`
- `tests/test_monitor_manager.py`

## Implementation Steps

1. Create MouseController class
   ```python
   class MouseController:
       def move_to(x, y) -> None
       def move_relative(dx, dy) -> None
       def click(button: str) -> None  # "left", "right", "middle"
       def scroll(dx, dy) -> None
       def get_position() -> tuple[int, int]
   ```

2. Implement acceleration curves
   - Linear: speed = base_speed
   - Exponential: speed = base_speed * (acceleration ** time_held)
   - S-curve: smooth start/end, fast middle
   - Port logic from MouseActions.ahk

3. Create HotkeyManager class
   ```python
   class HotkeyManager:
       def register(key, callback, modifiers=[]) -> None
       def unregister(key) -> None
       def enable() -> None
       def disable() -> None
   ```

4. Implement numpad key handling
   - Map all numpad keys (0-9, +, -, *, /, Enter, Del)
   - Handle with/without NumLock
   - Support modifier combinations (Ctrl, Shift, Alt)

5. Create MonitorManager class
   ```python
   class MonitorManager:
       def get_monitors() -> list[Monitor]
       def get_primary() -> Monitor
       def get_monitor_at(x, y) -> Monitor
       def clamp_to_screens(x, y) -> tuple[int, int]
   ```

6. Implement Xrandr integration
   - Query monitor geometry
   - Handle negative coordinates (left-of-primary)
   - Support dynamic monitor changes

7. Write integration tests
   - Test mouse movement (requires X11 display)
   - Test hotkey capture
   - Mock pynput for unit tests

## Todo List

- [x] Create MouseController with pynput backend
- [x] Implement move_to, move_relative, click, scroll
- [x] Port acceleration curves from Windows
- [x] Create HotkeyManager with global key capture
- [x] Map all numpad keycodes (NumLock on/off)
- [x] Support modifier keys (Ctrl, Shift, Alt)
- [x] Create MonitorManager with Xrandr
- [x] Handle multi-monitor coordinates
- [x] Write unit tests with mocked pynput
- [ ] Write integration tests (X11 required - deferred to Phase 4)

## Success Criteria

- [x] Mouse moves to absolute coordinates
- [x] Mouse moves relative with acceleration
- [x] All mouse buttons click correctly
- [x] Scroll works vertically and horizontally
- [ ] Numpad 8/2/4/6 move cursor in directions (integration test - Phase 4)
- [ ] Numpad 5 performs left click (integration test - Phase 4)
- [ ] Numpad * toggles enable/disable (integration test - Phase 4)
- [x] Multi-monitor coordinates handled correctly
- [x] Works with NumLock on and off

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| pynput NumLock issues | High | Raw keysym fallback via python-xlib |
| Key suppression not working | High | Test early, evdev fallback |
| Multi-monitor edge cases | Medium | Test on dual/triple setups |
| Permission issues (input group) | Medium | Document uinput setup |

## Security Considerations

- Global hotkey capture requires X11 access
- No keylogging - only capture registered keys
- Document required permissions

## Next Steps

After Phase 2 complete:
- Phase 3: Position Memory & Audio (depends on MouseController)
- Phase 4: GUI Implementation (depends on HotkeyManager)
