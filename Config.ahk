; ######################################################################################################################
; Configuration Management Module
; ######################################################################################################################

#Requires AutoHotkey v2.0

class Config {
    static iniFile := A_ScriptDir . "\settings.ini"
    static settings := Map()
    static defaults := Map()

    ; Initialize default values
    static __New() {
        ; Movement settings
        Config.defaults["Movement.BaseSpeed"] := 10
        Config.defaults["Movement.MoveDelay"] := 15
        Config.defaults["Movement.AccelerationRate"] := 1.1
        Config.defaults["Movement.MaxSpeed"] := 50
        Config.defaults["Movement.EnableAbsoluteMovement"] := false
        Config.defaults["Movement.ScrollStep"] := 3
        Config.defaults["Movement.ScrollAccelerationRate"] := 1.1
        Config.defaults["Movement.MaxScrollSpeed"] := 10
        Config.defaults["Movement.MaxUndoLevels"] := 10

        ; Position settings
        Config.defaults["Positions.MaxSaved"] := 5

        ; Visual settings
        Config.defaults["Visual.StatusIndicatorEnabled"] := true
        Config.defaults["Visual.StatusIndicatorPosition"] := "TopRight"
        Config.defaults["Visual.StatusIndicatorSize"] := "Medium"
        Config.defaults["Visual.StatusIndicatorOpacity"] := 80
        Config.defaults["Visual.ShowTooltips"] := true
        Config.defaults["Visual.TooltipDuration"] := 1500
        Config.defaults["Visual.ColorTheme"] := "Default"
        Config.defaults["Visual.EnableAudioFeedback"] := false
        Config.defaults["Visual.StatusVisibleOnStartup"] := true
        Config.defaults["Visual.UseSecondaryMonitor"] := false
        Config.defaults["Visual.StatusX"] := "Round(A_ScreenWidth * 0.65)"
        Config.defaults["Visual.StatusY"] := "15"
        Config.defaults["Visual.TooltipX"] := "20"
        Config.defaults["Visual.TooltipY"] := "A_ScreenHeight - 80"

        ; Hotkey defaults
        Config.defaults["Hotkeys.ToggleMouseMode"] := "NumpadAdd"
        Config.defaults["Hotkeys.SaveMode"] := "NumpadMult"
        Config.defaults["Hotkeys.LoadMode"] := "NumpadSub"
        Config.defaults["Hotkeys.UndoMove"] := "NumpadDiv"
        Config.defaults["Hotkeys.ToggleStatus"] := "^NumpadAdd"
        Config.defaults["Hotkeys.ReloadScript"] := "^!r"
        Config.defaults["Hotkeys.OpenSettings"] := "^!s"
        Config.defaults["Hotkeys.SecondaryMonitor"] := "!Numpad9"
        Config.defaults["Hotkeys.MonitorTest"] := "^!Numpad9"

        ; Movement hotkeys (numpad)
        Config.defaults["Hotkeys.MoveLeft"] := "Numpad4"
        Config.defaults["Hotkeys.MoveRight"] := "Numpad6"
        Config.defaults["Hotkeys.MoveUp"] := "Numpad8"
        Config.defaults["Hotkeys.MoveDown"] := "Numpad2"
        Config.defaults["Hotkeys.MoveDiagNW"] := "Numpad7"
        Config.defaults["Hotkeys.MoveDiagNE"] := "Numpad9"
        Config.defaults["Hotkeys.MoveDiagSW"] := "Numpad1"
        Config.defaults["Hotkeys.MoveDiagSE"] := "Numpad3"
        Config.defaults["Hotkeys.MouseClick"] := "Numpad5"
        Config.defaults["Hotkeys.RightClick"] := "Numpad0"
        Config.defaults["Hotkeys.MiddleClick"] := "NumpadEnter"

        ; Click hold toggle hotkeys
        Config.defaults["Hotkeys.ToggleLeftHold"] := "NumpadClear"
        Config.defaults["Hotkeys.ToggleRightHold"] := "NumpadIns"
        Config.defaults["Hotkeys.ToggleMiddleHold"] := "+NumpadEnter"
        Config.defaults["Hotkeys.SpecialNumpadDot"] := "NumpadDot"
        Config.defaults["Hotkeys.ToggleInverted"] := "!Numpad1"

        ; Scroll hotkeys (when mouse mode is active)
        Config.defaults["Hotkeys.ScrollUp"] := "Numpad7"
        Config.defaults["Hotkeys.ScrollDown"] := "Numpad1"
        Config.defaults["Hotkeys.ScrollLeft"] := "Numpad9"
        Config.defaults["Hotkeys.ScrollRight"] := "Numpad3"

        ; Advanced settings
        Config.defaults["Advanced.LowMemoryMode"] := false
        Config.defaults["Advanced.UpdateFrequency"] := "Normal"
        Config.defaults["Advanced.EnableLogging"] := false
        Config.defaults["Advanced.LogLevel"] := "Info"
        Config.defaults["Advanced.StartWithWindows"] := false
        Config.defaults["Advanced.CheckForUpdates"] := "Weekly"

        ; Status settings
        Config.defaults["Status.VisibleOnStartup"] := true
        Config.defaults["Status.DefaultPosition"] := "TopRight"

        ; Saved positions file
        Config.defaults["Files.SavedPositions"] := A_ScriptDir . "\positions.dat"
    }

    ; Initialize the config system - call this from Main.ahk
    static Initialize() {
        ; Load defaults into settings first
        for key, value in Config.defaults {
            Config.settings[key] := value
        }
        
        ; Create config file if it doesn't exist
        if (!FileExist(Config.iniFile)) {
            Config.CreateDefaultConfigFile()
        }
        
        ; Load settings from file
        Config.Load()
    }

    ; Create default config file
    static CreateDefaultConfigFile() {
        ; Ensure directory exists
        SplitPath(Config.iniFile, , &dir)
        if (!DirExist(dir)) {
            DirCreate(dir)
        }

        ; Create file with default values
        for key, value in Config.defaults {
            parts := StrSplit(key, ".", , 2)
            if (parts.Length = 2) {
                section := parts[1]
                keyName := parts[2]
                
                ; Convert boolean to string
                if (value = true) {
                    value := "1"
                } else if (value = false) {
                    value := "0"
                }
                
                IniWrite(value, Config.iniFile, section, keyName)
            }
        }
    }

    ; Load settings from INI file
    static Load() {
        ; Don't clear settings - they already have defaults
        
        ; Override with saved settings if file exists
        if (FileExist(Config.iniFile)) {
            ; Read all sections
            sections := ["Movement", "Visual", "Hotkeys", "Advanced", "Files", "Status", "Positions"]
            
            for section in sections {
                try {
                    ; First check if section exists by trying to read the entire section
                    sectionContent := IniRead(Config.iniFile, section)
                    
                    if (sectionContent != "") {
                        ; Parse each line
                        loop parse, sectionContent, "`n", "`r" {
                            if (A_LoopField = "")
                                continue
                            
                            ; Split key=value
                            parts := StrSplit(A_LoopField, "=", , 2)
                            if (parts.Length = 2) {
                                key := section . "." . parts[1]
                                value := parts[2]
                                
                                ; Convert string values to appropriate types
                                if (Config.defaults.Has(key)) {
                                    defaultValue := Config.defaults[key]
                                    if (Type(defaultValue) = "Integer") {
                                        value := Integer(value)
                                    } else if (Type(defaultValue) = "Float") {
                                        value := Float(value)
                                    } else if (defaultValue = true || defaultValue = false) {
                                        value := (value = "1" || value = "true")
                                    }
                                }
                                
                                Config.settings[key] := value
                            }
                        }
                    }
                } catch {
                    ; Section doesn't exist, continue with defaults
                    continue
                }
            }
        }
        
        return true
    }

    ; Save settings to INI file
    static Save() {
        ; Ensure directory exists
        SplitPath(Config.iniFile, , &dir)
        if (!DirExist(dir)) {
            DirCreate(dir)
        }

        ; Save each setting
        for key, value in Config.settings {
            ; Split key into section.name
            parts := StrSplit(key, ".", , 2)
            if (parts.Length = 2) {
                section := parts[1]
                keyName := parts[2]

                ; Convert boolean to string
                if (value = true) {
                    value := "1"
                } else if (value = false) {
                    value := "0"
                }

                IniWrite(value, Config.iniFile, section, keyName)
            }
        }

        return true
    }

    ; Get a setting value
    static Get(key, defaultValue := "") {
        if (Config.settings.Has(key)) {
            return Config.settings[key]
        } else if (Config.defaults.Has(key)) {
            return Config.defaults[key]
        }
        return defaultValue
    }

    ; Set a setting value
    static Set(key, value) {
        Config.settings[key] := value
    }

    ; Check if a key exists
    static Has(key) {
        return Config.settings.Has(key) || Config.defaults.Has(key)
    }

    ; Get all settings in a section
    static GetSection(section) {
        result := Map()
        prefix := section . "."

        ; Get from both defaults and settings
        for key, value in Config.settings {
            if (SubStr(key, 1, StrLen(prefix)) = prefix) {
                shortKey := SubStr(key, StrLen(prefix) + 1)
                result[shortKey] := value
            }
        }

        return result
    }

    ; Persistent positions file path
    static PersistentPositionsFile => Config.Get("Files.SavedPositions", A_ScriptDir . "\positions.dat")

    ; Common status properties (for compatibility)
    static StatusVisibleOnStartup => Config.Get("Visual.StatusVisibleOnStartup", true)
}


