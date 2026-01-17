---
phase: 4
title: "GUI Implementation"
status: pending
priority: P2
effort: 10h
---

# Phase 4: GUI Implementation

## Context

- Parent: [plan.md](./plan.md)
- Source: [LINUX_PORT_PLAN.md](../../LINUX_PORT_PLAN.md) Section 3 Phase 4
- Dependencies: Phase 1-3 (all core modules)

## Overview

Create GTK 4 settings GUI. **MVP scope: 2-3 tabs only.** Full 7-tab GUI deferred to post-MVP.

## Key Insights

- GTK 4 has better Wayland support than Qt
- AppIndicator3 for cross-DE tray support
- Start minimal, expand incrementally
- Status indicator as floating window

## Requirements

### Functional (MVP)
- Settings window with notebook (tabs)
- Tab 1: Movement settings (speed, acceleration)
- Tab 2: Positions (grid view of 9 slots)
- Tab 3: About (version, system info)
- System tray icon
- Status indicator (floating bar)

### Non-Functional
- Native GTK look
- Theme-aware colors
- Responsive to window resize
- Remember window position

## Architecture

```
src/ui/
  __init__.py
  app.py              # GTK Application
  main_window.py      # Settings window
  status_indicator.py # Floating status bar
  system_tray.py      # AppIndicator3 tray
  widgets/
    __init__.py
    position_grid.py  # 3x3 position buttons
    speed_slider.py   # Speed/accel sliders
  tabs/
    __init__.py
    movement_tab.py   # Movement settings
    positions_tab.py  # Position memory
    about_tab.py      # Version info
```

### GTK 4 Structure
```
GtkApplication
  └── GtkApplicationWindow (Settings)
        └── GtkNotebook
              ├── MovementTab
              ├── PositionsTab
              └── AboutTab
  └── GtkWindow (StatusIndicator)
```

## Related Code Files

### Create
- `src/ui/__init__.py`
- `src/ui/app.py`
- `src/ui/main_window.py`
- `src/ui/status_indicator.py`
- `src/ui/system_tray.py`
- `src/ui/widgets/__init__.py`
- `src/ui/widgets/position_grid.py`
- `src/ui/widgets/speed_slider.py`
- `src/ui/tabs/__init__.py`
- `src/ui/tabs/movement_tab.py`
- `src/ui/tabs/positions_tab.py`
- `src/ui/tabs/about_tab.py`
- `data/icons/app-icon.svg`
- `data/icons/tray-icon.svg`

## Implementation Steps

1. Create GTKApplication class
   ```python
   class MouseNumpadApp(Gtk.Application):
       def __init__(self):
           super().__init__(application_id="com.github.mouse-on-numpad")

       def do_activate(self):
           window = MainWindow(application=self)
           window.present()
   ```

2. Create MainWindow with notebook
   - GtkApplicationWindow base
   - GtkHeaderBar with title
   - GtkNotebook for tabs
   - Connect to ConfigManager for persistence

3. Implement MovementTab
   - Speed slider (1-100)
   - Acceleration factor slider (1.0-3.0)
   - Curve dropdown (Linear, Exponential, S-curve)
   - Apply/Reset buttons

4. Implement PositionsTab
   - 3x3 grid of position buttons
   - Show coordinates on each slot
   - Right-click context menu (Save, Load, Clear)
   - Undo/Redo buttons

5. Implement AboutTab
   - Application name and version
   - System info (Python, GTK, display server)
   - Links (GitHub, docs)
   - License

6. Create StatusIndicator
   - Small floating GtkWindow
   - Shows: "Mouse Mode: ON/OFF"
   - Theme-aware background color
   - Configurable position (corner)
   - Hide when disabled (optional)

7. Create SystemTray
   - Use AppIndicator3
   - Menu items: Toggle, Settings, Exit
   - Icon changes based on state

8. Apply themes
   - Connect ThemeManager to CSS
   - Use GtkCssProvider for custom styling
   - Support all 7 color themes

## Todo List

- [ ] Create GTKApplication with proper app ID
- [ ] Create MainWindow with GtkNotebook
- [ ] Implement MovementTab (speed, acceleration)
- [ ] Implement PositionsTab (3x3 grid)
- [ ] Implement AboutTab (version info)
- [ ] Create StatusIndicator floating window
- [ ] Create SystemTray with AppIndicator3
- [ ] Connect tabs to ConfigManager
- [ ] Apply color themes via CSS
- [ ] Create SVG icons for app and tray
- [ ] Test on GNOME and KDE

## Success Criteria

- [ ] `mouse-on-numpad --settings` opens GUI
- [ ] Movement tab shows sliders, changes persist
- [ ] Position grid shows all 9 slots
- [ ] Clicking position loads it
- [ ] Tray icon appears in system tray
- [ ] Tray menu toggles enable/disable
- [ ] Status indicator shows current state
- [ ] Theme changes apply immediately

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| GTK 4 learning curve | Medium | Follow PyGObject docs |
| AppIndicator not on all DEs | Low | Fallback to GtkStatusIcon |
| Theme CSS complexity | Low | Start with minimal styling |
| Window position persistence | Low | Store in config |

## Security Considerations

- GUI runs as user, no elevated privileges
- No network access
- Config changes written to user files only

## Next Steps

After Phase 4 complete:
- MVP functional with GUI
- Phase 5: Wayland support
- Future: Add remaining 4 tabs
