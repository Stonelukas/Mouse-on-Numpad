#Requires AutoHotkey v2.0

; ######################################################################################################################
; Tooltip System Module - Separate tooltip management for different types
; ######################################################################################################################

class TooltipSystem {
    ; GUI elements
    static globalTooltip := ""
    static mouseTooltip := ""
    
    ; Timer
    static mouseTooltipTimer := ""

    static Initialize() {
        TooltipSystem._InitializeTooltip()
        TooltipSystem._InitializeMouseTooltip()
    }

    static _InitializeTooltip() {
        TooltipSystem.globalTooltip := Gui("+AlwaysOnTop -MaximizeBox -MinimizeBox +LastFound -Caption +Border", "")
        TooltipSystem.globalTooltip.BackColor := "0x607D8B"
        TooltipSystem.globalTooltip.MarginX := 5
        TooltipSystem.globalTooltip.MarginY := 2
        
        TooltipSystem.globalTooltip.textCtrl := TooltipSystem.globalTooltip.Add("Text", "cWhite Center w50 h16", "")
        TooltipSystem.globalTooltip.textCtrl.SetFont("s8 Bold", "Segoe UI")
        
        pos := MonitorUtils.GetGuiPosition("tooltip")
        TooltipSystem.globalTooltip.Move(pos[1], pos[2], 60, 22)
        TooltipSystem.globalTooltip.Show("NoActivate Hide")  ; Create but keep hidden
        WinSetTransparent(0, TooltipSystem.globalTooltip.Hwnd)
    }

    static _InitializeMouseTooltip() {
        TooltipSystem.mouseTooltip := Gui("+AlwaysOnTop -MaximizeBox -MinimizeBox +LastFound -Caption +Border", "")
        TooltipSystem.mouseTooltip.BackColor := "0x4CAF50"
        TooltipSystem.mouseTooltip.MarginX := 8
        TooltipSystem.mouseTooltip.MarginY := 4
        
        TooltipSystem.mouseTooltip.textCtrl := TooltipSystem.mouseTooltip.Add("Text", "cWhite Center w120 h20", "")
        TooltipSystem.mouseTooltip.textCtrl.SetFont("s9 Bold", "Segoe UI")
        
        pos := MonitorUtils.GetGuiPosition("tooltip")
        TooltipSystem.mouseTooltip.Move(pos[1], pos[2] - 30, 140, 28)
        TooltipSystem.mouseTooltip.Show("NoActivate Hide")  ; Create but keep hidden
        WinSetTransparent(0, TooltipSystem.mouseTooltip.Hwnd)
    }

    ; Standard tooltip for movement and general feedback
    static ShowStandard(text, type := "info", duration := "") {
        if (!StateManager.IsStatusVisible() || MonitorUtils.IsFullscreen()) {
            return
        }
        
        ; Make sure tooltip is visible before updating content
        TooltipSystem.globalTooltip.Show("NoActivate")
        
        TooltipSystem.globalTooltip.BackColor := TooltipSystem._GetTooltipColor(type)
        TooltipSystem.globalTooltip.textCtrl.Text := text
        
        ; Calculate size
        textLength := StrLen(text)
        if (text == "↑" || text == "↓" || text == "←" || text == "→" || text == "↖" || text == "↗" || text == "↙" || text == "↘") {
            tooltipWidth := 40
            textWidth := 30
        } else {
            tooltipWidth := (textLength * 9) + 24
            textWidth := tooltipWidth - 16
            if (tooltipWidth < 60) {
                tooltipWidth := 60
                textWidth := 44
            }
            if (tooltipWidth > 250) {
                tooltipWidth := 250
                textWidth := 234
            }
        }
        
        TooltipSystem.globalTooltip.textCtrl.Move(8, 2, textWidth, 18)
        
        pos := MonitorUtils.GetGuiPosition("tooltip")
        TooltipSystem.globalTooltip.Move(pos[1], pos[2], tooltipWidth, 22)
        
        WinSetTransparent(255, TooltipSystem.globalTooltip.Hwnd)
        
        ; Determine duration
        if (duration != "") {
            displayDuration := duration
        } else if (text == "↑" || text == "↓" || text == "←" || text == "→" || text == "↖" || text == "↗" || text == "↙" || text == "↘") {
            displayDuration := Config.FeedbackDurationShort
        } else {
            displayDuration := Config.FeedbackDurationLong
        }
        
        SetTimer(() => WinSetTransparent(0, TooltipSystem.globalTooltip.Hwnd), -displayDuration)
    }

    ; Dedicated mouse tooltip with 4-second duration
    static ShowMouseAction(text, type := "success") {
        if (!StateManager.IsStatusVisible() || MonitorUtils.IsFullscreen()) {
            return
        }
        
        ; Make sure mouse tooltip is visible before updating content
        TooltipSystem.mouseTooltip.Show("NoActivate")
        
        ; Cancel any existing mouse tooltip timer
        if (TooltipSystem.mouseTooltipTimer != "") {
            SetTimer(TooltipSystem.mouseTooltipTimer, 0)
            TooltipSystem.mouseTooltipTimer := ""
        }
        
        ; Set color based on type
        switch type {
            case "success": TooltipSystem.mouseTooltip.BackColor := "0x4CAF50"
            case "warning": TooltipSystem.mouseTooltip.BackColor := "0xFF9800"
            case "info": TooltipSystem.mouseTooltip.BackColor := "0x2196F3"
            case "error": TooltipSystem.mouseTooltip.BackColor := "0xF44336"
            default: TooltipSystem.mouseTooltip.BackColor := "0x4CAF50"
        }
        
        TooltipSystem.mouseTooltip.textCtrl.Text := text
        
        ; Calculate width based on text
        textLength := StrLen(text)
        tooltipWidth := (textLength * 10) + 30
        if (tooltipWidth < 120) tooltipWidth := 120
        if (tooltipWidth > 300) tooltipWidth := 300
        textWidth := tooltipWidth - 20
        
        TooltipSystem.mouseTooltip.textCtrl.Move(10, 4, textWidth, 20)
        
        pos := MonitorUtils.GetGuiPosition("tooltip")
        TooltipSystem.mouseTooltip.Move(pos[1], pos[2] - 35, tooltipWidth, 28)
        
        ; Show for exactly 4 seconds
        WinSetTransparent(255, TooltipSystem.mouseTooltip.Hwnd)
        
        ; Set timer to hide after 4 seconds
        TooltipSystem.mouseTooltipTimer := () => WinSetTransparent(0, TooltipSystem.mouseTooltip.Hwnd)
        SetTimer(TooltipSystem.mouseTooltipTimer, -4000)
    }

    ; Forced tooltip that always shows (for critical messages)
    static ShowForced(text, type := "info") {
        ; Make sure tooltip is visible
        TooltipSystem.globalTooltip.Show("NoActivate")
        
        TooltipSystem.globalTooltip.BackColor := TooltipSystem._GetTooltipColor(type)
        TooltipSystem.globalTooltip.textCtrl.Text := text
        
        textLength := StrLen(text)
        tooltipWidth := (textLength * 9) + 24
        if (tooltipWidth < 60) tooltipWidth := 60
        if (tooltipWidth > 250) tooltipWidth := 250
        
        pos := MonitorUtils.GetGuiPosition("tooltip")
        TooltipSystem.globalTooltip.Move(pos[1], pos[2], tooltipWidth, 22)
        
        WinSetTransparent(255, TooltipSystem.globalTooltip.Hwnd)
        
        SetTimer(() => WinSetTransparent(0, TooltipSystem.globalTooltip.Hwnd), -1000)
    }

    static _GetTooltipColor(type) {
        switch type {
            case "success": return "0x4CAF50"
            case "warning": return "0xFF9800"
            case "info": return "0x2196F3"
            case "error": return "0xF44336"
            default: return "0x607D8B"
        }
    }

    static HandleFullscreen() {
        if ((!StateManager.IsStatusVisible() || MonitorUtils.IsFullscreen())) {
            try {
                if (TooltipSystem.globalTooltip != "") {
                    TooltipSystem.globalTooltip.Hide()
                }
                if (TooltipSystem.mouseTooltip != "") {
                    TooltipSystem.mouseTooltip.Hide()
                }
            }
        }
    }

    static UpdateVisibility() {
        if (!StateManager.IsStatusVisible() || MonitorUtils.IsFullscreen()) {
            try {
                if (TooltipSystem.globalTooltip != "") {
                    TooltipSystem.globalTooltip.Hide()
                }
                if (TooltipSystem.mouseTooltip != "") {
                    TooltipSystem.mouseTooltip.Hide()
                }
            }
        } else {
            ; Only show tooltips when they actually have content and are needed
            ; Don't auto-show empty tooltips
        }
    }

    static Cleanup() {
        if (TooltipSystem.globalTooltip != "") {
            TooltipSystem.globalTooltip.Destroy()
        }
        if (TooltipSystem.mouseTooltip != "") {
            TooltipSystem.mouseTooltip.Destroy()
        }
    }
}