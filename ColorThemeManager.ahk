; ######################################################################################################################
; Color Theme Manager Module - Fixed version with correct Config method calls
; ######################################################################################################################

#Requires AutoHotkey v2.0

class ColorThemeManager {
    ; Store available themes
    static themes := Map(
        "Default", {
            name: "Default",
            colors: {
                info: 0x4A90E2,      ; Blue
                success: 0x7ED321,   ; Green
                warning: 0xF5A623,   ; Orange
                error: 0xD0021B,     ; Red
                background: 0x1A1A1A, ; Dark background
                text: 0xFFFFFF,      ; White text
                inactive: 0x808080,  ; Gray
                accent: 0x00D4FF     ; Cyan accent
            }
        },
        "Dark Mode", {
            name: "Dark Mode",
            colors: {
                info: 0x3498DB,      ; Softer blue
                success: 0x2ECC71,   ; Softer green
                warning: 0xF39C12,   ; Softer orange
                error: 0xE74C3C,     ; Softer red
                background: 0x0D0D0D, ; Very dark
                text: 0xECECEC,      ; Off-white
                inactive: 0x5A5A5A,  ; Dark gray
                accent: 0x9B59B6     ; Purple accent
            }
        },
        "High Contrast", {
            name: "High Contrast",
            colors: {
                info: 0x0080FF,      ; Bright blue
                success: 0x00FF00,   ; Bright green
                warning: 0xFFFF00,   ; Yellow
                error: 0xFF0000,     ; Bright red
                background: 0x000000, ; Black
                text: 0xFFFFFF,      ; White
                inactive: 0x808080,  ; Gray
                accent: 0xFF00FF     ; Magenta
            }
        },
        "Ocean", {
            name: "Ocean",
            colors: {
                info: 0x006994,      ; Ocean blue
                success: 0x00A86B,   ; Sea green
                warning: 0xFFB347,   ; Sandy orange
                error: 0xFF6B6B,     ; Coral red
                background: 0x001F3F, ; Deep ocean
                text: 0xE6F3FF,      ; Light blue-white
                inactive: 0x4B7A94,  ; Muted ocean
                accent: 0x00CED1     ; Dark turquoise
            }
        },
        "Forest", {
            name: "Forest",
            colors: {
                info: 0x5DADE2,      ; Sky blue
                success: 0x58D68D,   ; Leaf green
                warning: 0xF7DC6F,   ; Sunlight yellow
                error: 0xEC7063,     ; Autumn red
                background: 0x0B3D0B, ; Deep forest
                text: 0xF0FFF0,      ; Honeydew
                inactive: 0x6B8E6B,  ; Moss green
                accent: 0x98FB98     ; Pale green
            }
        },
        "Sunset", {
            name: "Sunset",
            colors: {
                info: 0x5499C7,      ; Twilight blue
                success: 0x52BE80,   ; Mint green
                warning: 0xF8C471,   ; Sunset orange
                error: 0xE59866,     ; Burnt orange
                background: 0x2C1810, ; Dark brown
                text: 0xFFF5E6,      ; Warm white
                inactive: 0x8B6347,  ; Sienna
                accent: 0xFF7F50     ; Coral
            }
        },
        "Minimal", {
            name: "Minimal",
            colors: {
                info: 0x666666,      ; Dark gray
                success: 0x4CAF50,   ; Material green
                warning: 0xFF9800,   ; Material orange
                error: 0xF44336,     ; Material red
                background: 0xFAFAFA, ; Near white
                text: 0x212121,      ; Near black
                inactive: 0xBDBDBD,  ; Light gray
                accent: 0x2196F3     ; Material blue
            }
        }
    )
    
    ; Current theme tracking
    static currentTheme := "Default"
    static currentColors := ""
    
    ; Initialize with default colors
    static __New() {
        ; Set default colors on class initialization
        ColorThemeManager.currentColors := ColorThemeManager.themes["Default"].colors
    }
    
    ; Initialize theme system
    static Initialize() {
        ; Set default colors first
        ColorThemeManager.currentColors := ColorThemeManager.themes["Default"].colors
        
        ; Load saved theme from config - FIXED: use Config.Get
        savedTheme := Config.Get("Visual.ColorTheme", "Default")
        if (savedTheme != "" && ColorThemeManager.themes.Has(savedTheme)) {
            ColorThemeManager.ApplyTheme(savedTheme)
        } else {
            ; Default to "Default" theme
            ColorThemeManager.ApplyTheme("Default")
        }
    }
    
    ; Set active theme
    static ApplyTheme(themeName) {
        if (ColorThemeManager.themes.Has(themeName)) {
            ColorThemeManager.currentTheme := themeName
            ColorThemeManager.currentColors := ColorThemeManager.themes[themeName].colors
            
            ; Save to config - FIXED: use Config.Set
            Config.Set("Visual.ColorTheme", themeName)
            
            ; Apply theme to existing GUIs
            ColorThemeManager.UpdateAllGUIs()
            
            return true
        }
        return false
    }
    
    ; Wrapper method for compatibility
    static SetTheme(themeName) {
        return ColorThemeManager.ApplyTheme(themeName)
    }
    
    ; Get current theme name
    static GetCurrentTheme() {
        return ColorThemeManager.currentTheme
    }
    
    ; Get color from current theme
    static GetColor(colorKey) {
        ; Ensure currentColors is initialized
        if (ColorThemeManager.currentColors = "") {
            ColorThemeManager.currentColors := ColorThemeManager.themes["Default"].colors
        }
        
        if (ColorThemeManager.currentColors.HasOwnProp(colorKey)) {
            return ColorThemeManager.currentColors.%colorKey%
        }
        
        ; Return a default color if key not found
        return 0x808080  ; Gray
    }
    
    ; Get contrasting color for text visibility
    static GetContrastingColor(bgColor) {
        ; Extract RGB components
        r := (bgColor >> 16) & 0xFF
        g := (bgColor >> 8) & 0xFF
        b := bgColor & 0xFF
        
        ; Calculate luminance using standard formula
        luminance := (0.299 * r + 0.587 * g + 0.114 * b) / 255
        
        ; Return white for dark backgrounds, black for light backgrounds
        return luminance > 0.5 ? 0x000000 : 0xFFFFFF
    }
    
    ; Get all theme names
    static GetThemeNames() {
        names := []
        for name, theme in ColorThemeManager.themes {
            names.Push(name)
        }
        return names
    }
    
    ; Update all GUIs with new theme
    static UpdateAllGUIs() {
        ; This would be called to update any existing GUIs
        ; Each GUI module should register itself to receive theme updates
        
        ; Update tooltips if they exist
        if (IsSet(TooltipSystem)) {
            ; TooltipSystem will use GetColor() to get current colors
        }
        
        ; Update status indicator if it exists
        if (IsSet(StatusIndicator)) {
            StatusIndicator.Update()
        }
    }
    
    ; Get theme info for display
    static GetThemeInfo(themeName := "") {
        if (themeName = "") {
            themeName := ColorThemeManager.currentTheme
        }
        
        if (ColorThemeManager.themes.Has(themeName)) {
            theme := ColorThemeManager.themes[themeName]
            info := "Theme: " . theme.name . "`n`n"
            info .= "Colors:`n"
            
            for colorName, colorValue in theme.colors {
                ; Convert to hex string
                hexColor := Format("0x{:06X}", colorValue)
                info .= "  " . colorName . ": " . hexColor . "`n"
            }
            
            return info
        }
        
        return "Theme not found: " . themeName
    }
    
    ; Export current theme as string (for debugging)
    static ExportCurrentTheme() {
        return ColorThemeManager.GetThemeInfo(ColorThemeManager.currentTheme)
    }
    
    ; Add custom theme
    static AddCustomTheme(name, colors) {
        ; Validate required color keys
        requiredKeys := ["info", "success", "warning", "error", "background", "text", "inactive", "accent"]
        
        for key in requiredKeys {
            if (!colors.HasOwnProp(key)) {
                throw Error("Missing required color key: " . key)
            }
        }
        
        ColorThemeManager.themes[name] := {
            name: name,
            colors: colors
        }
        
        return true
    }
    
    ; Cleanup method for resource management
    static Cleanup() {
        ; Clear all themes except defaults
        try {
            ; Keep only the default themes
            defaultThemes := ["Default", "Dark Mode", "High Contrast", "Ocean", "Forest", "Sunset", "Minimal"]
            for themeName in ColorThemeManager.themes {
                if (!defaultThemes.Has(themeName)) {
                    ColorThemeManager.themes.Delete(themeName)
                }
            }
            
            ; Reset to default theme
            ColorThemeManager.currentTheme := "Default"
            ColorThemeManager.currentColors := ColorThemeManager.themes["Default"].colors
            
        } catch Error as e {
            ; Ignore cleanup errors
        }
    }
}
}