# Phase 5: Profiles System

## Overview
- Priority: Low
- Status: Pending
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
- [ ] Create profiles directory structure
- [ ] Add profile save/load functions
- [ ] Add Profiles tab or section in GUI
- [ ] Implement profile switching

## Success Criteria
- Create/save/load/delete profiles
- Profiles include all settings
- Quick switch via GUI
