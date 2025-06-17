#Requires AutoHotkey v2.0

; ######################################################################################################################
; Main Entry Point - Mouse on Numpad Enhanced with Working Color Theme Support
; Version: 2.1.5 - Fixed Theme Application
; ######################################################################################################################

; Include all modules in correct order
#Include "Config.ahk"
#Include "StateManager.ahk"
#Include "MonitorUtils.ahk"
#Include "ColorThemeManager.ahk"  ; MUST be before tooltip and status modules
#Include "TooltipSystem.ahk"      ; Updated version with theme support
#Include "StatusIndicator.ahk"    ; Updated version with theme support
#Include "MouseActions.ahk"
#Include "PositionMemory.ahk"
#Include "HotkeyManager.ahk"

; Include Settings GUI modules
#Include "GUI\SettingsGUI_Base.ahk"
#Include "GUI\SettingsGUI_TabManager.ahk"

; Include Tab modules
#Include "GUI\Tabs\MovementTabModule.ahk"
#Include "GUI\Tabs\PositionsTabModule.ahk"
#Include "GUI\Tabs\VisualsTabModule.ahk"
#Include "GUI\Tabs\HotkeysTabModule.ahk"
#Include "GUI\Tabs\AdvancedTabModule.ahk"
#Include "GUI\Tabs\ProfilesTabModule.ahk"
#Include "GUI\Tabs\AboutTabModule.ahk"

; ======================================================================================================================
; Main Initialization
; ======================================================================================================================

initialize() {
    ; CRITICAL: Set coordinate mode to Screen for proper negative coordinate handling
    CoordMode("Mouse", "Screen")
    CoordMode("Pixel", "Screen")
    CoordMode("ToolTip", "Screen")
    CoordMode("Menu", "Screen")
    CoordMode("Caret", "Screen")
    
    ; Load configuration FIRST
    Config.Load()
    
    ; Initialize state manager
    StateManager.Initialize()
    
    ; Initialize color theme system BEFORE creating any GUIs
    ColorThemeManager.Initialize()
    
    ; Set up exit handler
    OnExit(onScriptExit)
    
    ; Initialize monitor system
    MonitorUtils.Init()
    
    ; Initialize all GUI systems (they will use the current theme)
    TooltipSystem.Initialize()
    StatusIndicator.Initialize()
    
    ; Load position memory
    PositionMemory.LoadPositions()
    
    ; Start periodic checks
    SetTimer(checkFullscreenPeriodically, 500)
    
    ; Force initial status update to ensure colors are applied
    StatusIndicator.Update()
}

onScriptExit(ExitReason, ExitCode) {
    if (!StateManager.IsReloading()) {
        ; Save current theme preference
        ColorThemeManager.SaveTheme()
        Config.Save()
    }
    
    PositionMemory.SavePositions()
    TooltipSystem.Cleanup()
    StatusIndicator.Cleanup()
    
    SetTimer(checkFullscreenPeriodically, 0)
}

checkFullscreenPeriodically() {
    ; Refresh monitor configuration periodically (every 10 checks)
    static checkCount := 0
    checkCount++
    if (checkCount >= 10) {
        MonitorUtils.Refresh()
        checkCount := 0
    }
    
    StatusIndicator.UpdateVisibility()
    TooltipSystem.HandleFullscreen()
}

; ======================================================================================================================
; Theme Testing and Debug Hotkeys
; ======================================================================================================================

; Theme cycle test (Ctrl+Alt+T) - cycles through all themes
^!t::{
    static themeIndex := 1
    themes := ColorThemeManager.GetThemeList()
    
    themeIndex++
    if (themeIndex > themes.Length) {
        themeIndex := 1
    }
    
    ColorThemeManager.SetTheme(themes[themeIndex])
    TooltipSystem.ShowStandard("Theme: " . themes[themeIndex], "info", 2000)
    
    ; Force status update
    StatusIndicator.Update()
}

; Force theme application (Ctrl+Alt+F) - reapplies current theme
^!f::{
    currentTheme := ColorThemeManager.GetCurrentTheme()
    
    ; Force reapply the current theme
    ColorThemeManager.SetTheme(currentTheme)
    
    ; Force update all components
    StatusIndicator.Update()
    
    ; Show confirmation
    TooltipSystem.ShowStandard("Theme Reapplied: " . currentTheme, "success", 2000)
}

; Theme debug info (Ctrl+Alt+Shift+T) - shows current theme details
^!+d::{
    currentTheme := ColorThemeManager.GetCurrentTheme()
    savedTheme := Config.ColorTheme
    
    debugInfo := "Theme Debug Info:`n`n"
    debugInfo .= "Current Active Theme: " . currentTheme . "`n"
    debugInfo .= "Saved Config Theme: " . savedTheme . "`n`n"
    
    ; Get theme colors
    debugInfo .= "Current Theme Colors:`n"
    debugInfo .= ColorThemeManager.ExportCurrentTheme()
    
    MsgBox(debugInfo, "Theme Debug", "Iconi")
}

; Debug mode (Ctrl+Alt+D) - checks for stray GUI elements
^!d::{
    ; Test theme colors with different tooltip types
    TooltipSystem.ShowStandard("Info Tooltip", "info", 1500)
    SetTimer(() => TooltipSystem.ShowStandard("Success Tooltip", "success", 1500), -1700)
    SetTimer(() => TooltipSystem.ShowStandard("Warning Tooltip", "warning", 1500), -3400)
    SetTimer(() => TooltipSystem.ShowStandard("Error Tooltip", "error", 1500), -5100)
    
    ; Test mouse action tooltip
    SetTimer(() => TooltipSystem.ShowMouseAction("Mouse Action Test", "success"), -7000)
    
    ; Test status messages
    SetTimer(() => StatusIndicator.ShowTemporaryMessage("Temporary Status", "info", 1000), -11500)
}

; ======================================================================================================================
; Start the Application
; ======================================================================================================================

; Initialize and start
initialize()

