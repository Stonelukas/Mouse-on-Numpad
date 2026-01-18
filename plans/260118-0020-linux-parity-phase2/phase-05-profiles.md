# Phase 5: Profiles System

## Overview
- Priority: Low
- Status: Complete
- Effort: 1.5h

## Goal
Save/load config profiles for different use cases.

## Implementation

### Profile Storage
```
~/.config/mouse-on-numpad/
├── config.json          # Active config
├── profiles/
│   ├── default.json
│   ├── gaming.json
│   └── precision.json
```

### Config Additions
```python
"profiles": {
    "active": "default",
    "list": ["default", "gaming", "precision"]
}
```

### GUI
- Profiles dropdown in Settings
- Save As / Delete buttons
- Import/Export option

## Todo
- [x] Create profiles directory structure
- [x] Add profile save/load functions
- [x] Add Profiles tab or section in GUI
- [x] Implement profile switching

## Success Criteria
- Create/save/load/delete profiles
- Profiles include all settings
- Quick switch via GUI
