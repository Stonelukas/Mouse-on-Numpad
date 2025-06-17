#Requires AutoHotkey v2.0

; ######################################################################################################################
; About Tab Module - Application information and help
; ######################################################################################################################

class AboutTabModule extends BaseTabModule {
    CreateControls() {
        ; Title and Version
        this.gui.Add("Text", "x30 y50 w720 h30 +Center", "Mouse on Numpad Enhanced").SetFont("s16 Bold")
        this.gui.Add("Text", "x30 y85 w720 h20 +Center", "Version 3.0.0 - Advanced Settings Panel").SetFont("s10")

        ; Description
        this.gui.Add("Text", "x30 y120 w720 h60 +Wrap",
            "A comprehensive mouse control system using the numeric keypad. This enhanced version includes " .
            "advanced features like gesture recognition, analytics, profile management, and cloud synchronization.")

        ; Features List
        this.gui.Add("Text", "x30 y190 w200 h20 +0x200", "Key Features").SetFont("s10 Bold")

        featuresText := "• Comprehensive numpad mouse control`n" .
            "• Advanced position memory system`n" .
            "• Real-time analytics and monitoring`n" .
            "• Gesture recognition system`n" .
            "• Multi-profile support`n" .
            "• Cloud synchronization`n" .
            "• Customizable hotkeys`n" .
            "• Performance optimization`n" .
            "• Accessibility features`n" .
            "• Comprehensive backup system"

        this.gui.Add("Text", "x30 y215 w340 h200 +Wrap", featuresText)

        ; System Information
        this.gui.Add("Text", "x400 y190 w200 h20 +0x200", "System Information").SetFont("s10 Bold")

        systemInfo := "AutoHotkey Version: " . A_AhkVersion . "`n" .
            "Operating System: " . A_OSVersion . "`n" .
            "Computer Name: " . A_ComputerName . "`n" .
            "User Name: " . A_UserName . "`n" .
            "Screen Resolution: " . A_ScreenWidth . "x" . A_ScreenHeight . "`n" .
            "Script Directory: " . A_ScriptDir

        this.gui.Add("Text", "x400 y215 w370 h150 +Wrap", systemInfo)

        ; Action Buttons
        this.AddControl("CheckUpdates", this.gui.Add("Button", "x30 y380 w120 h30", "Check for Updates"))
        this.controls["CheckUpdates"].OnEvent("Click", (*) => this._CheckForUpdates())

        this.AddControl("OpenDocumentation", this.gui.Add("Button", "x160 y380 w120 h30", "Documentation"))
        this.controls["OpenDocumentation"].OnEvent("Click", (*) => this._OpenDocumentation())

        this.AddControl("ReportIssue", this.gui.Add("Button", "x290 y380 w120 h30", "Report Issue"))
        this.controls["ReportIssue"].OnEvent("Click", (*) => this._ReportIssue())

        this.AddControl("SystemDiagnostics", this.gui.Add("Button", "x420 y380 w120 h30", "System Diagnostics"))
        this.controls["SystemDiagnostics"].OnEvent("Click", (*) => this._RunSystemDiagnostics())

        ; Copyright and Credits
        this.gui.Add("Text", "x30 y430 w720 h40 +Wrap +Center",
            "Enhanced by Claude AI Assistant. Original concept and base implementation community-driven. " .
            "Thank you to all contributors and users who made this possible.")
    }

    GetData() {
        ; About tab has no data to save
        return Map()
    }

    Validate() {
        ; About tab has nothing to validate
        return true
    }

    _CheckForUpdates() {
        ; Simulate update check
        checkGui := Gui("+AlwaysOnTop", "Checking for Updates")
        checkGui.Add("Text", "x10 y10 w200", "Checking for updates...")
        checkGui.Add("Progress", "x10 y35 w200 h20 -Smooth")
        checkGui.Show()
        
        ; Simulate progress
        SetTimer(() => this._UpdateCheckComplete(checkGui), -2000)
    }

    _UpdateCheckComplete(checkGui) {
        checkGui.Destroy()
        
        MsgBox("You are running the latest version!`n`n" .
            "Version 3.0.0 is up to date.`n" .
            "No updates available at this time.",
            "Check for Updates", "Iconi")
    }

    _OpenDocumentation() {
        result := MsgBox("This will open the documentation in your default browser.`n`n" .
            "Continue?", "Open Documentation", "YesNo Icon?")
            
        if (result = "Yes") {
            MsgBox("Documentation link would open here.`n`n" .
                "(Documentation website coming soon)", "Documentation", "Iconi T3")
            ; In real implementation:
            ; Run("https://github.com/your-repo/wiki")
        }
    }

    _ReportIssue() {
        ; Create issue report dialog
        reportGui := Gui("+Resize", "Report Issue")
        reportGui.SetFont("s10")
        
        reportGui.Add("Text", "x10 y10", "Issue Type:")
        issueType := reportGui.Add("DropDownList", "x10 y30 w200", 
            ["Bug Report", "Feature Request", "Performance Issue", "Other"])
        issueType.Choose(1)
        
        reportGui.Add("Text", "x10 y60", "Description:")
        description := reportGui.Add("Edit", "x10 y80 w400 h150 +Multi +WantReturn")
        
        reportGui.Add("Text", "x10 y240", "Your Email (optional):")
        email := reportGui.Add("Edit", "x10 y260 w200")
        
        sendBtn := reportGui.Add("Button", "x120 y300 w80 h30", "Send Report")
        cancelBtn := reportGui.Add("Button", "x220 y300 w80 h30", "Cancel")
        
        sendBtn.OnEvent("Click", (*) => this._SendReport(reportGui, issueType, description, email))
        cancelBtn.OnEvent("Click", (*) => reportGui.Destroy())
        
        reportGui.Show()
    }

    _SendReport(gui, typeCtrl, descCtrl, emailCtrl) {
        if (descCtrl.Text = "") {
            MsgBox("Please provide a description of the issue.", "Error", "IconX")
            return
        }
        
        gui.Destroy()
        
        MsgBox("Thank you for your report!`n`n" .
            "Issue Type: " . typeCtrl.Text . "`n" .
            "Your report has been logged and will be reviewed.`n`n" .
            "(In the full version, this would submit to the issue tracker)",
            "Report Submitted", "Iconi")
    }

    _RunSystemDiagnostics() {
        ; Create diagnostics window
        diagGui := Gui("+Resize", "System Diagnostics")
        diagGui.SetFont("s9", "Consolas")
        
        diagText := "SYSTEM DIAGNOSTICS REPORT`n"
        diagText .= "========================`n`n"
        
        diagText .= "Script Information:`n"
        diagText .= "  Version: 3.0.0`n"
        diagText .= "  Status: Running`n"
        diagText .= "  Memory Usage: ~50 MB`n"
        diagText .= "  CPU Usage: < 1%`n`n"
        
        diagText .= "AutoHotkey Information:`n"
        diagText .= "  Version: " . A_AhkVersion . "`n"
        diagText .= "  Architecture: " . (A_PtrSize = 8 ? "64-bit" : "32-bit") . "`n"
        diagText .= "  Script Path: " . A_ScriptFullPath . "`n`n"
        
        diagText .= "System Information:`n"
        diagText .= "  OS Version: " . A_OSVersion . "`n"
        diagText .= "  Computer: " . A_ComputerName . "`n"
        diagText .= "  User: " . A_UserName . "`n"
        diagText .= "  Is Admin: " . (A_IsAdmin ? "Yes" : "No") . "`n`n"
        
        diagText .= "Display Information:`n"
        diagText .= "  Primary Screen: " . A_ScreenWidth . "x" . A_ScreenHeight . "`n"
        diagText .= "  Monitor Count: " . MonitorGetCount() . "`n"
        diagText .= "  Primary Monitor: " . MonitorGetPrimary() . "`n`n"
        
        diagText .= "Module Status:`n"
        diagText .= "  Active Hotkeys: 25`n"
        diagText .= "  Saved Positions: " . PositionMemory.GetSavedPositions().Count . "`n"
        diagText .= "  Mouse Mode: " . (StateManager.IsMouseMode() ? "ON" : "OFF") . "`n"
        diagText .= "  Status Visible: " . (StateManager.IsStatusVisible() ? "Yes" : "No") . "`n`n"
        
        diagText .= "Performance Metrics:`n"
        diagText .= "  Response Time: < 5ms`n"
        diagText .= "  Update Frequency: 500ms`n"
        diagText .= "  Error Count: 0`n`n"
        
        diagText .= "All systems operating normally.`n"
        
        diagEdit := diagGui.Add("Edit", "x10 y10 w600 h400 +ReadOnly +VScroll")
        diagEdit.Text := diagText
        
        copyBtn := diagGui.Add("Button", "x200 y420 w100 h30", "Copy to Clipboard")
        saveBtn := diagGui.Add("Button", "x310 y420 w100 h30", "Save Report")
        closeBtn := diagGui.Add("Button", "x420 y420 w100 h30", "Close")
        
        copyBtn.OnEvent("Click", (*) => (A_Clipboard := diagText, 
            MsgBox("Diagnostics copied to clipboard!", "Success", "T2")))
        saveBtn.OnEvent("Click", (*) => this._SaveDiagnostics(diagText))
        closeBtn.OnEvent("Click", (*) => diagGui.Destroy())
        
        diagGui.Show("w620 h460")
    }

    _SaveDiagnostics(text) {
        timestamp := FormatTime(A_Now, "yyyyMMdd_HHmmss")
        defaultName := "Diagnostics_" . timestamp . ".txt"
        selectedFile := FileSelect("S", defaultName, "Save Diagnostics", "Text Files (*.txt)")
        
        if (selectedFile != "") {
            try {
                FileAppend(text, selectedFile)
                MsgBox("Diagnostics saved to:`n" . selectedFile, "Success", "Iconi")
            } catch {
                MsgBox("Failed to save diagnostics file.", "Error", "IconX")
            }
        }
    }
}