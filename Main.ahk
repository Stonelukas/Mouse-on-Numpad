#Requires AutoHotkey v2.0

; ######################################################################################################################
; Main Entry Point - Mouse on Numpad Enhanced with Color Theme Support
; Version: 2.1.4 - Modular Structure with Themes
; ######################################################################################################################
;
; IMPORTANT: This script properly handles negative monitor coordinates.
; CoordMode is set to "Screen" for all coordinate operations to ensure
; proper handling of monitors positioned to the left or above the primary monitor.
; ######################################################################################################################

; Include all modules
#Include "Config.ahk"
#Include "StateManager.ahk"
#Include "MonitorUtils.ahk"
#Include "ColorThemeManager.ahk"  ; NEW: Include before tooltip and status modules
#Include "TooltipSystem.ahk"
#Include "StatusIndicator.ahk"
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
    
    ; Load configuration
    Config.Load()
    StateManager.Initialize()
    
    ; Initialize color theme system
    ColorThemeManager.Initialize()
    
    ; Set up exit handler
    OnExit(onScriptExit)
    
    ; Initialize monitor system
    MonitorUtils.Init()
    
    ; Initialize all systems
    TooltipSystem.Initialize()
    StatusIndicator.Initialize()
    ; Initialize Settings GUI system (but don't show it)
    ; The GUI will be created when first opened
    PositionMemory.LoadPositions()
    
    ; Start periodic checks
    SetTimer(checkFullscreenPeriodically, 500)
    
    ; Update initial status
    StatusIndicator.Update()
}

onScriptExit(ExitReason, ExitCode) {
    if (!StateManager.IsReloading()) {
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

; Start the application
initialize()

; Debug function to check for invisible GUIs (press Ctrl+Alt+D to use)
^!d::{
    ; Hide all known GUIs to identify any strays
    try {
        if (TooltipSystem.globalTooltip != "") {
            TooltipSystem.globalTooltip.Hide()
        }
        if (TooltipSystem.mouseTooltip != "") {
            TooltipSystem.mouseTooltip.Hide()
        }
        if (StatusIndicator.statusIndicator != "") {
            StatusIndicator.statusIndicator.Hide()
        }
        
        ; Show debug message
        MsgBox("All known GUIs hidden. If you still see something, it's an unknown GUI element.", "Debug", "T3")
        
        ; Restore visibility
        StatusIndicator.UpdateVisibility()
        TooltipSystem.UpdateVisibility()
    }
}

; Theme test hotkey (Ctrl+Alt+T)
^!t::{
    ; Cycle through themes for testing
    static themeIndex := 1
    themes := ["Default", "Dark Mode", "High Contrast", "Minimal"]
    
    themeIndex++
    if (themeIndex > themes.Length) {
        themeIndex := 1
    }
    
    ColorThemeManager.SetTheme(themes[themeIndex])
    TooltipSystem.ShowStandard("Theme: " . themes[themeIndex], "info", 2000)
}

; ######################################################################################################################
; Quick Patch for Theme Application
; ######################################################################################################################
; Add this to your Main.ahk after the initialize() function to fix theme application
; ######################################################################################################################

; Force theme application hotkey (Ctrl+Alt+F)
^!f::{
    ; Get the current saved theme
    currentTheme := Config.ColorTheme
    
    if (currentTheme = "") {
        currentTheme := "Default"
    }
    
    ; Force re-apply the theme
    ColorThemeManager.SetTheme(currentTheme)
    
    ; Force update of status indicator
    if (StatusIndicator.statusIndicator != "") {
        ; Get the current state colors
        backgroundColor := ""
        
        if (!StateManager.IsMouseMode()) {
            backgroundColor := ColorThemeManager.GetColor("statusOff")
        } else if (StateManager.IsSaveMode()) {
            backgroundColor := ColorThemeManager.GetColor("statusSave")
        } else if (StateManager.IsLoadMode()) {
            backgroundColor := ColorThemeManager.GetColor("statusLoad")
        } else if (StateManager.IsInvertedMode()) {
            backgroundColor := ColorThemeManager.GetColor("statusInverted")
        } else {
            backgroundColor := ColorThemeManager.GetColor("statusOn")
        }
        
        ; Apply the color
        StatusIndicator.statusIndicator.BackColor := backgroundColor
        
        ; Update text color for contrast
        textColor := GetContrastingColor(backgroundColor)
        StatusIndicator.statusIndicator.textCtrl.SetFont("c" . textColor)
    }
    
    ; Test with a tooltip
    if (TooltipSystem.globalTooltip != "") {
        bgColor := ColorThemeManager.GetColor("tooltipInfo")
        TooltipSystem.globalTooltip.BackColor := bgColor
        
        textColor := GetContrastingColor(bgColor)
        TooltipSystem.globalTooltip.textCtrl.SetFont("c" . textColor)
    }
    
    ; Show confirmation
    TooltipSystem.ShowStandard("Theme Applied: " . currentTheme, "success", 2000)
    
    ; Update status
    StatusIndicator.Update()
}

; Also fix the MsgBox debug info error
^!+t::{
    currentTheme := ColorThemeManager.GetCurrentTheme()
    savedTheme := Config.ColorTheme
    
    debugInfo := "Theme Debug Info:`n`n"
    debugInfo .= "Current Active Theme: " . currentTheme . "`n"
    debugInfo .= "Saved Config Theme: " . savedTheme . "`n`n"
    debugInfo .= "Current Colors:`n"
    
    ; Get theme export separately
    themeExport := ColorThemeManager.ExportCurrentTheme()
    debugInfo .= themeExport
    
    ; Fix the msgbox call - options parameter must be a string
    MsgBox(debugInfo, "Theme Debug", "Iconi")
}