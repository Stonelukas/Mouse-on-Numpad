#Requires AutoHotkey v2.0

; ######################################################################################################################
; Fixed Color Theme Manager - Corrected Static Method Syntax
; ######################################################################################################################

class ColorThemeManager {
    ; Theme definitions
    static themes := Map(
        "Default", {
            name: "Default",
            description: "Standard blue/green theme",
            colors: {
                ; GUI backgrounds
                guiBackground: "0xF5F5F5",
                guiTextColor: "0x000000",
                
                ; Status indicator colors
                statusOff: "0xF44336",         ; Red
                statusOn: "0x4CAF50",          ; Green
                statusSave: "0x9C27B0",        ; Purple
                statusLoad: "0x2196F3",        ; Blue
                statusInverted: "0xFF9800",    ; Orange
                
                ; Tooltip colors
                tooltipDefault: "0x607D8B",    ; Blue-grey
                tooltipSuccess: "0x4CAF50",    ; Green
                tooltipWarning: "0xFF9800",    ; Orange
                tooltipInfo: "0x2196F3",       ; Blue
                tooltipError: "0xF44336",      ; Red
                
                ; Text colors
                textDefault: "0xFFFFFF",       ; White
                textDark: "0x000000",          ; Black
                
                ; Control backgrounds
                editBackground: "0xFFFFFF",
                editText: "0x000000",
                listViewBackground: "0xFFFFFF",
                listViewText: "0x000000"
            }
        },
        
        "Dark Mode", {
            name: "Dark Mode",
            description: "Dark theme for reduced eye strain",
            colors: {
                ; GUI backgrounds
                guiBackground: "0x1E1E1E",
                guiTextColor: "0xE0E0E0",
                
                ; Status indicator colors
                statusOff: "0xB71C1C",         ; Dark Red
                statusOn: "0x2E7D32",          ; Dark Green
                statusSave: "0x6A1B9A",        ; Dark Purple
                statusLoad: "0x1565C0",        ; Dark Blue
                statusInverted: "0xE65100",    ; Dark Orange
                
                ; Tooltip colors
                tooltipDefault: "0x37474F",    ; Dark Blue-grey
                tooltipSuccess: "0x2E7D32",    ; Dark Green
                tooltipWarning: "0xE65100",    ; Dark Orange
                tooltipInfo: "0x1565C0",       ; Dark Blue
                tooltipError: "0xB71C1C",      ; Dark Red
                
                ; Text colors
                textDefault: "0xE0E0E0",       ; Light Grey
                textDark: "0xFFFFFF",          ; White
                
                ; Control backgrounds
                editBackground: "0x2D2D2D",
                editText: "0xE0E0E0",
                listViewBackground: "0x2D2D2D",
                listViewText: "0xE0E0E0"
            }
        },
        
        "High Contrast", {
            name: "High Contrast",
            description: "Maximum contrast for accessibility",
            colors: {
                ; GUI backgrounds
                guiBackground: "0x000000",
                guiTextColor: "0xFFFFFF",
                
                ; Status indicator colors
                statusOff: "0xFF0000",         ; Pure Red
                statusOn: "0x00FF00",          ; Pure Green
                statusSave: "0xFF00FF",        ; Magenta
                statusLoad: "0x00FFFF",        ; Cyan
                statusInverted: "0xFFFF00",    ; Yellow
                
                ; Tooltip colors
                tooltipDefault: "0xFFFFFF",    ; White
                tooltipSuccess: "0x00FF00",    ; Green
                tooltipWarning: "0xFFFF00",    ; Yellow
                tooltipInfo: "0x00FFFF",       ; Cyan
                tooltipError: "0xFF0000",      ; Red
                
                ; Text colors
                textDefault: "0x000000",       ; Black
                textDark: "0xFFFFFF",          ; White
                
                ; Control backgrounds
                editBackground: "0xFFFFFF",
                editText: "0x000000",
                listViewBackground: "0xFFFFFF",
                listViewText: "0x000000"
            }
        },
        
        "Minimal", {
            name: "Minimal",
            description: "Clean, minimal grayscale theme",
            colors: {
                ; GUI backgrounds
                guiBackground: "0xFAFAFA",
                guiTextColor: "0x212121",
                
                ; Status indicator colors
                statusOff: "0x757575",         ; Grey
                statusOn: "0x424242",          ; Dark Grey
                statusSave: "0x616161",        ; Medium Grey
                statusLoad: "0x9E9E9E",        ; Light Grey
                statusInverted: "0x424242",    ; Dark Grey
                
                ; Tooltip colors
                tooltipDefault: "0x616161",    ; Grey
                tooltipSuccess: "0x424242",    ; Dark Grey
                tooltipWarning: "0x757575",    ; Grey
                tooltipInfo: "0x9E9E9E",       ; Light Grey
                tooltipError: "0x424242",      ; Dark Grey
                
                ; Text colors
                textDefault: "0xFFFFFF",       ; White
                textDark: "0x212121",          ; Dark Grey
                
                ; Control backgrounds
                editBackground: "0xFFFFFF",
                editText: "0x212121",
                listViewBackground: "0xFFFFFF",
                listViewText: "0x212121"
            }
        }
    )
    
    ; Current theme storage
    static currentTheme := "Default"
    static currentColors := ""
    
    ; Initialize static property with default colors
    static __New() {
        ; Set default colors on class initialization
        ColorThemeManager.currentColors := ColorThemeManager.themes["Default"].colors
    }
    
    ; Initialize theme system
    static Initialize() {
        ; Set default colors first
        ColorThemeManager.currentColors := ColorThemeManager.themes["Default"].colors
        
        ; Load saved theme from config
        if (Config.ColorTheme != "" && ColorThemeManager.themes.Has(Config.ColorTheme)) {
            ColorThemeManager.ApplyTheme(Config.ColorTheme)
        } else {
            ; Default to "Default" theme
            ColorThemeManager.ApplyTheme("Default")
        }
    }
    
    ; Set active theme - renamed from SetTheme to avoid confusion
    static ApplyTheme(themeName) {
        if (ColorThemeManager.themes.Has(themeName)) {
            ColorThemeManager.currentTheme := themeName
            ColorThemeManager.currentColors := ColorThemeManager.themes[themeName].colors
            Config.ColorTheme := themeName
            
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
        ; Default fallback color
        return "0x000000"
    }
    
    ; Apply theme to all existing GUIs - renamed from ApplyTheme
    static UpdateAllGUIs() {
        try {
            ; Apply to tooltip system
            if (HasProp(TooltipSystem, "isInitialized") && TooltipSystem.isInitialized) {
                TooltipSystem.ApplyTheme()
            }
            
            ; Apply to status indicator
            if (HasProp(StatusIndicator, "isInitialized") && StatusIndicator.isInitialized) {
                StatusIndicator.ApplyTheme()
            }
            
            ; Apply to settings GUI if open
            if (HasProp(SettingsGUI, "isOpen") && SettingsGUI.isOpen && SettingsGUI.gui != "") {
                ColorThemeManager.ApplyThemeToGUI(SettingsGUI.gui)
            }
        }
    }
    
    ; Apply theme to a specific GUI
    static ApplyThemeToGUI(gui) {
        try {
            ; Only apply a light background to settings GUI, keep text black
            if (gui = SettingsGUI.gui) {
                gui.BackColor := "e9e9e9"  ; Always light gray
                return
            }
            
            ; For other GUIs, apply full theme
            bgColor := ColorThemeManager.GetColor("guiBackground")
            if (SubStr(bgColor, 1, 2) = "0x") {
                bgColor := SubStr(bgColor, 3)
            }
            gui.BackColor := bgColor
        }
    }
    
    ; Get theme list for dropdown
    static GetThemeList() {
        themeList := []
        for name, theme in ColorThemeManager.themes {
            themeList.Push(name)
        }
        return themeList
    }
    
    ; Get theme description
    static GetThemeDescription(themeName) {
        if (ColorThemeManager.themes.Has(themeName)) {
            return ColorThemeManager.themes[themeName].description
        }
        return ""
    }
    
    ; Export theme colors for debugging
    static ExportCurrentTheme() {
        output := "Current Theme: " . ColorThemeManager.currentTheme . "`n`n"
        output .= "Colors:`n"
        
        if (ColorThemeManager.currentColors != "") {
            for key, value in ColorThemeManager.currentColors.OwnProps() {
                output .= "  " . key . ": " . value . "`n"
            }
        }
        
        return output
    }
    
    ; Save theme preference
    static SaveTheme() {
        Config.ColorTheme := ColorThemeManager.currentTheme
        Config.Save()
    }
}

; ######################################################################################################################
; Helper Functions for Color Manipulation
; ######################################################################################################################

; Convert hex color to RGB components
ConvertHexToRGB(hexColor) {
    ; Remove 0x prefix if present
    if (SubStr(hexColor, 1, 2) = "0x") {
        hexColor := SubStr(hexColor, 3)
    }
    
    ; Ensure we have 6 characters
    if (StrLen(hexColor) != 6) {
        return {r: 0, g: 0, b: 0}
    }
    
    ; Extract RGB components
    r := Integer("0x" . SubStr(hexColor, 1, 2))
    g := Integer("0x" . SubStr(hexColor, 3, 2))
    b := Integer("0x" . SubStr(hexColor, 5, 2))
    
    return {r: r, g: g, b: b}
}

; Get contrasting color (black or white) based on background
GetContrastingColor(hexColor) {
    rgb := ConvertHexToRGB(hexColor)
    
    ; Calculate luminance using W3C formula
    luminance := (0.299 * rgb.r + 0.587 * rgb.g + 0.114 * rgb.b) / 255
    
    ; Return black or white based on luminance
    return luminance > 0.5 ? "0x000000" : "0xFFFFFF"
}

; Convert RGB to hex color
ConvertRGBToHex(r, g, b) {
    return Format("0x{:02X}{:02X}{:02X}", r, g, b)
}

; Lighten a color by a percentage (0-100)
LightenColor(hexColor, percent) {
    rgb := ConvertHexToRGB(hexColor)
    
    ; Calculate new values
    factor := 1 + (percent / 100)
    newR := Min(255, Round(rgb.r * factor))
    newG := Min(255, Round(rgb.g * factor))
    newB := Min(255, Round(rgb.b * factor))
    
    return ConvertRGBToHex(newR, newG, newB)
}

; Darken a color by a percentage (0-100)
DarkenColor(hexColor, percent) {
    rgb := ConvertHexToRGB(hexColor)
    
    ; Calculate new values
    factor := 1 - (percent / 100)
    newR := Max(0, Round(rgb.r * factor))
    newG := Max(0, Round(rgb.g * factor))
    newB := Max(0, Round(rgb.b * factor))
    
    return ConvertRGBToHex(newR, newG, newB)
}

; Initialize the static properties when the script loads
ColorThemeManager.__New()