#Requires AutoHotkey v2.0

; ######################################################################################################################
; Settings GUI Module - Main Structure and Core Methods
; ######################################################################################################################

; Include the other GUI modules
#Include "SettingsTabs.ahk"
#Include "SettingsActions.ahk"
#Include "SettingsHelpers.ahk"
#Include "SettingsTheme.ahk"

class SettingsGUI {
    static gui := ""
    static currentTab := 1
    static tabs := []
    static controls := Map()
    static isOpen := false
    static tempSettings := Map()
    static isDarkMode := false

    static Show() {
        if (SettingsGUI.isOpen) {
            try {
                SettingsGUI.gui.Show()
                SettingsGUI.gui.Flash()
            }
            return
        }

        SettingsGUI._CreateGUI()
        SettingsGUI.isOpen := true
    }

    static _CreateGUI() {
        ; Create main GUI window with fixed size
        SettingsGUI.gui := Gui("+Resize +MaximizeBox -MinimizeBox", "Mouse on Numpad Enhanced - Settings v3.0.0")
        
        ; Check if we should use dark mode based on current color theme
        if (Config.ColorTheme = "Dark Mode" || Config.ColorTheme = "Minimal") {
            SettingsGUI.isDarkMode := true
        }
        
        ; Apply theme colors (method from SettingsTheme.ahk)
        SettingsGUI._ApplyGUITheme()
        
        SettingsGUI.gui.MarginX := 0
        SettingsGUI.gui.MarginY := 0

        ; Set minimum size
        SettingsGUI.gui.MinSize := "800x600"

        ; Set up event handlers
        SettingsGUI.gui.OnEvent("Close", (*) => SettingsGUI._OnClose())
        SettingsGUI.gui.OnEvent("Size", (*) => SettingsGUI._OnResize())

        ; Initialize temp settings with current values
        SettingsGUI._InitializeTempSettings()
        
        ; Add dark mode toggle button in top right
        SettingsGUI.controls["DarkModeToggle"] := SettingsGUI.gui.Add("Button", "x710 y8 w70 h25", 
            SettingsGUI.isDarkMode ? "☀ Light" : "🌙 Dark")
        SettingsGUI.controls["DarkModeToggle"].OnEvent("Click", (*) => SettingsGUI._ToggleDarkMode())

        ; Create tab control
        SettingsGUI._CreateTabControl()

        ; Create all tab content (methods from SettingsTabs.ahk)
        SettingsGUI._CreateMovementTab()
        SettingsGUI._CreatePositionTab()
        SettingsGUI._CreateVisualsTab()
        SettingsGUI._CreateHotkeysTab()
        SettingsGUI._CreateAdvancedTab()
        SettingsGUI._CreateProfilesTab()
        SettingsGUI._CreateAboutTab()

        ; Exit tab control scope
        SettingsGUI.controls["TabControl"].UseTab()

        ; Create bottom button bar
        SettingsGUI._CreateBottomButtonBar()

        ; Show first tab
        SettingsGUI._ShowTab(1)

        ; Position and show GUI
        centerX := (A_ScreenWidth - 800) // 2
        centerY := (A_ScreenHeight - 600) // 2
        SettingsGUI.gui.Show("x" . centerX . " y" . centerY . " w800 h600")
    }

    static _InitializeTempSettings() {
        ; Copy current settings to temp storage
        SettingsGUI.tempSettings["MoveStep"] := Config.MoveStep
        SettingsGUI.tempSettings["MoveDelay"] := Config.MoveDelay
        SettingsGUI.tempSettings["AccelerationRate"] := Config.AccelerationRate
        SettingsGUI.tempSettings["MaxSpeed"] := Config.MaxSpeed
        SettingsGUI.tempSettings["EnableAbsoluteMovement"] := Config.EnableAbsoluteMovement
        SettingsGUI.tempSettings["MaxSavedPositions"] := Config.MaxSavedPositions
        SettingsGUI.tempSettings["MaxUndoLevels"] := Config.MaxUndoLevels
        SettingsGUI.tempSettings["EnableAudioFeedback"] := Config.EnableAudioFeedback
        SettingsGUI.tempSettings["StatusVisibleOnStartup"] := Config.StatusVisibleOnStartup
        SettingsGUI.tempSettings["UseSecondaryMonitor"] := Config.UseSecondaryMonitor
        SettingsGUI.tempSettings["ScrollStep"] := Config.ScrollStep
        SettingsGUI.tempSettings["ScrollAccelerationRate"] := Config.ScrollAccelerationRate
        SettingsGUI.tempSettings["MaxScrollSpeed"] := Config.MaxScrollSpeed
        SettingsGUI.tempSettings["ColorTheme"] := Config.ColorTheme
        SettingsGUI.tempSettings["TooltipDuration"] := Config.TooltipDuration
        SettingsGUI.tempSettings["StatusMessageDuration"] := Config.StatusMessageDuration
        SettingsGUI.tempSettings["StatusX"] := Config.StatusX
        SettingsGUI.tempSettings["StatusY"] := Config.StatusY
        SettingsGUI.tempSettings["TooltipX"] := Config.TooltipX
        SettingsGUI.tempSettings["TooltipY"] := Config.TooltipY
    }

    static _CreateTabControl() {
        ; Create tab control with explicit height
        SettingsGUI.controls["TabControl"] := SettingsGUI.gui.Add("Tab3", "x10 y35 w780 h475", [
            "Movement", "Positions", "Visuals", "Hotkeys", "Advanced", "Profiles", "About"
        ])

        ; Apply clipping style
        SettingsGUI.controls["TabControl"].Opt("+0x4000000")  ; WS_CLIPSIBLINGS

        ; Tab change event
        SettingsGUI.controls["TabControl"].OnEvent("Change", (*) => SettingsGUI._OnTabChange())
    }

    static _CreateBottomButtonBar() {
        ; Horizontal separator line
        SettingsGUI.controls["Separator"] := SettingsGUI.gui.Add("Text", "x10 y520 w780 h1 +0x10")
        
        ; Left side buttons
        SettingsGUI.controls["ImportSettings"] := SettingsGUI.gui.Add("Button", "x20 y535 w100 h25", "Import Settings")
        SettingsGUI.controls["ImportSettings"].OnEvent("Click", (*) => SettingsGUI._ImportSettings())
        
        SettingsGUI.controls["ExportSettings"] := SettingsGUI.gui.Add("Button", "x130 y535 w100 h25", "Export Settings")
        SettingsGUI.controls["ExportSettings"].OnEvent("Click", (*) => SettingsGUI._ExportSettings())

        ; Right side buttons
        SettingsGUI.controls["Help"] := SettingsGUI.gui.Add("Button", "x480 y535 w60 h25", "Help")
        SettingsGUI.controls["Help"].OnEvent("Click", (*) => SettingsGUI._ShowHelp())

        SettingsGUI.controls["Apply"] := SettingsGUI.gui.Add("Button", "x550 y535 w70 h25", "Apply")
        SettingsGUI.controls["Apply"].OnEvent("Click", (*) => SettingsGUI._ApplySettings())
        SettingsGUI.controls["Apply"].SetFont("Bold")

        SettingsGUI.controls["OK"] := SettingsGUI.gui.Add("Button", "x630 y535 w70 h25 +Default", "OK")
        SettingsGUI.controls["OK"].OnEvent("Click", (*) => SettingsGUI._ApplyAndClose())
        SettingsGUI.controls["OK"].SetFont("Bold")

        SettingsGUI.controls["Cancel"] := SettingsGUI.gui.Add("Button", "x710 y535 w70 h25", "Cancel")
        SettingsGUI.controls["Cancel"].OnEvent("Click", (*) => SettingsGUI._Cancel())
        
        ; Apply dark mode styles if needed
        if (SettingsGUI.isDarkMode) {
            SettingsGUI.controls["Separator"].Opt("+Background3E3E42")
        }
    }

    ; Event Handlers
    static _OnTabChange() {
        currentTab := SettingsGUI.controls["TabControl"].Value
        SettingsGUI._ShowTab(currentTab)
    }

    static _ShowTab(tabNumber) {
        SettingsGUI.currentTab := tabNumber

        ; Update controls based on current tab
        switch tabNumber {
            case 1: SettingsGUI._UpdateMovementPreview()
            case 2:
                MonitorUtils.Refresh()
                SettingsGUI._PopulatePositionList()
            case 3: SettingsGUI._UpdateVisualsPreview()
            case 4: SettingsGUI._PopulateHotkeyList()
            case 6: SettingsGUI._PopulateProfileList()
        }
    }

    static _OnResize() {
        ; Handle window resizing
        try {
            SettingsGUI.gui.GetPos(, , &width, &height)

            ; Resize tab control
            SettingsGUI.controls["TabControl"].Move(10, 35, width - 20, height - 125)
            
            ; Update dark mode toggle position
            if (SettingsGUI.controls.Has("DarkModeToggle")) {
                SettingsGUI.controls["DarkModeToggle"].Move(width - 80, 8)
            }

            ; Update button positions
            buttonY := height - 65
            separatorY := height - 80

            ; Update separator line
            if (SettingsGUI.controls.Has("Separator")) {
                SettingsGUI.controls["Separator"].Move(10, separatorY, width - 20, 1)
            }

            ; Update button positions
            SettingsGUI.controls["ImportSettings"].Move(20, buttonY)
            SettingsGUI.controls["ExportSettings"].Move(130, buttonY)
            SettingsGUI.controls["Help"].Move(width - 320, buttonY)
            SettingsGUI.controls["Apply"].Move(width - 250, buttonY)
            SettingsGUI.controls["OK"].Move(width - 170, buttonY)
            SettingsGUI.controls["Cancel"].Move(width - 90, buttonY)
        }
    }

    static _OnClose() {
        SettingsGUI.isOpen := false
        SettingsGUI.gui.Destroy()
    }

    static _ApplyAndClose() {
        SettingsGUI._ApplySettings()
        SettingsGUI._OnClose()
    }

    static _Cancel() {
        result := MsgBox("Are you sure you want to cancel?`nAny unsaved changes will be lost.", "Cancel Settings",
            "YesNo Icon?")
        if (result = "Yes") {
            SettingsGUI._OnClose()
        }
    }
}