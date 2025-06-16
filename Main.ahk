#Requires AutoHotkey v2.0

; ######################################################################################################################
; Main Entry Point - Mouse on Numpad Enhanced
; Version: 2.1.3 - Modular Structure
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

; ======================================================================================================================
; Main Initialization
; ======================================================================================================================

initialize() {
    ; Load configuration
    Config.Load()
    StateManager.Initialize()
    
    ; Set up exit handler
    OnExit(onScriptExit)
    
    ; Initialize all systems
    TooltipSystem.Initialize()
    StatusIndicator.Initialize()
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