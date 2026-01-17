# Phase 1: Scroll Support

## Context
- Parent: [plan.md](plan.md)
- Windows: Numpad 7/1 = vertical scroll, 9/3 = horizontal scroll with acceleration

## Overview
- Priority: High
- Status: Done (2026-01-18 00:00)
- Effort: 30m

## Implementation

### Key Mappings
```python
SCROLL_KEYS = {
    71: ("up",),      # KEY_KP7 - scroll up
    79: ("down",),    # KEY_KP1 - scroll down
    73: ("right",),   # KEY_KP9 - scroll right (matches Windows numpad layout)
    81: ("left",),    # KEY_KP3 - scroll left
}
```

### Config Additions
```python
"scroll": {
    "step": 3,
    "acceleration_rate": 1.1,
    "max_speed": 10,
}
```

### Changes to daemon.py
1. Add SCROLL_KEYS mapping (reuse diagonal key codes when mouse mode active)
2. Create scroll handler with acceleration (similar to movement)
3. Call `self.mouse.scroll(dx, dy)` - already implemented in UinputMouse

## Todo
- [x] Add scroll config defaults
- [x] Add SCROLL_KEYS to daemon
- [x] Implement scroll handler with acceleration
- [x] Test vertical and horizontal scroll

## Success Criteria
- Numpad 7/1 scrolls vertically with acceleration
- Numpad 9/3 scrolls horizontally
- Works in mouse mode only
