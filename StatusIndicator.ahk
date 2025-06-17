#Requires AutoHotkey v2.0

; ######################################################################################################################
; Updated Status Indicator Module - With Color Theme Support
; ######################################################################################################################
; 
; IMPORTANT: This is an updated version of StatusIndicator.ahk that integrates with ColorThemeManager.
; Replace the existing StatusIndicator.ahk with this version.
; ######################################################################################################################

class StatusIndicator {
    static statusIndicator := ""

    static Initialize() {
        StatusIndicator.statusIndicator := Gui("+AlwaysOnTop -MaximizeBox -MinimizeBox +LastFound -Caption +Border", "")
        StatusIndicator.statusIndicator.BackColor := ColorThemeManager.GetColor("statusOff")
        StatusIndicator.statusIndicator.MarginX := 4
        StatusIndicator.statusIndicator.MarginY := 2
        
        StatusIndicator.statusIndicator.textCtrl := StatusIndicator.statusIndicator.Add("Text", "cWhite Left h18", "⌨️ OFF • 🔄 Relative")
        StatusIndicator.statusIndicator.textCtrl.SetFont("s8 Bold", "Segoe UI")
        
        ; Apply text color based on theme
        textColor := ColorThemeManager.GetColor("textDefault")
        StatusIndicator.statusIndicator.textCtrl.SetFont("c" . textColor)
        
        pos := MonitorUtils.GetGuiPosition("status")
        
        ; Only show if status should be visible
        if (StateManager.IsStatusVisible()) {
            StatusIndicator.statusIndicator.Show("x" . pos[1] . " y" . pos[2] . " w116 h22 NoActivate")
        } else {
            StatusIndicator.statusIndicator.Move(pos[1], pos[2], 116, 22)
        }
    }

    static Update() {
        mainStatus := ""
        backgroundColor := ""
        
        if (!StateManager.IsMouseMode()) {
            backgroundColor := ColorThemeManager.GetColor("statusOff")
            mainStatus := "⌨️ OFF"
        } else if (StateManager.IsSaveMode()) {
            backgroundColor := ColorThemeManager.GetColor("statusSave")
            mainStatus := "💾 SAVE"
        } else if (StateManager.IsLoadMode()) {
            backgroundColor := ColorThemeManager.GetColor("statusLoad")
            mainStatus := "📂 LOAD"
        } else if (StateManager.IsInvertedMode()) {
            backgroundColor := ColorThemeManager.GetColor("statusInverted")
            mainStatus := "🔄 INV"
        } else {
            backgroundColor := ColorThemeManager.GetColor("statusOn")
            mainStatus := "🖱️ ON"
        }
        
        movementMode := Config.EnableAbsoluteMovement ? "🎯 ABS" : "🔄 REL"
        
        heldButtons := ""
        if (StateManager.IsLeftButtonHeld() || GetKeyState("LButton", "P")) {
            heldButtons := heldButtons . "🖱️L"
        }
        if (StateManager.IsRightButtonHeld() || GetKeyState("RButton", "P")) {
            heldButtons := heldButtons . "🖱️R"
        }
        if (StateManager.IsMiddleButtonHeld() || GetKeyState("MButton", "P")) {
            heldButtons := heldButtons . "🖱️M"
        }
        
        if (heldButtons != "") {
            combinedText := mainStatus . "•" . movementMode . "•" . heldButtons
        } else {
            combinedText := mainStatus . "•" . movementMode
        }
        
        ; Calculate text width accounting for emojis
        textWidth := StatusIndicator._CalculateTextWidth(combinedText)
        guiWidth := textWidth + 8
        
        if (guiWidth < 60) {
            guiWidth := 60
        }
        
        StatusIndicator.statusIndicator.BackColor := backgroundColor
        
        ; Update text color for contrast
        textColor := GetContrastingColor(backgroundColor)
        StatusIndicator.statusIndicator.textCtrl.SetFont("c" . textColor)
        
        StatusIndicator.statusIndicator.textCtrl.Text := combinedText
        StatusIndicator.statusIndicator.textCtrl.Move(2, 2, textWidth + 4, 18)
        
        pos := MonitorUtils.GetGuiPosition("status")
        StatusIndicator.statusIndicator.Move(pos[1], pos[2], guiWidth, 22)
        
        StatusIndicator.UpdateVisibility()
    }

    static _CalculateTextWidth(text) {
        ; Count emojis to calculate proper width
        keyboardEmojis := StrLen(text) - StrLen(StrReplace(text, "⌨️", ""))
        mouseEmojis := StrLen(text) - StrLen(StrReplace(text, "🖱️", ""))
        arrowEmojis := StrLen(text) - StrLen(StrReplace(text, "🔄", ""))
        targetEmojis := StrLen(text) - StrLen(StrReplace(text, "🎯", ""))
        saveEmojis := StrLen(text) - StrLen(StrReplace(text, "💾", ""))
        loadEmojis := StrLen(text) - StrLen(StrReplace(text, "📂", ""))
        
        totalEmojis := keyboardEmojis + mouseEmojis + arrowEmojis + targetEmojis + saveEmojis + loadEmojis
        regularChars := StrLen(text) - totalEmojis
        
        return (regularChars * 5) + (totalEmojis * 8)
    }

    static ShowTemporaryMessage(text, type := "info", duration := 800) {
        StatusIndicator.statusIndicator.BackColor := StatusIndicator._GetColorForType(type)
        
        ; Update text color for contrast
        bgColor := StatusIndicator._GetColorForType(type)
        textColor := GetContrastingColor(bgColor)
        StatusIndicator.statusIndicator.textCtrl.SetFont("c" . textColor)
        
        StatusIndicator.statusIndicator.textCtrl.Text := text
        
        SetTimer(() => StatusIndicator.Update(), -duration)
    }

    static _GetColorForType(type) {
        switch type {
            case "success": return ColorThemeManager.GetColor("tooltipSuccess")
            case "warning": return ColorThemeManager.GetColor("tooltipWarning")
            case "info": return ColorThemeManager.GetColor("tooltipInfo")
            case "error": return ColorThemeManager.GetColor("tooltipError")
            default: return ColorThemeManager.GetColor("tooltipDefault")
        }
    }

    static UpdateVisibility() {
        if (!StateManager.IsStatusVisible() || MonitorUtils.IsFullscreen()) {
            try {
                StatusIndicator.statusIndicator.Hide()
            }
        } else {
            try {
                StatusIndicator.statusIndicator.Show("NoActivate")
            }
        }
    }

    static ShowToggleMessage() {
        tempStatusGui := Gui("+AlwaysOnTop -MaximizeBox -MinimizeBox +LastFound -Caption +Border", "")
        tempStatusGui.MarginX := 8
        tempStatusGui.MarginY := 4
        
        if (StateManager.IsStatusVisible()) {
            tempStatusGui.BackColor := ColorThemeManager.GetColor("statusOn")
            statusText := "Status ON"
        } else {
            tempStatusGui.BackColor := ColorThemeManager.GetColor("statusInverted")
            statusText := "Status OFF"
        }
        
        ; Get contrasting text color
        textColor := GetContrastingColor(tempStatusGui.BackColor)
        
        textLength := StrLen(statusText)
        guiWidth := (textLength * 8) + 20
        if (guiWidth < 80) guiWidth := 80
        textWidth := guiWidth - 16
        
        tempStatusGui.textCtrl := tempStatusGui.Add("Text", "cWhite Center w" . textWidth . " h18", statusText)
        tempStatusGui.textCtrl.SetFont("s9 Bold c" . textColor, "Segoe UI")
        
        pos := MonitorUtils.GetGuiPosition("tooltip")
        tempStatusGui.Show("x" . pos[1] . " y" . pos[2] . " w" . guiWidth . " h26 NoActivate")
        
        SetTimer(() => tempStatusGui.Destroy(), -3000)
    }

    static ShowSecondaryMonitorToggle() {
        tempGui := Gui("+AlwaysOnTop -MaximizeBox -MinimizeBox +LastFound -Caption +Border", "")
        tempGui.MarginX := 8
        tempGui.MarginY := 4
        
        if (Config.UseSecondaryMonitor) {
            tempGui.BackColor := ColorThemeManager.GetColor("statusOn")
            statusText := "Secondary Monitor ON"
        } else {
            tempGui.BackColor := ColorThemeManager.GetColor("statusInverted")
            statusText := "Secondary Monitor OFF"
        }
        
        ; Get contrasting text color
        textColor := GetContrastingColor(tempGui.BackColor)
        
        textLength := StrLen(statusText)
        guiWidth := (textLength * 8) + 20
        if (guiWidth < 120) guiWidth := 120
        textWidth := guiWidth - 16
        
        tempGui.textCtrl := tempGui.Add("Text", "cWhite Center w" . textWidth . " h18", statusText)
        tempGui.textCtrl.SetFont("s9 Bold c" . textColor, "Segoe UI")
        
        pos := MonitorUtils.GetGuiPosition("tooltip")
        tempGui.Show("x" . pos[1] . " y" . pos[2] . " w" . guiWidth . " h26 NoActivate")
        
        SetTimer(() => tempGui.Destroy(), -3000)
    }

    static Cleanup() {
        if (StatusIndicator.statusIndicator != "") {
            StatusIndicator.statusIndicator.Destroy()
        }
    }
    
    ; Apply theme colors to status indicator
    static ApplyTheme() {
        if (StatusIndicator.statusIndicator != "") {
            ; The background color will be updated on the next Update() call
            StatusIndicator.Update()
        }
    }
}