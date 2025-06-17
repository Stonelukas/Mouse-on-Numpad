#Requires AutoHotkey v2.0

; ######################################################################################################################
; Color Theme Manager - Manages application-wide color themes
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
    
    ; Current theme
    static currentTheme := "Default"
    static currentColors := ColorThemeManager.themes["Default"].colors
    
    ; Initialize theme system
    static Initialize() {
        ; Load saved theme from config
        if (Config.ColorTheme != "") {
            ColorThemeManager.SetTheme(Config.ColorTheme)
        }
    }
    
    ; Set active theme
    static SetTheme(themeName) {
        if (ColorThemeManager.themes.Has(themeName)) {
            ColorThemeManager.currentTheme := themeName
            ColorThemeManager.currentColors := ColorThemeManager.themes[themeName].colors
            Config.ColorTheme := themeName
            
            ; Apply theme to existing GUIs
            ColorThemeManager.ApplyTheme()
            
            return true
        }
        return false
    }
    
    ; Get current theme name
    static GetCurrentTheme() {
        return ColorThemeManager.currentTheme
    }
    
    ; Get color from current theme
    static GetColor(colorKey) {
        if (ColorThemeManager.currentColors.HasOwnProp(colorKey)) {
            return ColorThemeManager.currentColors.%colorKey%
        }
        return "0x000000" ; Default to black if not found
    }
    
    ; Apply theme to all existing GUIs
    static ApplyTheme() {
        try {
            ; Update tooltip colors
            if (TooltipSystem.globalTooltip != "") {
                ; The background color will be applied when showing tooltips
                TooltipSystem.ApplyTheme()
            }
            
            if (TooltipSystem.mouseTooltip != "") {
                ; The background color will be applied when showing tooltips
            }
            
            ; Update status indicator colors
            if (StatusIndicator.statusIndicator != "") {
                ; The background color will be applied on next update
                StatusIndicator.Update()
            }
            
            ; Update settings GUI if open
            if (SettingsGUI.isOpen && SettingsGUI.gui != "") {
                ColorThemeManager.ApplyThemeToGUI(SettingsGUI.gui)
            }
        }
    }
    
    ; Apply theme to a specific GUI
    static ApplyThemeToGUI(gui) {
        try {
            ; Set GUI background color
            gui.BackColor := ColorThemeManager.GetColor("guiBackground")
            
            ; Update text controls
            for hwnd, ctrl in gui {
                switch Type(ctrl) {
                    case "Gui.Text":
                        ; Text controls can have their color changed
                        ctrl.SetFont("c" . ColorThemeManager.GetColor("guiTextColor"))
                    
                    case "Gui.Edit":
                        ; Edit controls - apply background if supported
                        try {
                            ctrl.Opt("+Background" . ColorThemeManager.GetColor("editBackground"))
                            ctrl.SetFont("c" . ColorThemeManager.GetColor("editText"))
                        }
                    
                    case "Gui.ListView":
                        ; ListView controls
                        try {
                            ctrl.Opt("+Background" . ColorThemeManager.GetColor("listViewBackground"))
                            ctrl.SetFont("c" . ColorThemeManager.GetColor("listViewText"))
                        }
                }
            }
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
        
        for key, value in ColorThemeManager.currentColors.OwnProps() {
            output .= "  " . key . ": " . value . "`n"
        }
        
        return output
    }
    
    ; Create a custom theme (for future use)
    static CreateCustomTheme(name, description, colors) {
        if (!ColorThemeManager.themes.Has(name)) {
            ColorThemeManager.themes[name] := {
                name: name,
                description: description,
                colors: colors
            }
            return true
        }
        return false
    }
    
    ; Save custom themes to file (for future use)
    static SaveCustomThemes() {
        ; This would save custom themes to an INI file
        ; Implementation for future version
    }
    
    ; Load custom themes from file (for future use)
    static LoadCustomThemes() {
        ; This would load custom themes from an INI file
        ; Implementation for future version
    }
}

; ######################################################################################################################
; Updated methods for existing classes to use ColorThemeManager
; ######################################################################################################################

; Extension methods for TooltipSystem
class TooltipSystemThemed {
    static GetTooltipColor(type) {
        switch type {
            case "success": return ColorThemeManager.GetColor("tooltipSuccess")
            case "warning": return ColorThemeManager.GetColor("tooltipWarning")
            case "info": return ColorThemeManager.GetColor("tooltipInfo")
            case "error": return ColorThemeManager.GetColor("tooltipError")
            default: return ColorThemeManager.GetColor("tooltipDefault")
        }
    }
}

; Extension methods for StatusIndicator
class StatusIndicatorThemed {
    static GetStatusColor(mode) {
        if (!StateManager.IsMouseMode()) {
            return ColorThemeManager.GetColor("statusOff")
        } else if (StateManager.IsSaveMode()) {
            return ColorThemeManager.GetColor("statusSave")
        } else if (StateManager.IsLoadMode()) {
            return ColorThemeManager.GetColor("statusLoad")
        } else if (StateManager.IsInvertedMode()) {
            return ColorThemeManager.GetColor("statusInverted")
        } else {
            return ColorThemeManager.GetColor("statusOn")
        }
    }
}

; Helper function to convert hex color to RGB components
ConvertHexToRGB(hexColor) {
    ; Remove 0x prefix if present
    if (SubStr(hexColor, 1, 2) = "0x") {
        hexColor := SubStr(hexColor, 3)
    }
    
    ; Extract RGB components
    r := Integer("0x" . SubStr(hexColor, 1, 2))
    g := Integer("0x" . SubStr(hexColor, 3, 2))
    b := Integer("0x" . SubStr(hexColor, 5, 2))
    
    return {r: r, g: g, b: b}
}

; Helper function to create a contrasting color
GetContrastingColor(hexColor) {
    rgb := ConvertHexToRGB(hexColor)
    
    ; Calculate luminance
    luminance := (0.299 * rgb.r + 0.587 * rgb.g + 0.114 * rgb.b) / 255
    
    ; Return black or white based on luminance
    return luminance > 0.5 ? "0x000000" : "0xFFFFFF"
}