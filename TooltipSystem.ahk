#Requires AutoHotkey v2.0

; ######################################################################################################################
; Tooltip System - Centralized tooltip management
; ######################################################################################################################

class TooltipSystem {
    ; Tooltip instances
    static globalTooltip := ""
    static mouseTooltip := ""
    static tempTooltips := Map()
    
    ; Tooltip settings
    static defaultDuration := 3000
    static mouseActionDuration := 4000
    static arrowDuration := 200
    
    ; Initialize tooltip system
    static Init() {
        ; Create persistent tooltips
        TooltipSystem.CreateTooltips()
    }
    
    ; Create tooltip GUIs
    static CreateTooltips() {
        ; Global tooltip (for general messages)
        TooltipSystem.globalTooltip := Gui("+AlwaysOnTop -Caption +ToolWindow", "")
        TooltipSystem.globalTooltip.MarginX := 10
        TooltipSystem.globalTooltip.MarginY := 5
        TooltipSystem.globalTooltip.BackColor := Config.GetThemeColor("TooltipDefault")
        
        ; Mouse action tooltip (separate from global)
        TooltipSystem.mouseTooltip := Gui("+AlwaysOnTop -Caption +ToolWindow", "")
        TooltipSystem.mouseTooltip.MarginX := 10
        TooltipSystem.mouseTooltip.MarginY := 5
        TooltipSystem.mouseTooltip.BackColor := Config.GetThemeColor("TooltipSuccess")
    }
    
    ; Show tooltip
    static Show(text, x := "", y := "") {
        ; Get position
        if (x == "" || y == "") {
            ; Use configured position
            mon := MonitorUtils.GetMonitorInfo()
            xPos := Config.TooltipX is Number ? Config.TooltipX : MonitorUtils.EvaluateExpression(Config.TooltipX)
            yPos := Config.TooltipY is Number ? Config.TooltipY : MonitorUtils.EvaluateExpression(Config.TooltipY)
            x := mon.left + xPos
            y := mon.top + yPos
        }
        
        ; Clear existing content
        for hwnd in TooltipSystem.globalTooltip {
            hwnd.Destroy()
        }
        
        ; Add new text
        textCtrl := TooltipSystem.globalTooltip.Add("Text", "cWhite", text)
        textCtrl.SetFont("s10", "Segoe UI")
        
        ; Show tooltip
        TooltipSystem.globalTooltip.Show("x" . x . " y" . y . " NoActivate")
    }
    
    ; Show temporary tooltip
    static ShowTemporary(text, type := "default", duration := 0) {
        if (duration == 0) {
            duration := Config.TooltipDuration
        }
        
        ; Select tooltip based on context
        if (type == "mouse") {
            TooltipSystem.ShowMouseAction(text, duration)
        } else {
            TooltipSystem.ShowWithStyle(text, type, duration)
        }
    }
    
    ; Show mouse action tooltip (separate system)
    static ShowMouseAction(text, duration := 0) {
        if (duration == 0) {
            duration := TooltipSystem.mouseActionDuration
        }
        
        ; Get position
        mon := MonitorUtils.GetMonitorInfo()
        xPos := Config.TooltipX is Number ? Config.TooltipX : MonitorUtils.EvaluateExpression(Config.TooltipX)
        yPos := Config.TooltipY is Number ? Config.TooltipY : MonitorUtils.EvaluateExpression(Config.TooltipY)
        x := mon.left + xPos
        y := mon.top + yPos + 40  ; Offset to avoid overlap
        
        ; Clear existing content
        for hwnd in TooltipSystem.mouseTooltip {
            hwnd.Destroy()
        }
        
        ; Set background color
        TooltipSystem.mouseTooltip.BackColor := Config.GetThemeColor("TooltipSuccess")
        
        ; Add new text
        textCtrl := TooltipSystem.mouseTooltip.Add("Text", "cWhite", text)
        textCtrl.SetFont("s10 Bold", "Segoe UI")
        
        ; Show tooltip
        TooltipSystem.mouseTooltip.Show("x" . x . " y" . y . " NoActivate")
        
        ; Set timer to hide
        SetTimer(() => TooltipSystem.HideMouseTooltip(), -duration)
    }
    
    ; Show arrow tooltip (very short duration)
    static ShowArrow(direction) {
        arrows := Map(
            "up", "↑",
            "down", "↓",
            "left", "←",
            "right", "→",
            "up-left", "↖",
            "up-right", "↗",
            "down-left", "↙",
            "down-right", "↘"
        )
        
        if (arrows.Has(direction)) {
            TooltipSystem.ShowTemporary(arrows[direction], "default", TooltipSystem.arrowDuration)
        }
    }
    
    ; Show tooltip with style
    static ShowWithStyle(text, style := "default", duration := 0) {
        if (duration == 0) {
            duration := Config.TooltipDuration
        }
        
        ; Get position
        mon := MonitorUtils.GetMonitorInfo()
        xPos := Config.TooltipX is Number ? Config.TooltipX : MonitorUtils.EvaluateExpression(Config.TooltipX)
        yPos := Config.TooltipY is Number ? Config.TooltipY : MonitorUtils.EvaluateExpression(Config.TooltipY)
        x := mon.left + xPos
        y := mon.top + yPos
        
        ; Clear existing content
        for hwnd in TooltipSystem.globalTooltip {
            hwnd.Destroy()
        }
        
        ; Set background color based on style
        bgColor := Config.GetThemeColor("Tooltip" . StrTitle(style))
        TooltipSystem.globalTooltip.BackColor := bgColor
        
        ; Add new text
        textCtrl := TooltipSystem.globalTooltip.Add("Text", "cWhite", text)
        textCtrl.SetFont("s10", "Segoe UI")
        
        ; Show tooltip
        TooltipSystem.globalTooltip.Show("x" . x . " y" . y . " NoActivate")
        
        ; Set timer to hide
        SetTimer(() => TooltipSystem.Hide(), -duration)
    }
    
    ; Hide global tooltip
    static Hide() {
        TooltipSystem.globalTooltip.Hide()
    }
    
    ; Hide mouse tooltip
    static HideMouseTooltip() {
        TooltipSystem.mouseTooltip.Hide()
    }
    
    ; Hide all tooltips
    static HideAll() {
        TooltipSystem.globalTooltip.Hide()
        TooltipSystem.mouseTooltip.Hide()
        
        ; Hide any temporary tooltips
        for id, tooltip in TooltipSystem.tempTooltips {
            tooltip.Destroy()
        }
        TooltipSystem.tempTooltips.Clear()
    }
    
    ; Clean up tooltips
    static CleanUp() {
        TooltipSystem.HideAll()
        
        if (TooltipSystem.globalTooltip) {
            TooltipSystem.globalTooltip.Destroy()
        }
        
        if (TooltipSystem.mouseTooltip) {
            TooltipSystem.mouseTooltip.Destroy()
        }
    }
}