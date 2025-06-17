#Requires AutoHotkey v2.0

; ######################################################################################################################
; Settings GUI Dark Mode - Dark mode toggle and theme management
; ######################################################################################################################

; Toggle Dark Mode
SettingsGUI._ToggleDarkMode := (*) {
    ; Toggle the dark mode state
    SettingsGUI.isDarkMode := !SettingsGUI.isDarkMode
    
    ; Update button text
    SettingsGUI.controls["DarkModeToggle"].Text := SettingsGUI.isDarkMode ? "🌙 Dark" : "☀ Light"
    
    ; Store preference
    IniWrite(SettingsGUI.isDarkMode ? "1" : "0", Config.PersistentPositionsFile, "Settings", "DarkMode")
    
    ; Show message about restart requirement
    MsgBox("Dark mode " . (SettingsGUI.isDarkMode ? "enabled" : "disabled") . ".`n`nPlease close and reopen the settings window to apply the theme change.", 
        "Theme Changed", "Iconi")
}

; Apply Dark Mode Theme
SettingsGUI._ApplyDarkMode := (*) {
    if (!SettingsGUI.isDarkMode) {
        return  ; Light mode uses defaults
    }
    
    ; Set window background
    SettingsGUI.gui.BackColor := "0x1E1E1E"
    
    ; Update all text controls to light colors
    for ctrlName, ctrl in SettingsGUI.controls {
        try {
            switch ctrl.Type {
                case "Text":
                    ctrl.Opt("cE0E0E0")  ; Light gray text
                case "GroupBox":
                    ctrl.Opt("cWhite")   ; White group box text
                case "CheckBox":
                    ctrl.Opt("cWhite")   ; White checkbox text
                case "Edit":
                    ; Edit controls have limited styling in AHK
                    ; Background color doesn't work well
                case "Button":
                    ; Buttons also have limited styling options
                    ; Can't easily change background color
            }
        }
    }
    
    ; Update specific controls that need special handling
    if (SettingsGUI.controls.Has("TabControl")) {
        ; Tab control doesn't support dark mode well in AHK v2
        ; Would need custom drawing or owner-drawn tabs
    }
}

; Get Theme Colors
SettingsGUI._GetThemeTextColor := (*) {
    return SettingsGUI.isDarkMode ? "cE0E0E0" : "c000000"
}

SettingsGUI._GetThemeControlBg := (*) {
    return SettingsGUI.isDarkMode ? "0x2D2D30" : "0xFFFFFF"
}

; Helper to apply consistent styling to controls
SettingsGUI._StyleControl := (control, type := "text") {
    if (!SettingsGUI.isDarkMode) {
        return  ; Light mode uses defaults
    }
    
    switch type {
        case "text":
            control.Opt("cE0E0E0")
        case "label":
            control.Opt("cSilver")
        case "heading":
            control.Opt("cWhite")
            control.SetFont("Bold")
        case "groupbox":
            control.Opt("cWhite")
        case "button":
            ; Buttons have limited styling options in AHK v2
            ; We can't easily change their background color
        case "edit":
            ; Edit controls also have limited styling
            ; Background color changes don't work well
    }
}

; Initialize Dark Mode on GUI Creation
SettingsGUI._InitializeDarkMode := (*) {
    ; Load dark mode preference
    SettingsGUI.isDarkMode := IniRead(Config.PersistentPositionsFile, "Settings", "DarkMode", "0") = "1"
    
    ; Apply dark mode if enabled
    if (SettingsGUI.isDarkMode) {
        SettingsGUI._ApplyDarkMode()
    }
}