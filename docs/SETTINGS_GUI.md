# Settings GUI Guide

Open the Settings GUI with Ctrl+Alt+S or programmatically via `SettingsGUI.Show()`.

## Tabs
- Movement: Configure speed, acceleration, max speed, scroll behavior, absolute/relative movement.
- Positions: Manage saved positions, preview/go to, import/export, monitor testing, backup/restore saved positions.
- Visuals: Theme selection, audio feedback, status visibility, monitor selection, UI positions (with testers).
- Hotkeys: View and change key bindings, detect conflicts, test, reset individual/all.
- Advanced: Performance toggles, logging, experimental features, resets, and system info.
- Profiles: Manage named configurations (load/save/update/delete/import/export; future enhancements noted in UI).
- About: Version info, system diagnostics, links to documentation and issue reporting.

## Applying Changes
- Click Apply to save without closing; OK to save and close. Cancel discards changes.
- Changes are written via `Config.Set(...)` and `Config.Save()`; some changes (e.g., theme) apply immediately.

## Programmatic Access
While the tab modules are primarily internal, `SettingsGUI` exposes:
- `SettingsGUI.Show()` — open or focus the settings window

Advanced automation can inspect or manipulate controls stored in `SettingsGUI.controls` after `Show()` for custom workflows.