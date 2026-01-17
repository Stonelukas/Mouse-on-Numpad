# Phase 4: Color Themes

## Overview
- Priority: Low
- Status: Pending
- Effort: 1h

## Goal
Add color theme support matching Windows version.

## Themes (from Windows)
- Default (blue/gray)
- Dark (dark gray/white)
- Light (white/black)
- High Contrast (black/yellow)
- Custom (user-defined)

## Implementation

### Config
```python
"theme": {
    "name": "default",
    "colors": {
        "bg_enabled": "#4CAF50",
        "bg_disabled": "#666666",
        "text": "#FFFFFF",
    }
}
```

### Theme Presets
Store in `themes.json` or hardcoded dict.

### Apply Theme
- Status indicator uses theme colors
- Settings GUI uses system theme (GTK)

## Todo
- [ ] Define theme presets
- [ ] Add theme config section
- [ ] Update status indicator CSS
- [ ] Add theme selector in GUI

## Success Criteria
- 4+ theme options available
- Theme persists across restarts
