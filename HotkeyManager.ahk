#Requires AutoHotkey v2.0

; ######################################################################################################################
; Hotkey Manager Module - All hotkey definitions organized by category
; ######################################################################################################################

; Ensure we're using screen coordinates globally
CoordMode("Mouse", "Screen")
CoordMode("Pixel", "Screen")
CoordMode("ToolTip", "Screen")
CoordMode("Menu", "Screen")
CoordMode("Caret", "Screen")

; ======================================================================================================================
; Global Hotkeys (Always Active)
; ======================================================================================================================

NumpadAdd::{
    StateManager.ToggleMouseMode()
    StatusIndicator.Update()
}

NumpadMult::{
    StateManager.ToggleSaveMode()
    StatusIndicator.Update()
}

NumpadSub::{
    StateManager.ToggleLoadMode()
    StatusIndicator.Update()
}

NumpadDiv::{
    MouseActions.UndoLastMovement()
}

^NumpadAdd::{
    StateManager.ToggleStatusVisibility()
    StatusIndicator.UpdateVisibility()
    StatusIndicator.Update()
    StatusIndicator.ShowToggleMessage()
}

^!r::{
    StateManager.ReloadWithGUI()
}

; Secondary Monitor Toggle - Alt+Numpad9
!Numpad9::{
    StateManager.ToggleSecondaryMonitor()
    StatusIndicator.Update()
    StatusIndicator.ShowSecondaryMonitorToggle()
}

; Monitor Test - Ctrl+Alt+Numpad9
^!Numpad9::{
    mon := MonitorUtils.GetMonitorInfo()
    monType := mon.isPrimary ? "PRIMARY" : "SECONDARY"
    
    MonitorUtils.CreatePositionTest(mon, "TOP-LEFT", mon.left + 20, mon.top + 20)
    MonitorUtils.CreatePositionTest(mon, "TOP-RIGHT", mon.right - 220, mon.top + 20)
    MonitorUtils.CreatePositionTest(mon, "BOTTOM-LEFT", mon.left + 20, mon.bottom - 60)
    MonitorUtils.CreatePositionTest(mon, "BOTTOM-RIGHT", mon.right - 220, mon.bottom - 60)
    MonitorUtils.CreatePositionTest(mon, "CENTER", mon.left + (mon.width//2) - 100, 
                   mon.top + (mon.height//2) - 15)
    
    result := monType " Monitor`n"
            . "Size: " mon.width "x" mon.height "`n"
            . "Position: " mon.left "," mon.top
    TooltipSystem.ShowForced(result, "info")
}

; Settings GUI Show - Ctrl+Alt+s
^!s::{
    SettingsGUI.Show()
}

; ======================================================================================================================
; Position Memory Hotkeys (Active only when in Save Mode or Load Mode)
; ======================================================================================================================

#HotIf (StateManager.IsSaveMode() || StateManager.IsLoadMode())

Numpad4::{
    PositionMemory.HandleSlot(1)
}

Numpad5::{
    PositionMemory.HandleSlot(2)
}

Numpad6::{
    PositionMemory.HandleSlot(3)
}

Numpad8::{
    PositionMemory.HandleSlot(4)
}

Numpad0::{
    PositionMemory.HandleSlot(5)
}

#HotIf

; ======================================================================================================================
; Mouse Mode Hotkeys (Active only when Mouse Mode is ON and NOT in Save/Load Mode)
; ======================================================================================================================

#HotIf StateManager.IsMouseMode() && !StateManager.IsSaveMode() && !StateManager.IsLoadMode()

Numpad8::{
    MouseActions.MoveDiagonal("Numpad8", 0, -Config.MoveStep)
}

Numpad2::{
    MouseActions.MoveDiagonal("Numpad2", 0, Config.MoveStep)
}

Numpad4::{
    MouseActions.MoveDiagonal("Numpad4", -Config.MoveStep, 0)
}

Numpad6::{
    MouseActions.MoveDiagonal("Numpad6", Config.MoveStep, 0)
}

Numpad5::{
    Click("left")
}

NumpadClear::{
    if (StateManager.IsLeftButtonHeld()) {
        StateManager.SetLeftButtonHeld(false)
        Click("Left", , , , , "U")
        TooltipSystem.ShowMouseAction("🖱️ Left Released", "info")
        
        if (Config.EnableAudioFeedback) {
            SoundBeep(400, 100)
        }
    } else {
        StateManager.SetLeftButtonHeld(true)
        Click("Left", , , , , "D")
        TooltipSystem.ShowMouseAction("🖱️ Left Held", "success")
        
        if (Config.EnableAudioFeedback) {
            SoundBeep(500, 100)
        }
    }
    
    Sleep(150)
    StatusIndicator.Update()
}

Numpad0::{
    Click("right")
}

NumpadIns::{
    if (StateManager.IsRightButtonHeld()) {
        StateManager.SetRightButtonHeld(false)
        Click("Right", , , , , "U")
        TooltipSystem.ShowMouseAction("🖱️ Right Released", "warning")
        
        if (Config.EnableAudioFeedback) {
            SoundBeep(400, 100)
        }
    } else {
        StateManager.SetRightButtonHeld(true)
        Click("Right", , , , , "D")
        TooltipSystem.ShowMouseAction("🖱️ Right Held", "success")
        
        if (Config.EnableAudioFeedback) {
            SoundBeep(600, 100)
        }
    }
    
    Sleep(150)
    StatusIndicator.Update()
}

NumpadDot::{
    wasInvertedMode := StateManager.IsInvertedMode()
    wasRightHeld := StateManager.IsRightButtonHeld()
    
    if (wasInvertedMode && wasRightHeld) {
        StateManager.ToggleInvertedMode()
        StateManager.SetRightButtonHeld(false)
        Click("Right", , , , , "U")
        TooltipSystem.ShowMouseAction("🔄🖱️ Both Off", "warning")
        Sleep(150)
        StatusIndicator.Update()
    } else if (wasInvertedMode && !wasRightHeld) {
        StateManager.SetRightButtonHeld(true)
        Click("Right", , , , , "D")
        TooltipSystem.ShowMouseAction("🖱️ Right Added", "success")
        Sleep(150)
        StatusIndicator.Update()
    } else if (!wasInvertedMode && wasRightHeld) {
        StateManager.ToggleInvertedMode()
        TooltipSystem.ShowMouseAction("🔄 Inverted Added", "success")
        Sleep(150)
        StatusIndicator.Update()
    } else {
        StateManager.ToggleInvertedMode()
        Sleep(100)
        StateManager.SetRightButtonHeld(true)
        Click("Right", , , , , "D")
        TooltipSystem.ShowMouseAction("🔄🖱️ Both On", "success")
        Sleep(150)
        StatusIndicator.Update()
    }
}

!Numpad1::{
    wasInvertedMode := StateManager.IsInvertedMode()

    if wasInvertedMode  {
        StateManager.ToggleInvertedMode()
        TooltipSystem.ShowMouseAction("🔄 Inverted Off", "warning")
        Sleep(150)
        StatusIndicator.Update()
    } else if !wasInvertedMode  {
        StateManager.ToggleInvertedMode()
        TooltipSystem.ShowMouseAction("🔄 Inverted On", "success")
        Sleep(150)
        StatusIndicator.Update()
    }
}

NumpadEnter::{
    Click("middle")
}

+NumpadEnter::{
    if (StateManager.IsMiddleButtonHeld()) {
        StateManager.SetMiddleButtonHeld(false)
        Click("Middle", , , , , "U")
        TooltipSystem.ShowMouseAction("🖱️ Middle Released", "warning")
        
        if (Config.EnableAudioFeedback) {
            SoundBeep(350, 100)
        }
    } else {
        StateManager.SetMiddleButtonHeld(true)
        Click("Middle", , , , , "D")
        TooltipSystem.ShowMouseAction("🖱️ Middle Held", "success")
        
        if (Config.EnableAudioFeedback) {
            SoundBeep(550, 100)
        }
    }
    
    Sleep(150)
    StatusIndicator.Update()
}

Numpad7::{
    MouseActions.ScrollWithAcceleration("Up", "Numpad7")
}

Numpad1::{
    MouseActions.ScrollWithAcceleration("Down", "Numpad1")
}

Numpad9::{
    MouseActions.ScrollWithAcceleration("Left", "Numpad9")
}

Numpad3::{
    MouseActions.ScrollWithAcceleration("Right", "Numpad3")
}

#HotIf