#Requires AutoHotkey v2.0

; ######################################################################################################################
; Status Indicator - Status bar display and management
; ######################################################################################################################

class StatusIndicator {
    ; Status GUI
    static gui := ""
    static textCtrl := ""
    static isVisible := false
    static lastStatus := ""
    static hideTimer := ""
    
    ; Initialize status indicator
    static Init() {
        ; Create status GUI
        StatusIndicator.gui := Gui("+AlwaysOnTop -MaximizeBox -MinimizeBox +LastFound -Caption +Border", "")
        StatusIndicator.gui.BackColor := Config.GetThemeColor("StatusOff")
        StatusIndicator.gui.MarginX := 4
        StatusIndicator.gui.MarginY := 2
        
        ; Add text control
        StatusIndicator.textCtrl := StatusIndicator.gui.Add("Text", "cWhite Left w140 h18", "🖱️ OFF")
        StatusIndicator.textCtrl.SetFont("s8 Bold", "Segoe UI")
        
        ; Position and show if configured
        StatusIndicator.UpdatePosition()
        
        if (Config.StatusVisibleOnStartup) {
            StatusIndicator.Show()
        }
    }
    
    ; Update status display
    static Update() {
        if (!StatusIndicator.gui) {
            return
        }
        
        ; Build status text
        statusText := "🖱️ "
        
        if (State.mouseMode) {
            statusText .= "ON"
            
            if (State.saveMode) {
                statusText .= " | 💾 SAVE"
                StatusIndicator.gui.BackColor := Config.GetThemeColor("StatusSave")
            } else if (State.loadMode) {
                statusText .= " | 📂 LOAD"
                StatusIndicator.gui.BackColor := Config.GetThemeColor("StatusLoad")
            } else if (State.invertMode) {
                statusText .= " | 🔄 INV"
                StatusIndicator.gui.BackColor := Config.GetThemeColor("StatusInverted")
            } else {
                StatusIndicator.gui.BackColor := Config.GetThemeColor("StatusOn")
            }
        } else {
            statusText .= "OFF"
            StatusIndicator.gui.BackColor := Config.GetThemeColor("StatusOff")
        }
        
        ; Update text
        StatusIndicator.textCtrl.Text := statusText
        StatusIndicator.lastStatus := statusText
        
        ; Auto-resize window to fit text
        StatusIndicator.gui.GetPos(, , &width)
        textWidth := StatusIndicator.GetTextWidth(statusText)
        if (textWidth + 8 != width) {
            StatusIndicator.gui.Show("w" . (textWidth + 8) . " NA")
        }
    }
    
    ; Update position
    static UpdatePosition() {
        if (!StatusIndicator.gui) {
            return
        }
        
        ; Get monitor info
        mon := MonitorUtils.GetMonitorInfo()
        
        ; Calculate position
        xPos := Config.StatusX is Number ? Config.StatusX : MonitorUtils.EvaluateExpression(Config.StatusX)
        yPos := Config.StatusY is Number ? Config.StatusY : MonitorUtils.EvaluateExpression(Config.StatusY)
        
        ; Apply monitor offset
        x := mon.left + xPos
        y := mon.top + yPos
        
        ; Show at new position
        if (StatusIndicator.isVisible) {
            StatusIndicator.gui.Show("x" . x . " y" . y . " NoActivate")
        }
    }
    
    ; Show status indicator
    static Show() {
        if (!StatusIndicator.gui) {
            return
        }
        
        StatusIndicator.UpdatePosition()
        StatusIndicator.gui.Show("NoActivate")
        StatusIndicator.isVisible := true
    }
    
    ; Hide status indicator
    static Hide() {
        if (StatusIndicator.gui) {
            StatusIndicator.gui.Hide()
            StatusIndicator.isVisible := false
        }
    }
    
    ; Toggle visibility
    static Toggle() {
        if (StatusIndicator.isVisible) {
            StatusIndicator.Hide()
        } else {
            StatusIndicator.Show()
        }
    }
    
    ; Show temporary message
    static ShowMessage(text, duration := 0) {
        if (!StatusIndicator.gui) {
            return
        }
        
        if (duration == 0) {
            duration := Config.StatusMessageDuration
        }
        
        ; Save current status
        savedStatus := StatusIndicator.lastStatus
        savedColor := StatusIndicator.gui.BackColor
        
        ; Show message
        StatusIndicator.textCtrl.Text := text
        StatusIndicator.gui.BackColor := Config.GetThemeColor("TooltipWarning")
        
        ; Clear any existing timer
        if (StatusIndicator.hideTimer) {
            SetTimer(StatusIndicator.hideTimer, 0)
        }
        
        ; Set timer to restore
        StatusIndicator.hideTimer := () => StatusIndicator.RestoreStatus(savedStatus, savedColor)
        SetTimer(StatusIndicator.hideTimer, -duration)
    }
    
    ; Restore status
    static RestoreStatus(text, color) {
        if (StatusIndicator.gui) {
            StatusIndicator.textCtrl.Text := text
            StatusIndicator.gui.BackColor := color
            StatusIndicator.Update()
        }
    }
    
    ; Get text width (approximate)
    static GetTextWidth(text) {
        ; Rough approximation: 7 pixels per character
        return StrLen(text) * 7 + 20
    }
    
    ; Destroy status indicator
    static Destroy() {
        if (StatusIndicator.hideTimer) {
            SetTimer(StatusIndicator.hideTimer, 0)
        }
        
        if (StatusIndicator.gui) {
            StatusIndicator.gui.Destroy()
            StatusIndicator.gui := ""
        }
    }
}