; Direct execution of Hotkeys Tab test
; Save this file in the Tests folder and run it

#Requires AutoHotkey v2.0

; Set working directory to Tests folder
SetWorkingDir(A_ScriptDir)

; Include all required files (same as TestRunner.ahk)
#Include "..\Config.ahk"
#Include "..\StateManager.ahk"
#Include "..\MonitorUtils.ahk"
#Include "..\ColorThemeManager.ahk"
#Include "..\TooltipSystem.ahk"
#Include "..\StatusIndicator.ahk"
#Include "..\MouseActions.ahk"
#Include "..\PositionMemory.ahk"
#Include "..\HotkeyManager.ahk"

; Include Settings GUI modules
#Include "..\GUI\SettingsGUI_Base.ahk"
#Include "..\GUI\SettingsGUI_TabManager.ahk"

; Include Tab modules
#Include "..\GUI\Tabs\MovementTabModule.ahk"
#Include "..\GUI\Tabs\PositionsTabModule.ahk"
#Include "..\GUI\Tabs\VisualsTabModule.ahk"
#Include "..\GUI\Tabs\HotkeysTabModule.ahk"
#Include "..\GUI\Tabs\AdvancedTabModule.ahk"
#Include "..\GUI\Tabs\ProfilesTabModule.ahk"
#Include "..\GUI\Tabs\AboutTabModule.ahk"

; Include test framework
#Include "TestFramework.ahk"
#Include "TestConfig.ahk"
#Include "ArrayHelpers.ahk"

; Include the specific test
#Include "GUI\Test_HotkeysTab.ahk"

; Initialize components
Config.Load()
StateManager.Initialize()
ColorThemeManager.Initialize()
MonitorUtils.Init()

; Create and run the test
testSuite := Test_HotkeysTab()
testSuite.Setup()
testSuite.Run()

; Display results
results := testSuite.GetResults()
MsgBox("Test Results:`n`n" . 
    "Total: " . results["total"] . "`n" .
    "Passed: " . results["passed"] . "`n" .
    "Failed: " . results["failed"] . "`n" .
    "Errors: " . results["errors"] . "`n" .
    "Duration: " . Round(results["duration"] / 1000, 2) . "s",
    "Test Complete", "Iconi")