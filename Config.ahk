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
        Config.defaults["Movement.AccelerationEnabled"] := true
        Config.defaults["Movement.MaxSpeed"] := 50
        Config.defaults["Movement.AccelerationRate"] := 2
        Config.defaults["Movement.ScrollSpeed"] := 3
        Config.defaults["Movement.SmoothScrolling"] := true
        Config.defaults["Movement.MovementMode"] := "Normal"

        ; Visual settings
        Config.defaults["Visual.StatusIndicatorEnabled"] := true
        Config.defaults["Visual.StatusIndicatorPosition"] := "TopRight"
        Config.defaults["Visual.StatusIndicatorSize"] := "Medium"
        Config.defaults["Visual.StatusIndicatorOpacity"] := 80
        Config.defaults["Visual.ShowTooltips"] := true
        Config.defaults["Visual.TooltipDuration"] := 1500
        Config.defaults["Visual.ColorTheme"] := "Blue"
        Config.defaults["Visual.AudioFeedback"] := false

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
        Config.defaults["Hotkeys.MiddleClick"] := "NumpadDot"

        ; Click hold defaults Hotkeys
        Config.defaults["Hotkeys.ToggleLeftHold"] := "NumpadClear"
        Config.defaults["Hotkeys.ToggleRightHold"] := "NumpadIns"
        Config.defaults["Hotkeys.ToggleMiddleHold"] := "+NumpadEnter"
        Config.defaults["Hotkeys.SpecialNumpadDot"] := "NumpadDot"
        Config.defaults["Hotkeys.ToggleInverted"] := "!Numpad1"

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

    ; Load settings from INI file
    static Load() {
        Config.settings.Clear()

        ; Load all defaults first
        for key, value in Config.defaults {
            Config.settings[key] := value
        }

        ; Override with saved settings if file exists
        if (FileExist(Config.iniFile)) {
            ; Read each section
            sections := ["Movement", "Visual", "Hotkeys", "Advanced", "Files"]

            for section in sections {
                ; Get all keys in this section
                sectionContent := IniRead(Config.iniFile, section, "")
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

        ; Get from defaults first
        for key, value in Config.defaults {
            if (SubStr(key, 1, StrLen(prefix)) = prefix) {
                shortKey := SubStr(key, StrLen(prefix) + 1)
                result[shortKey] := Config.Get(key)
            }
        }

        return result
    }

    ; Reset a setting to default
    static Reset(key) {
        if (Config.defaults.Has(key)) {
            Config.settings[key] := Config.defaults[key]
            return true
        }
        return false
    }

    ; Reset all settings to defaults
    static ResetAll() {
        Config.settings.Clear()
        for key, value in Config.defaults {
            Config.settings[key] := value
        }
        Config.Save()
    }

    ; Persistent positions file path
    static PersistentPositionsFile => Config.Get("Files.SavedPositions", A_ScriptDir . "\positions.dat")

    ; Common status properties
    static StatusVisibleOnStartup => Config.Get("Status.VisibleOnStartup", true)

    ; Add this to the end of your Config.ahk file to provide compatibility with old property access

}


