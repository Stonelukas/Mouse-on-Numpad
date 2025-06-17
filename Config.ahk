#Requires AutoHotkey v2.0

; ######################################################################################################################
; Configuration Management - Core settings and INI file handling
; ######################################################################################################################

class Config {
    ; Movement settings
    static MoveStep := 5
    static MoveDelay := 50
    static AccelerationRate := 1.1
    static MaxSpeed := 50
    static EnableAbsoluteMovement := false
    
    ; Position memory
    static MaxSavedPositions := 30
    static MaxUndoLevels := 20
    static PersistentPositionsFile := A_ScriptDir . "\MouseNumpadConfig.ini"
    
    ; Visual settings
    static StatusVisibleOnStartup := true
    static UseSecondaryMonitor := false
    static EnableAudioFeedback := false
    static ColorTheme := "Default"
    static TooltipDuration := 3000
    static StatusMessageDuration := 800
    
    ; GUI Positions (can be expressions)
    static StatusX := "Round(A_ScreenWidth * 0.65)"
    static StatusY := "15"
    static TooltipX := "20"
    static TooltipY := "A_ScreenHeight - 80"
    
    ; Scroll settings
    static ScrollStep := 3
    static ScrollAccelerationRate := 1.0
    static MaxScrollSpeed := 10
    
    ; Advanced features (from EnhancedConfig)
    static EnableAnalytics := false
    static EnableLogging := false
    static LogLevel := "INFO"
    static EnableGestureRecognition := false
    static EnableCloudSync := false
    static ShowWelcomeOnStartup := true
    
    ; Color themes
    static ColorThemes := Map(
        "Default", Map(
            "StatusOn", "0x2ECC71",
            "StatusOff", "0xE74C3C",
            "StatusInverted", "0x3498DB",
            "StatusSave", "0xF39C12",
            "StatusLoad", "0x9B59B6",
            "TooltipDefault", "0x34495E",
            "TooltipSuccess", "0x27AE60",
            "TooltipWarning", "0xE67E22",
            "TooltipError", "0xC0392B"
        ),
        "Dark", Map(
            "StatusOn", "0x1ABC9C",
            "StatusOff", "0xC0392B",
            "StatusInverted", "0x2980B9",
            "StatusSave", "0xD68910",
            "StatusLoad", "0x8E44AD",
            "TooltipDefault", "0x2C3E50",
            "TooltipSuccess", "0x229954",
            "TooltipWarning", "0xD35400",
            "TooltipError", "0xA93226"
        ),
        "Light", Map(
            "StatusOn", "0x58D68D",
            "StatusOff", "0xEC7063",
            "StatusInverted", "0x5DADE2",
            "StatusSave", "0xF5B041",
            "StatusLoad", "0xAF7AC5",
            "TooltipDefault", "0x5D6D7E",
            "TooltipSuccess", "0x52BE80",
            "TooltipWarning", "0xF39C12",
            "TooltipError", "0xE74C3C"
        )
    )
    
    ; Initialize configuration
    static Init() {
        ; Create config file if it doesn't exist
        if (!FileExist(Config.PersistentPositionsFile)) {
            Config.CreateDefaultConfig()
        }
        
        ; Load configuration from file
        Config.Load()
    }
    
    ; Load configuration from INI file
    static Load() {
        try {
            ; Movement settings
            Config.MoveStep := Integer(IniRead(Config.PersistentPositionsFile, "Movement", "MoveStep", Config.MoveStep))
            Config.MoveDelay := Integer(IniRead(Config.PersistentPositionsFile, "Movement", "MoveDelay", Config.MoveDelay))
            Config.AccelerationRate := Float(IniRead(Config.PersistentPositionsFile, "Movement", "AccelerationRate", Config.AccelerationRate))
            Config.MaxSpeed := Integer(IniRead(Config.PersistentPositionsFile, "Movement", "MaxSpeed", Config.MaxSpeed))
            Config.EnableAbsoluteMovement := IniRead(Config.PersistentPositionsFile, "Movement", "EnableAbsoluteMovement", "0") = "1"
            
            ; Position settings
            Config.MaxSavedPositions := Integer(IniRead(Config.PersistentPositionsFile, "Positions", "MaxSavedPositions", Config.MaxSavedPositions))
            Config.MaxUndoLevels := Integer(IniRead(Config.PersistentPositionsFile, "Positions", "MaxUndoLevels", Config.MaxUndoLevels))
            
            ; Visual settings
            Config.StatusVisibleOnStartup := IniRead(Config.PersistentPositionsFile, "Visual", "StatusVisibleOnStartup", "1") = "1"
            Config.UseSecondaryMonitor := IniRead(Config.PersistentPositionsFile, "Visual", "UseSecondaryMonitor", "0") = "1"
            Config.EnableAudioFeedback := IniRead(Config.PersistentPositionsFile, "Visual", "EnableAudioFeedback", "0") = "1"
            Config.ColorTheme := IniRead(Config.PersistentPositionsFile, "Visual", "ColorTheme", "Default")
            Config.TooltipDuration := Integer(IniRead(Config.PersistentPositionsFile, "Visual", "TooltipDuration", Config.TooltipDuration))
            Config.StatusMessageDuration := Integer(IniRead(Config.PersistentPositionsFile, "Visual", "StatusMessageDuration", Config.StatusMessageDuration))
            
            ; GUI Positions
            Config.StatusX := IniRead(Config.PersistentPositionsFile, "Positions", "StatusX", Config.StatusX)
            Config.StatusY := IniRead(Config.PersistentPositionsFile, "Positions", "StatusY", Config.StatusY)
            Config.TooltipX := IniRead(Config.PersistentPositionsFile, "Positions", "TooltipX", Config.TooltipX)
            Config.TooltipY := IniRead(Config.PersistentPositionsFile, "Positions", "TooltipY", Config.TooltipY)
            
            ; Scroll settings
            Config.ScrollStep := Integer(IniRead(Config.PersistentPositionsFile, "Scroll", "ScrollStep", Config.ScrollStep))
            Config.ScrollAccelerationRate := Float(IniRead(Config.PersistentPositionsFile, "Scroll", "ScrollAccelerationRate", Config.ScrollAccelerationRate))
            Config.MaxScrollSpeed := Integer(IniRead(Config.PersistentPositionsFile, "Scroll", "MaxScrollSpeed", Config.MaxScrollSpeed))
            
            ; Advanced settings
            Config.EnableAnalytics := IniRead(Config.PersistentPositionsFile, "Advanced", "EnableAnalytics", "0") = "1"
            Config.EnableLogging := IniRead(Config.PersistentPositionsFile, "Advanced", "EnableLogging", "0") = "1"
            Config.LogLevel := IniRead(Config.PersistentPositionsFile, "Advanced", "LogLevel", "INFO")
            Config.EnableGestureRecognition := IniRead(Config.PersistentPositionsFile, "Advanced", "EnableGestureRecognition", "0") = "1"
            Config.EnableCloudSync := IniRead(Config.PersistentPositionsFile, "Advanced", "EnableCloudSync", "0") = "1"
            Config.ShowWelcomeOnStartup := IniRead(Config.PersistentPositionsFile, "Advanced", "ShowWelcomeOnStartup", "1") = "1"
            
        } catch Error as e {
            ; Handle load errors gracefully
            MsgBox("Error loading configuration: " . e.Message . "`n`nUsing default values.", "Config Load Error", "IconX")
        }
    }
    
    ; Save configuration to INI file
    static Save() {
        try {
            ; Movement settings
            IniWrite(Config.MoveStep, Config.PersistentPositionsFile, "Movement", "MoveStep")
            IniWrite(Config.MoveDelay, Config.PersistentPositionsFile, "Movement", "MoveDelay")
            IniWrite(Config.AccelerationRate, Config.PersistentPositionsFile, "Movement", "AccelerationRate")
            IniWrite(Config.MaxSpeed, Config.PersistentPositionsFile, "Movement", "MaxSpeed")
            IniWrite(Config.EnableAbsoluteMovement ? "1" : "0", Config.PersistentPositionsFile, "Movement", "EnableAbsoluteMovement")
            
            ; Position settings
            IniWrite(Config.MaxSavedPositions, Config.PersistentPositionsFile, "Positions", "MaxSavedPositions")
            IniWrite(Config.MaxUndoLevels, Config.PersistentPositionsFile, "Positions", "MaxUndoLevels")
            
            ; Visual settings
            IniWrite(Config.StatusVisibleOnStartup ? "1" : "0", Config.PersistentPositionsFile, "Visual", "StatusVisibleOnStartup")
            IniWrite(Config.UseSecondaryMonitor ? "1" : "0", Config.PersistentPositionsFile, "Visual", "UseSecondaryMonitor")
            IniWrite(Config.EnableAudioFeedback ? "1" : "0", Config.PersistentPositionsFile, "Visual", "EnableAudioFeedback")
            IniWrite(Config.ColorTheme, Config.PersistentPositionsFile, "Visual", "ColorTheme")
            IniWrite(Config.TooltipDuration, Config.PersistentPositionsFile, "Visual", "TooltipDuration")
            IniWrite(Config.StatusMessageDuration, Config.PersistentPositionsFile, "Visual", "StatusMessageDuration")
            
            ; GUI Positions
            IniWrite(Config.StatusX, Config.PersistentPositionsFile, "Positions", "StatusX")
            IniWrite(Config.StatusY, Config.PersistentPositionsFile, "Positions", "StatusY")
            IniWrite(Config.TooltipX, Config.PersistentPositionsFile, "Positions", "TooltipX")
            IniWrite(Config.TooltipY, Config.PersistentPositionsFile, "Positions", "TooltipY")
            
            ; Scroll settings
            IniWrite(Config.ScrollStep, Config.PersistentPositionsFile, "Scroll", "ScrollStep")
            IniWrite(Config.ScrollAccelerationRate, Config.PersistentPositionsFile, "Scroll", "ScrollAccelerationRate")
            IniWrite(Config.MaxScrollSpeed, Config.PersistentPositionsFile, "Scroll", "MaxScrollSpeed")
            
            ; Advanced settings
            IniWrite(Config.EnableAnalytics ? "1" : "0", Config.PersistentPositionsFile, "Advanced", "EnableAnalytics")
            IniWrite(Config.EnableLogging ? "1" : "0", Config.PersistentPositionsFile, "Advanced", "EnableLogging")
            IniWrite(Config.LogLevel, Config.PersistentPositionsFile, "Advanced", "LogLevel")
            IniWrite(Config.EnableGestureRecognition ? "1" : "0", Config.PersistentPositionsFile, "Advanced", "EnableGestureRecognition")
            IniWrite(Config.EnableCloudSync ? "1" : "0", Config.PersistentPositionsFile, "Advanced", "EnableCloudSync")
            IniWrite(Config.ShowWelcomeOnStartup ? "1" : "0", Config.PersistentPositionsFile, "Advanced", "ShowWelcomeOnStartup")
            
        } catch Error as e {
            MsgBox("Error saving configuration: " . e.Message, "Config Save Error", "IconX")
        }
    }
    
    ; Create default configuration file
    static CreateDefaultConfig() {
        Config.Save()
    }
    
    ; Get theme color
    static GetThemeColor(colorType) {
        if (Config.ColorThemes.Has(Config.ColorTheme)) {
            theme := Config.ColorThemes[Config.ColorTheme]
            if (theme.Has(colorType)) {
                return theme[colorType]
            }
        }
        ; Return default color if not found
        return Config.ColorThemes["Default"][colorType]
    }
}