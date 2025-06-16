#Requires AutoHotkey v2.0

; ######################################################################################################################
; Main Entry Point - Mouse on Numpad Enhanced
; Version: 2.1.3 - Modular Structure
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
#Include "TooltipSystem.ahk"
#Include "StatusIndicator.ahk"
#Include "MouseActions.ahk"
#Include "PositionMemory.ahk"
#Include "HotkeyManager.ahk"
#Include "SettingsGUI.ahk"

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