# Usage and Setup

## Requirements
- AutoHotkey v2.0
- Windows (for GUI/monitor APIs used in this project)

## Getting Started
1. Place all `.ahk` files in the same folder.
2. Run `Main.ahk` — this is the entry point.
3. Press Ctrl+Alt+S to open the Settings GUI.

## Initialization Order (handled by Main.ahk)
The app configures coordinate modes and initializes these systems in order:
1. `Config.Initialize()` and `Config.Load()`
2. `ErrorLogger.Initialize()`
3. `StateManager.Initialize()`
4. `ColorThemeManager.Initialize()`
5. `MonitorUtils.Init()`
6. `TooltipSystem.Initialize()`
7. `StatusIndicator.Initialize()`
8. `PositionMemory.LoadPositions()`
9. `HotkeyManager.Initialize()`

A periodic fullscreen check runs every 500ms to auto-hide UI when apps go fullscreen.

## Configuration Files
- Settings: `settings.ini` (created next to scripts)
- Saved positions: `positions.dat` (path via `Config.PersistentPositionsFile`)

## Quick Examples (AHK v2)
```autohotkey
; Change theme
ColorThemeManager.SetTheme("Dark Mode")

; Show short info tooltip
TooltipSystem.ShowStandard("Info message", "info", 1500)

; Show 4-sec mouse action tooltip
TooltipSystem.ShowMouseAction("Left Held", "success")

; Toggle mouse mode and move up while key held
StateManager.ToggleMouseMode()
MouseActions.MoveInDirection("Up")

; Save/restore a position
PositionMemory.SavePosition(1)
PositionMemory.RestorePosition(1)

; Update a hotkey binding at runtime
HotkeyManager.UpdateHotkey("MoveUp", "^!Up")
Config.Save()
```

## Opening the Settings GUI
- Keyboard shortcut: Ctrl+Alt+S
- Or programmatically:
```autohotkey
SettingsGUI.Show()
```

## Fullscreen Handling
- When an app goes fullscreen, tooltips and status indicator auto-hide.
- When fullscreen ends, the status indicator restores if configured visible.