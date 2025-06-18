#Requires AutoHotkey v2.0

; ######################################################################################################################
; Advanced Tab Module - Advanced settings and features
; ######################################################################################################################

class AdvancedTabModule extends BaseTabModule {
    CreateControls() {
        ; Performance Section
        this.gui.Add("Text", "x30 y50 w200 h20 +0x200", "Performance Settings").SetFont("s10 Bold")

        this.AddControl("LowMemoryMode", this.gui.Add("CheckBox", "x30 y75 w200", "Enable Low Memory Mode"))
        this.gui.Add("Text", "x50 y95 w400", "Reduces memory usage at the cost of some features")

        this.AddControl("ReduceAnimations", this.gui.Add("CheckBox", "x30 y115 w200", "Reduce Animations"))
        this.gui.Add("Text", "x50 y135 w400", "Disables visual effects for better performance")

        ; Update Frequency
        this.gui.Add("Text", "x30 y165 w150", "Update Frequency:")
        this.AddControl("UpdateFrequency", this.gui.Add("Edit", "x180 y162 w60 Number"))
        this.controls["UpdateFrequency"].Text := "500"
        
        this.AddControl("UpdateFrequencyUpDown", this.gui.Add("UpDown", "x240 y162 w20 h20 Range100-2000", 500))
        this.gui.Add("Text", "x265 y165 w200", "milliseconds between updates")

        ; Logging Section
        this.gui.Add("Text", "x30 y205 w200 h20 +0x200", "Logging & Debugging").SetFont("s10 Bold")

        this.AddControl("EnableLogging", this.gui.Add("CheckBox", "x30 y230 w200", "Enable Debug Logging"))
        this.gui.Add("Text", "x50 y250 w300", "Logs actions for troubleshooting")

        this.AddControl("LogLevel", this.gui.Add("DropDownList", "x250 y228 w100", 
            ["Error", "Warning", "Info", "Debug"]))
        this.controls["LogLevel"].Choose(2)

        ; Log Management Buttons
        this.AddControl("ViewLogs", this.gui.Add("Button", "x30 y275 w100 h25", "View Logs"))
        this.controls["ViewLogs"].OnEvent("Click", (*) => this._ViewLogs())

        this.AddControl("ClearLogs", this.gui.Add("Button", "x140 y275 w100 h25", "Clear Logs"))
        this.controls["ClearLogs"].OnEvent("Click", (*) => this._ClearLogs())

        ; Advanced Features Section
        this.gui.Add("Text", "x450 y50 w200 h20 +0x200", "Advanced Features").SetFont("s10 Bold")

        this.AddControl("EnableGestures", this.gui.Add("CheckBox", "x450 y75 w200", 
            "Enable Gesture Recognition"))
        this.gui.Add("Text", "x470 y95 w300", "Recognize mouse gestures for quick actions")

        this.AddControl("EnableAnalytics", this.gui.Add("CheckBox", "x450 y115 w200", 
            "Enable Usage Analytics"))
        this.gui.Add("Text", "x470 y135 w300", "Track usage patterns for optimization")

        this.AddControl("EnableCloudSync", this.gui.Add("CheckBox", "x450 y155 w200", 
            "Enable Cloud Synchronization"))
        this.gui.Add("Text", "x470 y175 w300", "Sync settings across devices")

        ; Experimental Features
        this.gui.Add("Text", "x450 y205 w200 h20 +0x200", "Experimental Features").SetFont("s10 Bold")

        this.AddControl("EnablePrediction", this.gui.Add("CheckBox", "x450 y230 w200", 
            "Enable Movement Prediction"))
        this.gui.Add("Text", "x470 y250 w300", "Predict and suggest common movements")

        this.AddControl("EnableMagneticSnap", this.gui.Add("CheckBox", "x450 y270 w200", 
            "Enable Magnetic Snapping"))
        this.gui.Add("Text", "x470 y290 w300", "Automatically snap to UI elements")

        ; Reset Section
        this.gui.Add("Text", "x450 y330 w200 h20 +0x200", "Reset Options").SetFont("s10 Bold")

        this.AddControl("ResetToDefaults", this.gui.Add("Button", "x450 y355 w150 h25", "Reset to Defaults"))
        this.controls["ResetToDefaults"].OnEvent("Click", (*) => this._ResetToDefaults())

        this.AddControl("FactoryReset", this.gui.Add("Button", "x450 y385 w150 h25", "Factory Reset"))
        this.controls["FactoryReset"].OnEvent("Click", (*) => this._FactoryReset())

        ; System Info Section
        this.gui.Add("Text", "x30 y330 w200 h20 +0x200", "System Information").SetFont("s10 Bold")

        systemInfo := "AutoHotkey Version: " . A_AhkVersion . "`n" .
            "Script Directory: " . A_ScriptDir . "`n" .
            "Memory Usage: ~50 MB (estimated)"

        this.gui.Add("Text", "x30 y355 w400 h60 +Wrap", systemInfo)
    }

    GetData() {
        ; Advanced settings are not currently saved
        return Map()
    }

    Validate() {
        try {
            updateFreq := Integer(this.controls["UpdateFrequency"].Text)
            if (updateFreq < 100 || updateFreq > 2000) {
                MsgBox("Update frequency must be between 100 and 2000 milliseconds", 
                    "Validation Error", "IconX")
                return false
            }
            return true
        } catch {
            MsgBox("Please enter a valid update frequency", "Validation Error", "IconX")
            return false
        }
    }

    _ViewLogs() {
        logFile := A_ScriptDir . "\MouseNumpad.log"
        if (FileExist(logFile)) {
            Run("notepad.exe " . logFile)
        } else {
            MsgBox("No log file found.`n`nEnable logging to create logs.", "No Logs", "Iconi")
        }
    }

    _ClearLogs() {
        logFile := A_ScriptDir . "\MouseNumpad.log"
        if (FileExist(logFile)) {
            result := MsgBox("Clear all log entries?`n`nThis cannot be undone.", 
                "Clear Logs", "YesNo Icon?")
            if (result = "Yes") {
                try {
                    FileDelete(logFile)
                    MsgBox("Logs have been cleared.", "Logs Cleared", "Iconi T2")
                } catch {
                    MsgBox("Failed to clear logs. The file may be in use.", "Error", "IconX")
                }
            }
        } else {
            MsgBox("No log file found.", "No Logs", "Iconi")
        }
    }

    _ResetToDefaults() {
        result := MsgBox("Reset all settings to default values?`n`n" .
            "Your saved positions will be preserved, but all other settings " .
            "will be restored to their original values.",
            "Reset to Defaults", "YesNo Icon?")
            
        if (result = "Yes") {
            ; Reset to default values
            Config.get("Movement.BaseSpeed") := 4
            Config.get("Movement.MoveDelay") := 15
            Config.get("Movement.AccelerationRate") := 1.1
            Config.get("Movement.MaxSpeed") := 30
            Config.get("Movement.EnableAbsoluteMovement") := false
            Config.get("Visual.EnableAudioFeedback") := false
            Config.get("Movement.ScrollStep") := 1
            Config.get("Movement.ScrollAccelerationRate") := 1.1
            Config.get("Movement.MaxScrollSpeed") := 10

            ; Re-initialize temp settings
            SettingsGUI._InitializeTempSettings()
            
            MsgBox("Settings have been reset to defaults.`n`n" .
                "Click Apply or OK to save the changes.", "Reset Complete", "Iconi T2")
        }
    }

    _FactoryReset() {
        result := MsgBox("FACTORY RESET WARNING!`n`n" .
            "This will:`n" .
            "• Reset ALL settings to defaults`n" .
            "• Clear ALL saved positions`n" .
            "• Remove ALL profiles`n" .
            "• Delete ALL logs`n`n" .
            "This action cannot be undone!`n`n" .
            "Are you absolutely sure?",
            "Factory Reset", "YesNo IconX Default2")
            
        if (result = "Yes") {
            ; Double confirmation with typed confirmation
            IB := InputBox("Type 'RESET' to confirm factory reset:", 
                "Final Confirmation", "w300 h120")
                
            if (IB.Result = "OK" && IB.Value = "RESET") {
                MsgBox("Factory reset would be performed here.`n`n" .
                    "(This feature is disabled for safety in the current version)",
                    "Factory Reset", "Iconi")
                    
                ; In a real implementation:
                ; - Reset all settings
                ; - Clear position memory
                ; - Delete config files
                ; - Restart application
            } else if (IB.Result = "OK") {
                MsgBox("Confirmation text did not match. Factory reset cancelled.", 
                    "Cancelled", "Iconi")
            }
        }
    }
}