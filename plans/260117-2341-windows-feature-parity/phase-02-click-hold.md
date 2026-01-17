# Phase 2: Click Hold

## Context
- Parent: [plan.md](plan.md)
- Windows: NumpadDot toggles left click hold, NumpadEnter toggles middle hold

## Overview
- Priority: Medium
- Status: Done (2026-01-18 00:05)
- Effort: 30m

## Implementation

### Key Mappings
```python
HOLD_KEYS = {
    83: "left",   # KEY_KPDOT - toggle left hold
    96: "middle", # KEY_KPENTER - toggle middle hold (if not used for click)
}
```

### State Tracking
```python
self._held_buttons: set[str] = set()  # {"left", "middle"}
```

### Logic
1. On NumpadDot press:
   - If "left" not in held_buttons: `mouse.press("left")`, add to set
   - Else: `mouse.release("left")`, remove from set

### Changes
- Add to daemon.py `__init__`: `self._held_buttons = set()`
- Add HOLD_KEYS handling in `_handle_key()`
- Use existing `UinputMouse.press()` and `release()` methods

## Todo
- [x] Add _held_buttons state
- [x] Add HOLD_KEYS mapping
- [x] Implement toggle logic
- [x] Release all held buttons on mode disable

## Success Criteria
- NumpadDot holds/releases left click
- Held state persists until toggled off
- All buttons released when mouse mode disabled
