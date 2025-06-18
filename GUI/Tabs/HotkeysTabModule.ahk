#Requires AutoHotkey v2.0

; ######################################################################################################################
; Hotkeys Tab Module - Fixed Implementation
; ######################################################################################################################

class HotkeysTabModule extends BaseTabModule {
    CreateControls() {
        ; Create ListView
        this.AddControl("HotkeyList", this.gui.Add("ListView", "x20 y50 w650 h330 -Multi", 
            ["Action", "Current", "Default"]))
        
        ; Configure columns
        this.controls["HotkeyList"].ModifyCol(1, 250)
        this.controls["HotkeyList"].ModifyCol(2, 150)
        this.controls["HotkeyList"].ModifyCol(3, 150)
        
        ; Populate hotkey list
        this._PopulateHotkeyList()
        
        ; Buttons
        this.AddControl("EditHotkey", this.gui.Add("Button", "x690 y75 w80 h25", "Edit"))
        this.controls["EditHotkey"].OnEvent("Click", (*) => this._EditSelectedHotkey())
        
        this.AddControl("ResetHotkey", this.gui.Add("Button", "x690 y105 w80 h25", "Reset"))
        this.controls["ResetHotkey"].OnEvent("Click", (*) => this._ResetSelectedHotkey())
        
        this.AddControl("TestHotkey", this.gui.Add("Button", "x690 y135 w80 h25", "Test"))
        this.controls["TestHotkey"].OnEvent("Click", (*) => this._TestSelectedHotkey())
        
        ; Conflict Detection
        this.gui.Add("Text", "x30 y390 w200 h20 +0x200", "Conflict Detection").SetFont("s10 Bold")
        
        this.AddControl("ConflictStatus", this.gui.Add("Text", "x30 y415 w450 h20"))
        this.controls["ConflictStatus"].Text := "No conflicts detected"
        
        this.AddControl("ScanConflicts", this.gui.Add("Button", "x500 y412 w120 h25", "Scan for Conflicts"))
        this.controls["ScanConflicts"].OnEvent("Click", (*) => this._ScanForConflicts())
        
        this.AddControl("ResetAllHotkeys", this.gui.Add("Button", "x630 y412 w120 h25", "Reset All"))
        this.controls["ResetAllHotkeys"].OnEvent("Click", (*) => this._ResetAllHotkeys())
    }
    
    _PopulateHotkeyList() {
        this.controls["HotkeyList"].Delete()
        
        ; Get hotkeys from HotkeyManager
        hotkeyList := HotkeyManager.GetHotkeyList()
        
        for hotkeyInfo in hotkeyList {
            ; Get current key from config
            currentKey := Config.Get("Hotkeys." . hotkeyInfo.configKey, hotkeyInfo.default)
            this.controls["HotkeyList"].Add(, hotkeyInfo.description, currentKey, hotkeyInfo.default)
        }
    }
    
    _EditSelectedHotkey() {
        row := this.controls["HotkeyList"].GetNext()
        if (!row) {
            MsgBox("Please select a hotkey to edit.", "No Selection", "Icon!")
            return
        }
        
        ; Get current hotkey info
        action := this.controls["HotkeyList"].GetText(row, 1)
        currentKey := this.controls["HotkeyList"].GetText(row, 2)
        defaultKey := this.controls["HotkeyList"].GetText(row, 3)
        
        ; Create edit dialog
        this.editDialog := Gui("+Owner" . this.gui.Hwnd . " -MaximizeBox -MinimizeBox", "Edit Hotkey")
        this.editDialog.OnEvent("Close", (*) => this._CancelEdit())
        
        ; Add controls
        this.editDialog.SetFont("s10")
        this.editDialog.Add("Text", "x10 y10 w350", "Action: " . action).SetFont("Bold")
        this.editDialog.Add("Text", "x10 y35 w350", "Current: " . this._FormatHotkeyDisplay(currentKey))
        this.editDialog.Add("Text", "x10 y55 w350", "Default: " . this._FormatHotkeyDisplay(defaultKey))
        
        this.editDialog.Add("Text", "x10 y85 w350", "New hotkey:")
        
        ; Use standard Hotkey control for now
        this.editHotkey := this.editDialog.Add("Hotkey", "x10 y105 w200 vNewHotkey")
        if (currentKey != "None" && currentKey != "") {
            try {
                this.editHotkey.Value := currentKey
            }
        }
        
        ; Buttons
        saveBtn := this.editDialog.Add("Button", "x10 y140 w80", "&OK")
        saveBtn.OnEvent("Click", (*) => this._SaveEdit(row))
        
        cancelBtn := this.editDialog.Add("Button", "x100 y140 w80", "&Cancel")
        cancelBtn.OnEvent("Click", (*) => this._CancelEdit())
        
        clearBtn := this.editDialog.Add("Button", "x190 y140 w80", "C&lear")
        clearBtn.OnEvent("Click", (*) => this._ClearHotkey())
        
        defaultBtn := this.editDialog.Add("Button", "x280 y140 w80", "&Default")
        defaultBtn.OnEvent("Click", (*) => this._SetDefault(defaultKey))
        
        ; Show dialog
        this.editDialog.Show("w370 h180")
    }
    
    _FormatHotkeyDisplay(hotkey) {
        display := hotkey
        display := StrReplace(display, "^", "Ctrl+")
        display := StrReplace(display, "!", "Alt+")
        display := StrReplace(display, "+", "Shift+")
        display := StrReplace(display, "#", "Win+")
        return display
    }
    
    _SaveEdit(row) {
        ; Get the new hotkey value
        newHotkey := this.editHotkey.Value
        
        if (newHotkey = "") {
            newHotkey := "None"
        }
        
        ; Check for conflicts
        conflict := this._CheckHotkeyConflict(newHotkey, row)
        if (conflict) {
            MsgBox("This hotkey is already assigned to: " . conflict . "`n`nPlease choose a different hotkey.", 
                "Hotkey Conflict", "IconX")
            return
        }
        
        ; Get the config key for this hotkey
        hotkeyList := HotkeyManager.GetHotkeyList()
        configKey := ""
        action := this.controls["HotkeyList"].GetText(row, 1)
        
        for hotkeyInfo in hotkeyList {
            if (hotkeyInfo.description = action) {
                configKey := hotkeyInfo.configKey
                break
            }
        }
        
        if (configKey = "") {
            MsgBox("Unable to find configuration key for this hotkey.", "Error", "IconX")
            return
        }
        
        ; Update the ListView
        this.controls["HotkeyList"].Modify(row, "Col2", newHotkey)
        
        ; Save to config
        Config.Set("Hotkeys." . configKey, newHotkey)
        Config.Save()
        
        ; Update the hotkey binding
        HotkeyManager.UpdateHotkey(configKey, newHotkey)
        
        ; Close dialog
        this.editDialog.Destroy()
        
        ; Show success message
        MsgBox("Hotkey updated successfully!", "Success", "Iconi T2")
    }
    
    _CancelEdit() {
        if (IsObject(this.editDialog)) {
            this.editDialog.Destroy()
        }
    }
    
    _ClearHotkey() {
        this.editHotkey.Value := ""
    }
    
    _SetDefault(defaultKey) {
        if (defaultKey != "None" && defaultKey != "") {
            try {
                this.editHotkey.Value := defaultKey
            } catch {
                ; Some keys might not be settable directly
                MsgBox("Unable to set this default key directly. Please type it manually.", "Info", "Iconi")
            }
        }
    }
    
    _CheckHotkeyConflict(newHotkey, currentRow) {
        if (newHotkey = "None" || newHotkey = "") {
            return ""
        }
        
        totalRows := this.controls["HotkeyList"].GetCount()
        Loop totalRows {
            if (A_Index = currentRow) {
                continue
            }
            
            existingHotkey := this.controls["HotkeyList"].GetText(A_Index, 2)
            if (existingHotkey = newHotkey) {
                return this.controls["HotkeyList"].GetText(A_Index, 1)
            }
        }
        
        return ""
    }
    
    _ResetSelectedHotkey() {
        row := this.controls["HotkeyList"].GetNext()
        if (!row) {
            MsgBox("Please select a hotkey to reset.", "No Selection", "Icon!")
            return
        }
        
        action := this.controls["HotkeyList"].GetText(row, 1)
        currentKey := this.controls["HotkeyList"].GetText(row, 2)
        defaultKey := this.controls["HotkeyList"].GetText(row, 3)
        
        if (currentKey = defaultKey) {
            MsgBox("This hotkey is already set to its default value.", "Already Default", "Iconi")
            return
        }
        
        result := MsgBox("Reset '" . action . "' to its default hotkey '" . defaultKey . "'?", 
            "Reset Hotkey", "YesNo Icon?")
            
        if (result = "Yes") {
            ; Find config key
            hotkeyList := HotkeyManager.GetHotkeyList()
            configKey := ""
            
            for hotkeyInfo in hotkeyList {
                if (hotkeyInfo.description = action) {
                    configKey := hotkeyInfo.configKey
                    break
                }
            }
            
            if (configKey != "") {
                ; Update ListView
                this.controls["HotkeyList"].Modify(row, "Col2", defaultKey)
                
                ; Save to config
                Config.Set("Hotkeys." . configKey, defaultKey)
                Config.Save()
                
                ; Update hotkey binding
                HotkeyManager.UpdateHotkey(configKey, defaultKey)
                
                MsgBox("Hotkey reset to default!", "Success", "Iconi T2")
            }
        }
    }
    
    _TestSelectedHotkey() {
        row := this.controls["HotkeyList"].GetNext()
        if (!row) {
            MsgBox("Please select a hotkey to test.", "No Selection", "Icon!")
            return
        }
        
        action := this.controls["HotkeyList"].GetText(row, 1)
        hotkey := this.controls["HotkeyList"].GetText(row, 2)
        
        if (hotkey = "None" || hotkey = "") {
            MsgBox("This action has no hotkey assigned.", "No Hotkey", "Iconi")
            return
        }
        
        ; Create test window
        testGui := Gui("+AlwaysOnTop +Owner" . this.gui.Hwnd, "Test Hotkey")
        testGui.SetFont("s10")
        testGui.Add("Text", "x10 y10 w300", "Testing: " . action)
        testGui.Add("Text", "x10 y35 w300 h20 +0x200", "Press: " . this._FormatHotkeyDisplay(hotkey))
        testGui.SetFont("s8")
        testGui.Add("Text", "x10 y60 w300", "The action will be triggered when you press the hotkey.")
        testGui.Add("Text", "x10 y80 w300", "This window will close automatically in 10 seconds.")
        
        closeBtn := testGui.Add("Button", "x120 y110 w80 h25", "Close")
        closeBtn.OnEvent("Click", (*) => testGui.Destroy())
        
        testGui.Show()
        
        ; Auto-close after 10 seconds
        SetTimer(() => (WinExist("Test Hotkey") ? testGui.Destroy() : ""), -10000)
    }
    
    _ScanForConflicts() {
        ; Update status
        this.controls["ConflictStatus"].Text := "Scanning for conflicts..."
        
        ; Check for conflicts
        conflicts := []
        hotkeyMap := Map()
        
        totalRows := this.controls["HotkeyList"].GetCount()
        Loop totalRows {
            action := this.controls["HotkeyList"].GetText(A_Index, 1)
            hotkey := this.controls["HotkeyList"].GetText(A_Index, 2)
            
            if (hotkey != "None" && hotkey != "") {
                if (hotkeyMap.Has(hotkey)) {
                    conflicts.Push(hotkey . " is used by both '" . hotkeyMap[hotkey] . "' and '" . action . "'")
                } else {
                    hotkeyMap[hotkey] := action
                }
            }
        }
        
        ; Show results
        if (conflicts.Length > 0) {
            this.controls["ConflictStatus"].Text := conflicts.Length . " conflict(s) found!"
            
            msg := "The following conflicts were found:`n`n"
            for conflict in conflicts {
                msg .= "• " . conflict . "`n"
            }
            
            MsgBox(msg, "Hotkey Conflicts", "IconX")
        } else {
            this.controls["ConflictStatus"].Text := "No conflicts detected. All hotkeys are unique."
            MsgBox("All hotkeys are unique. No conflicts found!", "Scan Complete", "Iconi T3")
        }
    }
    
    _ResetAllHotkeys() {
        result := MsgBox("Are you sure you want to reset ALL hotkeys to their default values?`n`nThis action cannot be undone.", 
            "Reset All Hotkeys", "YesNo IconX Default2")
            
        if (result = "Yes") {
            confirm := MsgBox("This will reset all hotkey customizations. Continue?", 
                "Confirm Reset", "YesNo IconX Default2")
                
            if (confirm = "Yes") {
                ; Reset all hotkeys
                hotkeyList := HotkeyManager.GetHotkeyList()
                
                for hotkeyInfo in hotkeyList {
                    Config.Set("Hotkeys." . hotkeyInfo.configKey, hotkeyInfo.default)
                }
                
                ; Save config
                Config.Save()
                
                ; Re-register all hotkeys
                HotkeyManager.RegisterHotkeys()
                
                ; Refresh the list
                this._PopulateHotkeyList()
                
                MsgBox("All hotkeys have been reset to their default values!", "Reset Complete", "Iconi T2")
            }
        }
    }
    
    GetData() {
        ; Return current hotkey configuration
        data := Map()
        
        hotkeyList := HotkeyManager.GetHotkeyList()
        totalRows := this.controls["HotkeyList"].GetCount()
        
        Loop totalRows {
            action := this.controls["HotkeyList"].GetText(A_Index, 1)
            current := this.controls["HotkeyList"].GetText(A_Index, 2)
            
            ; Find the config key for this action
            for hotkeyInfo in hotkeyList {
                if (hotkeyInfo.description = action) {
                    data[hotkeyInfo.configKey] := current
                    break
                }
            }
        }
        
        return data
    }
    
    Validate() {
        ; Check for conflicts
        hotkeyMap := Map()
        totalRows := this.controls["HotkeyList"].GetCount()
        
        Loop totalRows {
            hotkey := this.controls["HotkeyList"].GetText(A_Index, 2)
            action := this.controls["HotkeyList"].GetText(A_Index, 1)
            
            if (hotkey != "None" && hotkey != "") {
                if (hotkeyMap.Has(hotkey)) {
                    MsgBox("Hotkey conflict detected!`n`n'" . hotkey . "' is assigned to both:`n- " 
                        . hotkeyMap[hotkey] . "`n- " . action . "`n`nPlease resolve before saving.", 
                        "Validation Error", "IconX")
                    return false
                }
                hotkeyMap[hotkey] := action
            }
        }
        
        return true
    }
    
    Refresh() {
        this._PopulateHotkeyList()
    }
}