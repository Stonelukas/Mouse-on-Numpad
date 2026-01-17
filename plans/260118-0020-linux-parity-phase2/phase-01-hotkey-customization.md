# Phase 1: Hotkey Customization

## Overview
- Priority: High
- Status: ✅ Complete
- Effort: 1.5h
- Review: [code-reviewer-260118-0029](../reports/code-reviewer-260118-0029-hotkey-customization.md)

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
- [x] Add hotkeys config section (config.py)
- [x] Create HotkeysTab GUI widget (hotkeys_tab.py)
- [x] Implement key capture dialog (KeyCaptureButton)
- [x] Update daemon to use config keycodes (daemon.py)
- [x] Add hotkey reset function (reset button)

## Post-Review Actions
- [x] Fix import organization in daemon.py (ruff --fix)
- [x] Install mypy for type checking
- [x] Add reload_hotkeys() state clearing
- [x] Fix conflict detection to include slot keys
- [x] Modularize hotkeys_tab.py (271 lines → 3 files)

## Success Criteria
- Users can remap any numpad function
- Changes persist across restarts
- Conflicts detected and prevented
