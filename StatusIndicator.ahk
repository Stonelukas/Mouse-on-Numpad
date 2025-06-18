#Requires AutoHotkey v2.0

; ######################################################################################################################
; Fixed Status Indicator Module - With Working Color Theme Support
; ######################################################################################################################

class StatusIndicator {
    static statusIndicator := ""
    static isInitialized := false

    static Initialize() {
        StatusIndicator.statusIndicator := Gui("+AlwaysOnTop -MaximizeBox -MinimizeBox +LastFound -Caption +Border", "")
        StatusIndicator.statusIndicator.MarginX := 4
        StatusIndicator.statusIndicator.MarginY := 2
        
        ; Set initial background color
        StatusIndicator.statusIndicator.BackColor := ColorThemeManager.GetColor("statusOff")
        
        ; Create text control without initial color (will be set by Update)
        StatusIndicator.statusIndicator.textCtrl := StatusIndicator.statusIndicator.Add("Text", "Left h18", "⌨️ OFF • 🔄 Relative")
        StatusIndicator.statusIndicator.textCtrl.SetFont("s8 Bold", "Segoe UI")
        
        pos := MonitorUtils.GetGuiPosition("status")
        
        ; Position the GUI but don't show yet
        StatusIndicator.statusIndicator.Move(pos[1], pos[2], 116, 22)
        
        StatusIndicator.isInitialized := true
        
        ; Only show if status should be visible
        if (StateManager.IsStatusVisible()) {
            StatusIndicator.statusIndicator.Show("NoActivate")
        }
        
        ; Force initial update to apply colors
        StatusIndicator.Update()
    }

    static Update() {
        if (!StatusIndicator.isInitialized) {
            return
        }
        
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
        
        movementMode := Config.get("Movement.EnableAbsoluteMovement") ? "🎯 ABS" : "🔄 REL"
        
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
        
        ; Apply background color
        StatusIndicator.statusIndicator.BackColor := backgroundColor
        
        ; Get contrasting text color and apply it
        textColor := GetContrastingColor(backgroundColor)
        ; Remove the 0x prefix if present for SetFont
        if (SubStr(textColor, 1, 2) = "0x") {
            textColor := SubStr(textColor, 3)
        }
        StatusIndicator.statusIndicator.textCtrl.SetFont("c" . textColor)
        
        ; Update text
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
        bgColor := StatusIndicator._GetColorForType(type)
        StatusIndicator.statusIndicator.BackColor := bgColor
        
        ; Update text color for contrast
        textColor := GetContrastingColor(bgColor)
        if (SubStr(textColor, 1, 2) = "0x") {
            textColor := SubStr(textColor, 3)
        }
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
        if (!StatusIndicator.isInitialized) {
            return
        }
        
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
            bgColor := ColorThemeManager.GetColor("statusOn")
            statusText := "Status ON"
        } else {
            bgColor := ColorThemeManager.GetColor("statusInverted")
            statusText := "Status OFF"
        }
        
        tempStatusGui.BackColor := bgColor
        
        ; Get contrasting text color
        textColor := GetContrastingColor(bgColor)
        if (SubStr(textColor, 1, 2) = "0x") {
            textColor := SubStr(textColor, 3)
        }
        
        textLength := StrLen(statusText)
        guiWidth := (textLength * 8) + 20
        if (guiWidth < 80) guiWidth := 80
        textWidth := guiWidth - 16
        
        tempStatusGui.textCtrl := tempStatusGui.Add("Text", "Center w" . textWidth . " h18", statusText)
        tempStatusGui.textCtrl.SetFont("s9 Bold c" . textColor, "Segoe UI")
        
        pos := MonitorUtils.GetGuiPosition("tooltip")
        tempStatusGui.Show("x" . pos[1] . " y" . pos[2] . " w" . guiWidth . " h26 NoActivate")
        
        SetTimer(() => tempStatusGui.Destroy(), -3000)
    }

    static ShowSecondaryMonitorToggle() {
        tempGui := Gui("+AlwaysOnTop -MaximizeBox -MinimizeBox +LastFound -Caption +Border", "")
        tempGui.MarginX := 8
        tempGui.MarginY := 4
        
        if (Config.get("Visual.UseSecondaryMonitor")) {
            bgColor := ColorThemeManager.GetColor("statusOn")
            statusText := "Secondary Monitor ON"
        } else {
            bgColor := ColorThemeManager.GetColor("statusInverted")
            statusText := "Secondary Monitor OFF"
        }
        
        tempGui.BackColor := bgColor
        
        ; Get contrasting text color
        textColor := GetContrastingColor(bgColor)
        if (SubStr(textColor, 1, 2) = "0x") {
            textColor := SubStr(textColor, 3)
        }
        
        textLength := StrLen(statusText)
        guiWidth := (textLength * 8) + 20
        if (guiWidth < 120) guiWidth := 120
        textWidth := guiWidth - 16
        
        tempGui.textCtrl := tempGui.Add("Text", "Center w" . textWidth . " h18", statusText)
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
    
    ; Apply theme colors to status indicator - force immediate update
    static ApplyTheme() {
        if (StatusIndicator.isInitialized && StatusIndicator.statusIndicator != "") {
            ; Force update with current state
            StatusIndicator.Update()
        }
    }
}