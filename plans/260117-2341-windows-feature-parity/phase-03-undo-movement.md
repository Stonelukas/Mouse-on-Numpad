# Phase 3: Undo Movement

## Context
- Parent: [plan.md](plan.md)
- Windows: MaxUndoLevels=10, NumpadDiv undoes last move

## Overview
- Priority: Medium
- Status: Done (2026-01-18 00:10)
- Effort: 45m

## Implementation

### Config
```python
"undo": {
    "max_levels": 10,
}
```

### State
```python
self._position_history: list[tuple[int, int]] = []
```

### Logic
1. Before each mouse.move(): record current position
2. On NumpadDiv (KEY_KPSLASH = 98):
   - Pop last position from history
   - Move mouse to that position

### Getting Current Position
Need to query current mouse position. Options:
- Use pynput Controller().position (might not work on Wayland)
- Track position in state (accumulate deltas)
- Query via /dev/input (complex)

Simplest: Track in MovementController, store absolute coords.

## Todo
- [x] Add undo config
- [x] Add position history tracking
- [x] Record position before moves
- [x] Add KEY_KPSLASH handler
- [x] Implement undo (move to last position)

## Success Criteria
- NumpadDiv undoes last movement
- History limited to max_levels
- Works with diagonal moves
