#Requires AutoHotkey v2.0

; ######################################################################################################################
; State Manager - Global application state management
; ######################################################################################################################

class State {
    ; Mode states
    static mouseMode := false
    static saveMode := false
    static loadMode := false
    static invertMode := false
    
    ; Movement tracking
    static currentSpeed := 0
    static moveCount := 0
    static lastMoveTime := 0
    static consecutiveMoves := 0
    
    ; Position tracking
    static lastX := 0
    static lastY := 0
    static undoHistory := []
    
    ; Timers
    static activeTimers := Map()
    
    ; Toggle mouse mode on/off
    static ToggleMouseMode() {
        State.mouseMode := !State.mouseMode
        
        ; Reset other modes when turning off
        if (!State.mouseMode) {
            State.saveMode := false
            State.loadMode := false
            State.currentSpeed := 0
            State.consecutiveMoves := 0
        }
        
        ; Update status indicator
        StatusIndicator.Update()
        
        ; Show feedback
        if (State.mouseMode) {
            TooltipSystem.ShowTemporary("🖱️ Mouse Mode: ON", "success")
        } else {
            TooltipSystem.ShowTemporary("🖱️ Mouse Mode: OFF", "error")
        }
    }
    
    ; Toggle save mode
    static ToggleSaveMode() {
        State.saveMode := !State.saveMode
        
        ; Turn off load mode if save mode is activated
        if (State.saveMode) {
            State.loadMode := false
        }
        
        ; Update UI
        StatusIndicator.Update()
        
        ; Show feedback
        if (State.saveMode) {
            TooltipSystem.ShowTemporary("💾 Save Mode: ON`nUse Ctrl+Numpad to save positions", "warning", 4000)
        } else {
            TooltipSystem.ShowTemporary("💾 Save Mode: OFF", "default")
        }
    }
    
    ; Toggle load mode
    static ToggleLoadMode() {
        State.loadMode := !State.loadMode
        
        ; Turn off save mode if load mode is activated
        if (State.loadMode) {
            State.saveMode := false
        }
        
        ; Update UI
        StatusIndicator.Update()
        
        ; Show feedback
        if (State.loadMode) {
            TooltipSystem.ShowTemporary("📂 Load Mode: ON`nUse Alt+Numpad to load positions", "info", 4000)
        } else {
            TooltipSystem.ShowTemporary("📂 Load Mode: OFF", "default")
        }
    }
    
    ; Toggle invert mode
    static ToggleInvertMode() {
        State.invertMode := !State.invertMode
        
        ; Update UI
        StatusIndicator.Update()
        
        ; Show feedback
        if (State.invertMode) {
            TooltipSystem.ShowTemporary("🔄 Inverted Mode: ON", "info")
        } else {
            TooltipSystem.ShowTemporary("🔄 Inverted Mode: OFF", "default")
        }
    }
    
    ; Reset movement state
    static ResetMovement() {
        State.currentSpeed := 0
        State.consecutiveMoves := 0
        State.lastMoveTime := 0
    }
    
    ; Add position to undo history
    static AddToHistory(x, y) {
        ; Add current position to history
        State.undoHistory.Push({x: x, y: y, time: A_TickCount})
        
        ; Limit history size
        if (State.undoHistory.Length > Config.MaxUndoLevels) {
            State.undoHistory.RemoveAt(1)
        }
        
        ; Update last position
        State.lastX := x
        State.lastY := y
    }
    
    ; Get last position from history
    static GetLastPosition() {
        if (State.undoHistory.Length > 0) {
            return State.undoHistory[State.undoHistory.Length]
        }
        return {x: 0, y: 0}
    }
    
    ; Clear undo history
    static ClearHistory() {
        State.undoHistory := []
    }
    
    ; Set a timer
    static SetTimer(name, callback, period) {
        ; Clear existing timer if any
        if (State.activeTimers.Has(name)) {
            SetTimer(State.activeTimers[name], 0)
        }
        
        ; Create new timer
        State.activeTimers[name] := callback
        SetTimer(callback, period)
    }
    
    ; Clear a timer
    static ClearTimer(name) {
        if (State.activeTimers.Has(name)) {
            SetTimer(State.activeTimers[name], 0)
            State.activeTimers.Delete(name)
        }
    }
    
    ; Clear all timers
    static ClearAllTimers() {
        for name, callback in State.activeTimers {
            SetTimer(callback, 0)
        }
        State.activeTimers.Clear()
    }
}