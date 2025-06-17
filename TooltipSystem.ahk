#Requires AutoHotkey v2.0

; ######################################################################################################################
; Updated Tooltip System Module - With Color Theme Support
; ######################################################################################################################
; 
; IMPORTANT: This is an updated version of TooltipSystem.ahk that integrates with ColorThemeManager.
; Replace the existing TooltipSystem.ahk with this version.
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
        TooltipSystem.globalTooltip.BackColor := ColorThemeManager.GetColor("tooltipDefault")
        TooltipSystem.globalTooltip.MarginX := 5
        TooltipSystem.globalTooltip.MarginY := 2
        
        TooltipSystem.globalTooltip.textCtrl := TooltipSystem.globalTooltip.Add("Text", "cWhite Center w50 h16", "")
        TooltipSystem.globalTooltip.textCtrl.SetFont("s8 Bold", "Segoe UI")
        
        ; Apply text color based on theme
        textColor := ColorThemeManager.GetColor("textDefault")
        TooltipSystem.globalTooltip.textCtrl.SetFont("c" . textColor)
        
        pos := MonitorUtils.GetGuiPosition("tooltip")
        TooltipSystem.globalTooltip.Move(pos[1], pos[2], 60, 22)
        TooltipSystem.globalTooltip.Show("NoActivate Hide")  ; Create but keep hidden
        WinSetTransparent(0, TooltipSystem.globalTooltip.Hwnd)
    }

    static _InitializeMouseTooltip() {
        TooltipSystem.mouseTooltip := Gui("+AlwaysOnTop -MaximizeBox -MinimizeBox +LastFound -Caption +Border", "")
        TooltipSystem.mouseTooltip.BackColor := ColorThemeManager.GetColor("tooltipSuccess")
        TooltipSystem.mouseTooltip.MarginX := 8
        TooltipSystem.mouseTooltip.MarginY := 4
        
        TooltipSystem.mouseTooltip.textCtrl := TooltipSystem.mouseTooltip.Add("Text", "cWhite Center w120 h20", "")
        TooltipSystem.mouseTooltip.textCtrl.SetFont("s9 Bold", "Segoe UI")
        
        ; Apply text color based on theme
        textColor := ColorThemeManager.GetColor("textDefault")
        TooltipSystem.mouseTooltip.textCtrl.SetFont("c" . textColor)
        
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
        
        ; Apply theme color
        TooltipSystem.globalTooltip.BackColor := TooltipSystem._GetTooltipColor(type)
        TooltipSystem.globalTooltip.textCtrl.Text := text
        
        ; Update text color for contrast
        bgColor := TooltipSystem._GetTooltipColor(type)
        textColor := GetContrastingColor(bgColor)
        TooltipSystem.globalTooltip.textCtrl.SetFont("c" . textColor)
        
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
        
        ; Apply theme color
        bgColor := TooltipSystem._GetTooltipColor(type)
        TooltipSystem.mouseTooltip.BackColor := bgColor
        
        ; Update text color for contrast
        textColor := GetContrastingColor(bgColor)
        TooltipSystem.mouseTooltip.textCtrl.SetFont("c" . textColor)
        
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
        
        ; Apply theme color
        bgColor := TooltipSystem._GetTooltipColor(type)
        TooltipSystem.globalTooltip.BackColor := bgColor
        
        ; Update text color for contrast
        textColor := GetContrastingColor(bgColor)
        TooltipSystem.globalTooltip.textCtrl.SetFont("c" . textColor)
        
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
            case "success": return ColorThemeManager.GetColor("tooltipSuccess")
            case "warning": return ColorThemeManager.GetColor("tooltipWarning")
            case "info": return ColorThemeManager.GetColor("tooltipInfo")
            case "error": return ColorThemeManager.GetColor("tooltipError")
            default: return ColorThemeManager.GetColor("tooltipDefault")
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
    
    ; Apply theme colors to existing tooltips
    static ApplyTheme() {
        ; Re-initialize tooltips with new colors
        if (TooltipSystem.globalTooltip != "") {
            TooltipSystem.globalTooltip.BackColor := ColorThemeManager.GetColor("tooltipDefault")
            textColor := GetContrastingColor(ColorThemeManager.GetColor("tooltipDefault"))
            TooltipSystem.globalTooltip.textCtrl.SetFont("c" . textColor)
        }
        
        if (TooltipSystem.mouseTooltip != "") {
            TooltipSystem.mouseTooltip.BackColor := ColorThemeManager.GetColor("tooltipSuccess")
            textColor := GetContrastingColor(ColorThemeManager.GetColor("tooltipSuccess"))
            TooltipSystem.mouseTooltip.textCtrl.SetFont("c" . textColor)
        }
    }
}