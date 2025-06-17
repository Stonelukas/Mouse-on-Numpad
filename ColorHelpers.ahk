#Requires AutoHotkey v2.0

; ######################################################################################################################
; Color Helper Functions - Utilities for color manipulation
; ######################################################################################################################
;
; Place this file in your main directory and include it after ColorThemeManager.ahk
; ######################################################################################################################

; Helper function to convert hex color to RGB components
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

; Helper function to create a contrasting color
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

; Mix two colors by a ratio (0-100, where 0 is all color1 and 100 is all color2)
MixColors(hexColor1, hexColor2, ratio := 50) {
    rgb1 := ConvertHexToRGB(hexColor1)
    rgb2 := ConvertHexToRGB(hexColor2)
    
    factor := ratio / 100
    
    newR := Round(rgb1.r * (1 - factor) + rgb2.r * factor)
    newG := Round(rgb1.g * (1 - factor) + rgb2.g * factor)
    newB := Round(rgb1.b * (1 - factor) + rgb2.b * factor)
    
    return ConvertRGBToHex(newR, newG, newB)
}