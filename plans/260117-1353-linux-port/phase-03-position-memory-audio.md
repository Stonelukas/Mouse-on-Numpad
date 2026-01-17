---
phase: 3
title: "Position Memory & Audio"
status: pending
priority: P2
effort: 4h
---

# Phase 3: Position Memory & Audio

## Context

- Parent: [plan.md](./plan.md)
- Source: [LINUX_PORT_PLAN.md](../../LINUX_PORT_PLAN.md) Section 3 Phase 3
- Dependencies: Phase 1 (ConfigManager), Phase 2 (MouseController)

## Overview

Implement 9-slot position memory system, audio feedback via PulseAudio, and CLI for headless operation.

## Key Insights

- Position memory enables quick cursor teleportation
- Undo/redo history (10 levels) for position mistakes
- Audio feedback uses tone generation like Windows SoundBeep()
- CLI enables scripting and daemon mode

## Requirements

### Functional
- 9 position slots (Numpad 1-9)
- Save: Ctrl+Numpad N
- Load: Numpad N
- Clear: Shift+Numpad N
- Undo/redo history (10 levels)
- Audio beep feedback
- CLI for daemon/scripting

### Non-Functional
- Position persistence across sessions
- Audio latency <50ms
- CLI must work headless (no X11 for daemon)

## Architecture

```
src/
  core/
    position_memory.py   # PositionMemory (9 slots + history)
  input/
    audio_manager.py     # AudioManager (PulseAudio)
  cli.py                 # CLI entry point
```

### Position Storage (positions.json)
```json
{
  "slots": {
    "1": {"x": 100, "y": 200, "monitor": 0},
    "2": null,
    "3": {"x": 500, "y": 300, "monitor": 1}
  },
  "history": [
    {"action": "save", "slot": 1, "position": {...}}
  ]
}
```

## Related Code Files

### Create
- `src/core/position_memory.py`
- `src/input/audio_manager.py`
- `src/cli.py`
- `tests/test_position_memory.py`
- `tests/test_audio_manager.py`

## Implementation Steps

1. Create PositionMemory class
   ```python
   class PositionMemory:
       def save_position(slot: int, x: int, y: int) -> None
       def load_position(slot: int) -> tuple[int, int] | None
       def clear_position(slot: int) -> None
       def get_all_positions() -> dict[int, Position]
       def undo() -> bool
       def redo() -> bool
   ```

2. Implement position persistence
   - Load from ~/.config/mouse-on-numpad/positions.json
   - Save on every change
   - Validate coordinates against current monitors

3. Implement undo/redo history
   - Circular buffer of 10 entries
   - Store action type, slot, old/new values
   - Persist history (optional)

4. Create AudioManager class
   ```python
   class AudioManager:
       def beep(frequency: int, duration_ms: int) -> None
       def play_feedback(action: str) -> None  # "save", "load", "toggle"
       def set_volume(percent: int) -> None
       def enable() -> None
       def disable() -> None
   ```

5. Implement PulseAudio backend
   - Use pulsectl for volume control
   - Generate tones programmatically (simpleaudio)
   - Fallback: system `paplay` command

6. Create CLI interface
   ```bash
   mouse-on-numpad --daemon        # Background mode
   mouse-on-numpad --toggle        # Toggle enable
   mouse-on-numpad --save 1        # Save to slot 1
   mouse-on-numpad --load 1        # Load from slot 1
   mouse-on-numpad --status        # Show state
   mouse-on-numpad --list          # Show all positions
   ```

7. Write tests
   - Test position save/load/clear
   - Test undo/redo stack
   - Mock audio for CI

## Todo List

- [ ] Create PositionMemory with 9 slots
- [ ] Implement JSON persistence for positions
- [ ] Add undo/redo history (10 levels)
- [ ] Create AudioManager with PulseAudio
- [ ] Implement tone generation for beeps
- [ ] Add feedback sounds (save, load, toggle)
- [ ] Create CLI with argparse
- [ ] Implement --daemon mode
- [ ] Write unit tests for position memory
- [ ] Test CLI commands

## Success Criteria

- [ ] Ctrl+Numpad 1 saves current position to slot 1
- [ ] Numpad 1 moves cursor to saved position
- [ ] Shift+Numpad 1 clears slot 1
- [ ] Undo reverts last position action
- [ ] Audio beep plays on actions (if enabled)
- [ ] `mouse-on-numpad --status` shows current state
- [ ] `mouse-on-numpad --daemon` runs in background
- [ ] Positions persist after restart

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| PulseAudio not available | Medium | Fallback to ALSA/silent |
| Tone generation glitchy | Low | Use pre-recorded samples |
| Position invalid after monitor change | Low | Clamp to nearest valid |

## Security Considerations

- Position data is not sensitive
- Audio requires PulseAudio socket access
- Daemon mode: ensure single instance

## Next Steps

After Phase 3 complete:
- All core features work headless
- Phase 4: GUI to configure these features
