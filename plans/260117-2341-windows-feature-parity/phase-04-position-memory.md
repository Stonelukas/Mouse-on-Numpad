# Phase 4: Position Memory Integration

## Context
- Parent: [plan.md](plan.md)
- Windows: NumpadMult = save mode, NumpadSub = load mode, 5 slots
- Existing: `src/mouse_on_numpad/input/position_memory.py` (not wired)

## Overview
- Priority: Medium
- Status: Pending
- Effort: 45m

## Implementation

### Key Mappings
```python
KEY_KPASTERISK = 55  # Save mode toggle
KEY_KPMINUS = 74     # Load mode toggle

SLOT_KEYS = {
    75: 1,  # KEY_KP4 -> slot 1
    76: 2,  # KEY_KP5 -> slot 2
    77: 3,  # KEY_KP6 -> slot 3
    72: 4,  # KEY_KP8 -> slot 4
    82: 5,  # KEY_KP0 -> slot 5
}
```

### State
```python
self._save_mode = False
self._load_mode = False
```

### Logic
1. NumpadMult toggles save_mode
2. NumpadSub toggles load_mode
3. When in save_mode and slot key pressed: save current pos to slot
4. When in load_mode and slot key pressed: move to saved pos
5. Exit mode after action

### Wire Existing Code
- `PositionMemory.save(slot, x, y)`
- `PositionMemory.load(slot)` -> (x, y)
- Already instantiated in daemon: `self.positions`

## Todo
- [ ] Add save_mode/load_mode state
- [ ] Add mode toggle handlers
- [ ] Add slot key handlers
- [ ] Get current position for save
- [ ] Move to position for load

## Success Criteria
- NumpadMult enters save mode
- NumpadSub enters load mode
- Slot keys save/load positions
- Positions persist across restarts
