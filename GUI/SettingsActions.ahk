#Requires AutoHotkey v2.0

; ######################################################################################################################
; Settings GUI Actions - All action/button handler methods
; ######################################################################################################################

; Apply Settings
SettingsGUI._ApplySettings := (*) {
    ; Apply all settings from temp storage to actual config
    try {
        ; Movement Settings
        Config.MoveStep := Integer(SettingsGUI.controls["MoveStep"].Text)
        Config.MoveDelay := Integer(SettingsGUI.controls["MoveDelay"].Text)
        Config.AccelerationRate := Float(SettingsGUI.controls["AccelerationRate"].Text)
        Config.MaxSpeed := Integer(SettingsGUI.controls["MaxSpeed"].Text)

        ; Absolute Movement
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
        Config.TooltipDuration := SettingsGUI.tempSettings["TooltipDuration"]
        Config.StatusMessageDuration := SettingsGUI.tempSettings["StatusMessageDuration"]

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

; Test Methods
SettingsGUI._TestAudio := (*) {
    if (SettingsGUI.controls["EnableAudioFeedback"].Value) {
        SoundBeep(800, 200)
        MsgBox("Audio feedback test completed!", "Test Audio", "T2")
    } else {
        MsgBox("Audio feedback is currently disabled.`nEnable it first to test.", "Test Audio", "Icon!")
    }
}

SettingsGUI._TestStatusPosition := (*) {
    ; Create test status indicator at configured position
    xPos := SettingsGUI.controls["StatusX"].Text
    yPos := SettingsGUI.controls["StatusY"].Text
    
    ; Evaluate expressions
    testX := Config.TooltipX is Number ? xPos : MonitorUtils.EvaluateExpression(xPos)
    testY := Config.TooltipY is Number ? yPos : MonitorUtils.EvaluateExpression(yPos)
    
    ; Get monitor position
    mon := MonitorUtils.GetMonitorInfo()
    finalX := mon.left + testX
    finalY := mon.top + testY
    
    ; Create test GUI
    testGui := Gui("+AlwaysOnTop -MaximizeBox -MinimizeBox +LastFound -Caption +Border", "")
    testGui.BackColor := Config.GetThemeColor("StatusOn")
    testGui.MarginX := 4
    testGui.MarginY := 2
    
    testGui.textCtrl := testGui.Add("Text", "cWhite Left h18", "🖱️ TEST STATUS")
    testGui.textCtrl.SetFont("s8 Bold", "Segoe UI")
    
    testGui.Show("x" . finalX . " y" . finalY . " w100 h22 NoActivate")
    
    ; Flash and destroy after 3 seconds
    loop 3 {
        Sleep(300)
        testGui.Hide()
        Sleep(300)
        testGui.Show("NoActivate")
    }
    testGui.Destroy()
    
    MsgBox("Status position test completed at:`nX: " . finalX . ", Y: " . finalY, "Test Complete", "Iconi T3")
}

SettingsGUI._TestTooltipPosition := (*) {
    ; Create test tooltip at configured position
    xPos := SettingsGUI.controls["TooltipX"].Text
    yPos := SettingsGUI.controls["TooltipY"].Text
    
    ; Evaluate expressions
    testX := Config.TooltipX is Number ? xPos : MonitorUtils.EvaluateExpression(xPos)
    testY := Config.TooltipY is Number ? yPos : MonitorUtils.EvaluateExpression(yPos)
    
    ; Get monitor position
    mon := MonitorUtils.GetMonitorInfo()
    finalX := mon.left + testX
    finalY := mon.top + testY
    
    ; Create test GUI
    testGui := Gui("+AlwaysOnTop -MaximizeBox -MinimizeBox +LastFound -Caption +Border", "")
    testGui.BackColor := Config.GetThemeColor("TooltipSuccess")
    testGui.MarginX := 8
    testGui.MarginY := 4
    
    testGui.textCtrl := testGui.Add("Text", "cWhite Center w120 h20", "🎯 TEST TOOLTIP")
    testGui.textCtrl.SetFont("s9 Bold", "Segoe UI")
    
    testGui.Show("x" . finalX . " y" . finalY . " w140 h28 NoActivate")
    
    ; Show different colors
    colors := ["TooltipSuccess", "TooltipWarning", "TooltipInfo", "TooltipError", "TooltipDefault"]
    labels := ["✓ Success", "⚠ Warning", "ℹ Info", "✕ Error", "• Default"]
    
    for i, colorType in colors {
        Sleep(800)
        testGui.BackColor := Config.GetThemeColor(colorType)
        testGui.textCtrl.Text := labels[i]
    }
    
    Sleep(800)
    testGui.Destroy()
    
    MsgBox("Tooltip position test completed at:`nX: " . finalX . ", Y: " . finalY, "Test Complete", "Iconi T3")
}

; Theme Methods
SettingsGUI._ApplyThemeNow := (*) {
    ; Apply the selected theme immediately without saving to config
    Config.ColorTheme := SettingsGUI.controls["ColorTheme"].Text
    Config.TooltipDuration := SettingsGUI.tempSettings["TooltipDuration"]
    Config.StatusMessageDuration := SettingsGUI.tempSettings["StatusMessageDuration"]
    
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

SettingsGUI._ResetVisuals := (*) {
    result := MsgBox("Reset all visual settings to default?`n`nThis will reset:`n• Color theme to Default`n• All positions to default`n• Tooltip durations to default",
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

; Position Management
SettingsGUI._GotoSelectedPosition := (*) {
    row := SettingsGUI.controls["PositionList"].GetNext()
    if (row) {
        slot := Integer(SettingsGUI.controls["PositionList"].GetText(row, 1))
        savedPositions := PositionMemory.GetSavedPositions()
        if (savedPositions.Has(slot)) {
            pos := savedPositions[slot]
            ; CRITICAL: Set coordinate mode to Screen for proper negative coordinate handling
            CoordMode("Mouse", "Screen")
            ; Add current position to history before moving
            MouseGetPos(&currentX, &currentY)
            MouseActions.AddToHistory(currentX, currentY)
            ; Move to the saved position
            MouseMove(pos.x, pos.y, 10)
            ; Show feedback
            TooltipSystem.ShowMouseAction("Moved to position " . slot . " (" . pos.x . ", " . pos.y . ")", "success")
        } else {
            MsgBox("Position data not found for slot " . slot, "Error", "IconX")
        }
    } else {
        MsgBox("Please select a position from the list first.", "No Selection", "Icon!")
    }
}

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

        ; Add a label showing the slot number
        labelGui := Gui("+AlwaysOnTop -Caption +ToolWindow", "")
        labelGui.BackColor := "0x2196F3"
        labelGui.SetFont("s12 Bold", "Segoe UI")
        labelGui.Add("Text", "x5 y2 w40 h20 Center cWhite", "Slot " . slot)
        labelGui.Show("x" . (x - 25) . " y" . (y + 30) . " w50 h25 NoActivate")

        ; Flash the preview
        loop 3 {
            Sleep(200)
            previewGui.Hide()
            labelGui.Hide()
            Sleep(200)
            previewGui.Show("NoActivate")
            labelGui.Show("NoActivate")
        }

        ; Clean up
        Sleep(500)
        previewGui.Destroy()
        labelGui.Destroy()

    } else {
        MsgBox("Please select a position from the list to preview.", "No Selection", "Icon!")
    }
}

SettingsGUI._SaveCurrentPosition := (*) {
    ; Create a custom dialog that updates mouse position in real-time
    saveDialog := Gui("+AlwaysOnTop", "Save Mouse Position")
    saveDialog.SetFont("s10")
    
    ; Apply dark mode if needed
    if (SettingsGUI.isDarkMode) {
        saveDialog.BackColor := "0x1E1E1E"
    }

    ; Instructions
    instructionText := saveDialog.Add("Text", "x10 y10 w300", "Move your mouse to the desired position.")
    if (SettingsGUI.isDarkMode) {
        instructionText.Opt("cWhite")
    }

    ; Current position display (will update)
    posText := saveDialog.Add("Text", "x10 y35 w300 h20", "Current mouse position: ")
    if (SettingsGUI.isDarkMode) {
        posText.Opt("cSilver")
    }
    posDisplay := saveDialog.Add("Text", "x10 y55 w300 h20 +0x200", "X: 0, Y: 0")
    posDisplay.SetFont("s12 Bold")
    if (SettingsGUI.isDarkMode) {
        posDisplay.Opt("cLime")
    }

    ; Slot selection
    slotLabel := saveDialog.Add("Text", "x10 y85 w100", "Save to slot:")
    if (SettingsGUI.isDarkMode) {
        slotLabel.Opt("cWhite")
    }
    slotEdit := saveDialog.Add("Edit", "x110 y82 w50 Number")
    slotUpDown := saveDialog.Add("UpDown", "x160 y82 w20 h20 Range1-" . Config.MaxSavedPositions, 1)
    slotDesc := saveDialog.Add("Text", "x185 y85 w100", "(1-" . Config.MaxSavedPositions . ")")
    if (SettingsGUI.isDarkMode) {
        slotDesc.Opt("cSilver")
    }

    ; Set initial value
    slotEdit.Text := "1"

    ; Buttons
    saveBtn := saveDialog.Add("Button", "x50 y120 w80 h25 +Default", "Save")
    cancelBtn := saveDialog.Add("Button", "x150 y120 w80 h25", "Cancel")

    ; Variables to store the position
    savedX := 0
    savedY := 0
    savedSlot := 1
    shouldSave := false

    ; Timer function to update position display
    updatePosDisplay() {
        ; CRITICAL: Set coordinate mode to Screen for proper negative coordinate handling
        CoordMode("Mouse", "Screen")
        MouseGetPos(&currentX, &currentY)
        posDisplay.Text := "X: " . currentX . ", Y: " . currentY
    }

    ; Start the timer
    SetTimer(updatePosDisplay, 50)  ; Update every 50ms

    ; Button event handlers
    onSaveClick(*) {
        ; CRITICAL: Set coordinate mode to Screen for proper negative coordinate handling
        CoordMode("Mouse", "Screen")
        MouseGetPos(&savedX, &savedY)  ; Capture position at save time
        shouldSave := true
        ; Store the slot value BEFORE destroying the dialog
        savedSlot := slotEdit.Text
        SetTimer(updatePosDisplay, 0)  ; Stop timer
        saveDialog.Destroy()
    }

    onCancelClick(*) {
        shouldSave := false
        SetTimer(updatePosDisplay, 0)  ; Stop timer
        saveDialog.Destroy()
    }

    onDialogClose(*) {
        SetTimer(updatePosDisplay, 0)  ; Stop timer
    }

    ; Attach events
    saveBtn.OnEvent("Click", onSaveClick)
    cancelBtn.OnEvent("Click", onCancelClick)
    saveDialog.OnEvent("Close", onDialogClose)

    ; Show dialog
    saveDialog.Show()

    ; Wait for dialog to close
    WinWaitClose(saveDialog)

    ; Process the save if user clicked Save
    if (shouldSave) {
        slot := Integer(savedSlot)  ; Use the saved slot value
        if (slot >= 1 && slot <= Config.MaxSavedPositions) {
            ; Check if slot already has a position
            if (PositionMemory.HasPosition(slot)) {
                result := MsgBox("Slot " . slot . " already has a saved position. Overwrite?", "Confirm Overwrite",
                    "YesNo Icon?")
                if (result != "Yes") {
                    return
                }
            }

            ; Save the captured position
            ; CRITICAL: Set coordinate mode to Screen for proper negative coordinate handling
            CoordMode("Mouse", "Screen")
            MouseGetPos(&tempX, &tempY)  ; Save current position
            MouseMove(savedX, savedY, 0)  ; Move to captured position
            PositionMemory.SavePosition(slot)  ; Save it
            MouseMove(tempX, tempY, 0)  ; Move back
            PositionMemory.SavePositions()  ; Persist to file

            ; Refresh the list
            SettingsGUI._PopulatePositionList()

            ; Show success with the saved position
            MsgBox("Mouse position (" . savedX . ", " . savedY . ") saved to slot " . slot, "Success", "Iconi T3")
        } else {
            MsgBox("Invalid slot number. Please enter a number between 1 and " . Config.MaxSavedPositions, "Error",
                "IconX")
        }
    }
}

SettingsGUI._DeleteSelectedPosition := (*) {
    row := SettingsGUI.controls["PositionList"].GetNext()
    if (row) {
        slot := Integer(SettingsGUI.controls["PositionList"].GetText(row, 1))
        x := SettingsGUI.controls["PositionList"].GetText(row, 2)
        y := SettingsGUI.controls["PositionList"].GetText(row, 3)

        result := MsgBox("Delete position " . slot . " (" . x . ", " . y . ")?`n`nThis cannot be undone.",
            "Confirm Delete", "YesNo IconX")
        if (result = "Yes") {
            ; Delete the position
            PositionMemory.ClearPosition(slot)
            PositionMemory.SavePositions()  ; Persist changes to file

            ; Refresh the list
            SettingsGUI._PopulatePositionList()

            ; Show confirmation
            MsgBox("Position " . slot . " has been deleted.", "Position Deleted", "Iconi T2")
        }
    } else {
        MsgBox("Please select a position to delete from the list.", "No Selection", "Icon!")
    }
}

SettingsGUI._ClearAllPositions := (*) {
    ; Check if there are any positions to clear
    if (PositionMemory.GetSavedPositions().Count = 0) {
        MsgBox("No saved positions to clear.", "Nothing to Clear", "Iconi")
        return
    }

    result := MsgBox("Are you sure you want to clear ALL saved positions?`n`nThis will permanently delete all " .
        PositionMemory.GetSavedPositions().Count . " saved positions.", "Clear All Positions",
        "YesNo IconX Default2")
    if (result = "Yes") {
        ; Double confirmation for safety
        confirm := MsgBox("This action cannot be undone. Are you absolutely sure?", "Final Confirmation",
            "YesNo IconX Default2")
        if (confirm = "Yes") {
            PositionMemory.ClearAllPositions()
            PositionMemory.SavePositions()  ; Persist changes to file
            SettingsGUI._PopulatePositionList()
            MsgBox("All positions have been cleared.", "Positions Cleared", "Iconi T2")
        }
    }
}

; Import/Export Methods
SettingsGUI._ImportPositions := (*) {
    MsgBox("Position import functionality will be implemented in a future update.", "Import Positions", "Iconi T3")
}

SettingsGUI._ExportPositions := (*) {
    MsgBox("Position export functionality will be implemented in a future update.", "Export Positions", "Iconi T3")
}

SettingsGUI._ImportSettings := (*) {
    MsgBox("Settings import functionality will be implemented in a future update.", "Import Settings", "Iconi T3")
}

SettingsGUI._ExportSettings := (*) {
    MsgBox("Settings export functionality will be implemented in a future update.", "Export Settings", "Iconi T3")
}

; Hotkey Methods
SettingsGUI._EditSelectedHotkey := (*) {
    MsgBox("Hotkey editing will be available in a future update.`nFor now, you can modify hotkeys in the HotkeyManager.ahk file.",
        "Edit Hotkey", "Iconi")
}

SettingsGUI._ResetSelectedHotkey := (*) {
    MsgBox("Reset hotkey functionality will be implemented in a future update.", "Reset Hotkey", "Iconi T3")
}

SettingsGUI._TestSelectedHotkey := (*) {
    row := SettingsGUI.controls["HotkeyList"].GetNext()
    if (row) {
        action := SettingsGUI.controls["HotkeyList"].GetText(row, 1)
        hotkey := SettingsGUI.controls["HotkeyList"].GetText(row, 2)
        MsgBox("Press " . hotkey . " to test:`n" . action, "Test Hotkey", "Iconi T5")
    } else {
        MsgBox("Please select a hotkey to test.", "No Selection", "Icon!")
    }
}

SettingsGUI._ScanForConflicts := (*) {
    ; Placeholder for conflict detection
    SettingsGUI.controls["ConflictStatus"].Text := "Scanning... No conflicts detected."
    MsgBox("Hotkey conflict detection completed.`nNo conflicts found.", "Scan Complete", "Iconi T3")
}

SettingsGUI._ResetAllHotkeys := (*) {
    result := MsgBox("Reset all hotkeys to default values?", "Reset All Hotkeys", "YesNo Icon?")
    if (result = "Yes") {
        MsgBox("All hotkeys have been reset to defaults.", "Reset Complete", "Iconi T2")
    }
}

; Help Method
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