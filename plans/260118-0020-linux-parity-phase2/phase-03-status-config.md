# Phase 3: Status Indicator Config

## Overview
- Priority: Medium
- Status: Complete
- Effort: 1h

## Goal
Add size, opacity, position options for status overlay.

## Implementation

### Config Additions
```python
"status_bar": {
    "enabled": True,
    "position": "top-right",  # top-left, top-right, bottom-left, bottom-right
    "size": "medium",         # small, medium, large
    "opacity": 80,            # 0-100
    "auto_hide": True,
}
```

### GUI Changes
- Position dropdown in Appearance tab
- Size dropdown (small=12px, medium=16px, large=24px)
- Opacity slider

### Status Indicator Changes
- Read position/size/opacity from config
- Apply opacity via CSS

## Todo
- [x] Add size/opacity config keys
- [x] Update status_indicator.py to use config
- [x] Add controls to Appearance tab
- [x] Implement position presets

## Success Criteria
- Users can resize, reposition, adjust opacity
- Changes apply in real-time
