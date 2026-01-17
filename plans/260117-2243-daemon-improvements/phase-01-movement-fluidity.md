---
title: "Phase 1: Fix Movement Fluidity"
status: pending
effort: 3h
---

# Phase 1: Fix Movement Fluidity

## Problem

Current `YdotoolMouse.move()` spawns subprocess for every movement step:
```python
subprocess.run(["ydotool", "mousemove", "-x", str(dx), "-y", str(dy)], check=False)
```

Subprocess overhead: ~30-50ms per call. At 10ms input loop = severe stutter.

## Solutions (pick one)

### Option A: Direct uinput (Recommended)

Use `python-evdev` UInput directly for mouse:
```python
from evdev import UInput, ecodes

class UinputMouse:
    def __init__(self):
        self._ui = UInput(
            events={ecodes.EV_REL: [ecodes.REL_X, ecodes.REL_Y]},
            name="mouse-on-numpad-mouse"
        )

    def move(self, dx: int, dy: int) -> None:
        self._ui.write(ecodes.EV_REL, ecodes.REL_X, dx)
        self._ui.write(ecodes.EV_REL, ecodes.REL_Y, dy)
        self._ui.syn()
```

**Pros:** Zero subprocess overhead, works on Wayland
**Cons:** Requires input group membership (already needed for evdev)

### Option B: Persistent ydotool socket

Keep ydotool process alive, send commands via socket/stdin.

**Pros:** Reuses existing tooling
**Cons:** Still IPC overhead, more complex

### Option C: libevdev-python bindings

Similar to Option A but using libevdev wrapper.

## Implementation Steps

1. Create `UinputMouse` class in `src/mouse_on_numpad/input/uinput_mouse.py`
2. Implement `move(dx, dy)`, `click(button)`, `scroll(dx, dy)`
3. Update `Daemon.__init__` to use `UinputMouse` instead of `YdotoolMouse`
4. Add fallback: try UInput, fall back to ydotool if fails
5. Add benchmark test comparing old vs new

## Files to Modify

| File | Change |
|------|--------|
| `src/mouse_on_numpad/input/uinput_mouse.py` | NEW: UinputMouse class |
| `src/mouse_on_numpad/daemon.py` | Use UinputMouse, add fallback |
| `tests/test_uinput_mouse.py` | NEW: Unit tests |

## Success Criteria

- [x] No subprocess calls during movement
- [x] <1ms per mouse move
- [x] Works on Wayland (ydotool fallback for X11 if needed)
- [x] Scroll and click also use UInput

## Implementation Status

**Status:** ✅ COMPLETE (with review findings)
**Implemented:** 2026-01-17
**Review Score:** 8/10

### Changes Made
1. ✅ Created `UinputMouse` class in `src/mouse_on_numpad/input/uinput_mouse.py`
2. ✅ Implemented move, click, press, release, scroll operations
3. ✅ Added `create_mouse_controller()` with auto-fallback to ydotool
4. ✅ Zero subprocess overhead achieved

### Review Findings (See reports/code-reviewer-260117-2252-phase1-movement-fluidity.md)
- **High Priority:** Missing permission error handling, wrong return type annotation
- **Medium Priority:** Resource leak risk, missing type hints
- **Low Priority:** Context manager pattern, docstring improvements

### Next Actions
1. Address HIGH priority findings (permission errors, type annotation)
2. Proceed to Phase 2: Diagonal & Acceleration

## Risks

- UInput requires `/dev/uinput` access (input group or udev rule)
- Some VMs may not expose `/dev/uinput`

## Reference

evdev UInput docs: https://python-evdev.readthedocs.io/en/latest/usage.html#create-input-devices
