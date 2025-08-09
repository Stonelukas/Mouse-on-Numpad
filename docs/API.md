# API Reference (AutoHotkey v2)

This reference lists public classes, methods, and functions designed for use across the project. Internal helpers are omitted or noted as internal.

Note: All modules are included by `Main.ahk` and initialize themselves in the correct order.

## Main
- `initialize()` — Entry-point initializer invoked at end of `Main.ahk`.

## Config (Config.ahk)
- `Config.Initialize()` — Prepares defaults, creates file if needed, loads values
- `Config.Load()` / `Config.Save()`
- `Config.CreateDefaultConfigFile()` — Creates `settings.ini` populated with defaults
- `Config.Get(key, default?)` -> any
- `Config.Set(key, value)`
- `Config.Has(key)` -> bool
- `Config.GetSection(section)` -> Map of keys in that section
- `Config.PersistentPositionsFile` — path to positions file
- `Config.StatusVisibleOnStartup` — bool

Example:
```autohotkey
if (!Config.Has("Visual.ColorTheme")) {
  Config.Set("Visual.ColorTheme", "Default")
}
Config.Save()
```

## StateManager (StateManager.ahk)
- Modes: `ToggleMouseMode()`, `ToggleInvertedMode()`, `ToggleSaveMode()`, `ToggleLoadMode()`
- Visibility: `ToggleStatusVisibility()`
- Monitors: `ToggleSecondaryMonitor()`
- Fullscreen: `SetFullscreenState(active)`, `IsinFullscreen()`
- Buttons: `SetLeftButtonHeld(v)`, `SetRightButtonHeld(v)`, `SetMiddleButtonHeld(v)`
- Getters: `IsMouseMode()`, `IsInvertedMode()`, `IsSaveMode()`, `IsLoadMode()`, `IsStatusVisible()`, `IsReloading()`
- Held-state getters: `IsLeftButtonHeld()`, `IsRightButtonHeld()`, `IsMiddleButtonHeld()`
- Last slot: `GetLastLoadedSlot()`, `SetLastLoadedSlot(slot)`
- Reload: `ReloadScript()`, `ReloadWithGUI()`
- Timers: `SetLeftClickHoldTimer(timer)`, `GetLeftClickHoldTimer()`, `ClearLeftClickHoldTimer()`

Example:
```autohotkey
StateManager.ToggleMouseMode()
if (StateManager.IsMouseMode()) {
  TooltipSystem.ShowStandard("Mouse Mode ON", "success")
}
```

## MonitorUtils (MonitorUtils.ahk)
- Lifecycle: `Init()`, `Refresh()`
- Monitor info: `GetMonitorFromPoint(x, y)` -> monitor|false, `GetMonitorInfo()` -> {left,top,right,bottom,...}
- GUI positions: `GetGuiPosition(which, customX?, customY?)` -> [x, y]
- Expressions: `EvaluateExpression(expr)` -> number
- Windows: `GetMonitorForWindow(hwnd)` -> monitor|false, `IsFullscreen()` -> bool
- Debug/testing: `CreatePositionTest(mon, label, x, y)`, `GetMonitorDescriptionForPosition(x, y)`, `ShowMonitorDebugInfo()` -> string

Example:
```autohotkey
pos := MonitorUtils.GetGuiPosition("tooltip")
TooltipSystem.ShowForced("At: " pos[1] "," pos[2], "info")
```

## TooltipSystem (TooltipSystem.ahk)
- Lifecycle: `Initialize()`, `Cleanup()`, `ApplyTheme()`
- Visibility: `UpdateVisibility()`, `HandleFullscreen()`, `HideAll()`
- Display: `ShowStandard(text, type := "info", duration := "")`, `ShowMouseAction(text, type := "success")`, `ShowForced(text, type := "info")`

Example:
```autohotkey
TooltipSystem.ShowStandard("Saved!", "success", 1200)
TooltipSystem.ShowMouseAction("Right Held", "warning")
```

## StatusIndicator (StatusIndicator.ahk)
- Lifecycle: `Initialize()`, `Cleanup()`, `ApplyTheme()`
- Update: `Update()`, `UpdateVisibility()`
- Transient messages: `ShowTemporaryMessage(text, type := "info", duration := 800)`
- Convenience: `ShowToggleMessage()`, `ShowSecondaryMonitorToggle()`

Example:
```autohotkey
StatusIndicator.ShowTemporaryMessage("↶ UNDONE", "success", 1000)
StatusIndicator.Update()
```

## MouseActions (MouseActions.ahk)
- Movement: `MoveInDirection(direction)` where direction is one of
  `"Left"|"Right"|"Up"|"Down"|"UpLeft"|"UpRight"|"DownLeft"|"DownRight"`
- Diagonals (two-key): `MoveDiagonal([key1, key2])`
- Clicks: `PerformClick(button := "Left")`
- Scroll: `ScrollWithAcceleration(direction, key)` where direction is `"Up"|"Down"|"Left"|"Right"`
- Undo: `UndoLastMove()` / `UndoLastMovement()`
- History: `GetPositionHistory()`, `AddToHistory(x, y)`

Example:
```autohotkey
MouseActions.PerformClick("Right")
MouseActions.ScrollWithAcceleration("Up", "!Numpad8")
```

## PositionMemory (PositionMemory.ahk)
- CRUD: `SavePosition(slot)`, `RestorePosition(slot)`, `ClearPosition(slot)`, `ClearAllPositions()`
- Mode-aware: `HandleSlot(slot)`
- Persistence: `LoadPositions()`, `SavePositions()`
- Query: `GetSavedPositions()`, `HasPosition(slot)`

Example:
```autohotkey
PositionMemory.SavePosition(2)
if (PositionMemory.HasPosition(2)) {
  PositionMemory.RestorePosition(2)
}
```

## HotkeyManager (HotkeyManager.ahk)
- Lifecycle: `Initialize()`
- Bindings: `UpdateHotkey(configKey, newKey)` -> bool, `UpdateMovementHotkeys()`
- Listing: `GetHotkeyList()` -> array of {configKey, description, currentKey, default}
- Handlers (callable): `ToggleMouseMode()`, `EnterSaveMode()`, `EnterLoadMode()`, `UndoLastMove()`, `ToggleStatusIndicator()`,
  `ReloadApplication()`, `ShowSettings()`, `ToggleSecondaryMonitor()`, `TestMonitors()`,
  `ToggleLeftButtonHold()`, `ToggleRightButtonHold()`, `ToggleMiddleButtonHold()`, `ToggleInvertedMode()`, `NumpadDotSpecial()`

Example:
```autohotkey
; Change one binding
HotkeyManager.UpdateHotkey("MoveUp", "Numpad8")
; Re-apply conditional movement hotkeys based on current state
HotkeyManager.UpdateMovementHotkeys()
```

## SettingsGUI (GUI/SettingsGUI_Base.ahk)
- Window: `SettingsGUI.Show()`
- Actions: `_ApplySettings()`, `_ApplyAndClose()`, `_Cancel()` — primarily invoked via UI buttons

## SettingsTabManager and BaseTabModule (GUI/SettingsGUI_TabManager.ahk)
- `SettingsTabManager.CreateTabControl(options, tabNames)` -> control
- `SettingsTabManager.RegisterModule(tabName, class)` -> module instance
- `SettingsTabManager.ValidateAll()` -> bool
- `SettingsTabManager.GetAllData()` -> Map
- `SettingsTabManager.ShowTab(tabName)`

- `class BaseTabModule` (extend for new tabs):
  - Lifecycle: `Initialize()` creates controls in the tab
  - Overridables: `CreateControls()`, `GetData()`, `Validate()`, `Refresh()`
  - Helpers: `AddControl(name, control)`

Example (adding a new tab):
```autohotkey
class MyTab extends BaseTabModule {
  CreateControls() {
    this.AddControl("Hello", this.gui.Add("Text", "x20 y50", "Hello World"))
  }
  GetData() { return Map("example", true) }
}
; Register:
; SettingsGUI.tabManager.RegisterModule("MyTab", MyTab)
```

## ColorThemeManager (ColorThemeManager.ahk)
See THEMING.md for details. Key methods: `SetTheme`, `GetColor`, `GetContrastingColor`, `AddCustomTheme`, `GetThemeNames`.

## ColorHelpers (ColorHelpers.ahk)
Utility functions: `ConvertHexToRGB`, `GetContrastingColor`, `ConvertRGBToHex`, `LightenColor`, `DarkenColor`, `MixColors`.

## ErrorLogger (ErrorLogger.ahk)
- Lifecycle: `Initialize()` (respects `Config.Debug.EnableLogging`)
- Logging: `LogError(msg, where?)`, `LogWarning(msg, where?)`, `LogInfo(msg, where?)`, `ClearLog()`
- Retrieval: `GetRecentEntries(n := 50)` -> string

Example:
```autohotkey
ErrorLogger.Initialize()
ErrorLogger.LogInfo("Something happened", "MyModule.Action")
MsgBox(ErrorLogger.GetRecentEntries(10))
```

## GUI Tab Modules (internal but discoverable)
- `MovementTabModule`, `PositionsTabModule`, `VisualsTabModule`, `HotkeysTabModule`, `AdvancedTabModule`, `ProfilesTabModule`, `AboutTabModule`
- Extend `BaseTabModule` and are registered by `SettingsGUI`.

## Notes
- Some method names contain legacy variants (e.g., `IsinFullscreen`). Prefer the provided methods as-is.
- Do not run module files directly; always start `Main.ahk`.