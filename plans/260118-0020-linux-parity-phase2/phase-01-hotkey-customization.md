# Phase 1: Hotkey Customization

## Overview
- Priority: High
- Status: Pending
- Effort: 1.5h

## Goal
Let users customize numpad key mappings via Settings GUI.

## Implementation

### Config Additions
```python
"hotkeys": {
    "toggle_mode": 78,      # KEY_KPPLUS
    "save_mode": 55,        # KEY_KPASTERISK
    "load_mode": 74,        # KEY_KPMINUS
    "undo": 98,             # KEY_KPSLASH
    "left_click": 76,       # KEY_KP5
    "right_click": 82,      # KEY_KP0
    "middle_click": 96,     # KEY_KPENTER
    "hold_left": 83,        # KEY_KPDOT
}
```

### GUI Changes
- Add "Hotkeys" tab to main_window.py
- Key capture widget (press key to assign)
- Reset to defaults button

### Daemon Changes
- Read keycodes from config instead of class constants
- Reload hotkeys on config change

## Todo
- [ ] Add hotkeys config section
- [ ] Create HotkeysTab GUI widget
- [ ] Implement key capture dialog
- [ ] Update daemon to use config keycodes
- [ ] Add hotkey reset function

## Success Criteria
- Users can remap any numpad function
- Changes persist across restarts
- Conflicts detected and prevented
