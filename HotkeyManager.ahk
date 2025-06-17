#Requires AutoHotkey v2.0

; ######################################################################################################################
; Hotkey Manager - All hotkey definitions
; ######################################################################################################################

; ======================================================================================================================
; CONTROL HOTKEYS
; ======================================================================================================================

; Toggle mouse mode on/off
^!t:: State.ToggleMouseMode()

; Toggle save mode
^!s:: State.ToggleSaveMode()

; Toggle load mode  
^!l:: State.ToggleLoadMode()

; Toggle status visibility
^!v:: StatusIndicator.Toggle()

; Undo last movement
^!z:: {
    if (State.mouseMode) {
        MouseActions.Undo()
    }
}

; Exit script
^!q:: ExitScript()

; Open settings
^!+s:: SettingsGUI.Show()

; ======================================================================================================================
; MOVEMENT HOTKEYS (When mouse mode is active)
; ======================================================================================================================

#HotIf State.mouseMode

; Movement keys with acceleration
Numpad8:: MouseActions.StartMove("up")
Numpad8 Up:: MouseActions.StopMove()

Numpad2:: MouseActions.StartMove("down")
Numpad2 Up:: MouseActions.StopMove()

Numpad4:: MouseActions.StartMove("left")
Numpad4 Up:: MouseActions.StopMove()

Numpad6:: MouseActions.StartMove("right")
Numpad6 Up:: MouseActions.StopMove()

; Diagonal movements
Numpad7:: MouseActions.StartMove("up-left")
Numpad7 Up:: MouseActions.StopMove()

Numpad9:: MouseActions.StartMove("up-right")
Numpad9 Up:: MouseActions.StopMove()

Numpad1:: MouseActions.StartMove("down-left")
Numpad1 Up:: MouseActions.StopMove()

Numpad3:: MouseActions.StartMove("down-right")
Numpad3 Up:: MouseActions.StopMove()

; Mouse clicks
Numpad5:: MouseActions.Click("left")
NumpadDot:: MouseActions.Click("right")
NumpadDel:: MouseActions.Click("right")

; Scroll wheel
NumpadAdd:: MouseActions.Scroll("up")
NumpadSub:: MouseActions.Scroll("down")

; Toggle invert mode
NumpadClear:: State.ToggleInvertMode()

; Center mouse on screen
Numpad0:: {
    mon := MonitorUtils.GetMonitorInfo()
    centerX := mon.left + (mon.width // 2)
    centerY := mon.top + (mon.height // 2)
    MouseMove(centerX, centerY, 0)
    TooltipSystem.ShowTemporary("🎯 Centered", "info", 500)
}

#HotIf

; ======================================================================================================================
; POSITION SAVE HOTKEYS (Ctrl + Numpad in save mode)
; ======================================================================================================================

#HotIf State.saveMode

^Numpad1:: PositionMemory.SavePosition(1)
^Numpad2:: PositionMemory.SavePosition(2)
^Numpad3:: PositionMemory.SavePosition(3)
^Numpad4:: PositionMemory.SavePosition(4)
^Numpad5:: PositionMemory.SavePosition(5)
^Numpad6:: PositionMemory.SavePosition(6)
^Numpad7:: PositionMemory.SavePosition(7)
^Numpad8:: PositionMemory.SavePosition(8)
^Numpad9:: PositionMemory.SavePosition(9)
^Numpad0:: PositionMemory.SavePosition(10)

; Extended slots with NumpadDot
^NumpadDot:: {
    ; Show slot selection GUI
    slotGui := Gui("+AlwaysOnTop", "Save to Slot")
    slotGui.Add("Text", , "Enter slot number (11-30):")
    slotEdit := slotGui.Add("Edit", "w100 Number")
    slotGui.Add("Button", "w50", "Save").OnEvent("Click", (*) => SaveToSlot())
    slotGui.Add("Button", "x+10 w50", "Cancel").OnEvent("Click", (*) => slotGui.Destroy())
    
    SaveToSlot() {
        slot := slotEdit.Text
        if (slot >= 11 && slot <= Config.MaxSavedPositions) {
            PositionMemory.SavePosition(slot)
            slotGui.Destroy()
        } else {
            MsgBox("Invalid slot number. Use 11-" . Config.MaxSavedPositions, "Error", "Icon!")
        }
    }
    
    slotGui.Show()
}

#HotIf

; ======================================================================================================================
; POSITION LOAD HOTKEYS (Alt + Numpad in load mode)
; ======================================================================================================================

#HotIf State.loadMode

!Numpad1:: PositionMemory.LoadPosition(1)
!Numpad2:: PositionMemory.LoadPosition(2)
!Numpad3:: PositionMemory.LoadPosition(3)
!Numpad4:: PositionMemory.LoadPosition(4)
!Numpad5:: PositionMemory.LoadPosition(5)
!Numpad6:: PositionMemory.LoadPosition(6)
!Numpad7:: PositionMemory.LoadPosition(7)
!Numpad8:: PositionMemory.LoadPosition(8)
!Numpad9:: PositionMemory.LoadPosition(9)
!Numpad0:: PositionMemory.LoadPosition(10)

; Extended slots with NumpadDot
!NumpadDot:: {
    ; Show slot selection GUI
    slotGui := Gui("+AlwaysOnTop", "Load from Slot")
    slotGui.Add("Text", , "Enter slot number (11-30):")
    slotEdit := slotGui.Add("Edit", "w100 Number")
    slotGui.Add("Button", "w50", "Load").OnEvent("Click", (*) => LoadFromSlot())
    slotGui.Add("Button", "x+10 w50", "Cancel").OnEvent("Click", (*) => slotGui.Destroy())
    
    LoadFromSlot() {
        slot := slotEdit.Text
        if (slot >= 11 && slot <= Config.MaxSavedPositions) {
            PositionMemory.LoadPosition(slot)
            slotGui.Destroy()
        } else {
            MsgBox("Invalid slot number. Use 11-" . Config.MaxSavedPositions, "Error", "Icon!")
        }
    }
    
    slotGui.Show()
}

#HotIf

; ======================================================================================================================
; QUICK ACCESS POSITION HOTKEYS (Always active)
; ======================================================================================================================

; Quick save positions (Ctrl+Shift+Numpad)
^+Numpad1:: {
    if (!State.saveMode) {
        PositionMemory.SavePosition(1)
    }
}

^+Numpad2:: {
    if (!State.saveMode) {
        PositionMemory.SavePosition(2)
    }
}

^+Numpad3:: {
    if (!State.saveMode) {
        PositionMemory.SavePosition(3)
    }
}

; Quick load positions (Alt+Shift+Numpad)
!+Numpad1:: {
    if (!State.loadMode) {
        PositionMemory.LoadPosition(1)
    }
}

!+Numpad2:: {
    if (!State.loadMode) {
        PositionMemory.LoadPosition(2)
    }
}

!+Numpad3:: {
    if (!State.loadMode) {
        PositionMemory.LoadPosition(3)
    }
}

; ======================================================================================================================
; DEBUG HOTKEYS (Development only)
; ======================================================================================================================

#HotIf Config.EnableLogging

; Show debug information
^!+d:: {
    debugText := "DEBUG INFORMATION`n"
    debugText .= "================`n`n"
    debugText .= "Mouse Mode: " . (State.mouseMode ? "ON" : "OFF") . "`n"
    debugText .= "Save Mode: " . (State.saveMode ? "ON" : "OFF") . "`n"
    debugText .= "Load Mode: " . (State.loadMode ? "ON" : "OFF") . "`n"
    debugText .= "Invert Mode: " . (State.invertMode ? "ON" : "OFF") . "`n`n"
    debugText .= "Move Count: " . State.moveCount . "`n"
    debugText .= "Current Speed: " . State.currentSpeed . "`n"
    debugText .= "Consecutive Moves: " . State.consecutiveMoves . "`n`n"
    debugText .= "Undo History: " . State.undoHistory.Length . " items`n"
    debugText .= "Analytics Events: " . AnalyticsSystem.events.Length . "`n"
    
    MsgBox(debugText, "Debug Info", "Iconi")
}

; Show performance stats
^!+p:: PerformanceMonitor.ShowStats()

; Show analytics report
^!+a:: AnalyticsSystem.ShowReport()

; Test notification
^!+n:: {
    TooltipSystem.ShowTemporary("🧪 Test notification", "info", 2000)
    StatusIndicator.ShowMessage("🧪 Test status message", 2000)
}

#HotIf

; ======================================================================================================================
; END OF HOTKEYS
; ======================================================================================================================