#Requires AutoHotkey v2.0

; ######################################################################################################################
; Positions Tab Module - Position memory settings (Complete)
; ######################################################################################################################

class PositionsTabModule extends BaseTabModule {
    CreateControls() {
        ; Position Slots Section
        this.gui.Add("Text", "x30 y50 w200 h20 +0x200", "Position Memory").SetFont("s10 Bold")

        this.gui.Add("Text", "x30 y75 w150", "Maximum Saved Positions:")
        this.AddControl("MaxSavedPositions", this.gui.Add("Edit", "x180 y72 w60 Number"))
        this.controls["MaxSavedPositions"].Text := this.tempSettings["MaxSavedPositions"]
        
        this.AddControl("MaxSavedPositionsUpDown", this.gui.Add("UpDown", "x240 y72 w20 h20 Range1-100",
            this.tempSettings["MaxSavedPositions"]))
        this.gui.Add("Text", "x265 y75 w300", "position slots (1-100)")

        this.gui.Add("Text", "x30 y100 w150", "Maximum Undo Levels:")
        this.AddControl("MaxUndoLevels", this.gui.Add("Edit", "x180 y97 w60 Number"))
        this.controls["MaxUndoLevels"].Text := this.tempSettings["MaxUndoLevels"]
        
        this.AddControl("MaxUndoLevelsUpDown", this.gui.Add("UpDown", "x240 y97 w20 h20 Range1-50",
            this.tempSettings["MaxUndoLevels"]))
        this.gui.Add("Text", "x265 y100 w300", "undo steps (1-50)")

        ; Current Positions Section
        this.gui.Add("Text", "x30 y140 w200 h20 +0x200", "Saved Positions").SetFont("s10 Bold")

        ; Position List - REDUCED HEIGHT to make room for buttons
        this.AddControl("PositionList", this.gui.Add("ListView", "x30 y165 w500 h150", 
            ["Slot", "X", "Y", "Description"]))
        this.controls["PositionList"].ModifyCol(1, 50)
        this.controls["PositionList"].ModifyCol(2, 80)
        this.controls["PositionList"].ModifyCol(3, 80)
        this.controls["PositionList"].ModifyCol(4, 280)

        ; Add double-click event to go to position
        this.controls["PositionList"].OnEvent("DoubleClick", (*) => this._GotoSelectedPosition())

        ; Position Management Buttons
        this.AddControl("GotoPosition", this.gui.Add("Button", "x550 y165 w120 h25", "Go to Position"))
        this.controls["GotoPosition"].OnEvent("Click", (*) => this._GotoSelectedPosition())

        this.AddControl("PreviewPosition", this.gui.Add("Button", "x550 y195 w120 h25", "Preview"))
        this.controls["PreviewPosition"].OnEvent("Click", (*) => this._PreviewSelectedPosition())
        this.controls["PreviewPosition"].ToolTip := "Preview the selected position with a visual indicator"

        this.AddControl("SaveCurrentPos", this.gui.Add("Button", "x550 y225 w120 h25", "Save Mouse Pos"))
        this.controls["SaveCurrentPos"].OnEvent("Click", (*) => this._SaveCurrentPosition())
        this.controls["SaveCurrentPos"].ToolTip := "Save current mouse cursor position to a slot"

        this.AddControl("DeletePosition", this.gui.Add("Button", "x550 y255 w120 h25", "Delete Position"))
        this.controls["DeletePosition"].OnEvent("Click", (*) => this._DeleteSelectedPosition())

        this.AddControl("ClearAllPositions", this.gui.Add("Button", "x550 y285 w120 h25", "Clear All"))
        this.controls["ClearAllPositions"].OnEvent("Click", (*) => this._ClearAllPositions())

        ; Import/Export buttons moved to new row
        this.AddControl("ImportPositions", this.gui.Add("Button", "x30 y325 w120 h25", "Import..."))
        this.controls["ImportPositions"].OnEvent("Click", (*) => this._ImportPositions())

        this.AddControl("ExportPositions", this.gui.Add("Button", "x160 y325 w120 h25", "Export..."))
        this.controls["ExportPositions"].OnEvent("Click", (*) => this._ExportPositions())

        ; Monitor test buttons - NOW VISIBLE
        this.AddControl("TestMonitors", this.gui.Add("Button", "x290 y325 w120 h25", "Test Monitors"))
        this.controls["TestMonitors"].OnEvent("Click", (*) => this._TestMonitorConfiguration())
        this.controls["TestMonitors"].ToolTip := "Show monitor configuration and boundaries"

        this.AddControl("RefreshMonitors", this.gui.Add("Button", "x420 y325 w120 h25", "Refresh Monitors"))
        this.controls["RefreshMonitors"].OnEvent("Click", (*) => this._RefreshMonitors())
        this.controls["RefreshMonitors"].ToolTip := "Refresh monitor configuration and update position descriptions"

        ; Position File Management
        this.gui.Add("Text", "x30 y365 w200 h20 +0x200", "Position File Management").SetFont("s10 Bold")

        this.gui.Add("Text", "x30 y390 w100", "Config File:")
        this.AddControl("ConfigFile", this.gui.Add("Edit", "x130 y387 w270 ReadOnly"))
        this.controls["ConfigFile"].Text := Config.PersistentPositionsFile

        this.AddControl("OpenConfigFolder", this.gui.Add("Button", "x410 y385 w75 h25", "Open Folder"))
        this.controls["OpenConfigFolder"].OnEvent("Click", (*) => this._OpenConfigFolder())

        this.AddControl("BackupConfig", this.gui.Add("Button", "x495 y385 w75 h25", "Backup"))
        this.controls["BackupConfig"].OnEvent("Click", (*) => this._BackupConfig())

        this.AddControl("RestoreBtn", this.gui.Add("Button", "x580 y385 w90 h25", "Restore..."))
        this.controls["RestoreBtn"].OnEvent("Click", (*) => this._RestoreBackup())

        ; Populate position list
        this._PopulatePositionList()
    }

    _ExportPositions() {
        ; Check if there are positions to export
        savedPositions := PositionMemory.GetSavedPositions()
        if (savedPositions.Count = 0) {
            MsgBox("No saved positions to export.", "Nothing to Export", "Icon!")
            return
        }

        ; File dialog to select export location
        timestamp := FormatTime(A_Now, "yyyyMMdd_HHmmss")
        defaultName := "MousePositions_" . timestamp . ".ini"
        selectedFile := FileSelect("S", defaultName, "Export Positions", "Position Files (*.ini)")

        if (selectedFile = "") {
            return  ; User cancelled
        }

        ; Add .ini extension if not present
        if (!RegExMatch(selectedFile, "i)\.ini$")) {
            selectedFile .= ".ini"
        }

        try {
            ; Create export file with header
            FileAppend("; Mouse on Numpad Enhanced - Exported Positions`n", selectedFile)
            FileAppend("; Exported on: " . FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") . "`n", selectedFile)
            FileAppend("; Total positions: " . savedPositions.Count . "`n`n", selectedFile)
            FileAppend("[Positions]`n", selectedFile)

            ; Write each position
            exportedCount := 0
            for slot, pos in savedPositions {
                FileAppend("Slot" . slot . "X=" . pos.x . "`n", selectedFile)
                FileAppend("Slot" . slot . "Y=" . pos.y . "`n", selectedFile)
                exportedCount++
            }

            ; Add metadata
            FileAppend("`n[Metadata]`n", selectedFile)
            FileAppend("ExportVersion=1.0`n", selectedFile)
            FileAppend("MaxSlots=" . Config.Get("Positions.MaxSaved") . "`n", selectedFile)
            FileAppend("PositionCount=" . exportedCount . "`n", selectedFile)

            MsgBox("Successfully exported " . exportedCount . " position(s) to:`n`n" . selectedFile, 
                "Export Complete", "Iconi")

            ; Ask if user wants to open the folder
            result := MsgBox("Would you like to open the folder containing the exported file?", 
                "Open Folder?", "YesNo Icon?")
            if (result = "Yes") {
                Run('explorer.exe /select,"' . selectedFile . '"')
            }

        } catch Error as e {
            MsgBox("Error exporting positions: " . e.Message, "Export Error", "IconX")
        }
    }

    _OpenConfigFolder() {
        Run("explorer.exe " . A_ScriptDir)
    }

    _BackupConfig() {
        ; Create backup with timestamp
        timestamp := FormatTime(A_Now, "yyyyMMdd_HHmmss")
        backupFile := "MouseNumpadConfig_Backup_" . timestamp . ".ini"

        try {
            ; Copy the current config file
            FileCopy(Config.PersistentPositionsFile, backupFile)

            ; Get file size for info
            fileSize := FileGetSize(backupFile)
            fileSizeKB := Round(fileSize / 1024, 2)

            ; Count saved positions
            savedCount := PositionMemory.GetSavedPositions().Count

            ; Show detailed success message
            MsgBox("Configuration backed up successfully!`n`n" .
                "Backup file: " . backupFile . "`n" .
                "File size: " . fileSizeKB . " KB`n" .
                "Saved positions: " . savedCount . "`n`n" .
                "Location: " . A_ScriptDir,
                "Backup Successful", "Iconi")

            ; Ask if user wants to open the backup location
            result := MsgBox("Would you like to open the backup folder?", "Open Folder?", "YesNo Icon?")
            if (result = "Yes") {
                Run('explorer.exe /select,"' . A_ScriptDir . "\" . backupFile . '"')
            }

        } catch Error as e {
            MsgBox("Failed to create backup: " . e.Message, "Backup Error", "IconX")
        }
    }

    _RestoreBackup() {
        ; File dialog to select backup file
        selectedFile := FileSelect(1, , "Select Backup File", "INI Files (*.ini)")
        if (selectedFile = "") {
            return  ; User cancelled
        }

        ; Confirm restoration
        result := MsgBox("Restore configuration from:`n" . selectedFile .
            "`n`nThis will replace your current configuration!",
            "Confirm Restore", "YesNo IconX")
        if (result != "Yes") {
            return
        }

        try {
            ; Backup current config first
            tempBackup := Config.PersistentPositionsFile . ".temp"
            FileCopy(Config.PersistentPositionsFile, tempBackup, 1)

            ; Copy backup file to config location
            FileCopy(selectedFile, Config.PersistentPositionsFile, 1)

            ; Reload configuration
            Config.Load()
            PositionMemory.LoadPositions()

            ; Update GUI to reflect new settings
            SettingsGUI._InitializeTempSettings()
            this.Refresh()

            ; Delete temp backup
            FileDelete(tempBackup)

            MsgBox("Configuration restored successfully!`n`nThe settings have been updated.", 
                "Restore Complete", "Iconi")

        } catch Error as e {
            ; Try to restore from temp backup on error
            try {
                FileCopy(tempBackup, Config.PersistentPositionsFile, 1)
                FileDelete(tempBackup)
            }
            MsgBox("Failed to restore backup: " . e.Message, "Restore Error", "IconX")
        }
    }

    _TestMonitorConfiguration() {
        ; Refresh monitor information
        MonitorUtils.Refresh()

        ; Get debug info from MonitorUtils
        monitorInfo := MonitorUtils.ShowMonitorDebugInfo()

        ; Show visual indicators on each monitor
        for monitor in MonitorUtils.monitors {
            ; Create a temporary GUI to show monitor bounds
            tempGui := Gui("+AlwaysOnTop -Caption +ToolWindow", "")
            tempGui.BackColor := monitor.IsPrimary ? "0x00FF00" : "0x0000FF"  ; Green for primary, blue for secondary
            tempGui.SetFont("s14 Bold", "Arial")
            label := "Monitor " . monitor.Index
            if (monitor.IsPrimary) {
                label .= " (PRIMARY)"
            }
            label .= "`n" . monitor.Width . " x " . monitor.Height
            label .= "`nLeft: " . monitor.Left . " Top: " . monitor.Top
            tempGui.Add("Text", "x10 y10 cWhite", label)

            ; Show in center of monitor
            centerX := monitor.Left + (monitor.Width // 2) - 150
            centerY := monitor.Top + (monitor.Height // 2) - 40
            tempGui.Show("x" . centerX . " y" . centerY . " w300 h80 NoActivate")

            ; Auto-destroy after 5 seconds
            SetTimer(() => tempGui.Destroy(), -5000)
        }

        MsgBox(monitorInfo, "Monitor Configuration", "Iconi")
    }

    _RefreshMonitors() {
        ; Refresh monitor configuration
        MonitorUtils.Refresh()

        ; Update position list with new monitor information
        this._PopulatePositionList()

        ; Show confirmation
        MsgBox("Monitor configuration refreshed!`n`nPosition descriptions have been updated.", 
            "Monitors Refreshed", "Iconi T2")
    }


    _ImportPositions() {
        ; File dialog to select import file
        selectedFile := FileSelect(1, , "Import Positions", "Position Files (*.ini;*.txt)")
        if (selectedFile = "") {
            return  ; User cancelled
        }

        try {
            importedCount := 0

            ; Read positions from the selected file
            loop Config.Get("Positions.MaxSaved") {
                x := IniRead(selectedFile, "Positions", "Slot" . A_Index . "X", "")
                y := IniRead(selectedFile, "Positions", "Slot" . A_Index . "Y", "")

                if (x != "" && y != "" && IsNumber(x) && IsNumber(y)) {
                    ; Ask if user wants to overwrite existing positions
                    if (importedCount = 0 && PositionMemory.GetSavedPositions().Count > 0) {
                        result := MsgBox("Do you want to:`n`nYes - Replace all existing positions`n" .
                            "No - Merge with existing positions (skip conflicts)`nCancel - Cancel import",
                            "Import Options", "YesNoCancel Icon?")
                        if (result = "Cancel") {
                            return
                        }
                        if (result = "Yes") {
                            PositionMemory.ClearAllPositions()
                        }
                    }

                    ; Import the position if slot is empty or we're replacing all
                    if (!PositionMemory.HasPosition(A_Index) || importedCount = 0) {
                        ; Save the position at the specific slot
                        ; We need to temporarily move the mouse to save it, then restore
                        ; CRITICAL: Set coordinate mode to Screen for proper negative coordinate handling
                        CoordMode("Mouse", "Screen")
                        MouseGetPos(&originalX, &originalY)

                        ; Disable audio feedback temporarily during import
                        originalAudioSetting := Config.Get("Visual.EnableAudioFeedback")
                        Config.set("Visual.EnableAudioFeedback", false)

                        MouseMove(Integer(x), Integer(y), 0)
                        PositionMemory.SavePosition(A_Index)
                        MouseMove(originalX, originalY, 0)

                        ; Restore audio setting
                        Config.set("Visual.EnableAudioFeedback", originalAudioSetting)

                        importedCount++
                    }
                }
            }

            if (importedCount > 0) {
                PositionMemory.SavePositions()  ; Persist to file
                this._PopulatePositionList()
                MsgBox("Successfully imported " . importedCount . " position(s).", "Import Complete", "Iconi")
            } else {
                MsgBox("No valid positions found in the selected file.", "Import Failed", "IconX")
            }

        } catch Error as e {
            MsgBox("Error importing positions: " . e.Message, "Import Error", "IconX")
        }
    }

    _DeleteSelectedPosition() {
        row := this.controls["PositionList"].GetNext()
        if (row) {
            slot := Integer(this.controls["PositionList"].GetText(row, 1))
            x := this.controls["PositionList"].GetText(row, 2)
            y := this.controls["PositionList"].GetText(row, 3)

            result := MsgBox("Delete position " . slot . " (" . x . ", " . y . ")?`n`nThis cannot be undone.",
                "Confirm Delete", "YesNo IconX")
            if (result = "Yes") {
                ; Delete the position
                PositionMemory.ClearPosition(slot)
                PositionMemory.SavePositions()  ; Persist changes to file

                ; Refresh the list
                this._PopulatePositionList()

                ; Show confirmation
                MsgBox("Position " . slot . " has been deleted.", "Position Deleted", "Iconi T2")
            }
        } else {
            MsgBox("Please select a position to delete from the list.", "No Selection", "Icon!")
        }
    }

    _ClearAllPositions() {
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
                this._PopulatePositionList()
                MsgBox("All positions have been cleared.", "Positions Cleared", "Iconi T2")
            }
        }
    }

    _SaveCurrentPosition() {
        ; Create a custom dialog that updates mouse position in real-time
        saveDialog := Gui("+AlwaysOnTop", "Save Mouse Position")
        saveDialog.SetFont("s10")

        ; Instructions
        saveDialog.Add("Text", "x10 y10 w300", "Move your mouse to the desired position.")

        ; Current position display (will update)
        posText := saveDialog.Add("Text", "x10 y35 w300 h20", "Current mouse position: ")
        posDisplay := saveDialog.Add("Text", "x10 y55 w300 h20 +0x200", "X: 0, Y: 0")
        posDisplay.SetFont("s12 Bold")

        ; Slot selection
        saveDialog.Add("Text", "x10 y85 w100", "Save to slot:")
        slotEdit := saveDialog.Add("Edit", "x110 y82 w50 Number")
        slotUpDown := saveDialog.Add("UpDown", "x160 y82 w20 h20 Range1-" . Config.Get("Positions.MaxSaved"), 1)
        saveDialog.Add("Text", "x185 y85 w100", "(1-" . Config.Get("Positions.MaxSaved") . ")")

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

        ; Button event handlers using nested functions to avoid arrow function parsing issues
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
            if (slot >= 1 && slot <= Config.Get("Positions.MaxSaved")) {
                ; Check if slot already has a position
                if (PositionMemory.HasPosition(slot)) {
                    result := MsgBox("Slot " . slot . " already has a saved position. Overwrite?", 
                        "Confirm Overwrite", "YesNo Icon?")
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
                this._PopulatePositionList()

                ; Show success with the saved position
                MsgBox("Mouse position (" . savedX . ", " . savedY . ") saved to slot " . slot, 
                    "Success", "Iconi T3")
            } else {
                MsgBox("Invalid slot number. Please enter a number between 1 and " . Config.Get("Positions.MaxSaved"), 
                    "Error", "IconX")
            }
        }
    }

    _PreviewSelectedPosition() {
        row := this.controls["PositionList"].GetNext()
        if (row) {
            slot := Integer(this.controls["PositionList"].GetText(row, 1))
            x := Integer(this.controls["PositionList"].GetText(row, 2))
            y := Integer(this.controls["PositionList"].GetText(row, 3))

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

    GetData() {
        return Map(
            "maxSavedPositions", Integer(this.controls["MaxSavedPositions"].Text),
            "maxUndoLevels", Integer(this.controls["MaxUndoLevels"].Text)
        )
    }

    Validate() {
        try {
            maxPositions := Integer(this.controls["MaxSavedPositions"].Text)
            if (maxPositions < 1 || maxPositions > 100) {
                MsgBox("Maximum Saved Positions must be between 1 and 100", "Validation Error", "IconX")
                return false
            }

            maxUndo := Integer(this.controls["MaxUndoLevels"].Text)
            if (maxUndo < 1 || maxUndo > 50) {
                MsgBox("Maximum Undo Levels must be between 1 and 50", "Validation Error", "IconX")
                return false
            }

            return true
        } catch {
            MsgBox("Please enter valid numeric values", "Validation Error", "IconX")
            return false
        }
    }

    Refresh() {
        ; Refresh monitor configuration when showing positions tab
        MonitorUtils.Refresh()
        this._PopulatePositionList()
    }

    _PopulatePositionList() {
        try {
            this.controls["PositionList"].Delete()

            savedPositions := PositionMemory.GetSavedPositions()

            ; Ensure monitors are initialized
            if (!MonitorUtils.initialized) {
                MonitorUtils.Init()
            }

            for slot, pos in savedPositions {
                ; Get monitor description for this position
                description := "Position on " . MonitorUtils.GetMonitorDescriptionForPosition(pos.x, pos.y)
                this.controls["PositionList"].Add(, slot, pos.x, pos.y, description)
            }
        }
    }

    _GotoSelectedPosition() {
        row := this.controls["PositionList"].GetNext()
        if (row) {
            slot := Integer(this.controls["PositionList"].GetText(row, 1))
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
}
