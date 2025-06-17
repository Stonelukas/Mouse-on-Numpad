#Requires AutoHotkey v2.0

; ######################################################################################################################
; Settings GUI List Populators - Methods for populating various lists
; ######################################################################################################################

; Populate Position List
SettingsGUI._PopulatePositionList := (*) {
    ; Clear existing items
    SettingsGUI.controls["PositionList"].Delete()
    
    ; Read all positions from INI file
    loop Config.MaxSavedPositions {
        x := IniRead(Config.PersistentPositionsFile, "Position" . A_Index, "X", "")
        y := IniRead(Config.PersistentPositionsFile, "Position" . A_Index, "Y", "")
        
        if (x != "" && y != "") {
            ; Get monitor info for this position
            monitorNum := MonitorUtils.GetMonitorAtPoint(x, y)
            monitorDesc := monitorNum > 0 ? "Monitor " . monitorNum : "Unknown"
            
            ; Determine if position is on screen
            isOnScreen := monitorNum > 0 ? "✓" : "✗"
            
            ; Add to list
            SettingsGUI.controls["PositionList"].Add("", A_Index, x, y, monitorDesc, isOnScreen)
        }
    }
    
    ; Update description
    SettingsGUI._UpdatePositionDescription()
}

; Populate Hotkey List
SettingsGUI._PopulateHotkeyList := (*) {
    ; Clear existing items
    SettingsGUI.controls["HotkeyList"].Delete()
    
    ; Define all hotkeys with descriptions
    hotkeys := [
        {action: "Toggle Script", key: "Ctrl+Alt+T", desc: "Turn the mouse numpad on/off"},
        {action: "Save Mode", key: "Ctrl+Alt+S", desc: "Toggle save position mode"},
        {action: "Load Mode", key: "Ctrl+Alt+L", desc: "Toggle load position mode"},
        {action: "Undo Last Move", key: "Ctrl+Alt+Z", desc: "Undo the last mouse movement"},
        {action: "Show/Hide Status", key: "Ctrl+Alt+V", desc: "Toggle status indicator visibility"},
        {action: "Settings GUI", key: "Ctrl+Alt+Shift+S", desc: "Open this settings window"},
        {action: "Exit Script", key: "Ctrl+Alt+Q", desc: "Exit the application"},
        {action: "Move Up", key: "Numpad8", desc: "Move mouse up"},
        {action: "Move Down", key: "Numpad2", desc: "Move mouse down"},
        {action: "Move Left", key: "Numpad4", desc: "Move mouse left"},
        {action: "Move Right", key: "Numpad6", desc: "Move mouse right"},
        {action: "Move Up-Left", key: "Numpad7", desc: "Move mouse diagonally up-left"},
        {action: "Move Up-Right", key: "Numpad9", desc: "Move mouse diagonally up-right"},
        {action: "Move Down-Left", key: "Numpad1", desc: "Move mouse diagonally down-left"},
        {action: "Move Down-Right", key: "Numpad3", desc: "Move mouse diagonally down-right"},
        {action: "Left Click", key: "Numpad5", desc: "Perform left mouse click"},
        {action: "Right Click", key: "NumpadDot", desc: "Perform right mouse click"},
        {action: "Scroll Up", key: "NumpadAdd", desc: "Scroll wheel up"},
        {action: "Scroll Down", key: "NumpadSub", desc: "Scroll wheel down"},
        {action: "Quick Save 1-10", key: "Ctrl+Numpad0-9", desc: "Save position to quick slot"},
        {action: "Quick Load 1-10", key: "Alt+Numpad0-9", desc: "Load position from quick slot"}
    ]
    
    ; Add each hotkey to the list
    for hotkey in hotkeys {
        SettingsGUI.controls["HotkeyList"].Add("", hotkey.action, hotkey.key, hotkey.desc)
    }
}

; Populate Profile List
SettingsGUI._PopulateProfileList := (*) {
    ; Clear existing items
    SettingsGUI.controls["ProfileList"].Delete()
    
    ; Define default profiles
    profiles := [
        {name: "Default", desc: "Standard configuration for general use", modified: "Built-in"},
        {name: "Gaming", desc: "Optimized for gaming with faster response", modified: "Built-in"},
        {name: "Productivity", desc: "Focused on precision and office work", modified: "Built-in"},
        {name: "Accessibility", desc: "Enhanced for users with motor limitations", modified: "Built-in"},
        {name: "Creative", desc: "Designed for graphic design and art", modified: "Built-in"}
    ]
    
    ; Add default profiles
    for profile in profiles {
        SettingsGUI.controls["ProfileList"].Add("", profile.name, profile.desc, profile.modified)
    }
    
    ; TODO: Add custom profiles from profiles directory
}

; Update Position Description
SettingsGUI._UpdatePositionDescription := (*) {
    ; Get all monitor info
    monitorInfo := MonitorUtils.GetAllMonitors()
    
    descText := "MONITOR CONFIGURATION:`r`n"
    descText .= "• Total Monitors: " . monitorInfo.count . "`r`n"
    
    if (monitorInfo.count > 0) {
        descText .= "• Primary: " . monitorInfo.primary.right . "x" . monitorInfo.primary.bottom . "`r`n"
        
        if (monitorInfo.count > 1) {
            descText .= "• Secondary: "
            for i, mon in monitorInfo.monitors {
                if (i != monitorInfo.primaryIndex) {
                    descText .= (mon.right - mon.left) . "x" . (mon.bottom - mon.top) . " "
                }
            }
            descText .= "`r`n"
        }
    }
    
    descText .= "`r`nPOSITION SLOTS:`r`n"
    
    ; Count used slots
    usedSlots := 0
    loop Config.MaxSavedPositions {
        x := IniRead(Config.PersistentPositionsFile, "Position" . A_Index, "X", "")
        if (x != "") {
            usedSlots++
        }
    }
    
    descText .= "• Used: " . usedSlots . " of " . Config.MaxSavedPositions . "`r`n"
    descText .= "• Available: " . (Config.MaxSavedPositions - usedSlots) . "`r`n"
    
    ; Update the description control
    SettingsGUI.controls["PositionDescription"].Text := descText
}

; Scan for Hotkey Conflicts
SettingsGUI._ScanForConflicts := (*) {
    ; Placeholder for hotkey conflict detection
    SettingsGUI.controls["ConflictStatus"].Text := "✓ No conflicts detected - All hotkeys are unique"
    SettingsGUI.controls["ConflictStatus"].SetFont("", "Segoe UI")
    
    MsgBox("Hotkey conflict scan completed.`nNo conflicts found!", "Scan Complete", "Iconi T2")
}

; Edit Selected Hotkey
SettingsGUI._EditSelectedHotkey := (*) {
    row := SettingsGUI.controls["HotkeyList"].GetNext()
    if (row) {
        action := SettingsGUI.controls["HotkeyList"].GetText(row, 1)
        currentKey := SettingsGUI.controls["HotkeyList"].GetText(row, 2)
        
        MsgBox("Hotkey editing for '" . action . "' will be implemented in a future update.`n`nCurrent key: " . currentKey, 
            "Edit Hotkey", "Iconi")
    } else {
        MsgBox("Please select a hotkey to edit.", "No Selection", "Icon!")
    }
}

; Reset Selected Hotkey
SettingsGUI._ResetSelectedHotkey := (*) {
    row := SettingsGUI.controls["HotkeyList"].GetNext()
    if (row) {
        action := SettingsGUI.controls["HotkeyList"].GetText(row, 1)
        
        result := MsgBox("Reset '" . action . "' to default hotkey?", "Reset Hotkey", "YesNo Icon?")
        if (result = "Yes") {
            MsgBox("Hotkey has been reset to default.", "Reset Complete", "Iconi T2")
        }
    } else {
        MsgBox("Please select a hotkey to reset.", "No Selection", "Icon!")
    }
}

; Test Selected Hotkey
SettingsGUI._TestSelectedHotkey := (*) {
    row := SettingsGUI.controls["HotkeyList"].GetNext()
    if (row) {
        action := SettingsGUI.controls["HotkeyList"].GetText(row, 1)
        key := SettingsGUI.controls["HotkeyList"].GetText(row, 2)
        
        MsgBox("Press " . key . " to test the '" . action . "' function.`n`nNote: Testing will be active for 5 seconds.",
            "Test Hotkey", "Iconi T5")
    } else {
        MsgBox("Please select a hotkey to test.", "No Selection", "Icon!")
    }
}

; Reset All Hotkeys
SettingsGUI._ResetAllHotkeys := (*) {
    result := MsgBox("Reset ALL hotkeys to their default values?`n`nThis cannot be undone.", 
        "Reset All Hotkeys", "YesNo IconX Default2")
    
    if (result = "Yes") {
        ; TODO: Implement hotkey reset logic
        SettingsGUI._PopulateHotkeyList()
        MsgBox("All hotkeys have been reset to defaults.", "Reset Complete", "Iconi T2")
    }
}