; ######################################################################################################################
; Complete Auto-Fix Script - Fixes ALL issues in the project
; Run this ONCE to fix:
; 1. Config.get → Config.Get
; 2. GetContrastingColor → ColorThemeManager.GetContrastingColor
; ######################################################################################################################

#Requires AutoHotkey v2.0

; List of files to fix
filesToFix := [
    "GUI\Tabs\MovementTabModule.ahk",
    "GUI\Tabs\PositionsTabModule.ahk", 
    "GUI\Tabs\VisualsTabModule.ahk",
    "GUI\Tabs\AdvancedTabModule.ahk",
    "GUI\SettingsGUI_Base.ahk",
    "StatusIndicator.ahk",
    "TooltipSystem.ahk",
    "StateManager.ahk",
    "MonitorUtils.ahk",
    "PositionMemory.ahk",
    "MouseActions.ahk",
    "ColorThemeManager.ahk"
]

; Counters for fixes
totalConfigFixes := 0
totalContrastingFixes := 0
filesFixed := 0

result := MsgBox("This script will fix ALL known issues in your project:`n`n" .
    "1. Config.get → Config.Get`n" .
    "2. GetContrastingColor → ColorThemeManager.GetContrastingColor`n`n" .
    "Backup files will be created with .backup extension.`n`n" .
    "Continue?", "Auto-Fix All Issues", "YesNo Icon?")

if (result = "No") {
    ExitApp()
}

; Process each file
for index, filename in filesToFix {  ; Fixed: Added explicit variable names
    if (FileExist(filename)) {
        ; Read file content
        content := FileRead(filename)
        originalContent := content
        
        fileModified := false
        configFixes := 0
        contrastingFixes := 0
        
        ; Fix 1: Config.get( → Config.Get(
        beforeCount := 0
        pos := 1
        while (pos := InStr(content, "Config.get(", , pos)) {
            beforeCount++
            pos++
        }
        content := StrReplace(content, "Config.get(", "Config.Get(")
        configFixes := beforeCount
        
        ; Fix 2: GetContrastingColor( → ColorThemeManager.GetContrastingColor(
        ; But don't replace if it's already ColorThemeManager.GetContrastingColor
        beforeCount := 0
        pos := 1
        while (pos := InStr(content, "GetContrastingColor(", , pos)) {
            ; Check if it's not already prefixed with ColorThemeManager.
            checkPos := pos - 20
            if (checkPos < 1) checkPos := 1
            precedingText := SubStr(content, checkPos, 30)
            
            if (!InStr(precedingText, "ColorThemeManager.GetContrastingColor")) {
                beforeCount++
            }
            pos++
        }
        
        ; Replace only standalone GetContrastingColor calls
        if (beforeCount > 0) {
            ; Use a more complex replacement to avoid double-replacing
            tempMarker := "<<TEMP_MARKER_DO_NOT_USE>>"
            content := StrReplace(content, "ColorThemeManager.GetContrastingColor", tempMarker)
            content := StrReplace(content, "GetContrastingColor", "ColorThemeManager.GetContrastingColor")
            content := StrReplace(content, tempMarker, "ColorThemeManager.GetContrastingColor")
            contrastingFixes := beforeCount
        }
        
        ; Check if any changes were made
        if (content != originalContent) {
            fileModified := true
            
            ; Backup original file
            FileCopy(filename, filename . ".backup", 1)
            
            ; Write fixed content
            FileDelete(filename)
            FileAppend(content, filename)
            
            filesFixed++
            totalConfigFixes += configFixes
            totalContrastingFixes += contrastingFixes
            
            OutputDebug("Fixed " . filename . ": " . configFixes . " Config fixes, " . 
                contrastingFixes . " GetContrastingColor fixes")
        }
    } else {
        OutputDebug("File not found: " . filename)
    }
}

; Show results
resultText := "Fix Complete!`n`n"
resultText .= "Files processed: " . filesToFix.Length . "`n"
resultText .= "Files modified: " . filesFixed . "`n"
resultText .= "Config.get fixes: " . totalConfigFixes . "`n"
resultText .= "GetContrastingColor fixes: " . totalContrastingFixes . "`n"
resultText .= "Total fixes: " . (totalConfigFixes + totalContrastingFixes) . "`n`n"

if (filesFixed > 0) {
    resultText .= "Backup files created with .backup extension`n"
    resultText .= "Please test your application to ensure everything works correctly."
} else {
    resultText .= "No fixes were needed - all files already use correct syntax."
}

MsgBox(resultText, "Auto-Fix Results", "Icon!")

; Ask to test
answer := MsgBox("Would you like to run Main.ahk to test the fixes?", "Test Application", "YesNo Icon?")
if (answer = "Yes") {
    Run("Main.ahk")
}

ExitApp()