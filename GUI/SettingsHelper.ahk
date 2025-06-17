#Requires AutoHotkey v2.0

; ######################################################################################################################
; Settings GUI Helpers - Helper methods and preview updates
; ######################################################################################################################

; Update Movement Preview
SettingsGUI._UpdateMovementPreview := (*) {
    try {
        ; Get current values from the controls
        moveStep := SettingsGUI.controls["MoveStep"].Text
        moveDelay := SettingsGUI.controls["MoveDelay"].Text
        accelRate := SettingsGUI.controls["AccelerationRate"].Text
        maxSpeed := SettingsGUI.controls["MaxSpeed"].Text
        isAbsolute := SettingsGUI.controls["EnableAbsoluteMovement"].Value

        ; Get scroll settings
        scrollStep := SettingsGUI.controls["ScrollStep"].Text
        scrollAccel := SettingsGUI.controls["ScrollAccelerationRate"].Text
        maxScrollSpeed := SettingsGUI.controls["MaxScrollSpeed"].Text

        previewText := "=== MOVEMENT & SCROLL PREVIEW ===`r`n`r`n"

        ; Movement Settings
        previewText .= "🖱️ MOVEMENT SETTINGS:`r`n"
        previewText .= "• Step Size: " . moveStep . " pixels`r`n"
        previewText .= "• Delay: " . moveDelay . " ms`r`n"
        previewText .= "• Acceleration: " . accelRate . "x per step`r`n"
        previewText .= "• Max Speed: " . maxSpeed . " pixels/step`r`n"
        previewText .= "• Mode: " . (isAbsolute ? "🎯 Absolute" : "🔄 Relative") . "`r`n"

        ; Scroll Settings
        previewText .= "`r`n📜 SCROLL SETTINGS:`r`n"
        previewText .= "• Step Size: " . scrollStep . " lines`r`n"
        previewText .= "• Acceleration: " . scrollAccel . "x per step`r`n"
        previewText .= "• Max Speed: " . maxScrollSpeed . " lines/step`r`n"

        ; Movement Calculations
        previewText .= "`r`n🧮 MOVEMENT CALCULATIONS:`r`n"
        previewText .= "• After 1 step: " . moveStep . " pixels`r`n"
        if (IsNumber(moveStep) && IsNumber(accelRate)) {
            previewText .= "• After 2 steps: " . Round(moveStep * accelRate) . " pixels`r`n"
            previewText .= "• After 3 steps: " . Round(moveStep * (accelRate ** 2)) . " pixels`r`n"
            if (accelRate > 1 && IsNumber(maxSpeed)) {
                previewText .= "• Time to max: ~" . Round(Log(maxSpeed / moveStep) / Log(accelRate) * moveDelay) . " ms`r`n"
            }
        }

        ; Scroll Calculations
        previewText .= "`r`n📊 SCROLL CALCULATIONS:`r`n"
        previewText .= "• After 1 step: " . scrollStep . " lines`r`n"
        if (IsNumber(scrollStep) && IsNumber(scrollAccel)) {
            previewText .= "• After 2 steps: " . Round(scrollStep * scrollAccel) . " lines`r`n"
            previewText .= "• After 3 steps: " . Round(scrollStep * (scrollAccel ** 2)) . " lines`r`n"
            if (scrollAccel > 1 && IsNumber(maxScrollSpeed)) {
                previewText .= "• Time to max: ~" . Round(Log(maxScrollSpeed / scrollStep) / Log(scrollAccel) * moveDelay) . " ms`r`n"
            }
        }

        ; Performance Info
        previewText .= "`r`n⚡ PERFORMANCE:`r`n"
        if (IsNumber(moveDelay)) {
            previewText .= "• Updates per second: " . Round(1000 / moveDelay) . " Hz`r`n"
            previewText .= "• Response time: " . moveDelay . " ms`r`n"
        }

        ; Update the preview control
        SettingsGUI.controls["MovementPreview"].Text := previewText

    } catch Error as e {
        SettingsGUI.controls["MovementPreview"].Text := "Error updating preview: " . e.Message
    }
}

; Update Visuals Preview
SettingsGUI._UpdateVisualsPreview := (*) {
    try {
        ; Get current selections
        colorTheme := SettingsGUI.controls["ColorTheme"].Text
        tooltipDuration := SettingsGUI.controls["TooltipDuration"].Text
        statusDuration := SettingsGUI.controls["StatusMessageDuration"].Text
        statusVisible := SettingsGUI.controls["StatusVisibleOnStartup"].Value
        useSecondary := SettingsGUI.controls["UseSecondaryMonitor"].Value
        audioEnabled := SettingsGUI.controls["EnableAudioFeedback"].Value

        ; Store temp theme
        SettingsGUI.tempSettings["ColorTheme"] := colorTheme
        SettingsGUI.tempSettings["TooltipDuration"] := tooltipDuration
        SettingsGUI.tempSettings["StatusMessageDuration"] := statusDuration

        previewText := "=== VISUAL SETTINGS PREVIEW ===`r`n`r`n"

        ; Theme Settings
        previewText .= "🎨 COLOR THEME SETTINGS:`r`n"
        previewText .= "• Current Theme: " . colorTheme . "`r`n"
        previewText .= "• Tooltip Duration: " . tooltipDuration . " ms`r`n"
        previewText .= "• Status Message Duration: " . statusDuration . " ms`r`n`r`n"

        ; Display Settings
        previewText .= "📺 DISPLAY SETTINGS:`r`n"
        previewText .= "• Status Visible on Startup: " . (statusVisible ? "Yes" : "No") . "`r`n"
        previewText .= "• Use Secondary Monitor: " . (useSecondary ? "Yes" : "No") . "`r`n"
        previewText .= "• Audio Feedback: " . (audioEnabled ? "Enabled" : "Disabled") . "`r`n`r`n"

        ; Position Settings
        previewText .= "📍 POSITION SETTINGS:`r`n"
        previewText .= "• Status Position: " . SettingsGUI.controls["StatusX"].Text . ", " . SettingsGUI.controls["StatusY"].Text . "`r`n"
        previewText .= "• Tooltip Position: " . SettingsGUI.controls["TooltipX"].Text . ", " . SettingsGUI.controls["TooltipY"].Text . "`r`n`r`n"

        ; Color Preview
        previewText .= "🎨 THEME COLOR PREVIEW:`r`n"
        ; Get the colors for this theme
        if (Config.ColorThemes.Has(colorTheme)) {
            theme := Config.ColorThemes[colorTheme]

            previewText .= "Status Colors:`r`n"
            previewText .= "• ON: " . SettingsGUI._ColorToRGB(theme["StatusOn"]) . "`r`n"
            previewText .= "• OFF: " . SettingsGUI._ColorToRGB(theme["StatusOff"]) . "`r`n"
            previewText .= "• Inverted: " . SettingsGUI._ColorToRGB(theme["StatusInverted"]) . "`r`n"
            previewText .= "• Save Mode: " . SettingsGUI._ColorToRGB(theme["StatusSave"]) . "`r`n"
            previewText .= "• Load Mode: " . SettingsGUI._ColorToRGB(theme["StatusLoad"]) . "`r`n`r`n"

            previewText .= "Tooltip Colors:`r`n"
            previewText .= "• Default: " . SettingsGUI._ColorToRGB(theme["TooltipDefault"]) . "`r`n"
            previewText .= "• Success: " . SettingsGUI._ColorToRGB(theme["TooltipSuccess"]) . "`r`n"
            previewText .= "• Warning: " . SettingsGUI._ColorToRGB(theme["TooltipWarning"]) . "`r`n"
            previewText .= "• Error: " . SettingsGUI._ColorToRGB(theme["TooltipError"]) . "`r`n"
        }

        ; Update the preview control
        SettingsGUI.controls["VisualPreview"].Text := previewText

    } catch Error as e {
        SettingsGUI.controls["VisualPreview"].Text := "Error updating preview: " . e.Message
    }
}

; Apply Settings
SettingsGUI._ApplySettings := (*) {
    try {
        ; Movement Settings
        Config.MoveStep := Integer(SettingsGUI.controls["MoveStep"].Text)
        Config.MoveDelay := Integer(SettingsGUI.controls["MoveDelay"].Text)
        Config.AccelerationRate := Float(SettingsGUI.controls["AccelerationRate"].Text)
        Config.MaxSpeed := Integer(SettingsGUI.controls["MaxSpeed"].Text)
        Config.EnableAbsoluteMovement := SettingsGUI.controls["EnableAbsoluteMovement"].Value ? true : false

        ; Position Settings
        Config.MaxSavedPositions := Integer(SettingsGUI.controls["MaxSavedPositions"].Text)
        Config.MaxUndoLevels := Integer(SettingsGUI.controls["MaxUndoLevels"].Text)

        ; Visual Settings
        Config.EnableAudioFeedback := SettingsGUI.controls["EnableAudioFeedback"].Value ? true : false
        Config.StatusVisibleOnStartup := SettingsGUI.controls["StatusVisibleOnStartup"].Value ? true : false
        Config.UseSecondaryMonitor := SettingsGUI.controls["UseSecondaryMonitor"].Value ? true : false

        ; Color Theme Settings
        Config.ColorTheme := SettingsGUI.controls["ColorTheme"].Text
        Config.TooltipDuration := Integer(SettingsGUI.controls["TooltipDuration"].Text)
        Config.StatusMessageDuration := Integer(SettingsGUI.controls["StatusMessageDuration"].Text)

        ; Scroll Settings
        Config.ScrollStep := Integer(SettingsGUI.controls["ScrollStep"].Text)
        Config.ScrollAccelerationRate := Float(SettingsGUI.controls["ScrollAccelerationRate"].Text)
        Config.MaxScrollSpeed := Integer(SettingsGUI.controls["MaxScrollSpeed"].Text)

        ; GUI Positions
        Config.StatusX := SettingsGUI.controls["StatusX"].Text
        Config.StatusY := SettingsGUI.controls["StatusY"].Text
        Config.TooltipX := SettingsGUI.controls["TooltipX"].Text
        Config.TooltipY := SettingsGUI.controls["TooltipY"].Text

        ; Save configuration
        Config.Save()

        ; Update status indicator to reflect changes
        StatusIndicator.Update()

        ; Update tooltip colors if theme changed
        if (TooltipSystem.globalTooltip != "") {
            TooltipSystem.globalTooltip.BackColor := Config.GetThemeColor("TooltipDefault")
        }
        if (TooltipSystem.mouseTooltip != "") {
            TooltipSystem.mouseTooltip.BackColor := Config.GetThemeColor("TooltipSuccess")
        }

        ; Show success message
        MsgBox("Settings have been applied successfully!", "Settings Applied", "Iconi T3")

    } catch Error as e {
        MsgBox("Error applying settings: " . e.Message . "`n`nPlease check your input values.", "Error", "IconX")
    }
}

; Apply Theme Now (without saving)
SettingsGUI._ApplyThemeNow := (*) {
    ; Apply the selected theme immediately without saving to config
    Config.ColorTheme := SettingsGUI.controls["ColorTheme"].Text
    Config.TooltipDuration := Integer(SettingsGUI.controls["TooltipDuration"].Text)
    Config.StatusMessageDuration := Integer(SettingsGUI.controls["StatusMessageDuration"].Text)

    ; Update all active GUI elements
    StatusIndicator.Update()

    ; Recreate tooltips with new colors
    if (TooltipSystem.globalTooltip != "") {
        TooltipSystem.globalTooltip.BackColor := Config.GetThemeColor("TooltipDefault")
    }
    if (TooltipSystem.mouseTooltip != "") {
        TooltipSystem.mouseTooltip.BackColor := Config.GetThemeColor("TooltipSuccess")
    }

    ; Show confirmation
    confirmGui := Gui("+AlwaysOnTop -MaximizeBox -MinimizeBox +LastFound -Caption +Border", "")
    confirmGui.BackColor := Config.GetThemeColor("TooltipSuccess")
    confirmGui.MarginX := 10
    confirmGui.MarginY := 5

    confirmGui.textCtrl := confirmGui.Add("Text", "cWhite Center w150 h20", "✓ Theme Applied!")
    confirmGui.textCtrl.SetFont("s10 Bold", "Segoe UI")

    centerX := (A_ScreenWidth - 170) // 2
    centerY := (A_ScreenHeight - 30) // 2
    confirmGui.Show("x" . centerX . " y" . centerY . " w170 h30 NoActivate")

    SetTimer(() => confirmGui.Destroy(), -2000)
}

; Reset Visuals
SettingsGUI._ResetVisuals := (*) {
    result := MsgBox(
        "Reset all visual settings to default?`n`nThis will reset:`n• Color theme to Default`n• All positions to default`n• Tooltip durations to default",
        "Reset Visual Settings", "YesNo Icon?")

    if (result = "Yes") {
        ; Reset to defaults
        SettingsGUI.controls["ColorTheme"].Choose(1)  ; Default theme
        SettingsGUI.controls["TooltipDuration"].Text := "3000"
        SettingsGUI.controls["StatusMessageDuration"].Text := "800"
        SettingsGUI.controls["StatusX"].Text := "Round(A_ScreenWidth * 0.65)"
        SettingsGUI.controls["StatusY"].Text := "15"
        SettingsGUI.controls["TooltipX"].Text := "20"
        SettingsGUI.controls["TooltipY"].Text := "A_ScreenHeight - 80"
        SettingsGUI.controls["StatusVisibleOnStartup"].Value := 1
        SettingsGUI.controls["UseSecondaryMonitor"].Value := 0
        SettingsGUI.controls["EnableAudioFeedback"].Value := 0

        ; Update temp settings
        SettingsGUI.tempSettings["ColorTheme"] := "Default"
        SettingsGUI.tempSettings["TooltipDuration"] := 3000
        SettingsGUI.tempSettings["StatusMessageDuration"] := 800

        ; Update preview
        SettingsGUI._UpdateVisualsPreview()

        MsgBox("Visual settings have been reset to defaults.", "Reset Complete", "Iconi T2")
    }
}

; Color to RGB conversion helper
SettingsGUI._ColorToRGB := (hex) {
    ; Convert hex color to RGB format
    hex := StrReplace(hex, "0x", "")
    hex := StrReplace(hex, "#", "")
    
    if (StrLen(hex) == 8) {  ; ARGB format
        hex := SubStr(hex, 3)  ; Skip alpha channel
    }
    
    r := Integer("0x" . SubStr(hex, 1, 2))
    g := Integer("0x" . SubStr(hex, 3, 2))
    b := Integer("0x" . SubStr(hex, 5, 2))
    
    return "RGB(" . r . ", " . g . ", " . b . ")"
}

; Show Help
SettingsGUI._ShowHelp := (*) {
    helpText := "MOUSE ON NUMPAD ENHANCED - SETTINGS HELP`n`n"
    helpText .= "TABS:`n"
    helpText .= "• Movement: Configure mouse movement speed, acceleration, and scrolling`n"
    helpText .= "• Positions: Manage saved mouse positions and undo levels`n"
    helpText .= "• Visuals: Customize appearance, positioning, and audio feedback`n"
    helpText .= "• Hotkeys: View and modify keyboard shortcuts`n"
    helpText .= "• Advanced: Performance, logging, and experimental features`n"
    helpText .= "• Profiles: Save and load different configurations`n"
    helpText .= "• About: Information about the application`n`n"
    helpText .= "BUTTONS:`n"
    helpText .= "• Apply: Save changes without closing the window`n"
    helpText .= "• OK: Save changes and close the window`n"
    helpText .= "• Cancel: Discard changes and close`n"
    helpText .= "• Import/Export: Share settings between devices`n`n"
    helpText .= "For more help, check the documentation or visit the support forum."

    MsgBox(helpText, "Settings Help", "Iconi")
}

; Import/Export Settings
SettingsGUI._ImportSettings := (*) {
    MsgBox("Import settings functionality will be implemented in a future update.", "Import Settings", "Iconi T3")
}

SettingsGUI._ExportSettings := (*) {
    MsgBox("Export settings functionality will be implemented in a future update.", "Export Settings", "Iconi T3")
}

; Position Management Methods
SettingsGUI._PreviewSelectedPosition := (*) {
    row := SettingsGUI.controls["PositionList"].GetNext()
    if (row) {
        slot := Integer(SettingsGUI.controls["PositionList"].GetText(row, 1))
        x := Integer(SettingsGUI.controls["PositionList"].GetText(row, 2))
        y := Integer(SettingsGUI.controls["PositionList"].GetText(row, 3))

        ; Create a preview window at the position
        previewGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20", "")
        previewGui.BackColor := "0xFF0000"  ; Red background
        WinSetTransColor("0xFF0000", previewGui)  ; Make red transparent

        ; Draw a circle/crosshair at the position
        previewGui.SetFont("s20 Bold", "Arial")
        previewGui.Add("Text", "x0 y0 w50 h50 Center cLime BackgroundTrans", "⊕")

        ; Show the preview at the saved position
        previewGui.Show("x" . (x - 25) . " y" . (y - 25) . " w50 h50 NoActivate")

        ; Destroy after 2 seconds
        SetTimer(() => previewGui.Destroy(), -2000)
    } else {
        MsgBox("Please select a position to preview.", "No Selection", "Icon!")
    }
}

SettingsGUI._DeleteSelectedPosition := (*) {
    row := SettingsGUI.controls["PositionList"].GetNext()
    if (row) {
        slot := Integer(SettingsGUI.controls["PositionList"].GetText(row, 1))
        result := MsgBox("Delete position " . slot . "?", "Confirm Delete", "YesNo Icon?")
        
        if (result = "Yes") {
            ; Remove from INI file
            IniDelete(Config.PersistentPositionsFile, "Position" . slot)
            
            ; Refresh list
            SettingsGUI._PopulatePositionList()
            
            MsgBox("Position " . slot . " has been deleted.", "Position Deleted", "Iconi T2")
        }
    } else {
        MsgBox("Please select a position to delete.", "No Selection", "Icon!")
    }
}

SettingsGUI._ClearAllPositions := (*) {
    result := MsgBox(
        "This will permanently delete ALL saved positions!`n`nAre you sure you want to continue?",
        "Clear All Positions", "YesNo IconX Default2")
    
    if (result = "Yes") {
        ; Delete all position sections from INI
        loop Config.MaxSavedPositions {
            IniDelete(Config.PersistentPositionsFile, "Position" . A_Index)
        }
        
        ; Refresh list
        SettingsGUI._PopulatePositionList()
        
        MsgBox("All saved positions have been cleared.", "Positions Cleared", "Iconi T2")
    }
}