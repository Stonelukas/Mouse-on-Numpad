; ######################################################################################################################
; Tooltip System Module - Enhanced dual tooltip system with theme support
; Complete fixed version with proper function calls
; ######################################################################################################################

#Requires AutoHotkey v2.0

class TooltipSystem {
    static globalTooltip := ""
    static mouseTooltip := ""
    static isInitialized := false
    static mouseTooltipTimer := ""
    
    ; Initialize tooltip system
    static Initialize() {
        if (TooltipSystem.isInitialized) {
            return
        }
        
        TooltipSystem._CreateGlobalTooltip()
        TooltipSystem._CreateMouseTooltip()
        TooltipSystem.isInitialized := true
    }
    
    ; Create standard tooltip GUI (very short duration)
    static _CreateGlobalTooltip() {
        TooltipSystem.globalTooltip := Gui("+AlwaysOnTop -MaximizeBox -MinimizeBox +LastFound -Caption +Border +ToolWindow", "")
        TooltipSystem.globalTooltip.MarginX := 10
        TooltipSystem.globalTooltip.MarginY := 1
        
        ; Apply theme background
        bgColor := ColorThemeManager.GetColor("tooltipDefault")
        TooltipSystem.globalTooltip.BackColor := bgColor
        
        TooltipSystem.globalTooltip.textCtrl := TooltipSystem.globalTooltip.Add("Text", "Center w120 h18", "")
        TooltipSystem.globalTooltip.textCtrl.SetFont("s9 Bold", "Segoe UI")
        
        pos := MonitorUtils.GetGuiPosition("tooltip")
        TooltipSystem.globalTooltip.Move(pos[1], pos[2], 140, 22)
        
        ; Create but hide initially
        TooltipSystem.globalTooltip.Show("NoActivate")
        TooltipSystem.globalTooltip.Hide()
    }
    
    ; Create mouse action tooltip GUI (4 second duration)
    static _CreateMouseTooltip() {
        TooltipSystem.mouseTooltip := Gui("+AlwaysOnTop -MaximizeBox -MinimizeBox +LastFound -Caption +Border +ToolWindow", "")
        TooltipSystem.mouseTooltip.MarginX := 10
        TooltipSystem.mouseTooltip.MarginY := 2
        
        ; Apply theme background
        bgColor := ColorThemeManager.GetColor("tooltipSuccess")
        TooltipSystem.mouseTooltip.BackColor := bgColor
        
        TooltipSystem.mouseTooltip.textCtrl := TooltipSystem.mouseTooltip.Add("Text", "Center w120 h20", "")
        TooltipSystem.mouseTooltip.textCtrl.SetFont("s9 Bold", "Segoe UI")
        
        pos := MonitorUtils.GetGuiPosition("tooltip")
        TooltipSystem.mouseTooltip.Move(pos[1], pos[2] - 30, 140, 28)
        
        ; Create but hide initially
        TooltipSystem.mouseTooltip.Show("NoActivate")
        TooltipSystem.mouseTooltip.Hide()
    }

    ; Standard tooltip for movement and general feedback
    static ShowStandard(text, type := "info", duration := "") {
        if (!TooltipSystem.isInitialized || !StateManager.IsStatusVisible() || MonitorUtils.IsFullscreen()) {
            return
        }
        
        ; Get theme color
        bgColor := TooltipSystem._GetTooltipColor(type)
        TooltipSystem.globalTooltip.BackColor := bgColor
        
        ; Get contrasting text color - Use ColorThemeManager method
        textColor := ColorThemeManager.GetContrastingColor(bgColor)
        if (SubStr(textColor, 1, 2) = "0x") {
            textColor := SubStr(textColor, 3)
        }
        TooltipSystem.globalTooltip.textCtrl.SetFont("c" . textColor)
        
        TooltipSystem.globalTooltip.textCtrl.Text := text
        
        textLength := StrLen(text)
        tooltipWidth := (textLength * 9) + 24
        if (tooltipWidth < 60) tooltipWidth := 60
        if (tooltipWidth > 250) tooltipWidth := 250
        
        pos := MonitorUtils.GetGuiPosition("tooltip")
        TooltipSystem.globalTooltip.Move(pos[1], pos[2], tooltipWidth, 22)
        
        TooltipSystem.globalTooltip.Show("NoActivate")
        WinSetTransparent(255, TooltipSystem.globalTooltip.Hwnd)
        
        SetTimer(() => TooltipSystem._HideGlobalTooltip(), -1000)
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
    
    ; Apply theme colors to existing tooltips - force immediate update
    static ApplyTheme() {
        if (!TooltipSystem.isInitialized) {
            return
        }
        
        ; Update default background colors
        if (TooltipSystem.globalTooltip != "") {
            bgColor := ColorThemeManager.GetColor("tooltipDefault")
            TooltipSystem.globalTooltip.BackColor := bgColor
            
            textColor := ColorThemeManager.GetContrastingColor(bgColor)
            if (SubStr(textColor, 1, 2) = "0x") {
                textColor := SubStr(textColor, 3)
            }
            TooltipSystem.globalTooltip.textCtrl.SetFont("c" . textColor)
        }
        
        if (TooltipSystem.mouseTooltip != "") {
            bgColor := ColorThemeManager.GetColor("tooltipSuccess")
            TooltipSystem.mouseTooltip.BackColor := bgColor
            
            textColor := ColorThemeManager.GetContrastingColor(bgColor)
            if (SubStr(textColor, 1, 2) = "0x") {
                textColor := SubStr(textColor, 3)
            }
            TooltipSystem.mouseTooltip.textCtrl.SetFont("c" . textColor)
        }
    }
    
    static _HideGlobalTooltip() {
        if (TooltipSystem.globalTooltip != "") {
            WinSetTransparent(0, TooltipSystem.globalTooltip.Hwnd)
            TooltipSystem.globalTooltip.Hide()
        }
    }
    
    ; Enhanced mouse action tooltip - 4 second duration
    static ShowMouseAction(text, type := "success") {
        if (!TooltipSystem.isInitialized || !StateManager.IsStatusVisible() || MonitorUtils.IsFullscreen()) {
            return
        }
        
        ; Cancel any existing timer
        if (TooltipSystem.mouseTooltipTimer) {
            SetTimer(TooltipSystem.mouseTooltipTimer, 0)
        }
        
        ; Apply theme color based on type
        bgColor := TooltipSystem._GetTooltipColor(type)
        TooltipSystem.mouseTooltip.BackColor := bgColor
        
        ; Update text color for contrast
        textColor := ColorThemeManager.GetContrastingColor(bgColor)
        if (SubStr(textColor, 1, 2) = "0x") {
            textColor := SubStr(textColor, 3)
        }
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
        TooltipSystem.mouseTooltip.Show("NoActivate")
        WinSetTransparent(255, TooltipSystem.mouseTooltip.Hwnd)
        
        ; Set timer to hide after 4 seconds
        TooltipSystem.mouseTooltipTimer := () => TooltipSystem._HideMouseTooltip()
        SetTimer(TooltipSystem.mouseTooltipTimer, -4000)
    }

    static _HideMouseTooltip() {
        if (TooltipSystem.mouseTooltip != "") {
            WinSetTransparent(0, TooltipSystem.mouseTooltip.Hwnd)
            TooltipSystem.mouseTooltip.Hide()
        }
    }

    ; Forced tooltip that always shows (for critical messages)
    static ShowForced(text, type := "info") {
        if (!TooltipSystem.isInitialized) {
            return
        }
        
        ; Apply theme color
        bgColor := TooltipSystem._GetTooltipColor(type)
        TooltipSystem.globalTooltip.BackColor := bgColor
        
        ; Update text color for contrast
        textColor := ColorThemeManager.GetContrastingColor(bgColor)
        if (SubStr(textColor, 1, 2) = "0x") {
            textColor := SubStr(textColor, 3)
        }
        TooltipSystem.globalTooltip.textCtrl.SetFont("c" . textColor)
        
        TooltipSystem.globalTooltip.textCtrl.Text := text
        
        textLength := StrLen(text)
        tooltipWidth := (textLength * 9) + 24
        if (tooltipWidth < 60) tooltipWidth := 60
        if (tooltipWidth > 250) tooltipWidth := 250
        
        pos := MonitorUtils.GetGuiPosition("tooltip")
        TooltipSystem.globalTooltip.Move(pos[1], pos[2], tooltipWidth, 22)
        
        TooltipSystem.globalTooltip.Show("NoActivate")
        WinSetTransparent(255, TooltipSystem.globalTooltip.Hwnd)
        
        SetTimer(() => TooltipSystem._HideGlobalTooltip(), -5000)
    }
    
    ; Alias methods for compatibility
    static Show(text, duration := 2000) {
        TooltipSystem.ShowStandard(text, "info", duration)
    }
    
    static HideAll() {
        TooltipSystem._HideGlobalTooltip()
        TooltipSystem._HideMouseTooltip()
    }
}