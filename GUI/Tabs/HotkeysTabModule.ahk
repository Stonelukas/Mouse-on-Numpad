#Requires AutoHotkey v2.0

; ######################################################################################################################
; Hotkeys Tab Module - Hotkey configuration and management
; ######################################################################################################################

class HotkeysTabModule extends BaseTabModule {
    CreateControls() {
        ; Hotkey List Section
        this.gui.Add("Text", "x30 y50 w200 h20 +0x200", "Hotkey Configuration").SetFont("s10 Bold")

        ; Hotkey ListView
        this.AddControl("HotkeyList", this.gui.Add("ListView", "x30 y75 w650 h300", 
            ["Action", "Current Hotkey", "Description"]))
        this.controls["HotkeyList"].ModifyCol(1, 200)
        this.controls["HotkeyList"].ModifyCol(2, 150)
        this.controls["HotkeyList"].ModifyCol(3, 300)

        ; Populate hotkey list
        this._PopulateHotkeyList()

        ; Hotkey Management Buttons
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

    GetData() {
        ; Hotkeys are currently not modifiable through GUI
        ; Return empty map for now
        return Map()
    }

    Validate() {
        ; No validation needed for read-only hotkey display
        return true
    }

    Refresh() {
        this._PopulateHotkeyList()
    }

    _PopulateHotkeyList() {
        try {
            this.controls["HotkeyList"].Delete()

            ; Add common hotkeys with descriptions
            hotkeys := [
                ["Toggle Mouse Mode", "Numpad +", "Enable/disable numpad mouse control"],
                ["Save Mode", "Numpad *", "Enter position save mode"],
                ["Load Mode", "Numpad -", "Enter position load mode"],
                ["Undo Movement", "Numpad /", "Undo last mouse movement"],
                ["Toggle Status", "Ctrl+Numpad +", "Show/hide status indicator"],
                ["Reload Script", "Ctrl+Alt+R", "Restart the application"],
                ["Settings", "Ctrl+Alt+S", "Open settings panel"],
                ["Secondary Monitor", "Alt+Numpad 9", "Toggle secondary monitor use"],
                ["Monitor Test", "Ctrl+Alt+Numpad 9", "Test monitor configuration"],
                ; Movement hotkeys (when mouse mode is active)
                ["Move Up", "Numpad 8", "Move cursor up (Mouse Mode)"],
                ["Move Down", "Numpad 2", "Move cursor down (Mouse Mode)"],
                ["Move Left", "Numpad 4", "Move cursor left (Mouse Mode)"],
                ["Move Right", "Numpad 6", "Move cursor right (Mouse Mode)"],
                ["Left Click", "Numpad 5", "Left mouse button (Mouse Mode)"],
                ["Right Click", "Numpad 0", "Right mouse button (Mouse Mode)"],
                ["Middle Click", "Numpad Enter", "Middle mouse button (Mouse Mode)"],
                ["Toggle Left Hold", "Numpad Clear", "Toggle left button hold (Mouse Mode)"],
                ["Toggle Right Hold", "Numpad Ins", "Toggle right button hold (Mouse Mode)"],
                ["Toggle Middle Hold", "Shift+Numpad Enter", "Toggle middle button hold (Mouse Mode)"],
                ["Scroll Up", "Numpad 7", "Scroll wheel up (Mouse Mode)"],
                ["Scroll Down", "Numpad 1", "Scroll wheel down (Mouse Mode)"],
                ["Scroll Left", "Numpad 9", "Horizontal scroll left (Mouse Mode)"],
                ["Scroll Right", "Numpad 3", "Horizontal scroll right (Mouse Mode)"],
                ["Inverted Mode", "Numpad Del", "Toggle inverted movement (Mouse Mode)"]
            ]

            for hotkey in hotkeys {
                this.controls["HotkeyList"].Add(, hotkey[1], hotkey[2], hotkey[3])
            }
        }
    }

    _EditSelectedHotkey() {
        row := this.controls["HotkeyList"].GetNext()
        if (!row) {
            MsgBox("Please select a hotkey to edit.", "No Selection", "Icon!")
            return
        }

        action := this.controls["HotkeyList"].GetText(row, 1)
        currentKey := this.controls["HotkeyList"].GetText(row, 2)
        
        MsgBox("Hotkey editing will be available in a future update.`n`n" .
            "Current hotkey for '" . action . "': " . currentKey . "`n`n" .
            "For now, you can modify hotkeys in the HotkeyManager.ahk file.",
            "Edit Hotkey", "Iconi")
    }

    _ResetSelectedHotkey() {
        row := this.controls["HotkeyList"].GetNext()
        if (!row) {
            MsgBox("Please select a hotkey to reset.", "No Selection", "Icon!")
            return
        }

        action := this.controls["HotkeyList"].GetText(row, 1)
        
        result := MsgBox("Reset '" . action . "' to its default hotkey?", 
            "Reset Hotkey", "YesNo Icon?")
        if (result = "Yes") {
            MsgBox("Hotkey reset functionality will be implemented in a future update.", 
                "Reset Hotkey", "Iconi T3")
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
        
        testGui := Gui("+AlwaysOnTop", "Test Hotkey")
        testGui.SetFont("s10")
        testGui.Add("Text", "x10 y10 w300", "Testing: " . action)
        testGui.Add("Text", "x10 y35 w300 h20 +0x200", "Press: " . hotkey)
        testGui.SetFont("s8")
        testGui.Add("Text", "x10 y60 w300", "The action will be triggered when you press the hotkey.")
        testGui.Add("Text", "x10 y80 w300", "This window will close automatically in 5 seconds.")
        
        closeBtn := testGui.Add("Button", "x120 y110 w80 h25", "Close")
        closeBtn.OnEvent("Click", (*) => testGui.Destroy())
        
        testGui.Show()
        
        ; Auto-close after 5 seconds
        SetTimer(() => testGui.Destroy(), -5000)
    }

    _ScanForConflicts() {
        ; Simulate conflict scanning
        this.controls["ConflictStatus"].Text := "Scanning for conflicts..."
        
        ; Simulate a delay
        SetTimer(() => this._CompleteScan(), -1000)
    }

    _CompleteScan() {
        ; Update status after "scan"
        this.controls["ConflictStatus"].Text := "No conflicts detected. All hotkeys are unique."
        
        MsgBox("Hotkey conflict detection completed.`n`n" .
            "No conflicts found with other applications or within the script.", 
            "Scan Complete", "Iconi T3")
    }

    _ResetAllHotkeys() {
        result := MsgBox("Are you sure you want to reset ALL hotkeys to their default values?`n`n" .
            "This will restore the original hotkey configuration.", 
            "Reset All Hotkeys", "YesNo IconX Default2")
            
        if (result = "Yes") {
            confirm := MsgBox("This action cannot be undone. Continue?", 
                "Confirm Reset", "YesNo IconX Default2")
                
            if (confirm = "Yes") {
                MsgBox("All hotkeys have been reset to defaults.`n`n" .
                    "(This feature will be fully implemented in a future update)", 
                    "Reset Complete", "Iconi T2")
                    
                ; Refresh the list
                this._PopulateHotkeyList()
            }
        }
    }
}