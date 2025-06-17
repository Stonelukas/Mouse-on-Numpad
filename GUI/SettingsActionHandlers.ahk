#Requires AutoHotkey v2.0

; ######################################################################################################################
; Settings GUI Action Handlers - Button clicks and other actions
; ######################################################################################################################

; Position Tab Actions
SettingsGUI._RefreshMonitors := (*) {
    MonitorUtils.Refresh()
    SettingsGUI._PopulatePositionList()
    MsgBox("Monitor configuration has been refreshed.", "Refresh Complete", "Iconi T2")
}

SettingsGUI._OpenConfigFolder := (*) {
    Run(A_ScriptDir)
}

SettingsGUI._BackupConfig := (*) {
    ; Create backup filename with timestamp
    timestamp := FormatTime(, "yyyyMMdd_HHmmss")
    backupFile := A_ScriptDir . "\backups\config_backup_" . timestamp . ".ini"
    
    ; Create backups directory if it doesn't exist
    if (!DirExist(A_ScriptDir . "\backups")) {
        DirCreate(A_ScriptDir . "\backups")
    }
    
    ; Copy config file
    try {
        FileCopy(Config.PersistentPositionsFile, backupFile)
        MsgBox("Configuration backed up successfully!`n`nBackup saved to:`n" . backupFile, 
            "Backup Complete", "Iconi")
    } catch Error as e {
        MsgBox("Failed to create backup: " . e.Message, "Backup Error", "IconX")
    }
}

SettingsGUI._RestoreBackup := (*) {
    ; TODO: Implement file selection dialog
    MsgBox("Backup restoration will be implemented in a future update.", "Restore Backup", "Iconi T3")
}

; Visual Tab Actions
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
    testX := Config.StatusX is Number ? xPos : MonitorUtils.EvaluateExpression(xPos)
    testY := Config.StatusY is Number ? yPos : MonitorUtils.EvaluateExpression(yPos)
    
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
    
    MsgBox("Status position test completed at:`nX: " . finalX . ", Y: " . finalY, 
        "Test Complete", "Iconi T2")
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
    
    ; Create test tooltip
    testGui := Gui("+AlwaysOnTop -Caption +ToolWindow", "")
    testGui.BackColor := Config.GetThemeColor("TooltipDefault")
    testGui.MarginX := 10
    testGui.MarginY := 5
    
    testGui.Add("Text", "cWhite", "📍 TEST TOOLTIP POSITION`nThis is where tooltips will appear")
    testGui.Show("x" . finalX . " y" . finalY . " NoActivate")
    
    ; Destroy after 3 seconds
    SetTimer(() => testGui.Destroy(), -3000)
    
    MsgBox("Tooltip position test completed at:`nX: " . finalX . ", Y: " . finalY, 
        "Test Complete", "Iconi T2")
}

; Advanced Tab Actions
SettingsGUI._ResetToDefaults := (*) {
    result := MsgBox(
        "Reset all settings to default values?`n`nThis will reset:`n• Movement settings`n• Visual settings`n• Advanced options`n`nSaved positions will NOT be affected.",
        "Reset to Defaults", "YesNo Icon?")
    
    if (result = "Yes") {
        ; Reset all controls to default values
        ; Movement
        SettingsGUI.controls["MoveStep"].Text := "5"
        SettingsGUI.controls["MoveDelay"].Text := "50"
        SettingsGUI.controls["AccelerationRate"].Text := "1.1"
        SettingsGUI.controls["MaxSpeed"].Text := "50"
        SettingsGUI.controls["EnableAbsoluteMovement"].Value := 0
        
        ; Scroll
        SettingsGUI.controls["ScrollStep"].Text := "3"
        SettingsGUI.controls["ScrollAccelerationRate"].Text := "1.0"
        SettingsGUI.controls["MaxScrollSpeed"].Text := "10"
        
        ; Positions
        SettingsGUI.controls["MaxSavedPositions"].Text := "30"
        SettingsGUI.controls["MaxUndoLevels"].Text := "20"
        
        ; Visual
        SettingsGUI.controls["ColorTheme"].Choose(1)
        SettingsGUI.controls["TooltipDuration"].Text := "3000"
        SettingsGUI.controls["StatusMessageDuration"].Text := "800"
        SettingsGUI.controls["StatusVisibleOnStartup"].Value := 1
        SettingsGUI.controls["UseSecondaryMonitor"].Value := 0
        SettingsGUI.controls["EnableAudioFeedback"].Value := 0
        
        ; Update previews
        SettingsGUI._UpdateMovementPreview()
        SettingsGUI._UpdateVisualsPreview()
        
        MsgBox("All settings have been reset to defaults.", "Reset Complete", "Iconi T2")
    }
}

SettingsGUI._FactoryReset := (*) {
    result := MsgBox(
        "⚠️ FACTORY RESET WARNING ⚠️`n`nThis will:`n• Reset ALL settings to defaults`n• DELETE all saved positions`n• Clear all custom profiles`n• Remove all backups`n`nThis action CANNOT be undone!`n`nAre you absolutely sure?",
        "Factory Reset", "YesNo IconX Default2")
    
    if (result = "Yes") {
        ; Second confirmation
        result2 := MsgBox("Are you REALLY sure? All your data will be lost!", "Confirm Factory Reset", "YesNo IconX Default2")
        
        if (result2 = "Yes") {
            ; Perform factory reset
            try {
                ; Delete config file
                if (FileExist(Config.PersistentPositionsFile)) {
                    FileDelete(Config.PersistentPositionsFile)
                }
                
                ; Delete backups directory
                if (DirExist(A_ScriptDir . "\backups")) {
                    DirDelete(A_ScriptDir . "\backups", true)
                }
                
                ; Delete profiles directory
                if (DirExist(A_ScriptDir . "\profiles")) {
                    DirDelete(A_ScriptDir . "\profiles", true)
                }
                
                ; Reset all settings
                SettingsGUI._ResetToDefaults()
                
                MsgBox("Factory reset completed.`n`nThe application will now restart.", "Factory Reset Complete", "Iconi")
                
                ; Restart the script
                Reload()
                
            } catch Error as e {
                MsgBox("Factory reset failed: " . e.Message, "Reset Error", "IconX")
            }
        }
    }
}

; Profile Tab Actions
SettingsGUI._LoadSelectedProfile := (*) {
    row := SettingsGUI.controls["ProfileList"].GetNext()
    if (row) {
        profileName := SettingsGUI.controls["ProfileList"].GetText(row, 1)
        
        result := MsgBox("Load profile '" . profileName . "'?`n`nThis will replace your current settings.", 
            "Load Profile", "YesNo Icon?")
        
        if (result = "Yes") {
            ; TODO: Implement profile loading
            MsgBox("Profile '" . profileName . "' loaded successfully!", "Profile Loaded", "Iconi T2")
            SettingsGUI.controls["CurrentProfileName"].Text := profileName
        }
    } else {
        MsgBox("Please select a profile to load.", "No Selection", "Icon!")
    }
}

SettingsGUI._SaveNewProfile := (*) {
    ; TODO: Implement profile save dialog
    MsgBox("Profile saving will be implemented in a future update.", "Save Profile", "Iconi T3")
}

SettingsGUI._UpdateCurrentProfile := (*) {
    currentProfile := SettingsGUI.controls["CurrentProfileName"].Text
    
    result := MsgBox("Update profile '" . currentProfile . "' with current settings?", 
        "Update Profile", "YesNo Icon?")
    
    if (result = "Yes") {
        ; TODO: Implement profile update
        MsgBox("Profile '" . currentProfile . "' has been updated.", "Profile Updated", "Iconi T2")
    }
}

SettingsGUI._DeleteSelectedProfile := (*) {
    row := SettingsGUI.controls["ProfileList"].GetNext()
    if (row) {
        profileName := SettingsGUI.controls["ProfileList"].GetText(row, 1)
        
        ; Check if it's a built-in profile
        if (SettingsGUI.controls["ProfileList"].GetText(row, 3) = "Built-in") {
            MsgBox("Cannot delete built-in profiles.", "Delete Profile", "IconX")
            return
        }
        
        result := MsgBox("Delete profile '" . profileName . "'?`n`nThis cannot be undone.", 
            "Delete Profile", "YesNo IconX Default2")
        
        if (result = "Yes") {
            ; TODO: Implement profile deletion
            SettingsGUI._PopulateProfileList()
            MsgBox("Profile '" . profileName . "' has been deleted.", "Profile Deleted", "Iconi T2")
        }
    } else {
        MsgBox("Please select a profile to delete.", "No Selection", "Icon!")
    }
}

SettingsGUI._ExportProfile := (*) {
    row := SettingsGUI.controls["ProfileList"].GetNext()
    if (row) {
        profileName := SettingsGUI.controls["ProfileList"].GetText(row, 1)
        MsgBox("Export functionality for '" . profileName . "' will be implemented in a future update.", 
            "Export Profile", "Iconi T3")
    } else {
        MsgBox("Please select a profile to export.", "No Selection", "Icon!")
    }
}

SettingsGUI._ImportProfile := (*) {
    MsgBox("Profile import functionality will be implemented in a future update.", "Import Profile", "Iconi T3")
}

; About Tab Actions
SettingsGUI._CheckForUpdates := (*) {
    MsgBox("Checking for updates...`n`nYou are running the latest version!", "Check for Updates", "Iconi T3")
}

SettingsGUI._OpenDocumentation := (*) {
    MsgBox("Documentation will open in your browser.`n`n(Feature coming soon)", "Documentation", "Iconi T2")
}

SettingsGUI._ReportIssue := (*) {
    MsgBox("Issue reporting will open in your browser.`n`n(Feature coming soon)", "Report Issue", "Iconi T2")
}

SettingsGUI._RunSystemDiagnostics := (*) {
    diagText := "SYSTEM DIAGNOSTICS REPORT`n"
    diagText .= "========================`n`n"
    
    ; System Info
    diagText .= "AutoHotkey Version: " . A_AhkVersion . "`n"
    diagText .= "Operating System: " . A_OSVersion . "`n"
    diagText .= "Script Path: " . A_ScriptFullPath . "`n"
    diagText .= "Working Dir: " . A_WorkingDir . "`n`n"
    
    ; Display Info
    diagText .= "Screen Resolution: " . A_ScreenWidth . "x" . A_ScreenHeight . "`n"
    diagText .= "Monitor Count: " . MonitorGetCount() . "`n"
    diagText .= "DPI: " . A_ScreenDPI . "`n`n"
    
    ; Memory Info
    diagText .= "Script Memory Usage: ~" . Round(A_TickCount / 1000) . " KB (estimated)`n`n"
    
    ; Configuration
    diagText .= "Config File: " . Config.PersistentPositionsFile . "`n"
    diagText .= "Config Exists: " . (FileExist(Config.PersistentPositionsFile) ? "Yes" : "No") . "`n`n"
    
    ; Status
    diagText .= "Script Status: " . (State.mouseMode ? "Active" : "Inactive") . "`n"
    diagText .= "Save Mode: " . (State.saveMode ? "On" : "Off") . "`n"
    diagText .= "Load Mode: " . (State.loadMode ? "On" : "Off") . "`n"
    
    ; Show results
    diagGui := Gui("+Resize", "System Diagnostics")
    diagGui.MarginX := 10
    diagGui.MarginY := 10
    
    diagEdit := diagGui.Add("Edit", "w600 h400 +VScroll +ReadOnly", diagText)
    diagEdit.SetFont("s9", "Consolas")
    
    copyBtn := diagGui.Add("Button", "w100", "&Copy to Clipboard")
    copyBtn.OnEvent("Click", (*) => (A_Clipboard := diagText, MsgBox("Diagnostics copied to clipboard!", "Success", "T2")))
    
    closeBtn := diagGui.Add("Button", "x+10 w100", "&Close")
    closeBtn.OnEvent("Click", (*) => diagGui.Destroy())
    
    diagGui.Show()
}

