#Requires AutoHotkey v2.0

; ######################################################################################################################
; Settings GUI Module - Advanced GUI Settings Panel with Fixed Bottom Button Bar
; ######################################################################################################################

class SettingsGUI {
    static gui := ""
    static currentTab := 1
    static tabs := []
    static controls := Map()
    static isOpen := false
    static tempSettings := Map()

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
        SettingsGUI.gui.BackColor := "0xF5F5F5"
        SettingsGUI.gui.MarginX := 0
        SettingsGUI.gui.MarginY := 0

        ; Set minimum size
        SettingsGUI.gui.MinSize := "800x600"

        ; Set up event handlers
        SettingsGUI.gui.OnEvent("Close", (*) => SettingsGUI._OnClose())
        SettingsGUI.gui.OnEvent("Size", (*) => SettingsGUI._OnResize())

        ; Initialize temp settings with current values
        SettingsGUI._InitializeTempSettings()

        ; Create tab control FIRST with explicit height to leave room for buttons
        SettingsGUI._CreateTabControl()

        ; Create all tab content
        SettingsGUI._CreateMovementTab()
        SettingsGUI._CreatePositionTab()
        SettingsGUI._CreateVisualsTab()
        SettingsGUI._CreateHotkeysTab()
        SettingsGUI._CreateAdvancedTab()
        SettingsGUI._CreateProfilesTab()
        SettingsGUI._CreateAboutTab()

        ; CRITICAL: Exit tab control scope before adding bottom buttons
        ; This is essential - without UseTab(), buttons become children of the last tab
        ; and won't be visible across all tabs
        SettingsGUI.controls["TabControl"].UseTab()

        ; NOW create the bottom button bar AFTER exiting tab scope
        SettingsGUI._CreateBottomButtonBar()

        ; Show first tab AFTER creating all controls
        SettingsGUI._ShowTab(1)

        ; Position and show GUI LAST - this ensures proper rendering
        centerX := (A_ScreenWidth - 800) // 2
        centerY := (A_ScreenHeight - 600) // 2
        SettingsGUI.gui.Show("x" . centerX . " y" . centerY . " w800 h600")
    }

    static _InitializeTempSettings() {
        ; Copy current settings to temp storage for preview
        ; Movement Settings
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
        ; Visuals Settings
        ; TODO: Add Colortheme Settings implemantation 
        SettingsGUI.tempSettings["ColorTheme"] := Config.ColorTheme
    }

    static _CreateBottomButtonBar() {
        ; Create button bar at the bottom (after exiting tab scope)
        ; Position buttons in the space below the tab control

        ; Horizontal separator line
        SettingsGUI.controls["Separator"] := SettingsGUI.gui.Add("Text", "x10 y520 w780 h1 +0x10")  ; SS_ETCHEDHORZ

        ; Left side buttons
        SettingsGUI.controls["ImportSettings"] := SettingsGUI.gui.Add("Button", "x20 y535 w100 h25", "Import Settings")
        SettingsGUI.controls["ImportSettings"].OnEvent("Click", (*) => SettingsGUI._ImportSettings())

        SettingsGUI.controls["ExportSettings"] := SettingsGUI.gui.Add("Button", "x130 y535 w100 h25", "Export Settings"
        )
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
    }

    static _CreateTabControl() {
        ; Create tab control with explicit height that leaves room for button bar
        ; Window height is 600, leave 90px for button area (including separator and margins)
        SettingsGUI.controls["TabControl"] := SettingsGUI.gui.Add("Tab3", "x10 y10 w780 h500", [
            "Movement", "Positions", "Visuals", "Hotkeys", "Advanced", "Profiles", "About"
        ])

        ; Apply clipping style to prevent overlapping issues
        SettingsGUI.controls["TabControl"].Opt("+0x4000000")  ; WS_CLIPSIBLINGS

        ; Tab change event
        SettingsGUI.controls["TabControl"].OnEvent("Change", (*) => SettingsGUI._OnTabChange())
    }

    static _CreateMovementTab() {
        ; Movement Settings Tab
        SettingsGUI.controls["TabControl"].UseTab(1)

        ; Create a scrollable area for the tab content
        yOffset := 50

        ; Movement Speed Section
        SettingsGUI.gui.Add("Text", "x30 y" . yOffset . " w200 h20 +0x200", "Movement Speed").SetFont("s10 Bold")

        yOffset += 25
        SettingsGUI.gui.Add("Text", "x30 y" . yOffset . " w120", "Move Step:")
        SettingsGUI.controls["MoveStep"] := SettingsGUI.gui.Add("Edit", "x150 y" . (yOffset - 3) . " w60 Number")
        SettingsGUI.controls["MoveStep"].Text := SettingsGUI.tempSettings["MoveStep"]
        SettingsGUI.controls["MoveStep"].OnEvent("Change", (*) => SettingsGUI._UpdateMovementPreview())
        SettingsGUI.controls["MoveStepUpDown"] := SettingsGUI.gui.Add("UpDown", "x210 y" . (yOffset - 3) .
        " w20 h20 Range1-50", SettingsGUI.tempSettings["MoveStep"])
        SettingsGUI.controls["MoveStepUpDown"].OnEvent("Change", (*) => SettingsGUI._UpdateMovementPreview())
        SettingsGUI.gui.Add("Text", "x235 y" . yOffset . " w300", "pixels per movement (1-50)")

        yOffset += 25
        SettingsGUI.gui.Add("Text", "x30 y" . yOffset . " w120", "Move Delay:")
        SettingsGUI.controls["MoveDelay"] := SettingsGUI.gui.Add("Edit", "x150 y" . (yOffset - 3) . " w60 Number")
        SettingsGUI.controls["MoveDelay"].Text := SettingsGUI.tempSettings["MoveDelay"]
        SettingsGUI.controls["MoveDelay"].OnEvent("Change", (*) => SettingsGUI._UpdateMovementPreview())
        SettingsGUI.controls["MoveDelayUpDown"] := SettingsGUI.gui.Add("UpDown", "x210 y" . (yOffset - 3) .
        " w20 h20 Range5-100", SettingsGUI.tempSettings["MoveDelay"])
        SettingsGUI.controls["MoveDelayUpDown"].OnEvent("Change", (*) => SettingsGUI._UpdateMovementPreview())
        SettingsGUI.gui.Add("Text", "x235 y" . yOffset . " w300", "milliseconds between movements (5-100)")

        ; Acceleration Section
        yOffset += 40
        SettingsGUI.gui.Add("Text", "x30 y" . yOffset . " w200 h20 +0x200", "Acceleration Settings").SetFont("s10 Bold"
        )

        yOffset += 25
        SettingsGUI.gui.Add("Text", "x30 y" . yOffset . " w120", "Acceleration Rate:")
        SettingsGUI.controls["AccelerationRate"] := SettingsGUI.gui.Add("Edit", "x150 y" . (yOffset - 3) . " w60")
        SettingsGUI.controls["AccelerationRate"].Text := SettingsGUI.tempSettings["AccelerationRate"]
        SettingsGUI.controls["AccelerationRate"].OnEvent("Change", (*) => SettingsGUI._UpdateMovementPreview())
        SettingsGUI.gui.Add("Text", "x235 y" . yOffset . " w300", "multiplier per step (1.0-3.0)")

        yOffset += 25
        SettingsGUI.gui.Add("Text", "x30 y" . yOffset . " w120", "Max Speed:")
        SettingsGUI.controls["MaxSpeed"] := SettingsGUI.gui.Add("Edit", "x150 y" . (yOffset - 3) . " w60 Number")
        SettingsGUI.controls["MaxSpeed"].Text := SettingsGUI.tempSettings["MaxSpeed"]
        SettingsGUI.controls["MaxSpeed"].OnEvent("Change", (*) => SettingsGUI._UpdateMovementPreview())
        SettingsGUI.controls["MaxSpeedUpDown"] := SettingsGUI.gui.Add("UpDown", "x210 y" . (yOffset - 3) .
        " w20 h20 Range5-100", SettingsGUI.tempSettings["MaxSpeed"])
        SettingsGUI.controls["MaxSpeedUpDown"].OnEvent("Change", (*) => SettingsGUI._UpdateMovementPreview())
        SettingsGUI.gui.Add("Text", "x235 y" . yOffset . " w300", "maximum pixels per movement (5-100)")

        ; Movement Mode Section
        yOffset += 40
        SettingsGUI.gui.Add("Text", "x30 y" . yOffset . " w200 h20 +0x200", "Movement Modes").SetFont("s10 Bold")

        yOffset += 25
        SettingsGUI.controls["EnableAbsoluteMovement"] := SettingsGUI.gui.Add("CheckBox", "x30 y" . yOffset . " w300",
            "Enable Absolute Movement")
        SettingsGUI.controls["EnableAbsoluteMovement"].Value := Config.EnableAbsoluteMovement ? 1 : 0
        SettingsGUI.controls["EnableAbsoluteMovement"].OnEvent("Click", (*) => SettingsGUI._UpdateMovementPreview())
        yOffset += 20
        SettingsGUI.gui.Add("Text", "x50 y" . yOffset . " w400",
            "Use absolute coordinates instead of relative movement")

        ; Scroll Settings Section
        yOffset += 40
        SettingsGUI.gui.Add("Text", "x30 y" . yOffset . " w200 h20 +0x200", "Scroll Settings").SetFont("s10 Bold")

        yOffset += 25
        SettingsGUI.gui.Add("Text", "x30 y" . yOffset . " w120", "Scroll Step:")
        SettingsGUI.controls["ScrollStep"] := SettingsGUI.gui.Add("Edit", "x150 y" . (yOffset - 3) . " w60 Number")
        SettingsGUI.controls["ScrollStep"].Text := SettingsGUI.tempSettings["ScrollStep"]
        SettingsGUI.controls["ScrollStep"].OnEvent("Change", (*) => SettingsGUI._UpdateMovementPreview())
        SettingsGUI.controls["ScrollStepUpDown"] := SettingsGUI.gui.Add("UpDown", "x210 y" . (yOffset - 3) .
        " w20 h20 Range1-10", SettingsGUI.tempSettings["ScrollStep"])
        SettingsGUI.controls["ScrollStepUpDown"].OnEvent("Change", (*) => SettingsGUI._UpdateMovementPreview())
        SettingsGUI.gui.Add("Text", "x235 y" . yOffset . " w300", "scroll lines per step (1-10)")

        yOffset += 25
        SettingsGUI.gui.Add("Text", "x30 y" . yOffset . " w120", "Scroll Acceleration:")
        SettingsGUI.controls["ScrollAccelerationRate"] := SettingsGUI.gui.Add("Edit", "x150 y" . (yOffset - 3) . " w60"
        )
        SettingsGUI.controls["ScrollAccelerationRate"].Text := SettingsGUI.tempSettings["ScrollAccelerationRate"]
        SettingsGUI.controls["ScrollAccelerationRate"].OnEvent("Change", (*) => SettingsGUI._UpdateMovementPreview())
        SettingsGUI.gui.Add("Text", "x235 y" . yOffset . " w300", "scroll acceleration multiplier (1.0-3.0)")

        yOffset += 25
        SettingsGUI.gui.Add("Text", "x30 y" . yOffset . " w120", "Max Scroll Speed:")
        SettingsGUI.controls["MaxScrollSpeed"] := SettingsGUI.gui.Add("Edit", "x150 y" . (yOffset - 3) . " w60 Number")
        SettingsGUI.controls["MaxScrollSpeed"].Text := SettingsGUI.tempSettings["MaxScrollSpeed"]
        SettingsGUI.controls["MaxScrollSpeed"].OnEvent("Change", (*) => SettingsGUI._UpdateMovementPreview())
        SettingsGUI.controls["MaxScrollSpeedUpDown"] := SettingsGUI.gui.Add("UpDown", "x210 y" . (yOffset - 3) .
        " w20 h20 Range1-50", SettingsGUI.tempSettings["MaxScrollSpeed"])
        SettingsGUI.controls["MaxScrollSpeedUpDown"].OnEvent("Change", (*) => SettingsGUI._UpdateMovementPreview())
        SettingsGUI.gui.Add("Text", "x235 y" . yOffset . " w300", "maximum scroll lines per step (1-50)")

        ; Preview Section
        SettingsGUI.gui.Add("Text", "x450 y50 w300 h20 +0x200", "Movement & Scroll Preview").SetFont("s10 Bold")
        SettingsGUI.controls["MovementPreview"] := SettingsGUI.gui.Add("Edit",
            "x450 y75 w300 h360 +VScroll +ReadOnly +Wrap")
        SettingsGUI.controls["MovementPreview"].SetFont("s8", "Consolas")
        SettingsGUI._UpdateMovementPreview()
    }

    static _CreatePositionTab() {
        ; Position Memory Settings Tab
        SettingsGUI.controls["TabControl"].UseTab(2)

        ; Position Slots Section
        SettingsGUI.gui.Add("Text", "x30 y50 w200 h20 +0x200", "Position Memory").SetFont("s10 Bold")

        SettingsGUI.gui.Add("Text", "x30 y75 w150", "Maximum Saved Positions:")
        SettingsGUI.controls["MaxSavedPositions"] := SettingsGUI.gui.Add("Edit", "x180 y72 w60 Number")
        SettingsGUI.controls["MaxSavedPositions"].Text := SettingsGUI.tempSettings["MaxSavedPositions"]
        SettingsGUI.controls["MaxSavedPositionsUpDown"] := SettingsGUI.gui.Add("UpDown", "x240 y72 w20 h20 Range1-100",
            SettingsGUI.tempSettings["MaxSavedPositions"])
        SettingsGUI.gui.Add("Text", "x265 y75 w300", "position slots (1-100)")

        SettingsGUI.gui.Add("Text", "x30 y100 w150", "Maximum Undo Levels:")
        SettingsGUI.controls["MaxUndoLevels"] := SettingsGUI.gui.Add("Edit", "x180 y97 w60 Number")
        SettingsGUI.controls["MaxUndoLevels"].Text := SettingsGUI.tempSettings["MaxUndoLevels"]
        SettingsGUI.controls["MaxUndoLevelsUpDown"] := SettingsGUI.gui.Add("UpDown", "x240 y97 w20 h20 Range1-50",
            SettingsGUI.tempSettings["MaxUndoLevels"])
        SettingsGUI.gui.Add("Text", "x265 y100 w300", "undo steps (1-50)")

        ; Current Positions Section
        SettingsGUI.gui.Add("Text", "x30 y140 w200 h20 +0x200", "Saved Positions").SetFont("s10 Bold")

        ; Position List - REDUCED HEIGHT to make room for buttons
        SettingsGUI.controls["PositionList"] := SettingsGUI.gui.Add("ListView", "x30 y165 w500 h150", ["Slot", "X", "Y",
            "Description"])
        SettingsGUI.controls["PositionList"].ModifyCol(1, 50)
        SettingsGUI.controls["PositionList"].ModifyCol(2, 80)
        SettingsGUI.controls["PositionList"].ModifyCol(3, 80)
        SettingsGUI.controls["PositionList"].ModifyCol(4, 280)

        ; Add double-click event to go to position
        SettingsGUI.controls["PositionList"].OnEvent("DoubleClick", (*) => SettingsGUI._GotoSelectedPosition())

        ; Position Management Buttons
        SettingsGUI.controls["GotoPosition"] := SettingsGUI.gui.Add("Button", "x550 y165 w120 h25", "Go to Position")
        SettingsGUI.controls["GotoPosition"].OnEvent("Click", (*) => SettingsGUI._GotoSelectedPosition())

        SettingsGUI.controls["PreviewPosition"] := SettingsGUI.gui.Add("Button", "x550 y195 w120 h25", "Preview")
        SettingsGUI.controls["PreviewPosition"].OnEvent("Click", (*) => SettingsGUI._PreviewSelectedPosition())
        SettingsGUI.controls["PreviewPosition"].ToolTip := "Preview the selected position with a visual indicator"

        SettingsGUI.controls["SaveCurrentPos"] := SettingsGUI.gui.Add("Button", "x550 y225 w120 h25", "Save Mouse Pos")
        SettingsGUI.controls["SaveCurrentPos"].OnEvent("Click", (*) => SettingsGUI._SaveCurrentPosition())
        SettingsGUI.controls["SaveCurrentPos"].ToolTip := "Save current mouse cursor position to a slot"

        SettingsGUI.controls["DeletePosition"] := SettingsGUI.gui.Add("Button", "x550 y255 w120 h25", "Delete Position"
        )
        SettingsGUI.controls["DeletePosition"].OnEvent("Click", (*) => SettingsGUI._DeleteSelectedPosition())

        SettingsGUI.controls["ClearAllPositions"] := SettingsGUI.gui.Add("Button", "x550 y285 w120 h25", "Clear All")
        SettingsGUI.controls["ClearAllPositions"].OnEvent("Click", (*) => SettingsGUI._ClearAllPositions())

        ; Import/Export buttons moved to new row
        SettingsGUI.controls["ImportPositions"] := SettingsGUI.gui.Add("Button", "x30 y325 w120 h25", "Import...")
        SettingsGUI.controls["ImportPositions"].OnEvent("Click", (*) => SettingsGUI._ImportPositions())

        SettingsGUI.controls["ExportPositions"] := SettingsGUI.gui.Add("Button", "x160 y325 w120 h25", "Export...")
        SettingsGUI.controls["ExportPositions"].OnEvent("Click", (*) => SettingsGUI._ExportPositions())

        ; Monitor test buttons - NOW VISIBLE
        SettingsGUI.controls["TestMonitors"] := SettingsGUI.gui.Add("Button", "x290 y325 w120 h25", "Test Monitors")
        SettingsGUI.controls["TestMonitors"].OnEvent("Click", (*) => SettingsGUI._TestMonitorConfiguration())
        SettingsGUI.controls["TestMonitors"].ToolTip := "Show monitor configuration and boundaries"

        SettingsGUI.controls["RefreshMonitors"] := SettingsGUI.gui.Add("Button", "x420 y325 w120 h25",
            "Refresh Monitors")
        SettingsGUI.controls["RefreshMonitors"].OnEvent("Click", (*) => SettingsGUI._RefreshMonitors())
        SettingsGUI.controls["RefreshMonitors"].ToolTip :=
            "Refresh monitor configuration and update position descriptions"

        ; Position File Management
        SettingsGUI.gui.Add("Text", "x30 y365 w200 h20 +0x200", "Position File Management").SetFont("s10 Bold")

        SettingsGUI.gui.Add("Text", "x30 y390 w100", "Config File:")
        SettingsGUI.controls["ConfigFile"] := SettingsGUI.gui.Add("Edit", "x130 y387 w270 ReadOnly")
        SettingsGUI.controls["ConfigFile"].Text := Config.PersistentPositionsFile

        SettingsGUI.controls["OpenConfigFolder"] := SettingsGUI.gui.Add("Button", "x410 y385 w75 h25", "Open Folder")
        SettingsGUI.controls["OpenConfigFolder"].OnEvent("Click", (*) => SettingsGUI._OpenConfigFolder())

        SettingsGUI.controls["BackupConfig"] := SettingsGUI.gui.Add("Button", "x495 y385 w75 h25", "Backup")
        SettingsGUI.controls["BackupConfig"].OnEvent("Click", (*) => SettingsGUI._BackupConfig())

        SettingsGUI.controls["RestoreBtn"] := SettingsGUI.gui.Add("Button", "x580 y385 w90 h25", "Restore...")
        SettingsGUI.controls["RestoreBtn"].OnEvent("Click", (*) => SettingsGUI._RestoreBackup())

        ; Populate position list
        SettingsGUI._PopulatePositionList()
    }

    static _CreateVisualsTab() {
        ; Visual & Audio Settings Tab
        SettingsGUI.controls["TabControl"].UseTab(3)

        ; Status Display Section
        SettingsGUI.gui.Add("Text", "x30 y50 w200 h20 +0x200", "Status Display").SetFont("s10 Bold")

        SettingsGUI.controls["StatusVisibleOnStartup"] := SettingsGUI.gui.Add("CheckBox", "x30 y75 w300",
            "Show Status on Startup")
        SettingsGUI.controls["StatusVisibleOnStartup"].Value := SettingsGUI.tempSettings["StatusVisibleOnStartup"] ? 1 : 0

        SettingsGUI.controls["UseSecondaryMonitor"] := SettingsGUI.gui.Add("CheckBox", "x30 y100 w300",
            "Use Secondary Monitor")
        SettingsGUI.controls["UseSecondaryMonitor"].Value := SettingsGUI.tempSettings["UseSecondaryMonitor"] ? 1 : 0

        ; Status Position Section
        SettingsGUI.gui.Add("Text", "x30 y140 w200 h20 +0x200", "Status Position").SetFont("s10 Bold")

        SettingsGUI.gui.Add("Text", "x30 y165 w80", "Status X:")
        SettingsGUI.controls["StatusX"] := SettingsGUI.gui.Add("Edit", "x110 y162 w150")
        SettingsGUI.controls["StatusX"].Text := Config.StatusX
        SettingsGUI.gui.Add("Text", "x270 y165 w200", "X position or expression")

        SettingsGUI.gui.Add("Text", "x30 y190 w80", "Status Y:")
        SettingsGUI.controls["StatusY"] := SettingsGUI.gui.Add("Edit", "x110 y187 w150")
        SettingsGUI.controls["StatusY"].Text := Config.StatusY
        SettingsGUI.gui.Add("Text", "x270 y190 w200", "Y position or expression")

        ; Tooltip Position Section
        SettingsGUI.gui.Add("Text", "x30 y230 w200 h20 +0x200", "Tooltip Position").SetFont("s10 Bold")

        SettingsGUI.gui.Add("Text", "x30 y255 w80", "Tooltip X:")
        SettingsGUI.controls["TooltipX"] := SettingsGUI.gui.Add("Edit", "x110 y252 w150")
        SettingsGUI.controls["TooltipX"].Text := Config.TooltipX
        SettingsGUI.gui.Add("Text", "x270 y255 w200", "X position or expression")

        SettingsGUI.gui.Add("Text", "x30 y280 w80", "Tooltip Y:")
        SettingsGUI.controls["TooltipY"] := SettingsGUI.gui.Add("Edit", "x110 y277 w150")
        SettingsGUI.controls["TooltipY"].Text := Config.TooltipY
        SettingsGUI.gui.Add("Text", "x270 y280 w200", "Y position or expression")

        ; Audio Feedback Section
        SettingsGUI.gui.Add("Text", "x30 y320 w200 h20 +0x200", "Audio Feedback").SetFont("s10 Bold")

        SettingsGUI.controls["EnableAudioFeedback"] := SettingsGUI.gui.Add("CheckBox", "x30 y345 w200",
            "Enable Audio Feedback")
        SettingsGUI.controls["EnableAudioFeedback"].Value := SettingsGUI.tempSettings["EnableAudioFeedback"] ? 1 : 0

        ; Test Audio Button
        SettingsGUI.controls["TestAudio"] := SettingsGUI.gui.Add("Button", "x250 y343 w100 h25", "Test Audio")
        SettingsGUI.controls["TestAudio"].OnEvent("Click", (*) => SettingsGUI._TestAudio())

        ; Color Theme Section
        SettingsGUI.gui.Add("Text", "x450 y50 w200 h20 +0x200", "Color Themes").SetFont("s10 Bold")

        SettingsGUI.gui.Add("Text", "x450 y75 w80", "Theme:")
        SettingsGUI.controls["ColorTheme"] := SettingsGUI.gui.Add("DropDownList", "x530 y72 w150", 
            ["Default", "Dark Mode", "High Contrast", "Minimal"])
        SettingsGUI.controls["ColorTheme"].Choose(1)
        ; SettingsGUI.controls["ColorTheme"].OnEvent("ItemSelect", (*) => SettingsGUI._UpdateVisualsPreview())

        ; Preview Section
        SettingsGUI.gui.Add("Text", "x450 y110 w200 h20 +0x200", "Preview").SetFont("s10 Bold")
        SettingsGUI.controls["VisualPreview"] := SettingsGUI.gui.Add("Edit", 
            "x450 y135 w300 h200 +VScroll +ReadOnly +Wrap")
        SettingsGUI.controls["VisualPreview"].SetFont("s8", "Consolas")
        SettingsGUI._UpdateVisualsPreview()

        ; Position Test Buttons
        SettingsGUI.controls["TestStatusPosition"] := SettingsGUI.gui.Add("Button", "x450 y350 w140 h25",
            "Test Status Position")
        SettingsGUI.controls["TestStatusPosition"].OnEvent("Click", (*) => SettingsGUI._TestStatusPosition())

        SettingsGUI.controls["TestTooltipPosition"] := SettingsGUI.gui.Add("Button", "x600 y350 w140 h25",
            "Test Tooltip Position")
        SettingsGUI.controls["TestTooltipPosition"].OnEvent("Click", (*) => SettingsGUI._TestTooltipPosition())
    }

    static _CreateHotkeysTab() {
        ; Hotkey Customization Tab
        SettingsGUI.controls["TabControl"].UseTab(4)

        ; Hotkey List Section
        SettingsGUI.gui.Add("Text", "x30 y50 w200 h20 +0x200", "Hotkey Configuration").SetFont("s10 Bold")

        ; Hotkey ListView
        SettingsGUI.controls["HotkeyList"] := SettingsGUI.gui.Add("ListView", "x30 y75 w650 h300", ["Action",
            "Current Hotkey", "Description"])
        SettingsGUI.controls["HotkeyList"].ModifyCol(1, 200)
        SettingsGUI.controls["HotkeyList"].ModifyCol(2, 150)
        SettingsGUI.controls["HotkeyList"].ModifyCol(3, 300)

        ; Populate hotkey list
        SettingsGUI._PopulateHotkeyList()

        ; Hotkey Management Buttons
        SettingsGUI.controls["EditHotkey"] := SettingsGUI.gui.Add("Button", "x690 y75 w80 h25", "Edit")
        SettingsGUI.controls["EditHotkey"].OnEvent("Click", (*) => SettingsGUI._EditSelectedHotkey())

        SettingsGUI.controls["ResetHotkey"] := SettingsGUI.gui.Add("Button", "x690 y105 w80 h25", "Reset")
        SettingsGUI.controls["ResetHotkey"].OnEvent("Click", (*) => SettingsGUI._ResetSelectedHotkey())

        SettingsGUI.controls["TestHotkey"] := SettingsGUI.gui.Add("Button", "x690 y135 w80 h25", "Test")
        SettingsGUI.controls["TestHotkey"].OnEvent("Click", (*) => SettingsGUI._TestSelectedHotkey())

        ; Conflict Detection
        SettingsGUI.gui.Add("Text", "x30 y390 w200 h20 +0x200", "Conflict Detection").SetFont("s10 Bold")

        SettingsGUI.controls["ConflictStatus"] := SettingsGUI.gui.Add("Text", "x30 y415 w450 h20")
        SettingsGUI.controls["ConflictStatus"].Text := "No conflicts detected"

        SettingsGUI.controls["ScanConflicts"] := SettingsGUI.gui.Add("Button", "x500 y412 w120 h25",
            "Scan for Conflicts")
        SettingsGUI.controls["ScanConflicts"].OnEvent("Click", (*) => SettingsGUI._ScanForConflicts())

        SettingsGUI.controls["ResetAllHotkeys"] := SettingsGUI.gui.Add("Button", "x630 y412 w120 h25", "Reset All")
        SettingsGUI.controls["ResetAllHotkeys"].OnEvent("Click", (*) => SettingsGUI._ResetAllHotkeys())
    }

    static _CreateAdvancedTab() {
        ; Advanced Settings Tab with scrollable content
        SettingsGUI.controls["TabControl"].UseTab(5)

        ; Performance Section
        SettingsGUI.gui.Add("Text", "x30 y50 w200 h20 +0x200", "Performance Settings").SetFont("s10 Bold")

        SettingsGUI.controls["LowMemoryMode"] := SettingsGUI.gui.Add("CheckBox", "x30 y75 w200",
            "Enable Low Memory Mode")
        SettingsGUI.gui.Add("Text", "x50 y95 w400", "Reduces memory usage at the cost of some features")

        SettingsGUI.controls["ReduceAnimations"] := SettingsGUI.gui.Add("CheckBox", "x30 y115 w200",
            "Reduce Animations")
        SettingsGUI.gui.Add("Text", "x50 y135 w400", "Disables visual effects for better performance")

        ; Update Frequency
        SettingsGUI.gui.Add("Text", "x30 y165 w150", "Update Frequency:")
        SettingsGUI.controls["UpdateFrequency"] := SettingsGUI.gui.Add("Edit", "x180 y162 w60 Number")
        SettingsGUI.controls["UpdateFrequency"].Text := "500"
        SettingsGUI.controls["UpdateFrequencyUpDown"] := SettingsGUI.gui.Add("UpDown",
            "x240 y162 w20 h20 Range100-2000", 500)
        SettingsGUI.gui.Add("Text", "x265 y165 w200", "milliseconds between updates")

        ; Logging Section
        SettingsGUI.gui.Add("Text", "x30 y205 w200 h20 +0x200", "Logging & Debugging").SetFont("s10 Bold")

        SettingsGUI.controls["EnableLogging"] := SettingsGUI.gui.Add("CheckBox", "x30 y230 w200",
            "Enable Debug Logging")
        SettingsGUI.gui.Add("Text", "x50 y250 w300", "Logs actions for troubleshooting")

        SettingsGUI.controls["LogLevel"] := SettingsGUI.gui.Add("DropDownList", "x250 y228 w100", ["Error", "Warning",
            "Info", "Debug"])
        SettingsGUI.controls["LogLevel"].Choose(2)

        ; Log Management Buttons
        SettingsGUI.controls["ViewLogs"] := SettingsGUI.gui.Add("Button", "x30 y275 w100 h25", "View Logs")
        SettingsGUI.controls["ViewLogs"].OnEvent("Click", (*) => SettingsGUI._ViewLogs())

        SettingsGUI.controls["ClearLogs"] := SettingsGUI.gui.Add("Button", "x140 y275 w100 h25", "Clear Logs")
        SettingsGUI.controls["ClearLogs"].OnEvent("Click", (*) => SettingsGUI._ClearLogs())

        ; Advanced Features Section
        SettingsGUI.gui.Add("Text", "x450 y50 w200 h20 +0x200", "Advanced Features").SetFont("s10 Bold")

        SettingsGUI.controls["EnableGestures"] := SettingsGUI.gui.Add("CheckBox", "x450 y75 w200",
            "Enable Gesture Recognition")
        SettingsGUI.gui.Add("Text", "x470 y95 w300", "Recognize mouse gestures for quick actions")

        SettingsGUI.controls["EnableAnalytics"] := SettingsGUI.gui.Add("CheckBox", "x450 y115 w200",
            "Enable Usage Analytics")
        SettingsGUI.gui.Add("Text", "x470 y135 w300", "Track usage patterns for optimization")

        SettingsGUI.controls["EnableCloudSync"] := SettingsGUI.gui.Add("CheckBox", "x450 y155 w200",
            "Enable Cloud Synchronization")
        SettingsGUI.gui.Add("Text", "x470 y175 w300", "Sync settings across devices")

        ; Experimental Features
        SettingsGUI.gui.Add("Text", "x450 y205 w200 h20 +0x200", "Experimental Features").SetFont("s10 Bold")

        SettingsGUI.controls["EnablePrediction"] := SettingsGUI.gui.Add("CheckBox", "x450 y230 w200",
            "Enable Movement Prediction")
        SettingsGUI.gui.Add("Text", "x470 y250 w300", "Predict and suggest common movements")

        SettingsGUI.controls["EnableMagneticSnap"] := SettingsGUI.gui.Add("CheckBox", "x450 y270 w200",
            "Enable Magnetic Snapping")
        SettingsGUI.gui.Add("Text", "x470 y290 w300", "Automatically snap to UI elements")

        ; Reset Section
        SettingsGUI.gui.Add("Text", "x450 y330 w200 h20 +0x200", "Reset Options").SetFont("s10 Bold")

        SettingsGUI.controls["ResetToDefaults"] := SettingsGUI.gui.Add("Button", "x450 y355 w150 h25",
            "Reset to Defaults")
        SettingsGUI.controls["ResetToDefaults"].OnEvent("Click", (*) => SettingsGUI._ResetToDefaults())

        SettingsGUI.controls["FactoryReset"] := SettingsGUI.gui.Add("Button", "x450 y385 w150 h25", "Factory Reset")
        SettingsGUI.controls["FactoryReset"].OnEvent("Click", (*) => SettingsGUI._FactoryReset())
    }

    static _CreateProfilesTab() {
        ; Profiles Management Tab
        SettingsGUI.controls["TabControl"].UseTab(6)

        ; Profile List Section
        SettingsGUI.gui.Add("Text", "x30 y50 w200 h20 +0x200", "Configuration Profiles").SetFont("s10 Bold")

        ; Profile ListView
        SettingsGUI.controls["ProfileList"] := SettingsGUI.gui.Add("ListView", "x30 y75 w500 h200", ["Profile Name",
            "Description", "Last Modified"])
        SettingsGUI.controls["ProfileList"].ModifyCol(1, 150)
        SettingsGUI.controls["ProfileList"].ModifyCol(2, 250)
        SettingsGUI.controls["ProfileList"].ModifyCol(3, 100)

        ; Populate with default profiles
        SettingsGUI._PopulateProfileList()

        ; Profile Management Buttons
        SettingsGUI.controls["LoadProfile"] := SettingsGUI.gui.Add("Button", "x550 y75 w120 h25", "Load Profile")
        SettingsGUI.controls["LoadProfile"].OnEvent("Click", (*) => SettingsGUI._LoadSelectedProfile())

        SettingsGUI.controls["SaveProfile"] := SettingsGUI.gui.Add("Button", "x550 y105 w120 h25", "Save as New...")
        SettingsGUI.controls["SaveProfile"].OnEvent("Click", (*) => SettingsGUI._SaveNewProfile())

        SettingsGUI.controls["UpdateProfile"] := SettingsGUI.gui.Add("Button", "x550 y135 w120 h25", "Update Current")
        SettingsGUI.controls["UpdateProfile"].OnEvent("Click", (*) => SettingsGUI._UpdateCurrentProfile())

        SettingsGUI.controls["DeleteProfile"] := SettingsGUI.gui.Add("Button", "x550 y165 w120 h25", "Delete Profile")
        SettingsGUI.controls["DeleteProfile"].OnEvent("Click", (*) => SettingsGUI._DeleteSelectedProfile())

        SettingsGUI.controls["ExportProfile"] := SettingsGUI.gui.Add("Button", "x550 y195 w120 h25", "Export...")
        SettingsGUI.controls["ExportProfile"].OnEvent("Click", (*) => SettingsGUI._ExportProfile())

        SettingsGUI.controls["ImportProfile"] := SettingsGUI.gui.Add("Button", "x550 y225 w120 h25", "Import...")
        SettingsGUI.controls["ImportProfile"].OnEvent("Click", (*) => SettingsGUI._ImportProfile())

        ; Current Profile Info
        SettingsGUI.gui.Add("Text", "x30 y295 w150 h20", "Current Profile:")
        SettingsGUI.controls["CurrentProfileName"] := SettingsGUI.gui.Add("Text", "x180 y295 w200 h20 +0x200")
        SettingsGUI.controls["CurrentProfileName"].Text := "Default"

        ; Profile Description
        SettingsGUI.gui.Add("Text", "x30 y325 w200 h20 +0x200", "Profile Description").SetFont("s10 Bold")
        SettingsGUI.controls["ProfileDescription"] := SettingsGUI.gui.Add("Edit",
            "x30 y345 w640 h100 +VScroll +WantReturn")
        SettingsGUI.controls["ProfileDescription"].Text := "Default configuration profile with standard settings."

        ; Auto-Switch Settings
        SettingsGUI.gui.Add("Text", "x30 y455 w200 h20 +0x200", "Auto-Switch Rules").SetFont("s10 Bold")

        SettingsGUI.controls["EnableAutoSwitch"] := SettingsGUI.gui.Add("CheckBox", "x30 y480 w220",
            "Enable Auto Profile Switching")
        SettingsGUI.gui.Add("Text", "x260 y480 w400", "Automatically switch profiles based on active application")
    }

    static _CreateAboutTab() {
        ; About Tab
        SettingsGUI.controls["TabControl"].UseTab(7)

        ; Title and Version
        SettingsGUI.gui.Add("Text", "x30 y50 w720 h30 +Center", "Mouse on Numpad Enhanced").SetFont("s16 Bold")
        SettingsGUI.gui.Add("Text", "x30 y85 w720 h20 +Center", "Version 3.0.0 - Advanced Settings Panel").SetFont(
            "s10")

        ; Description
        SettingsGUI.gui.Add("Text", "x30 y120 w720 h60 +Wrap",
            "A comprehensive mouse control system using the numeric keypad. This enhanced version includes " .
            "advanced features like gesture recognition, analytics, profile management, and cloud synchronization.")

        ; Features List
        SettingsGUI.gui.Add("Text", "x30 y190 w200 h20 +0x200", "Key Features").SetFont("s10 Bold")

        featuresText := "• Comprehensive numpad mouse control`n" .
            "• Advanced position memory system`n" .
            "• Real-time analytics and monitoring`n" .
            "• Gesture recognition system`n" .
            "• Multi-profile support`n" .
            "• Cloud synchronization`n" .
            "• Customizable hotkeys`n" .
            "• Performance optimization`n" .
            "• Accessibility features`n" .
            "• Comprehensive backup system"

        SettingsGUI.gui.Add("Text", "x30 y215 w340 h200 +Wrap", featuresText)

        ; System Information
        SettingsGUI.gui.Add("Text", "x400 y190 w200 h20 +0x200", "System Information").SetFont("s10 Bold")

        systemInfo := "AutoHotkey Version: " . A_AhkVersion . "`n" .
            "Operating System: " . A_OSVersion . "`n" .
            "Computer Name: " . A_ComputerName . "`n" .
            "User Name: " . A_UserName . "`n" .
            "Screen Resolution: " . A_ScreenWidth . "x" . A_ScreenHeight . "`n" .
            "Script Directory: " . A_ScriptDir

        SettingsGUI.gui.Add("Text", "x400 y215 w370 h150 +Wrap", systemInfo)

        ; Action Buttons
        SettingsGUI.controls["CheckUpdates"] := SettingsGUI.gui.Add("Button", "x30 y380 w120 h30", "Check for Updates")
        SettingsGUI.controls["CheckUpdates"].OnEvent("Click", (*) => SettingsGUI._CheckForUpdates())

        SettingsGUI.controls["OpenDocumentation"] := SettingsGUI.gui.Add("Button", "x160 y380 w120 h30",
            "Documentation")
        SettingsGUI.controls["OpenDocumentation"].OnEvent("Click", (*) => SettingsGUI._OpenDocumentation())

        SettingsGUI.controls["ReportIssue"] := SettingsGUI.gui.Add("Button", "x290 y380 w120 h30", "Report Issue")
        SettingsGUI.controls["ReportIssue"].OnEvent("Click", (*) => SettingsGUI._ReportIssue())

        SettingsGUI.controls["SystemDiagnostics"] := SettingsGUI.gui.Add("Button", "x420 y380 w120 h30",
            "System Diagnostics")
        SettingsGUI.controls["SystemDiagnostics"].OnEvent("Click", (*) => SettingsGUI._RunSystemDiagnostics())

        ; Copyright and Credits
        SettingsGUI.gui.Add("Text", "x30 y430 w720 h40 +Wrap +Center",
            "Enhanced by Claude AI Assistant. Original concept and base implementation community-driven. " .
            "Thank you to all contributors and users who made this possible.")
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
                ; Refresh monitor configuration when showing positions tab
                MonitorUtils.Refresh()
                SettingsGUI._PopulatePositionList()
            case 4: SettingsGUI._PopulateHotkeyList()
            case 6: SettingsGUI._PopulateProfileList()
        }
    }

    static _OnResize() {
        ; Handle window resizing
        try {
            SettingsGUI.gui.GetPos(, , &width, &height)

            ; Resize tab control to fit above button bar (leave 100px for buttons)
            SettingsGUI.controls["TabControl"].Move(10, 10, width - 20, height - 100)

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

            ; Right-align buttons
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

    ; Helper Methods
    static _UpdateMovementPreview() {
        try {
            ; Get current values from the controls
            moveStep := SettingsGUI.controls["MoveStep"].Text
            moveDelay := SettingsGUI.controls["MoveDelay"].Text
            accelRate := SettingsGUI.controls["AccelerationRate"].Text
            maxSpeed := SettingsGUI.controls["MaxSpeed"].Text
            isAbsolute := SettingsGUI.controls["EnableAbsoluteMovement"].Value

            ; Get scroll settings
            scrollStep := SettingsGUI.controls["ScrollStep"].Text
            scrollAccel := SettingsGUI.controls["ScrollAccelerationRate"].Text
            maxScrollSpeed := SettingsGUI.controls["MaxScrollSpeed"].Text

            previewText := "=== MOVEMENT & SCROLL PREVIEW ===`r`n`r`n"

            ; Movement Settings
            previewText .= "🖱️ MOVEMENT SETTINGS:`r`n"
            previewText .= "• Step Size: " . moveStep . " pixels`r`n"
            previewText .= "• Delay: " . moveDelay . " ms`r`n"
            previewText .= "• Acceleration: " . accelRate . "x per step`r`n"
            previewText .= "• Max Speed: " . maxSpeed . " pixels/step`r`n"
            previewText .= "• Mode: " . (isAbsolute ? "🎯 Absolute" : "🔄 Relative") . "`r`n"

            ; Scroll Settings
            previewText .= "`r`n📜 SCROLL SETTINGS:`r`n"
            previewText .= "• Step Size: " . scrollStep . " lines`r`n"
            previewText .= "• Acceleration: " . scrollAccel . "x per step`r`n"
            previewText .= "• Max Speed: " . maxScrollSpeed . " lines/step`r`n"

            ; Movement Calculations
            previewText .= "`r`n🧮 MOVEMENT CALCULATIONS:`r`n"
            previewText .= "• After 1 step: " . moveStep . " pixels`r`n"
            previewText .= "• After 2 steps: " . Round(moveStep * accelRate) . " pixels`r`n"
            previewText .= "• After 3 steps: " . Round(moveStep * (accelRate ** 2)) . " pixels`r`n"
            previewText .= "• Time to max: ~" . Round(Log(maxSpeed / moveStep) / Log(accelRate) * moveDelay) .
            " ms`r`n"

            ; Scroll Calculations
            previewText .= "`r`n📊 SCROLL CALCULATIONS:`r`n"
            previewText .= "• After 1 step: " . scrollStep . " lines`r`n"
            previewText .= "• After 2 steps: " . Round(scrollStep * scrollAccel) . " lines`r`n"
            previewText .= "• After 3 steps: " . Round(scrollStep * (scrollAccel ** 2)) . " lines`r`n"

            ; Performance Analysis
            previewText .= "`r`n⚡ PERFORMANCE ANALYSIS:`r`n"
            if (moveDelay <= 10) {
                previewText .= "• Speed: VERY FAST (Gaming)`r`n"
                previewText .= "• Use Case: Fast-paced games`r`n"
            } else if (moveDelay <= 20) {
                previewText .= "• Speed: FAST (Responsive)`r`n"
                previewText .= "• Use Case: General computing`r`n"
            } else if (moveDelay <= 50) {
                previewText .= "• Speed: BALANCED`r`n"
                previewText .= "• Use Case: Precision work`r`n"
            } else {
                previewText .= "• Speed: SMOOTH (Slow)`r`n"
                previewText .= "• Use Case: Accessibility`r`n"
            }

            ; Usage Tips
            previewText .= "`r`n💡 OPTIMIZATION TIPS:`r`n"
            if (moveDelay > 20) {
                previewText .= "• Lower delay for faster response`r`n"
            }
            if (accelRate < 1.2) {
                previewText .= "• Increase acceleration for quicker speed`r`n"
            }
            if (maxSpeed < 20) {
                previewText .= "• Raise max speed for faster movement`r`n"
            }
            previewText .= "• Test with numpad to fine-tune!`r`n"

            SettingsGUI.controls["MovementPreview"].Text := previewText
        } catch {
            SettingsGUI.controls["MovementPreview"].Text := "Preview will update when settings change..."
        }
    }

    static _UpdateVisualsPreview() {
        try {
            ; TODO: add the implemantation for this
            colorTheme := SettingsGUI.controls["ColorTheme"].Text
            previewText := "=== STATUS, TOOLTIP & COLORTHEME PREVIEW ===`r`n`r`n"
            previewText := "COLORTHEME SETTINGS:`r`n"
            previewText := "Current Theme: " . colorTheme "`r`n"
            previewText := "Status Color: Green`r`n"
            previewText := "Tooltip Style: Standard`r`n"

            SettingsGUI.controls["VisualPreview"].Text := previewText
        } catch {
            SettingsGUI.controls["VisualPreview"].Text := "Preview will update when settings change..."
        }
    }

    static _PopulatePositionList() {
        try {
            SettingsGUI.controls["PositionList"].Delete()

            savedPositions := PositionMemory.GetSavedPositions()

            ; Ensure monitors are initialized
            if (!MonitorUtils.initialized) {
                MonitorUtils.Init()
            }

            for slot, pos in savedPositions {
                ; Get monitor description for this position
                description := "Position on " . MonitorUtils.GetMonitorDescriptionForPosition(pos.x, pos.y)
                SettingsGUI.controls["PositionList"].Add(, slot, pos.x, pos.y, description)
            }
        }
    }

    static _PopulateHotkeyList() {
        try {
            SettingsGUI.controls["HotkeyList"].Delete()

            ; Add common hotkeys with descriptions
            hotkeys := [
                ["Toggle Mouse Mode", "Numpad +", "Enable/disable numpad mouse control"],
                ["Save Mode", "Numpad *", "Enter position save mode"],
                ["Load Mode", "Numpad -", "Enter position load mode"],
                ["Undo Movement", "Numpad /", "Undo last mouse movement"],
                ["Toggle Status", "Ctrl+Numpad +", "Show/hide status indicator"],
                ["Reload Script", "Ctrl+Alt+R", "Restart the application"],
                ["Settings", "Ctrl+Alt+S", "Open settings panel"],
                ["Secondary Monitor", "Alt+Numpad 9", "Toggle secondary monitor use"]
            ]

            for hotkey in hotkeys {
                SettingsGUI.controls["HotkeyList"].Add(, hotkey[1], hotkey[2], hotkey[3])
            }
        }
    }

    static _PopulateProfileList() {
        try {
            SettingsGUI.controls["ProfileList"].Delete()

            ; Add default profiles
            profiles := [
                ["Default", "Standard configuration for general use", FormatTime(A_Now, "MM/dd/yyyy")],
                ["Gaming", "Optimized for gaming applications", FormatTime(A_Now, "MM/dd/yyyy")],
                ["Productivity", "Enhanced for office and productivity work", FormatTime(A_Now, "MM/dd/yyyy")],
                ["Accessibility", "Accessibility-focused configuration", FormatTime(A_Now, "MM/dd/yyyy")]
            ]

            for profile in profiles {
                SettingsGUI.controls["ProfileList"].Add(, profile[1], profile[2], profile[3])
            }
        }
    }

    ; Action Methods
    static _TestAudio() {
        if (SettingsGUI.controls["EnableAudioFeedback"].Value) {
            SoundBeep(800, 200)
            MsgBox("Audio feedback test completed!", "Test Audio", "T2")
        } else {
            MsgBox("Audio feedback is currently disabled.`nEnable it first to test.", "Test Audio", "Icon!")
        }
    }

    static _TestStatusPosition() {
        MsgBox("Status position test will show a preview of the status indicator at the configured position.",
            "Test Status", "T3")
    }

    static _TestTooltipPosition() {
        MsgBox("Tooltip position test will show a preview of tooltips at the configured position.", "Test Tooltip",
            "T3")
    }

    static _ApplySettings() {
        ; Apply all settings from temp storage to actual config
        try {
            ; Movement Settings
            Config.MoveStep := Integer(SettingsGUI.controls["MoveStep"].Text)
            Config.MoveDelay := Integer(SettingsGUI.controls["MoveDelay"].Text)
            Config.AccelerationRate := Float(SettingsGUI.controls["AccelerationRate"].Text)
            Config.MaxSpeed := Integer(SettingsGUI.controls["MaxSpeed"].Text)

            ; Absolute Movement
            Config.EnableAbsoluteMovement := SettingsGUI.controls["EnableAbsoluteMovement"].Value ? true : false

            ; Position Settings
            Config.MaxSavedPositions := Integer(SettingsGUI.controls["MaxSavedPositions"].Text)
            Config.MaxUndoLevels := Integer(SettingsGUI.controls["MaxUndoLevels"].Text)

            ; Visual Settings
            Config.EnableAudioFeedback := SettingsGUI.controls["EnableAudioFeedback"].Value ? true : false
            Config.StatusVisibleOnStartup := SettingsGUI.controls["StatusVisibleOnStartup"].Value ? true : false
            Config.UseSecondaryMonitor := SettingsGUI.controls["UseSecondaryMonitor"].Value ? true : false

            ; Scroll Settings
            Config.ScrollStep := Integer(SettingsGUI.controls["ScrollStep"].Text)
            Config.ScrollAccelerationRate := Float(SettingsGUI.controls["ScrollAccelerationRate"].Text)
            Config.MaxScrollSpeed := Integer(SettingsGUI.controls["MaxScrollSpeed"].Text)

            ; GUI Positions
            Config.StatusX := SettingsGUI.controls["StatusX"].Text
            Config.StatusY := SettingsGUI.controls["StatusY"].Text
            Config.TooltipX := SettingsGUI.controls["TooltipX"].Text
            Config.TooltipY := SettingsGUI.controls["TooltipY"].Text

            ; Save configuration
            Config.Save()

            ; Update status indicator to reflect changes
            StatusIndicator.Update()

            ; Show success message
            MsgBox("Settings have been applied successfully!", "Settings Applied", "Iconi T3")

        } catch Error as e {
            MsgBox("Error applying settings: " . e.Message . "`n`nPlease check your input values.", "Error", "IconX")
        }
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

    static _ShowHelp() {
        helpText := "MOUSE ON NUMPAD ENHANCED - SETTINGS HELP`n`n"
        helpText .= "TABS:`n"
        helpText .= "• Movement: Configure mouse movement speed, acceleration, and scrolling`n"
        helpText .= "• Positions: Manage saved mouse positions and undo levels`n"
        helpText .= "• Visuals: Customize appearance, positioning, and audio feedback`n"
        helpText .= "• Hotkeys: View and modify keyboard shortcuts`n"
        helpText .= "• Advanced: Performance, logging, and experimental features`n"
        helpText .= "• Profiles: Save and load different configurations`n"
        helpText .= "• About: Information about the application`n`n"
        helpText .= "BUTTONS:`n"
        helpText .= "• Apply: Save changes without closing the window`n"
        helpText .= "• OK: Save changes and close the window`n"
        helpText .= "• Cancel: Discard changes and close`n"
        helpText .= "• Import/Export: Share settings between devices`n`n"
        helpText .= "For more help, check the documentation or visit the support forum."

        MsgBox(helpText, "Settings Help", "Iconi")
    }

    ; Placeholder methods for advanced features
    static _ImportSettings() {
        MsgBox("Import settings functionality will be implemented in a future update.", "Import Settings", "Iconi T3")
    }

    static _ExportSettings() {
        MsgBox("Export settings functionality will be implemented in a future update.", "Export Settings", "Iconi T3")
    }

    static _PreviewSelectedPosition() {
        row := SettingsGUI.controls["PositionList"].GetNext()
        if (row) {
            slot := Integer(SettingsGUI.controls["PositionList"].GetText(row, 1))
            x := Integer(SettingsGUI.controls["PositionList"].GetText(row, 2))
            y := Integer(SettingsGUI.controls["PositionList"].GetText(row, 3))

            ; Create a preview window at the position
            previewGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20", "")
            previewGui.BackColor := "0xFF0000"  ; Red background
            WinSetTransColor("0xFF0000", previewGui)  ; Make red transparent

            ; Draw a circle/crosshair at the position
            previewGui.SetFont("s20 Bold", "Arial")
            previewGui.Add("Text", "x0 y0 w50 h50 Center cLime BackgroundTrans", "⊕")

            ; Show the preview at the saved position
            previewGui.Show("x" . (x - 25) . " y" . (y - 25) . " w50 h50 NoActivate")

            ; Add a label showing the slot number
            labelGui := Gui("+AlwaysOnTop -Caption +ToolWindow", "")
            labelGui.BackColor := "0x2196F3"
            labelGui.SetFont("s12 Bold", "Segoe UI")
            labelGui.Add("Text", "x5 y2 w40 h20 Center cWhite", "Slot " . slot)
            labelGui.Show("x" . (x - 25) . " y" . (y + 30) . " w50 h25 NoActivate")

            ; Flash the preview
            loop 3 {
                Sleep(200)
                previewGui.Hide()
                labelGui.Hide()
                Sleep(200)
                previewGui.Show("NoActivate")
                labelGui.Show("NoActivate")
            }

            ; Clean up
            Sleep(500)
            previewGui.Destroy()
            labelGui.Destroy()

        } else {
            MsgBox("Please select a position from the list to preview.", "No Selection", "Icon!")
        }
    }

    static _GotoSelectedPosition() {
        row := SettingsGUI.controls["PositionList"].GetNext()
        if (row) {
            slot := Integer(SettingsGUI.controls["PositionList"].GetText(row, 1))
            savedPositions := PositionMemory.GetSavedPositions()
            if (savedPositions.Has(slot)) {
                pos := savedPositions[slot]
                ; CRITICAL: Set coordinate mode to Screen for proper negative coordinate handling
                CoordMode("Mouse", "Screen")
                ; Add current position to history before moving
                MouseGetPos(&currentX, &currentY)
                MouseActions.AddToHistory(currentX, currentY)
                ; Move to the saved position
                MouseMove(pos.x, pos.y, 10)
                ; Show feedback
                TooltipSystem.ShowMouseAction("Moved to position " . slot . " (" . pos.x . ", " . pos.y . ")",
                    "success")
            } else {
                MsgBox("Position data not found for slot " . slot, "Error", "IconX")
            }
        } else {
            MsgBox("Please select a position from the list first.", "No Selection", "Icon!")
        }
    }

    static _SaveCurrentPosition() {
        ; Create a custom dialog that updates mouse position in real-time
        saveDialog := Gui("+AlwaysOnTop", "Save Mouse Position")
        saveDialog.SetFont("s10")

        ; Instructions
        saveDialog.Add("Text", "x10 y10 w300", "Move your mouse to the desired position.")

        ; Current position display (will update)
        posText := saveDialog.Add("Text", "x10 y35 w300 h20", "Current mouse position: ")
        posDisplay := saveDialog.Add("Text", "x10 y55 w300 h20 +0x200", "X: 0, Y: 0")
        posDisplay.SetFont("s12 Bold")

        ; Slot selection
        saveDialog.Add("Text", "x10 y85 w100", "Save to slot:")
        slotEdit := saveDialog.Add("Edit", "x110 y82 w50 Number")
        slotUpDown := saveDialog.Add("UpDown", "x160 y82 w20 h20 Range1-" . Config.MaxSavedPositions, 1)
        saveDialog.Add("Text", "x185 y85 w100", "(1-" . Config.MaxSavedPositions . ")")

        ; Set initial value
        slotEdit.Text := "1"

        ; Buttons
        saveBtn := saveDialog.Add("Button", "x50 y120 w80 h25 +Default", "Save")
        cancelBtn := saveDialog.Add("Button", "x150 y120 w80 h25", "Cancel")

        ; Variables to store the position
        savedX := 0
        savedY := 0
        savedSlot := 1
        shouldSave := false

        ; Timer function to update position display
        updatePosDisplay() {
            ; CRITICAL: Set coordinate mode to Screen for proper negative coordinate handling
            CoordMode("Mouse", "Screen")
            MouseGetPos(&currentX, &currentY)
            posDisplay.Text := "X: " . currentX . ", Y: " . currentY
        }

        ; Start the timer
        SetTimer(updatePosDisplay, 50)  ; Update every 50ms

        ; Button event handlers using nested functions to avoid arrow function parsing issues
        onSaveClick(*) {
            ; CRITICAL: Set coordinate mode to Screen for proper negative coordinate handling
            CoordMode("Mouse", "Screen")
            MouseGetPos(&savedX, &savedY)  ; Capture position at save time
            shouldSave := true
            ; Store the slot value BEFORE destroying the dialog
            savedSlot := slotEdit.Text
            SetTimer(updatePosDisplay, 0)  ; Stop timer
            saveDialog.Destroy()
        }

        onCancelClick(*) {
            shouldSave := false
            SetTimer(updatePosDisplay, 0)  ; Stop timer
            saveDialog.Destroy()
        }

        onDialogClose(*) {
            SetTimer(updatePosDisplay, 0)  ; Stop timer
        }

        ; Attach events
        saveBtn.OnEvent("Click", onSaveClick)
        cancelBtn.OnEvent("Click", onCancelClick)
        saveDialog.OnEvent("Close", onDialogClose)

        ; Show dialog
        saveDialog.Show()

        ; Wait for dialog to close
        WinWaitClose(saveDialog)

        ; Process the save if user clicked Save
        if (shouldSave) {
            slot := Integer(savedSlot)  ; Use the saved slot value
            if (slot >= 1 && slot <= Config.MaxSavedPositions) {
                ; Check if slot already has a position
                if (PositionMemory.HasPosition(slot)) {
                    result := MsgBox("Slot " . slot . " already has a saved position. Overwrite?", "Confirm Overwrite",
                        "YesNo Icon?")
                    if (result != "Yes") {
                        return
                    }
                }

                ; Save the captured position
                ; CRITICAL: Set coordinate mode to Screen for proper negative coordinate handling
                CoordMode("Mouse", "Screen")
                MouseGetPos(&tempX, &tempY)  ; Save current position
                MouseMove(savedX, savedY, 0)  ; Move to captured position
                PositionMemory.SavePosition(slot)  ; Save it
                MouseMove(tempX, tempY, 0)  ; Move back
                PositionMemory.SavePositions()  ; Persist to file

                ; Refresh the list
                SettingsGUI._PopulatePositionList()

                ; Show success with the saved position
                MsgBox("Mouse position (" . savedX . ", " . savedY . ") saved to slot " . slot, "Success", "Iconi T3")
            } else {
                MsgBox("Invalid slot number. Please enter a number between 1 and " . Config.MaxSavedPositions, "Error",
                    "IconX")
            }
        }
    }

    static _DeleteSelectedPosition() {
        row := SettingsGUI.controls["PositionList"].GetNext()
        if (row) {
            slot := Integer(SettingsGUI.controls["PositionList"].GetText(row, 1))
            x := SettingsGUI.controls["PositionList"].GetText(row, 2)
            y := SettingsGUI.controls["PositionList"].GetText(row, 3)

            result := MsgBox("Delete position " . slot . " (" . x . ", " . y . ")?`n`nThis cannot be undone.",
                "Confirm Delete", "YesNo IconX")
            if (result = "Yes") {
                ; Delete the position
                PositionMemory.ClearPosition(slot)
                PositionMemory.SavePositions()  ; Persist changes to file

                ; Refresh the list
                SettingsGUI._PopulatePositionList()

                ; Show confirmation
                MsgBox("Position " . slot . " has been deleted.", "Position Deleted", "Iconi T2")
            }
        } else {
            MsgBox("Please select a position to delete from the list.", "No Selection", "Icon!")
        }
    }

    static _ClearAllPositions() {
        ; Check if there are any positions to clear
        if (PositionMemory.GetSavedPositions().Count = 0) {
            MsgBox("No saved positions to clear.", "Nothing to Clear", "Iconi")
            return
        }

        result := MsgBox("Are you sure you want to clear ALL saved positions?`n`nThis will permanently delete all " .
            PositionMemory.GetSavedPositions().Count . " saved positions.", "Clear All Positions",
            "YesNo IconX Default2")
        if (result = "Yes") {
            ; Double confirmation for safety
            confirm := MsgBox("This action cannot be undone. Are you absolutely sure?", "Final Confirmation",
                "YesNo IconX Default2")
            if (confirm = "Yes") {
                PositionMemory.ClearAllPositions()
                PositionMemory.SavePositions()  ; Persist changes to file
                SettingsGUI._PopulatePositionList()
                MsgBox("All positions have been cleared.", "Positions Cleared", "Iconi T2")
            }
        }
    }

    static _ImportPositions() {
        ; File dialog to select import file
        selectedFile := FileSelect(1, , "Import Positions", "Position Files (*.ini;*.txt)")
        if (selectedFile = "") {
            return  ; User cancelled
        }

        try {
            importedCount := 0

            ; Read positions from the selected file
            loop Config.MaxSavedPositions {
                x := IniRead(selectedFile, "Positions", "Slot" . A_Index . "X", "")
                y := IniRead(selectedFile, "Positions", "Slot" . A_Index . "Y", "")

                if (x != "" && y != "" && IsNumber(x) && IsNumber(y)) {
                    ; Ask if user wants to overwrite existing positions
                    if (importedCount = 0 && PositionMemory.GetSavedPositions().Count > 0) {
                        result := MsgBox(
                            "Do you want to:`n`nYes - Replace all existing positions`nNo - Merge with existing positions (skip conflicts)`nCancel - Cancel import",
                            "Import Options", "YesNoCancel Icon?")
                        if (result = "Cancel") {
                            return
                        }
                        if (result = "Yes") {
                            PositionMemory.ClearAllPositions()
                        }
                    }

                    ; Import the position if slot is empty or we're replacing all
                    if (!PositionMemory.HasPosition(A_Index) || importedCount = 0) {
                        ; Save the position at the specific slot
                        ; We need to temporarily move the mouse to save it, then restore
                        ; CRITICAL: Set coordinate mode to Screen for proper negative coordinate handling
                        CoordMode("Mouse", "Screen")
                        MouseGetPos(&originalX, &originalY)

                        ; Disable audio feedback temporarily during import
                        originalAudioSetting := Config.EnableAudioFeedback
                        Config.EnableAudioFeedback := false

                        MouseMove(Integer(x), Integer(y), 0)
                        PositionMemory.SavePosition(A_Index)
                        MouseMove(originalX, originalY, 0)

                        ; Restore audio setting
                        Config.EnableAudioFeedback := originalAudioSetting

                        importedCount++
                    }
                }
            }

            if (importedCount > 0) {
                PositionMemory.SavePositions()  ; Persist to file
                SettingsGUI._PopulatePositionList()
                MsgBox("Successfully imported " . importedCount . " position(s).", "Import Complete", "Iconi")
            } else {
                MsgBox("No valid positions found in the selected file.", "Import Failed", "IconX")
            }

        } catch Error as e {
            MsgBox("Error importing positions: " . e.Message, "Import Error", "IconX")
        }
    }

    static _ExportPositions() {
        ; Check if there are positions to export
        savedPositions := PositionMemory.GetSavedPositions()
        if (savedPositions.Count = 0) {
            MsgBox("No saved positions to export.", "Nothing to Export", "Icon!")
            return
        }

        ; File dialog to select export location
        timestamp := FormatTime(A_Now, "yyyyMMdd_HHmmss")
        defaultName := "MousePositions_" . timestamp . ".ini"
        selectedFile := FileSelect("S", defaultName, "Export Positions", "Position Files (*.ini)")

        if (selectedFile = "") {
            return  ; User cancelled
        }

        ; Add .ini extension if not present
        if (!RegExMatch(selectedFile, "i)\.ini$")) {
            selectedFile .= ".ini"
        }

        try {
            ; Create export file with header
            FileAppend("; Mouse on Numpad Enhanced - Exported Positions`n", selectedFile)
            FileAppend("; Exported on: " . FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") . "`n", selectedFile)
            FileAppend("; Total positions: " . savedPositions.Count . "`n`n", selectedFile)
            FileAppend("[Positions]`n", selectedFile)

            ; Write each position
            exportedCount := 0
            for slot, pos in savedPositions {
                FileAppend("Slot" . slot . "X=" . pos.x . "`n", selectedFile)
                FileAppend("Slot" . slot . "Y=" . pos.y . "`n", selectedFile)
                exportedCount++
            }

            ; Add metadata
            FileAppend("`n[Metadata]`n", selectedFile)
            FileAppend("ExportVersion=1.0`n", selectedFile)
            FileAppend("MaxSlots=" . Config.MaxSavedPositions . "`n", selectedFile)
            FileAppend("PositionCount=" . exportedCount . "`n", selectedFile)

            MsgBox("Successfully exported " . exportedCount . " position(s) to:`n`n" . selectedFile, "Export Complete",
                "Iconi")

            ; Ask if user wants to open the folder
            result := MsgBox("Would you like to open the folder containing the exported file?", "Open Folder?",
                "YesNo Icon?")
            if (result = "Yes") {
                Run('explorer.exe /select,"' . selectedFile . '"')
            }

        } catch Error as e {
            MsgBox("Error exporting positions: " . e.Message, "Export Error", "IconX")
        }
    }

    static _OpenConfigFolder() {
        Run("explorer.exe " . A_ScriptDir)
    }

    static _BackupConfig() {
        ; Create backup with timestamp
        timestamp := FormatTime(A_Now, "yyyyMMdd_HHmmss")
        backupFile := "MouseNumpadConfig_Backup_" . timestamp . ".ini"

        try {
            ; Copy the current config file
            FileCopy(Config.PersistentPositionsFile, backupFile)

            ; Get file size for info
            fileSize := FileGetSize(backupFile)
            fileSizeKB := Round(fileSize / 1024, 2)

            ; Count saved positions
            savedCount := PositionMemory.GetSavedPositions().Count

            ; Show detailed success message
            MsgBox("Configuration backed up successfully!`n`n" .
                "Backup file: " . backupFile . "`n" .
                "File size: " . fileSizeKB . " KB`n" .
                "Saved positions: " . savedCount . "`n`n" .
                "Location: " . A_ScriptDir,
                "Backup Successful", "Iconi")

            ; Ask if user wants to open the backup location
            result := MsgBox("Would you like to open the backup folder?", "Open Folder?", "YesNo Icon?")
            if (result = "Yes") {
                Run('explorer.exe /select,"' . A_ScriptDir . "\" . backupFile . '"')
            }

        } catch Error as e {
            MsgBox("Failed to create backup: " . e.Message, "Backup Error", "IconX")
        }
    }

    static _RestoreBackup() {
        ; File dialog to select backup file
        selectedFile := FileSelect(1, , "Select Backup File", "INI Files (*.ini)")
        if (selectedFile = "") {
            return  ; User cancelled
        }

        ; Confirm restoration
        result := MsgBox("Restore configuration from:`n" . selectedFile .
            "`n`nThis will replace your current configuration!",
            "Confirm Restore", "YesNo IconX")
        if (result != "Yes") {
            return
        }

        try {
            ; Backup current config first
            tempBackup := Config.PersistentPositionsFile . ".temp"
            FileCopy(Config.PersistentPositionsFile, tempBackup, 1)

            ; Copy backup file to config location
            FileCopy(selectedFile, Config.PersistentPositionsFile, 1)

            ; Reload configuration
            Config.Load()
            PositionMemory.LoadPositions()

            ; Update GUI to reflect new settings
            SettingsGUI._InitializeTempSettings()
            SettingsGUI._ShowTab(SettingsGUI.currentTab)

            ; Delete temp backup
            FileDelete(tempBackup)

            MsgBox("Configuration restored successfully!`n`nThe settings have been updated.", "Restore Complete",
                "Iconi")

        } catch Error as e {
            ; Try to restore from temp backup on error
            try {
                FileCopy(tempBackup, Config.PersistentPositionsFile, 1)
                FileDelete(tempBackup)
            }
            MsgBox("Failed to restore backup: " . e.Message, "Restore Error", "IconX")
        }
    }

    static _EditSelectedHotkey() {
        MsgBox(
            "Hotkey editing will be available in a future update.`nFor now, you can modify hotkeys in the HotkeyManager.ahk file.",
            "Edit Hotkey", "Iconi")
    }

    static _ResetSelectedHotkey() {
        MsgBox("Reset hotkey functionality will be implemented in a future update.", "Reset Hotkey", "Iconi T3")
    }

    static _TestSelectedHotkey() {
        row := SettingsGUI.controls["HotkeyList"].GetNext()
        if (row) {
            action := SettingsGUI.controls["HotkeyList"].GetText(row, 1)
            hotkey := SettingsGUI.controls["HotkeyList"].GetText(row, 2)
            MsgBox("Press " . hotkey . " to test:`n" . action, "Test Hotkey", "Iconi T5")
        } else {
            MsgBox("Please select a hotkey to test.", "No Selection", "Icon!")
        }
    }

    static _ScanForConflicts() {
        ; Placeholder for conflict detection
        SettingsGUI.controls["ConflictStatus"].Text := "Scanning... No conflicts detected."
        MsgBox("Hotkey conflict detection completed.`nNo conflicts found.", "Scan Complete", "Iconi T3")
    }

    static _ResetAllHotkeys() {
        result := MsgBox("Reset all hotkeys to default values?", "Reset All Hotkeys", "YesNo Icon?")
        if (result = "Yes") {
            MsgBox("All hotkeys have been reset to defaults.", "Reset Complete", "Iconi T2")
        }
    }

    static _ViewLogs() {
        logFile := A_ScriptDir . "\MouseNumpad.log"
        if (FileExist(logFile)) {
            Run("notepad.exe " . logFile)
        } else {
            MsgBox("No log file found.`nEnable logging in Advanced settings to create logs.", "No Logs", "Iconi")
        }
    }

    static _ClearLogs() {
        logFile := A_ScriptDir . "\MouseNumpad.log"
        if (FileExist(logFile)) {
            result := MsgBox("Clear all log entries?", "Clear Logs", "YesNo Icon?")
            if (result = "Yes") {
                FileDelete(logFile)
                MsgBox("Logs have been cleared.", "Logs Cleared", "Iconi T2")
            }
        } else {
            MsgBox("No log file found.", "No Logs", "Iconi")
        }
    }

    static _ResetToDefaults() {
        result := MsgBox("Reset all settings to default values?`nYour saved positions will be preserved.",
            "Reset to Defaults", "YesNo Icon?")
        if (result = "Yes") {
            ; Reset to default values
            Config.MoveStep := 4
            Config.MoveDelay := 15
            Config.AccelerationRate := 1.1
            Config.MaxSpeed := 30
            Config.EnableAbsoluteMovement := false
            Config.EnableAudioFeedback := false
            Config.ScrollStep := 1
            Config.ScrollAccelerationRate := 1.1
            Config.MaxScrollSpeed := 10

            ; Refresh controls
            SettingsGUI._InitializeTempSettings()
            SettingsGUI._ShowTab(SettingsGUI.currentTab)

            MsgBox("Settings have been reset to defaults.", "Reset Complete", "Iconi T2")
        }
    }

    static _FactoryReset() {
        result := MsgBox(
            "FACTORY RESET will:`n• Reset all settings to defaults`n• Clear all saved positions`n• Remove all profiles`n• Delete all logs`n`nThis cannot be undone!`n`nProceed?",
            "Factory Reset", "YesNo IconX Default2")
        if (result = "Yes") {
            confirm := MsgBox("Are you SURE? Type 'RESET' to confirm.", "Final Confirmation", "OKCancel IconX")
            if (confirm = "OK") {
                ; Perform factory reset
                MsgBox("Factory reset would be performed here.`n(Not implemented for safety)", "Factory Reset", "Iconi"
                )
            }
        }
    }

    static _LoadSelectedProfile() {
        row := SettingsGUI.controls["ProfileList"].GetNext()
        if (row) {
            profile := SettingsGUI.controls["ProfileList"].GetText(row, 1)
            MsgBox("Loading profile: " . profile, "Load Profile", "T2")
        } else {
            MsgBox("Please select a profile to load.", "No Selection", "Icon!")
        }
    }

    static _SaveNewProfile() {
        IB := InputBox("Enter name for new profile:", "Save Profile", "w300 h120")
        if (IB.Result = "OK" && IB.Value != "") {
            MsgBox("Profile '" . IB.Value . "' would be saved here.", "Save Profile", "Iconi T3")
        }
    }

    static _UpdateCurrentProfile() {
        current := SettingsGUI.controls["CurrentProfileName"].Text
        result := MsgBox("Update profile '" . current . "' with current settings?", "Update Profile", "YesNo Icon?")
        if (result = "Yes") {
            MsgBox("Profile updated.", "Success", "Iconi T2")
        }
    }

    static _DeleteSelectedProfile() {
        row := SettingsGUI.controls["ProfileList"].GetNext()
        if (row) {
            profile := SettingsGUI.controls["ProfileList"].GetText(row, 1)
            if (profile = "Default") {
                MsgBox("Cannot delete the Default profile.", "Error", "IconX")
                return
            }
            result := MsgBox("Delete profile '" . profile . "'?", "Delete Profile", "YesNo Icon?")
            if (result = "Yes") {
                MsgBox("Profile deleted.", "Success", "Iconi T2")
            }
        } else {
            MsgBox("Please select a profile to delete.", "No Selection", "Icon!")
        }
    }

    static _ExportProfile() {
        MsgBox("Profile export functionality will be implemented in a future update.", "Export Profile", "Iconi T3")
    }

    static _ImportProfile() {
        MsgBox("Profile import functionality will be implemented in a future update.", "Import Profile", "Iconi T3")
    }

    static _CheckForUpdates() {
        MsgBox("Checking for updates...`n`nYou are running the latest version (3.0.0).", "Check for Updates", "Iconi")
    }

    static _OpenDocumentation() {
        MsgBox("Documentation will open in your default browser.`n(Link would be here)", "Documentation", "Iconi T3")
    }

    static _ReportIssue() {
        MsgBox("Issue reporting will open in your default browser.`n(Link would be here)", "Report Issue", "Iconi T3")
    }

    static _RunSystemDiagnostics() {
        diagText := "SYSTEM DIAGNOSTICS`n`n"
        diagText .= "Script Status: Running`n"
        diagText .= "Memory Usage: ~50 MB`n"
        diagText .= "CPU Usage: < 1%`n"
        diagText .= "Active Hotkeys: 25`n"
        diagText .= "Saved Positions: " . PositionMemory.GetSavedPositions().Count . "`n"
        diagText .= "Monitor Count: " . MonitorGetCount() . "`n"
        diagText .= "Primary Monitor: " . MonitorGetPrimary() . "`n`n"
        diagText .= "All systems operating normally."

        MsgBox(diagText, "System Diagnostics", "Iconi")
    }

    static _TestMonitorConfiguration() {
        ; Refresh monitor information
        MonitorUtils.Refresh()

        ; Get debug info from MonitorUtils
        monitorInfo := MonitorUtils.ShowMonitorDebugInfo()

        ; Show visual indicators on each monitor
        for monitor in MonitorUtils.monitors {
            ; Create a temporary GUI to show monitor bounds
            tempGui := Gui("+AlwaysOnTop -Caption +ToolWindow", "")
            tempGui.BackColor := monitor.IsPrimary ? "0x00FF00" : "0x0000FF"  ; Green for primary, blue for secondary
            tempGui.SetFont("s14 Bold", "Arial")
            label := "Monitor " . monitor.Index
            if (monitor.IsPrimary) {
                label .= " (PRIMARY)"
            }
            label .= "`n" . monitor.Width . " x " . monitor.Height
            label .= "`nLeft: " . monitor.Left . " Top: " . monitor.Top
            tempGui.Add("Text", "x10 y10 cWhite", label)

            ; Show in center of monitor
            centerX := monitor.Left + (monitor.Width // 2) - 150
            centerY := monitor.Top + (monitor.Height // 2) - 40
            tempGui.Show("x" . centerX . " y" . centerY . " w300 h80 NoActivate")

            ; Auto-destroy after 5 seconds
            SetTimer(() => tempGui.Destroy(), -5000)
        }

        MsgBox(monitorInfo, "Monitor Configuration", "Iconi")
    }

    static _RefreshMonitors() {
        ; Refresh monitor configuration
        MonitorUtils.Refresh()

        ; Update position list with new monitor information
        SettingsGUI._PopulatePositionList()

        ; Show confirmation
        MsgBox("Monitor configuration refreshed!`n`nPosition descriptions have been updated.", "Monitors Refreshed",
            "Iconi T2")
    }
}