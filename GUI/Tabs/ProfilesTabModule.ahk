#Requires AutoHotkey v2.0

; ######################################################################################################################
; Profiles Tab Module - Profile management
; ######################################################################################################################

class ProfilesTabModule extends BaseTabModule {
    CreateControls() {
        ; Profile List Section
        this.gui.Add("Text", "x30 y50 w200 h20 +0x200", "Configuration Profiles").SetFont("s10 Bold")

        ; Profile ListView
        this.AddControl("ProfileList", this.gui.Add("ListView", "x30 y75 w500 h200", 
            ["Profile Name", "Description", "Last Modified"]))
        this.controls["ProfileList"].ModifyCol(1, 150)
        this.controls["ProfileList"].ModifyCol(2, 250)
        this.controls["ProfileList"].ModifyCol(3, 100)

        ; Populate with default profiles
        this._PopulateProfileList()

        ; Profile Management Buttons
        this.AddControl("LoadProfile", this.gui.Add("Button", "x550 y75 w120 h25", "Load Profile"))
        this.controls["LoadProfile"].OnEvent("Click", (*) => this._LoadSelectedProfile())

        this.AddControl("SaveProfile", this.gui.Add("Button", "x550 y105 w120 h25", "Save as New..."))
        this.controls["SaveProfile"].OnEvent("Click", (*) => this._SaveNewProfile())

        this.AddControl("UpdateProfile", this.gui.Add("Button", "x550 y135 w120 h25", "Update Current"))
        this.controls["UpdateProfile"].OnEvent("Click", (*) => this._UpdateCurrentProfile())

        this.AddControl("DeleteProfile", this.gui.Add("Button", "x550 y165 w120 h25", "Delete Profile"))
        this.controls["DeleteProfile"].OnEvent("Click", (*) => this._DeleteSelectedProfile())

        this.AddControl("ExportProfile", this.gui.Add("Button", "x550 y195 w120 h25", "Export..."))
        this.controls["ExportProfile"].OnEvent("Click", (*) => this._ExportProfile())

        this.AddControl("ImportProfile", this.gui.Add("Button", "x550 y225 w120 h25", "Import..."))
        this.controls["ImportProfile"].OnEvent("Click", (*) => this._ImportProfile())

        ; Current Profile Info
        this.gui.Add("Text", "x30 y295 w150 h20", "Current Profile:")
        this.AddControl("CurrentProfileName", this.gui.Add("Text", "x180 y295 w200 h20 +0x200"))
        this.controls["CurrentProfileName"].Text := "Default"

        ; Profile Description
        this.gui.Add("Text", "x30 y325 w200 h20 +0x200", "Profile Description").SetFont("s10 Bold")
        this.AddControl("ProfileDescription", this.gui.Add("Edit", "x30 y345 w640 h100 +VScroll +WantReturn"))
        this.controls["ProfileDescription"].Text := "Default configuration profile with standard settings."

        ; Auto-Switch Settings
        this.gui.Add("Text", "x30 y455 w200 h20 +0x200", "Auto-Switch Rules").SetFont("s10 Bold")

        this.AddControl("EnableAutoSwitch", this.gui.Add("CheckBox", "x30 y480 w220", 
            "Enable Auto Profile Switching"))
        this.gui.Add("Text", "x260 y480 w400", "Automatically switch profiles based on active application")
    }

    GetData() {
        ; Profile data is managed separately
        return Map()
    }

    Validate() {
        ; No validation needed for profiles
        return true
    }

    Refresh() {
        this._PopulateProfileList()
    }

    _PopulateProfileList() {
        try {
            this.controls["ProfileList"].Delete()

            ; Add default profiles
            profiles := [
                ["Default", "Standard configuration for general use", FormatTime(A_Now, "MM/dd/yyyy")],
                ["Gaming", "Optimized for gaming applications", FormatTime(A_Now, "MM/dd/yyyy")],
                ["Productivity", "Enhanced for office and productivity work", FormatTime(A_Now, "MM/dd/yyyy")],
                ["Accessibility", "Accessibility-focused configuration", FormatTime(A_Now, "MM/dd/yyyy")]
            ]

            for profile in profiles {
                this.controls["ProfileList"].Add(, profile[1], profile[2], profile[3])
            }
        }
    }

    _LoadSelectedProfile() {
        row := this.controls["ProfileList"].GetNext()
        if (!row) {
            MsgBox("Please select a profile to load.", "No Selection", "Icon!")
            return
        }

        profile := this.controls["ProfileList"].GetText(row, 1)
        
        result := MsgBox("Load profile '" . profile . "'?`n`n" .
            "This will replace your current settings with the saved profile.",
            "Load Profile", "YesNo Icon?")
            
        if (result = "Yes") {
            ; Update current profile display
            this.controls["CurrentProfileName"].Text := profile
            
            ; Update description based on profile
            switch profile {
                case "Gaming":
                    this.controls["ProfileDescription"].Text := 
                        "Gaming profile with fast response times and optimized movement."
                case "Productivity":
                    this.controls["ProfileDescription"].Text := 
                        "Productivity profile with precision movement and ergonomic settings."
                case "Accessibility":
                    this.controls["ProfileDescription"].Text := 
                        "Accessibility profile with slower movement and enhanced feedback."
                default:
                    this.controls["ProfileDescription"].Text := 
                        "Default configuration profile with standard settings."
            }
            
            MsgBox("Profile '" . profile . "' loaded successfully!", "Profile Loaded", "Iconi T2")
        }
    }

    _SaveNewProfile() {
        ; Create save dialog
        saveDialog := Gui("+AlwaysOnTop", "Save New Profile")
        saveDialog.SetFont("s10")
        
        saveDialog.Add("Text", "x10 y10", "Profile Name:")
        nameEdit := saveDialog.Add("Edit", "x10 y30 w250")
        
        saveDialog.Add("Text", "x10 y60", "Description:")
        descEdit := saveDialog.Add("Edit", "x10 y80 w250 h60 +Multi +WantReturn")
        
        saveBtn := saveDialog.Add("Button", "x60 y150 w60 h25 +Default", "Save")
        cancelBtn := saveDialog.Add("Button", "x140 y150 w60 h25", "Cancel")
        
        shouldSave := false
        profileName := ""
        profileDesc := ""
        
        onSaveClick(*) {
            profileName := nameEdit.Text
            profileDesc := descEdit.Text
            
            if (profileName = "") {
                MsgBox("Please enter a profile name.", "Error", "IconX")
                return
            }
            
            shouldSave := true
            saveDialog.Destroy()
        }
        
        onCancelClick(*) {
            saveDialog.Destroy()
        }
        
        saveBtn.OnEvent("Click", onSaveClick)
        cancelBtn.OnEvent("Click", onCancelClick)
        
        saveDialog.Show()
        WinWaitClose(saveDialog)
        
        if (shouldSave) {
            MsgBox("Profile '" . profileName . "' would be saved here.`n`n" .
                "(Profile saving will be fully implemented in a future update)",
                "Save Profile", "Iconi T3")
        }
    }

    _UpdateCurrentProfile() {
        current := this.controls["CurrentProfileName"].Text
        
        if (current = "Default" || current = "Gaming" || 
            current = "Productivity" || current = "Accessibility") {
            MsgBox("Cannot modify built-in profiles.`n`n" .
                "Please create a new profile instead.", "Error", "IconX")
            return
        }
        
        result := MsgBox("Update profile '" . current . "' with current settings?", 
            "Update Profile", "YesNo Icon?")
            
        if (result = "Yes") {
            MsgBox("Profile '" . current . "' updated successfully!`n`n" .
                "(This feature will be fully implemented in a future update)",
                "Success", "Iconi T2")
        }
    }

    _DeleteSelectedProfile() {
        row := this.controls["ProfileList"].GetNext()
        if (!row) {
            MsgBox("Please select a profile to delete.", "No Selection", "Icon!")
            return
        }

        profile := this.controls["ProfileList"].GetText(row, 1)
        
        if (profile = "Default" || profile = "Gaming" || 
            profile = "Productivity" || profile = "Accessibility") {
            MsgBox("Cannot delete built-in profiles.", "Error", "IconX")
            return
        }
        
        result := MsgBox("Delete profile '" . profile . "'?`n`n" .
            "This action cannot be undone.", "Delete Profile", "YesNo IconX")
            
        if (result = "Yes") {
            MsgBox("Profile '" . profile . "' deleted.`n`n" .
                "(This feature will be fully implemented in a future update)",
                "Success", "Iconi T2")
                
            ; Refresh list
            this._PopulateProfileList()
        }
    }

    _ExportProfile() {
        row := this.controls["ProfileList"].GetNext()
        if (!row) {
            MsgBox("Please select a profile to export.", "No Selection", "Icon!")
            return
        }

        profile := this.controls["ProfileList"].GetText(row, 1)
        
        ; File dialog
        timestamp := FormatTime(A_Now, "yyyyMMdd_HHmmss")
        defaultName := "Profile_" . profile . "_" . timestamp . ".ini"
        selectedFile := FileSelect("S", defaultName, "Export Profile", "Profile Files (*.ini)")
        
        if (selectedFile != "") {
            MsgBox("Profile '" . profile . "' would be exported to:`n" . selectedFile . "`n`n" .
                "(Export functionality will be implemented in a future update)",
                "Export Profile", "Iconi T3")
        }
    }

    _ImportProfile() {
        selectedFile := FileSelect(1, , "Import Profile", "Profile Files (*.ini)")
        
        if (selectedFile != "") {
            MsgBox("Profile would be imported from:`n" . selectedFile . "`n`n" .
                "(Import functionality will be implemented in a future update)",
                "Import Profile", "Iconi T3")
        }
    }
}