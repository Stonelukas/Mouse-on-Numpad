# Phase 2: Secondary Monitor

## Overview
- Priority: Medium
- Status: Complete
- Effort: 45m

## Goal
Add Alt+Numpad9 to toggle mouse between monitors.

## Implementation

### Key Mapping
```python
KEY_SECONDARY_MONITOR = (56, 73)  # Alt + Numpad9
```

### Logic
1. Get current mouse position
2. Detect which monitor cursor is on
3. Calculate center of next monitor
4. Move cursor to that position

### Use Existing
- MonitorManager already has monitor detection
- xdotool for position query/move (same as position memory)

## Todo
- [x] Add secondary_monitor hotkey config
- [x] Implement monitor cycling in daemon
- [x] Add modifier key (Alt) detection
- [x] Test with multi-monitor setup

## Success Criteria
- Alt+Numpad9 moves cursor to next monitor center
- Works with 2+ monitors
- Cycles back to first monitor
