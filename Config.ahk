#Requires AutoHotkey v2.0

; ######################################################################################################################
; Configuration Management Module
; ######################################################################################################################

class Config {
    ; Movement settings
    static MoveStep := 4
    static MoveDelay := 15
    static AccelerationRate := 1.1
    static MaxSpeed := 30
    static EnableAbsoluteMovement := false

    ; Undo settings
    static MaxUndoLevels := 10

    ; Position memory
    static MaxSavedPositions := 5
    static PersistentPositionsFile := "MouseNumpadConfig.ini"

    ; GUI settings
    static TooltipX := 20
    static TooltipY := "A_ScreenHeight - 80"
    static StatusX := "Round(A_ScreenWidth * 0.65)"
    static StatusY := 15
    static StatusVisibleOnStartup := true
    static FeedbackDurationShort := 200
    static FeedbackDurationLong := 3000
    static EnableAudioFeedback := false
    static UseSecondaryMonitor := false

    ; Scroll settings
    static ScrollStep := 1
    static ScrollAccelerationRate := 1.1
    static MaxScrollSpeed := 10

    ; Visual settings - Color Themes
    static ColorTheme := "Default"
    static ColorThemes := Map(
        "Default", Map(
            "StatusOn", "0x4CAF50",        ; Green
            "StatusOff", "0xF44336",       ; Red
            "StatusInverted", "0xFF9800",  ; Orange
            "StatusSave", "0x9C27B0",      ; Purple
            "StatusLoad", "0x2196F3",      ; Blue
            "TooltipDefault", "0x607D8B",  ; Blue Grey
            "TooltipSuccess", "0x4CAF50",  ; Green
            "TooltipWarning", "0xFF9800",  ; Orange
            "TooltipInfo", "0x2196F3",     ; Blue
            "TooltipError", "0xF44336"     ; Red
        ),
        "Dark Mode", Map(
            "StatusOn", "0x388E3C",        ; Dark Green
            "StatusOff", "0xC62828",       ; Dark Red
            "StatusInverted", "0xE65100",  ; Dark Orange
            "StatusSave", "0x6A1B9A",      ; Dark Purple
            "StatusLoad", "0x1565C0",      ; Dark Blue
            "TooltipDefault", "0x37474F",  ; Dark Blue Grey
            "TooltipSuccess", "0x2E7D32",  ; Dark Green
            "TooltipWarning", "0xEF6C00",  ; Dark Orange
            "TooltipInfo", "0x0277BD",     ; Dark Blue
            "TooltipError", "0xB71C1C"     ; Dark Red
        ),
        "High Contrast", Map(
            "StatusOn", "0x00FF00",        ; Bright Green
            "StatusOff", "0xFF0000",       ; Bright Red
            "StatusInverted", "0xFFFF00",  ; Yellow
            "StatusSave", "0xFF00FF",      ; Magenta
            "StatusLoad", "0x00FFFF",      ; Cyan
            "TooltipDefault", "0xFFFFFF",  ; White
            "TooltipSuccess", "0x00FF00",  ; Bright Green
            "TooltipWarning", "0xFFFF00",  ; Yellow
            "TooltipInfo", "0x00FFFF",     ; Cyan
            "TooltipError", "0xFF0000"     ; Bright Red
        ),
        "Minimal", Map(
            "StatusOn", "0x212121",        ; Almost Black
            "StatusOff", "0x757575",       ; Grey
            "StatusInverted", "0x424242",  ; Dark Grey
            "StatusSave", "0x616161",      ; Medium Grey
            "StatusLoad", "0x9E9E9E",      ; Light Grey
            "TooltipDefault", "0xBDBDBD",  ; Light Grey
            "TooltipSuccess", "0x424242",  ; Dark Grey
            "TooltipWarning", "0x616161",  ; Medium Grey
            "TooltipInfo", "0x757575",     ; Grey
            "TooltipError", "0x212121"     ; Almost Black
        )
    )

    ; Tooltip duration settings (theme-specific)
    static TooltipDuration := 3000
    static StatusMessageDuration := 800

    ; Hotkey settings
    static PrefixKey := ""
    static InvertModeToggleKey := "NumpadClear"
    static AbsoluteMovementToggleKey := "NumpadIns"

    ; Get current theme colors
    static GetThemeColor(colorType) {
        ; Ensure we have a valid theme name
        themeName := Config.ColorTheme
        if (themeName = "") {
            themeName := "Default"
        }
        ; Check if the theme exists
        if (Config.ColorThemes.Has(themeName)) {
            theme := Config.ColorThemes[themeName]
            ; Check if the color type exists in the theme
            if (theme.Has(colorType)) {
                return theme[colorType]
            }
        }
        
        ; Fallback to default theme if anything fails
        defaultTheme := Config.ColorThemes["Default"]
        if (defaultTheme.Has(colorType)) {
            return defaultTheme[colorType]
        }
        
        ; Ultimate fallback - return a default grey color
        return "0x25c462"
    }

    static Load() {
        ; Load settings from INI file
        Config._LoadMovementSettings()
        Config._LoadGUISettings()
        Config._LoadScrollSettings()
        Config._LoadHotkeySettings()
        Config._LoadFeatureSettings()
    }

    static _LoadMovementSettings() {
        tempMoveStep := IniRead(Config.PersistentPositionsFile, "Settings", "MoveStep", Config.MoveStep)
        tempMoveDelay := IniRead(Config.PersistentPositionsFile, "Settings", "MoveDelay", Config.MoveDelay)
        tempAccelerationRate := IniRead(Config.PersistentPositionsFile, "Settings", "AccelerationRate", Config.AccelerationRate
        )
        tempMaxSpeed := IniRead(Config.PersistentPositionsFile, "Settings", "MaxSpeed", Config.MaxSpeed)
        tempMaxUndoLevels := IniRead(Config.PersistentPositionsFile, "Settings", "MaxUndoLevels", Config.MaxUndoLevels)
        tempMaxSavedPositions := IniRead(Config.PersistentPositionsFile, "Settings", "MaxSavedPositions", Config.MaxSavedPositions
        )

        if (tempMoveStep != "" && IsNumber(tempMoveStep))
            Config.MoveStep := Number(tempMoveStep)
        if (tempMoveDelay != "" && IsNumber(tempMoveDelay))
            Config.MoveDelay := Number(tempMoveDelay)
        if (tempAccelerationRate != "" && IsNumber(tempAccelerationRate))
            Config.AccelerationRate := Number(tempAccelerationRate)
        if (tempMaxSpeed != "" && IsNumber(tempMaxSpeed))
            Config.MaxSpeed := Number(tempMaxSpeed)
        if (tempMaxUndoLevels != "" && IsNumber(tempMaxUndoLevels))
            Config.MaxUndoLevels := Number(tempMaxUndoLevels)
        if (tempMaxSavedPositions != "" && IsNumber(tempMaxSavedPositions))
            Config.MaxSavedPositions := Number(tempMaxSavedPositions)
    }

    static _LoadGUISettings() {
        tempTooltipX := IniRead(Config.PersistentPositionsFile, "GUI", "TooltipX", Config.TooltipX)
        tempTooltipY := IniRead(Config.PersistentPositionsFile, "GUI", "TooltipY", Config.TooltipY)
        tempStatusX := IniRead(Config.PersistentPositionsFile, "GUI", "StatusX", Config.StatusX)
        tempStatusY := IniRead(Config.PersistentPositionsFile, "GUI", "StatusY", Config.StatusY)
        tempColorTheme := IniRead(Config.PersistentPositionsFile, "Settings", "ColorTheme", Config.ColorTheme)
        tempTooltipDuration := IniRead(Config.PersistentPositionsFile, "Settings", "TooltipDuration", Config.TooltipDuration
        )
        tempStatusMessageDuration := IniRead(Config.PersistentPositionsFile, "Settings", "StatusMessageDuration",
            Config.StatusMessageDuration)

        if (tempTooltipX != "")
            Config.TooltipX := tempTooltipX
        if (tempTooltipY != "")
            Config.TooltipY := tempTooltipY
        if (tempStatusX != "")
            Config.StatusX := tempStatusX
        if (tempStatusY != "")
            Config.StatusY := tempStatusY
        if (tempColorTheme != "" && Config.ColorThemes.Has(tempColorTheme))
            Config.ColorTheme := tempColorTheme
        if (tempTooltipDuration != "" && IsNumber(tempTooltipDuration))
            Config.TooltipDuration := Number(tempTooltipDuration)
        if (tempStatusMessageDuration != "" && IsNumber(tempStatusMessageDuration))
            Config.StatusMessageDuration := Number(tempStatusMessageDuration)
    }

    static _LoadScrollSettings() {
        tempScrollStep := IniRead(Config.PersistentPositionsFile, "Settings", "ScrollStep", Config.ScrollStep)
        tempScrollAccelerationRate := IniRead(Config.PersistentPositionsFile, "Settings", "ScrollAccelerationRate",
            Config.ScrollAccelerationRate)
        tempMaxScrollSpeed := IniRead(Config.PersistentPositionsFile, "Settings", "MaxScrollSpeed", Config.MaxScrollSpeed
        )

        if (tempScrollStep != "" && IsNumber(tempScrollStep))
            Config.ScrollStep := Number(tempScrollStep)
        if (tempScrollAccelerationRate != "" && IsNumber(tempScrollAccelerationRate))
            Config.ScrollAccelerationRate := Number(tempScrollAccelerationRate)
        if (tempMaxScrollSpeed != "" && IsNumber(tempMaxScrollSpeed))
            Config.MaxScrollSpeed := Number(tempMaxScrollSpeed)
    }

    static _LoadHotkeySettings() {
        tempPrefixKey := IniRead(Config.PersistentPositionsFile, "Settings", "PrefixKey", Config.PrefixKey)
        tempInvertModeToggleKey := IniRead(Config.PersistentPositionsFile, "Settings", "InvertModeToggleKey", Config.InvertModeToggleKey
        )
        tempAbsoluteMovementToggleKey := IniRead(Config.PersistentPositionsFile, "Settings",
            "AbsoluteMovementToggleKey", Config.AbsoluteMovementToggleKey)

        if (tempPrefixKey != "")
            Config.PrefixKey := tempPrefixKey
        if (tempInvertModeToggleKey != "")
            Config.InvertModeToggleKey := tempInvertModeToggleKey
        if (tempAbsoluteMovementToggleKey != "")
            Config.AbsoluteMovementToggleKey := tempAbsoluteMovementToggleKey
    }

    static _LoadFeatureSettings() {
        tempEnableAudioFeedback := IniRead(Config.PersistentPositionsFile, "Settings", "EnableAudioFeedback", Config.EnableAudioFeedback
        )
        tempStatusVisibleOnStartup := IniRead(Config.PersistentPositionsFile, "Settings", "StatusVisibleOnStartup",
            Config.StatusVisibleOnStartup)
        tempEnableAbsoluteMovement := IniRead(Config.PersistentPositionsFile, "Settings", "EnableAbsoluteMovement",
            Config.EnableAbsoluteMovement)
        tempUseSecondaryMonitor := IniRead(Config.PersistentPositionsFile, "Settings", "UseSecondaryMonitor", Config.UseSecondaryMonitor
        )

        if (tempEnableAudioFeedback != "")
            Config.EnableAudioFeedback := (tempEnableAudioFeedback = "true" || tempEnableAudioFeedback = "1")
        if (tempStatusVisibleOnStartup != "")
            Config.StatusVisibleOnStartup := (tempStatusVisibleOnStartup = "true" || tempStatusVisibleOnStartup = "1")
        if (tempEnableAbsoluteMovement != "")
            Config.EnableAbsoluteMovement := (tempEnableAbsoluteMovement = "true" || tempEnableAbsoluteMovement = "1")
        if (tempUseSecondaryMonitor != "")
            Config.UseSecondaryMonitor := (tempUseSecondaryMonitor = "true" || tempUseSecondaryMonitor = "1")
    }

    static Save() {
        ; Save all settings to INI file
        Config._SaveGeneralSettings()
        Config._SaveMovementSettings()
        Config._SaveGUISettings()
        Config._SaveScrollSettings()
        Config._SaveHotkeySettings()
        Config._SaveFeatureSettings()
    }

    static _SaveMovementSettings() {
        IniWrite(Config.MoveStep, Config.PersistentPositionsFile, "Settings", "MoveStep")
        IniWrite(Config.MoveDelay, Config.PersistentPositionsFile, "Settings", "MoveDelay")
        IniWrite(Config.AccelerationRate, Config.PersistentPositionsFile, "Settings", "AccelerationRate")
        IniWrite(Config.MaxSpeed, Config.PersistentPositionsFile, "Settings", "MaxSpeed")
        IniWrite(Config.MaxUndoLevels, Config.PersistentPositionsFile, "Settings", "MaxUndoLevels")
        IniWrite(Config.MaxSavedPositions, Config.PersistentPositionsFile, "Settings", "MaxSavedPositions")
    }

    static _SaveGeneralSettings() {
        IniWrite(Config.ColorTheme, Config.PersistentPositionsFile, "Settings", "ColorTheme")
        IniWrite(Config.TooltipDuration, Config.PersistentPositionsFile, "Settings", "TooltipDuration")
        IniWrite(Config.StatusMessageDuration, Config.PersistentPositionsFile, "Settings", "StatusMessageDuration")
    }

    static _SaveGUISettings() {
        IniWrite(Config.TooltipX, Config.PersistentPositionsFile, "GUI", "TooltipX")
        IniWrite(Config.TooltipY, Config.PersistentPositionsFile, "GUI", "TooltipY")
        IniWrite(Config.StatusX, Config.PersistentPositionsFile, "GUI", "StatusX")
        IniWrite(Config.StatusY, Config.PersistentPositionsFile, "GUI", "StatusY")
    }

    static _SaveScrollSettings() {
        IniWrite(Config.ScrollStep, Config.PersistentPositionsFile, "Settings", "ScrollStep")
        IniWrite(Config.ScrollAccelerationRate, Config.PersistentPositionsFile, "Settings", "ScrollAccelerationRate")
        IniWrite(Config.MaxScrollSpeed, Config.PersistentPositionsFile, "Settings", "MaxScrollSpeed")
    }

    static _SaveHotkeySettings() {
        IniWrite(Config.PrefixKey, Config.PersistentPositionsFile, "Settings", "PrefixKey")
        IniWrite(Config.InvertModeToggleKey, Config.PersistentPositionsFile, "Settings", "InvertModeToggleKey")
        IniWrite(Config.AbsoluteMovementToggleKey, Config.PersistentPositionsFile, "Settings",
            "AbsoluteMovementToggleKey")
    }

    static _SaveFeatureSettings() {
        IniWrite(Config.EnableAudioFeedback, Config.PersistentPositionsFile, "Settings", "EnableAudioFeedback")
        IniWrite(Config.StatusVisibleOnStartup, Config.PersistentPositionsFile, "Settings", "StatusVisibleOnStartup")
        IniWrite(Config.EnableAbsoluteMovement, Config.PersistentPositionsFile, "Settings", "EnableAbsoluteMovement")
        IniWrite(Config.UseSecondaryMonitor, Config.PersistentPositionsFile, "Settings", "UseSecondaryMonitor")
    }
}
