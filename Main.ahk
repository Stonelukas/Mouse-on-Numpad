#Requires AutoHotkey v2.0

; ######################################################################################################################
; Main Entry Point - Mouse on Numpad Enhanced with Working Color Theme Support
; Version: 2.1.5 - Fixed Theme Application and Config Access
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

    ; Initialize configuration system FIRST
    Config.Initialize() ; This will create the file if needed and load settings

    ; Initialize state manager
    StateManager.Initialize()

    ; Initialize color theme system BEFORE creating any GUIs 
    ColorThemeManager.Initialize()
    
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

onScriptExit(*) {
    ; Save configuration
    Config.Save()
    
    ; Save positions
    PositionMemory.SavePositions()
    
    ; Clean up tooltips
    TooltipSystem.HideAll()
    
    ; Hide status indicator
    StatusIndicator.Hide()
}

checkFullscreenPeriodically() {
    ; Check if any app is fullscreen
    wasFullscreen := StateManager.isFullscreenActive
    StateManager.isFullscreenActive := MonitorUtils.IsFullscreen()
    
    ; Handle state change
    if (StateManager.isFullscreenActive && !wasFullscreen) {
        TooltipSystem.HideAll()
        StatusIndicator.Hide()
    } else if (!StateManager.isFullscreenActive && wasFullscreen) {
        if (StateManager.statusVisible) {
            StatusIndicator.Show()
        }
    }
}

; ======================================================================================================================
; Global Shortcut Documentation
; ======================================================================================================================

; Show help (Ctrl+Alt+H)
^!h::{
    helpText := "
    (
🖱️ MOUSE ON NUMPAD ENHANCED - KEYBOARD SHORTCUTS 🖱️

====== MAIN CONTROLS ======
Numpad +        Toggle Mouse Mode ON/OFF
Numpad *        Enter Save Position Mode
Numpad -        Enter Load Position Mode
Numpad /        Undo Last Movement

====== SETTINGS & DISPLAY ======
Ctrl+Numpad +   Toggle Status Display
Ctrl+Alt+S      Open Settings GUI
Ctrl+Alt+R      Reload Script
Ctrl+Alt+H      Show This Help

====== MONITOR CONTROLS ======
Alt+Numpad 9    Toggle Secondary Monitor
Ctrl+Alt+Numpad 9   Test Monitor Configuration

====== THEME SHORTCUTS ======
Ctrl+Shift+1-7  Quick Theme Switch
Ctrl+Alt+Shift+T    Theme Debug Info

====== MOUSE MOVEMENT (When Mouse Mode ON) ======
Numpad 8        Move Up
Numpad 2        Move Down
Numpad 4        Move Left
Numpad 6        Move Right
Numpad 7/9/1/3  Diagonal Movement
Numpad 5        Left Click (hold to drag)
Numpad 0        Right Click
Numpad .        Middle Click

====== POSITION MEMORY (In Save/Load Mode) ======
Numpad 1-9      Save/Load Position Slot
    )"
    
    MsgBox(helpText, "Keyboard Shortcuts", "Iconi")
}

; Open Settings GUI (Ctrl+Alt+S)
^!s::{
    SettingsGUI.Show()
}

; Reload Script (Ctrl+Alt+R)
^!r::{
    StateManager.ReloadScript()
}

; Quick theme switching (Ctrl+Shift+1 through 7)
^+1::ColorThemeManager.SetTheme("Default")
^+2::ColorThemeManager.SetTheme("Dark Mode")
^+3::ColorThemeManager.SetTheme("High Contrast")
^+4::ColorThemeManager.SetTheme("Ocean")
^+5::ColorThemeManager.SetTheme("Forest")
^+6::ColorThemeManager.SetTheme("Sunset")
^+7::ColorThemeManager.SetTheme("Minimal")

; Theme change notification
^+8::{
    currentTheme := ColorThemeManager.GetCurrentTheme()
    TooltipSystem.ShowStandard("Current theme: " . currentTheme, "success", 2000)
}

; Theme debug info (Ctrl+Alt+Shift+T) - shows current theme details
^!+d::{
    currentTheme := ColorThemeManager.GetCurrentTheme()
    savedTheme := Config.Get("Visual.ColorTheme", "Default")
    
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