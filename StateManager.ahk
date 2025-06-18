; ######################################################################################################################
; State Manager Module - Global Application State
; ######################################################################################################################

class StateManager {
    ; Mode states - using properties to allow modification
    static _mouseMode := false
    static _invertedMode := false
    static _saveMode := false
    static _loadMode := false
    static _statusVisible := false
    static _isReloading := false
    static _lastLoadedSlot := 0
    static _showingPositionFeedback := false
    static isFullscreenActive := false

    ; Mouse button states
    static _leftButtonHeld := false
    static _rightButtonHeld := false
    static _middleButtonHeld := false

    ; Timers
    static _leftClickHoldTimer := ""

    static Initialize() {
        StateManager._statusVisible := Config.StatusVisibleOnStartup
    }

    ; Mode Management
    static ToggleMouseMode() {
        StateManager._mouseMode := !StateManager._mouseMode
        StateManager._saveMode := false
        StateManager._loadMode := false
        
        if (Config.Get("Visual.EnableAudioFeedback")) {
            SoundBeep(StateManager._mouseMode ? 900 : 400, 150)
        }
    }

    static ToggleInvertedMode() {
        StateManager._invertedMode := !StateManager._invertedMode
        
        if (Config.Get("Visual.EnableAudioFeedback")) {
            SoundBeep(StateManager._invertedMode ? 600 : 300, 100)
        }
    }

    static ToggleSaveMode() {
        StateManager._saveMode := !StateManager._saveMode
        StateManager._loadMode := false
        
        if (Config.Get("Visual.EnableAudioFeedback")) {
            SoundBeep(StateManager._saveMode ? 750 : 350, 100)
        }
    }

    static ToggleLoadMode() {
        StateManager._loadMode := !StateManager._loadMode
        StateManager._saveMode := false
        
        if (!StateManager._loadMode) {
            StateManager._lastLoadedSlot := 0
        }
        
        if (Config.Get("Visual.EnableAudioFeedback")) {
            SoundBeep(StateManager._loadMode ? 750 : 350, 100)
        }
    }

    static ToggleAbsoluteMovement() {
        Config.set("Movement.EnableAbsoluteMovement", !Config.Get("Movement.EnableAbsoluteMovement"))
        
        if (Config.Get("Visual.EnableAudioFeedback")) {
            SoundBeep(Config.Get("Movement.EnableAbsoluteMovement") ? 850 : 450, 150)
        }
    }

    static ToggleStatusVisibility() {
        StateManager._statusVisible := !StateManager._statusVisible
        
        if (Config.Get("Visual.EnableAudioFeedback")) {
            SoundBeep(StateManager._statusVisible ? 800 : 400, 150)
        }
    }

    static ToggleSecondaryMonitor() {
        Config.set("Visual.UseSecondaryMonitor", !Config.Get("Visual.UseSecondaryMonitor"))
        
        if (Config.Get("Visual.EnableAudioFeedback")) {
            SoundBeep(Config.Get("Visual.UseSecondaryMonitor") ? 900 : 500, 150)
        }
    }

    ; Button State Management
    static SetLeftButtonHeld(held) {
        StateManager._leftButtonHeld := held
    }

    static SetRightButtonHeld(held) {
        StateManager._rightButtonHeld := held
    }

    static SetMiddleButtonHeld(held) {
        StateManager._middleButtonHeld := held
    }

    static SetFullscreenState(active) {
        previousState := StateManager.isFullscreenActive
        StateManager.isFullscreenActive := active
        
        ; Handle state change
        if (active && !previousState) {
            ; Entering fullscreen - hide UI elements
            TooltipSystem.HideAll()
            StatusIndicator.Hide()
        } else if (!active && previousState) {
            ; Exiting fullscreen - restore UI elements
            if (StateManager._statusVisible) {
                StatusIndicator.Show()
            }
        }
    }

    ; Getters
    ; Fullscreen management methods

    
    static IsinFullscreen() {
        return StateManager.isFullscreenActive
    }

    static IsMouseMode() {
        return StateManager._mouseMode
    }

    static IsInvertedMode() {
        return StateManager._invertedMode
    }

    static IsSaveMode() {
        return StateManager._saveMode
    }

    static IsLoadMode() {
        return StateManager._loadMode
    }

    static IsStatusVisible() {
        return StateManager._statusVisible
    }

    static IsReloading() {
        return StateManager._isReloading
    }

    static IsLeftButtonHeld() {
        return StateManager._leftButtonHeld
    }

    static IsRightButtonHeld() {
        return StateManager._rightButtonHeld
    }

    static IsMiddleButtonHeld() {
        return StateManager._middleButtonHeld
    }

    static GetLastLoadedSlot() {
        return StateManager._lastLoadedSlot
    }

    static SetLastLoadedSlot(slot) {
        StateManager._lastLoadedSlot := slot
    }

    static SetReloading(value) {
        StateManager._isReloading := value
    }

    ; Timer Management
    static SetLeftClickHoldTimer(timer) {
        StateManager._leftClickHoldTimer := timer
    }

    static GetLeftClickHoldTimer() {
        return StateManager._leftClickHoldTimer
    }

    static ClearLeftClickHoldTimer() {
        if (StateManager._leftClickHoldTimer != "") {
            SetTimer(StateManager._leftClickHoldTimer, 0)
            StateManager._leftClickHoldTimer := ""
        }
    }

    ; Reload functionality
    static ReloadScript() {
        StateManager._isReloading := true
        PositionMemory.SavePositions()
        Reload
    }

    static ReloadWithGUI() {
        reloadGui := Gui("+AlwaysOnTop -MaximizeBox -MinimizeBox +LastFound -Caption +Border", "")
        reloadGui.BackColor := "0xFF9800"
        reloadGui.MarginX := 15
        reloadGui.MarginY := 10
        
        reloadText := reloadGui.Add("Text", "cWhite Center w200 h30", "🔄 Reloading Script...")
        reloadText.SetFont("s12 Bold", "Segoe UI")
        
        centerX := A_ScreenWidth // 2 - 115
        centerY := A_ScreenHeight // 2 - 25
        reloadGui.Show("x" . centerX . " y" . centerY . " w230 h50 NoActivate")
        
        Sleep(1000)
        StateManager.ReloadScript()
    }
}