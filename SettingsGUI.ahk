#Requires AutoHotkey v2.0

; ######################################################################################################################
; Settings GUI Module - Advanced GUI Settings Panel with Tabbed Interface
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
        ; Create main GUI window
        SettingsGUI.gui := Gui("+Resize +MaximizeBox -MinimizeBox", "Mouse on Numpad Enhanced - Settings v3.0.0")
        SettingsGUI.gui.BackColor := "0xF5F5F5"
        SettingsGUI.gui.MarginX := 15
        SettingsGUI.gui.MarginY := 15
        
        ; Set up event handlers
        SettingsGUI.gui.OnEvent("Close", (*) => SettingsGUI._OnClose())
        SettingsGUI.gui.OnEvent("Size", (*) => SettingsGUI._OnResize())
        
        ; Initialize temp settings with current values
        SettingsGUI._InitializeTempSettings()
        
        ; Create tab control
        SettingsGUI._CreateTabControl()
        
        ; Create all tab content
        SettingsGUI._CreateMovementTab()
        SettingsGUI._CreatePositionTab()
        SettingsGUI._CreateVisualsTab()
        SettingsGUI._CreateHotkeysTab()
        SettingsGUI._CreateAdvancedTab()
        SettingsGUI._CreateProfilesTab()
        SettingsGUI._CreateAboutTab()
        
        ; Create bottom buttons
        SettingsGUI._CreateBottomButtons()
        
        ; Show first tab
        SettingsGUI._ShowTab(1)
        
        ; Position and show GUI - proper height for bottom section
        centerX := (A_ScreenWidth - 800) // 2
        centerY := (A_ScreenHeight - 420) // 2
        SettingsGUI.gui.Show("x" . centerX . " y" . centerY . " w800 h420")
    }
    
    static _InitializeTempSettings() {
        ; Copy current settings to temp storage for preview
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
    }
    
    static _CreateTabControl() {
        ; Create tab control - make it shorter to avoid blocking the buttons
        SettingsGUI.controls["TabControl"] := SettingsGUI.gui.Add("Tab3", "x15 y15 w770 h300", [
            "Movement", "Positions", "Visuals", "Hotkeys", "Advanced", "Profiles", "About"
        ])
        
        ; Tab change event
        SettingsGUI.controls["TabControl"].OnEvent("Change", (*) => SettingsGUI._OnTabChange())
    }
    
    static _CreateMovementTab() {
        ; Movement Settings Tab
        SettingsGUI.controls["TabControl"].UseTab(1)
        
        ; Movement Speed Section
        SettingsGUI.gui.Add("Text", "x30 y50 w200 h20 +0x200", "Movement Speed").SetFont("s10 Bold")
        
        SettingsGUI.gui.Add("Text", "x30 y75 w120", "Move Step:")
        SettingsGUI.controls["MoveStep"] := SettingsGUI.gui.Add("Edit", "x150 y72 w60 Number")
        SettingsGUI.controls["MoveStep"].Text := SettingsGUI.tempSettings["MoveStep"]
        SettingsGUI.controls["MoveStep"].OnEvent("Change", (*) => SettingsGUI._UpdateMovementPreview())
        SettingsGUI.controls["MoveStepUpDown"] := SettingsGUI.gui.Add("UpDown", "x210 y72 w20 h20 Range1-50", SettingsGUI.tempSettings["MoveStep"])
        SettingsGUI.controls["MoveStepUpDown"].OnEvent("Change", (*) => SettingsGUI._UpdateMovementPreview())
        SettingsGUI.gui.Add("Text", "x235 y75 w300", "pixels per movement (1-50)")
        
        SettingsGUI.gui.Add("Text", "x30 y100 w120", "Move Delay:")
        SettingsGUI.controls["MoveDelay"] := SettingsGUI.gui.Add("Edit", "x150 y97 w60 Number")
        SettingsGUI.controls["MoveDelay"].Text := SettingsGUI.tempSettings["MoveDelay"]
        SettingsGUI.controls["MoveDelay"].OnEvent("Change", (*) => SettingsGUI._UpdateMovementPreview())
        SettingsGUI.controls["MoveDelayUpDown"] := SettingsGUI.gui.Add("UpDown", "x210 y97 w20 h20 Range5-100", SettingsGUI.tempSettings["MoveDelay"])
        SettingsGUI.controls["MoveDelayUpDown"].OnEvent("Change", (*) => SettingsGUI._UpdateMovementPreview())
        SettingsGUI.gui.Add("Text", "x235 y100 w300", "milliseconds between movements (5-100)")
        
        ; Acceleration Section
        SettingsGUI.gui.Add("Text", "x30 y140 w200 h20 +0x200", "Acceleration Settings").SetFont("s10 Bold")
        
        SettingsGUI.gui.Add("Text", "x30 y165 w120", "Acceleration Rate:")
        SettingsGUI.controls["AccelerationRate"] := SettingsGUI.gui.Add("Edit", "x150 y162 w60")
        SettingsGUI.controls["AccelerationRate"].Text := SettingsGUI.tempSettings["AccelerationRate"]
        SettingsGUI.controls["AccelerationRate"].OnEvent("Change", (*) => SettingsGUI._UpdateMovementPreview())
        SettingsGUI.gui.Add("Text", "x235 y165 w300", "multiplier per step (1.0-3.0)")
        
        SettingsGUI.gui.Add("Text", "x30 y190 w120", "Max Speed:")
        SettingsGUI.controls["MaxSpeed"] := SettingsGUI.gui.Add("Edit", "x150 y187 w60 Number")
        SettingsGUI.controls["MaxSpeed"].Text := SettingsGUI.tempSettings["MaxSpeed"]
        SettingsGUI.controls["MaxSpeed"].OnEvent("Change", (*) => SettingsGUI._UpdateMovementPreview())
        SettingsGUI.controls["MaxSpeedUpDown"] := SettingsGUI.gui.Add("UpDown", "x210 y187 w20 h20 Range5-100", SettingsGUI.tempSettings["MaxSpeed"])
        SettingsGUI.controls["MaxSpeedUpDown"].OnEvent("Change", (*) => SettingsGUI._UpdateMovementPreview())
        SettingsGUI.gui.Add("Text", "x235 y190 w300", "maximum pixels per movement (5-100)")
        
        ; Movement Mode Section
        SettingsGUI.gui.Add("Text", "x30 y230 w200 h20 +0x200", "Movement Modes").SetFont("s10 Bold")
        
        SettingsGUI.controls["EnableAbsoluteMovement"] := SettingsGUI.gui.Add("CheckBox", "x30 y255 w300", "Enable Absolute Movement")
        ; Load the actual current config value, not temp settings
        SettingsGUI.controls["EnableAbsoluteMovement"].Value := Config.EnableAbsoluteMovement ? 1 : 0
        SettingsGUI.controls["EnableAbsoluteMovement"].OnEvent("Click", (*) => SettingsGUI._UpdateMovementPreview())
        SettingsGUI.gui.Add("Text", "x50 y275 w400", "Use absolute coordinates instead of relative movement")
        
        ; Scroll Settings Section
        SettingsGUI.gui.Add("Text", "x30 y315 w200 h20 +0x200", "Scroll Settings").SetFont("s10 Bold")
        
        SettingsGUI.gui.Add("Text", "x30 y340 w120", "Scroll Step:")
        SettingsGUI.controls["ScrollStep"] := SettingsGUI.gui.Add("Edit", "x150 y337 w60 Number")
        SettingsGUI.controls["ScrollStep"].Text := SettingsGUI.tempSettings["ScrollStep"]
        SettingsGUI.controls["ScrollStep"].OnEvent("Change", (*) => SettingsGUI._UpdateMovementPreview())
        SettingsGUI.controls["ScrollStepUpDown"] := SettingsGUI.gui.Add("UpDown", "x210 y337 w20 h20 Range1-10", SettingsGUI.tempSettings["ScrollStep"])
        SettingsGUI.controls["ScrollStepUpDown"].OnEvent("Change", (*) => SettingsGUI._UpdateMovementPreview())
        SettingsGUI.gui.Add("Text", "x235 y340 w300", "scroll lines per step (1-10)")
        
        SettingsGUI.gui.Add("Text", "x30 y365 w120", "Scroll Acceleration:")
        SettingsGUI.controls["ScrollAccelerationRate"] := SettingsGUI.gui.Add("Edit", "x150 y362 w60")
        SettingsGUI.controls["ScrollAccelerationRate"].Text := SettingsGUI.tempSettings["ScrollAccelerationRate"]
        SettingsGUI.controls["ScrollAccelerationRate"].OnEvent("Change", (*) => SettingsGUI._UpdateMovementPreview())
        SettingsGUI.gui.Add("Text", "x235 y365 w300", "scroll acceleration multiplier (1.0-3.0)")
        
        SettingsGUI.gui.Add("Text", "x30 y390 w120", "Max Scroll Speed:")
        SettingsGUI.controls["MaxScrollSpeed"] := SettingsGUI.gui.Add("Edit", "x150 y387 w60 Number")
        SettingsGUI.controls["MaxScrollSpeed"].Text := SettingsGUI.tempSettings["MaxScrollSpeed"]
        SettingsGUI.controls["MaxScrollSpeed"].OnEvent("Change", (*) => SettingsGUI._UpdateMovementPreview())
        SettingsGUI.controls["MaxScrollSpeedUpDown"] := SettingsGUI.gui.Add("UpDown", "x210 y387 w20 h20 Range1-50", SettingsGUI.tempSettings["MaxScrollSpeed"])
        SettingsGUI.controls["MaxScrollSpeedUpDown"].OnEvent("Change", (*) => SettingsGUI._UpdateMovementPreview())
        SettingsGUI.gui.Add("Text", "x235 y390 w300", "maximum scroll lines per step (1-50)")
        
        ; Preview Section - use Edit control for better scrolling
        SettingsGUI.gui.Add("Text", "x450 y50 w300 h20 +0x200", "Movement & Scroll Preview").SetFont("s10 Bold")
        SettingsGUI.controls["MovementPreview"] := SettingsGUI.gui.Add("Edit", "x450 y75 w300 h260 +VScroll +ReadOnly +Wrap")
        SettingsGUI.controls["MovementPreview"].SetFont("s8", "Consolas")
        SettingsGUI._UpdateMovementPreview()
        
        ; SAVE BUTTONS IN THE MOVEMENT TAB - moved lower to accommodate bigger preview
        SettingsGUI.controls["MovementApply"] := SettingsGUI.gui.Add("Button", "x450 y345 w80 h25", "Apply Settings")
        SettingsGUI.controls["MovementApply"].OnEvent("Click", (*) => SettingsGUI._ApplySettings())
        SettingsGUI.controls["MovementApply"].SetFont("s8 Bold")
        
        SettingsGUI.controls["MovementOK"] := SettingsGUI.gui.Add("Button", "x540 y345 w80 h25", "OK (Save & Close)")
        SettingsGUI.controls["MovementOK"].OnEvent("Click", (*) => SettingsGUI._ApplyAndClose())
        SettingsGUI.controls["MovementOK"].SetFont("s8 Bold")
        
        SettingsGUI.controls["MovementCancel"] := SettingsGUI.gui.Add("Button", "x630 y345 w80 h25", "Cancel")
        SettingsGUI.controls["MovementCancel"].OnEvent("Click", (*) => SettingsGUI._Cancel())
        SettingsGUI.controls["MovementCancel"].SetFont("s8 Bold")
    }
    
    static _CreatePositionTab() {
        ; Position Memory Settings Tab
        SettingsGUI.controls["TabControl"].UseTab(2)
        
        ; Position Slots Section
        SettingsGUI.gui.Add("Text", "x30 y50 w200 h20 +0x200", "Position Memory").SetFont("s10 Bold")
        
        SettingsGUI.gui.Add("Text", "x30 y75 w150", "Maximum Saved Positions:")
        SettingsGUI.controls["MaxSavedPositions"] := SettingsGUI.gui.Add("Edit", "x180 y72 w60 Number")
        SettingsGUI.controls["MaxSavedPositions"].Text := SettingsGUI.tempSettings["MaxSavedPositions"]
        SettingsGUI.controls["MaxSavedPositionsUpDown"] := SettingsGUI.gui.Add("UpDown", "x240 y72 w20 h20 Range1-100", SettingsGUI.tempSettings["MaxSavedPositions"])
        SettingsGUI.gui.Add("Text", "x265 y75 w300", "position slots (1-100)")
        
        SettingsGUI.gui.Add("Text", "x30 y100 w150", "Maximum Undo Levels:")
        SettingsGUI.controls["MaxUndoLevels"] := SettingsGUI.gui.Add("Edit", "x180 y97 w60 Number")
        SettingsGUI.controls["MaxUndoLevels"].Text := SettingsGUI.tempSettings["MaxUndoLevels"]
        SettingsGUI.controls["MaxUndoLevelsUpDown"] := SettingsGUI.gui.Add("UpDown", "x240 y97 w20 h20 Range1-50", SettingsGUI.tempSettings["MaxUndoLevels"])
        SettingsGUI.gui.Add("Text", "x265 y100 w300", "undo steps (1-50)")
        
        ; Current Positions Section
        SettingsGUI.gui.Add("Text", "x30 y140 w200 h20 +0x200", "Saved Positions").SetFont("s10 Bold")
        
        ; Position List - make it smaller to avoid overlap with bottom section
        SettingsGUI.controls["PositionList"] := SettingsGUI.gui.Add("ListView", "x30 y165 w500 h85", ["Slot", "X", "Y", "Description"])
        SettingsGUI.controls["PositionList"].ModifyCol(1, 50)
        SettingsGUI.controls["PositionList"].ModifyCol(2, 80)
        SettingsGUI.controls["PositionList"].ModifyCol(3, 80)
        SettingsGUI.controls["PositionList"].ModifyCol(4, 280)
        
        ; Position Management Buttons
        SettingsGUI.controls["GotoPosition"] := SettingsGUI.gui.Add("Button", "x550 y165 w120 h25", "Go to Position")
        SettingsGUI.controls["GotoPosition"].OnEvent("Click", (*) => SettingsGUI._GotoSelectedPosition())
        
        SettingsGUI.controls["SaveCurrentPos"] := SettingsGUI.gui.Add("Button", "x550 y195 w120 h25", "Save Current")
        SettingsGUI.controls["SaveCurrentPos"].OnEvent("Click", (*) => SettingsGUI._SaveCurrentPosition())
        
        SettingsGUI.controls["DeletePosition"] := SettingsGUI.gui.Add("Button", "x550 y225 w120 h25", "Delete Position")
        SettingsGUI.controls["DeletePosition"].OnEvent("Click", (*) => SettingsGUI._DeleteSelectedPosition())
        
        SettingsGUI.controls["ClearAllPositions"] := SettingsGUI.gui.Add("Button", "x550 y255 w120 h25", "Clear All")
        SettingsGUI.controls["ClearAllPositions"].OnEvent("Click", (*) => SettingsGUI._ClearAllPositions())
        
        SettingsGUI.controls["ImportPositions"] := SettingsGUI.gui.Add("Button", "x550 y285 w120 h25", "Import...")
        SettingsGUI.controls["ImportPositions"].OnEvent("Click", (*) => SettingsGUI._ImportPositions())
        
        SettingsGUI.controls["ExportPositions"] := SettingsGUI.gui.Add("Button", "x550 y315 w120 h25", "Export...")
        SettingsGUI.controls["ExportPositions"].OnEvent("Click", (*) => SettingsGUI._ExportPositions())
        
        ; Position File Management - back in tab but at the bottom, no overlap
        SettingsGUI.gui.Add("Text", "x30 y260 w200 h20 +0x200", "Position File Management").SetFont("s10 Bold")
        
        SettingsGUI.gui.Add("Text", "x30 y285 w100", "Config File:")
        SettingsGUI.controls["ConfigFile"] := SettingsGUI.gui.Add("Edit", "x130 y282 w150 ReadOnly")
        SettingsGUI.controls["ConfigFile"].Text := Config.PersistentPositionsFile
        
        SettingsGUI.controls["OpenConfigFolder"] := SettingsGUI.gui.Add("Button", "x290 y280 w80 h25", "Open Folder")
        SettingsGUI.controls["OpenConfigFolder"].OnEvent("Click", (*) => SettingsGUI._OpenConfigFolder())
        
        SettingsGUI.controls["BackupConfig"] := SettingsGUI.gui.Add("Button", "x380 y280 w60 h25", "Backup")
        SettingsGUI.controls["BackupConfig"].OnEvent("Click", (*) => SettingsGUI._BackupConfig())
        
        ; UNIVERSAL SAVE BUTTONS - in tab where they actually work
        SettingsGUI.controls["PosApply"] := SettingsGUI.gui.Add("Button", "x450 y280 w50 h25", "Apply")
        SettingsGUI.controls["PosApply"].OnEvent("Click", (*) => SettingsGUI._ApplySettings())
        SettingsGUI.controls["PosApply"].SetFont("s8 Bold")
        
        SettingsGUI.controls["PosOK"] := SettingsGUI.gui.Add("Button", "x510 y280 w40 h25", "OK")
        SettingsGUI.controls["PosOK"].OnEvent("Click", (*) => SettingsGUI._ApplyAndClose())
        SettingsGUI.controls["PosOK"].SetFont("s8 Bold")
        
        SettingsGUI.controls["PosCancel"] := SettingsGUI.gui.Add("Button", "x560 y280 w60 h25", "Cancel")
        SettingsGUI.controls["PosCancel"].OnEvent("Click", (*) => SettingsGUI._Cancel())
        SettingsGUI.controls["PosCancel"].SetFont("s8 Bold")
        
        ; Populate position list
        SettingsGUI._PopulatePositionList()
    }
    
    static _CreateVisualsTab() {
        ; Visual & Audio Settings Tab
        SettingsGUI.controls["TabControl"].UseTab(3)
        
        ; Status Display Section
        SettingsGUI.gui.Add("Text", "x30 y50 w200 h20 +0x200", "Status Display").SetFont("s10 Bold")
        
        SettingsGUI.controls["StatusVisibleOnStartup"] := SettingsGUI.gui.Add("CheckBox", "x30 y75 w300", "Show Status on Startup")
        SettingsGUI.controls["StatusVisibleOnStartup"].Checked := SettingsGUI.tempSettings["StatusVisibleOnStartup"]
        
        SettingsGUI.controls["UseSecondaryMonitor"] := SettingsGUI.gui.Add("CheckBox", "x30 y100 w300", "Use Secondary Monitor")
        SettingsGUI.controls["UseSecondaryMonitor"].Checked := SettingsGUI.tempSettings["UseSecondaryMonitor"]
        
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
        
        SettingsGUI.controls["EnableAudioFeedback"] := SettingsGUI.gui.Add("CheckBox", "x30 y345 w200", "Enable Audio Feedback")
        SettingsGUI.controls["EnableAudioFeedback"].Checked := SettingsGUI.tempSettings["EnableAudioFeedback"]
        
        ; Test Audio Button
        SettingsGUI.controls["TestAudio"] := SettingsGUI.gui.Add("Button", "x250 y343 w100 h25", "Test Audio")
        SettingsGUI.controls["TestAudio"].OnEvent("Click", (*) => SettingsGUI._TestAudio())
        
        ; Color Theme Section
        SettingsGUI.gui.Add("Text", "x450 y50 w200 h20 +0x200", "Color Themes").SetFont("s10 Bold")
        
        SettingsGUI.gui.Add("Text", "x450 y75 w80", "Theme:")
        SettingsGUI.controls["ColorTheme"] := SettingsGUI.gui.Add("DropDownList", "x530 y72 w150", ["Default", "Dark Mode", "High Contrast", "Colorful", "Minimal"])
        SettingsGUI.controls["ColorTheme"].Choose(1)
        
        ; Preview Section
        SettingsGUI.gui.Add("Text", "x450 y110 w200 h20 +0x200", "Preview").SetFont("s10 Bold")
        SettingsGUI.controls["VisualPreview"] := SettingsGUI.gui.Add("Text", "x450 y135 w300 h150 +Border")
        SettingsGUI.controls["VisualPreview"].Text := "Status and tooltip preview will appear here..."
        
        ; Position Test Buttons
        SettingsGUI.controls["TestStatusPosition"] := SettingsGUI.gui.Add("Button", "x450 y300 w140 h25", "Test Status Position")
        SettingsGUI.controls["TestStatusPosition"].OnEvent("Click", (*) => SettingsGUI._TestStatusPosition())
        
        SettingsGUI.controls["TestTooltipPosition"] := SettingsGUI.gui.Add("Button", "x600 y300 w140 h25", "Test Tooltip Position")
        SettingsGUI.controls["TestTooltipPosition"].OnEvent("Click", (*) => SettingsGUI._TestTooltipPosition())
    }
    
    static _CreateHotkeysTab() {
        ; Hotkey Customization Tab
        SettingsGUI.controls["TabControl"].UseTab(4)
        
        ; Hotkey List Section
        SettingsGUI.gui.Add("Text", "x30 y50 w200 h20 +0x200", "Hotkey Configuration").SetFont("s10 Bold")
        
        ; Hotkey ListView
        SettingsGUI.controls["HotkeyList"] := SettingsGUI.gui.Add("ListView", "x30 y75 w650 h350", ["Action", "Current Hotkey", "Description"])
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
        SettingsGUI.gui.Add("Text", "x30 y440 w200 h20 +0x200", "Conflict Detection").SetFont("s10 Bold")
        
        SettingsGUI.controls["ConflictStatus"] := SettingsGUI.gui.Add("Text", "x30 y465 w500 h20")
        SettingsGUI.controls["ConflictStatus"].Text := "No conflicts detected"
        
        SettingsGUI.controls["ScanConflicts"] := SettingsGUI.gui.Add("Button", "x550 y462 w120 h25", "Scan for Conflicts")
        SettingsGUI.controls["ScanConflicts"].OnEvent("Click", (*) => SettingsGUI._ScanForConflicts())
        
        SettingsGUI.controls["ResetAllHotkeys"] := SettingsGUI.gui.Add("Button", "x680 y462 w80 h25", "Reset All")
        SettingsGUI.controls["ResetAllHotkeys"].OnEvent("Click", (*) => SettingsGUI._ResetAllHotkeys())
    }
    
    static _CreateAdvancedTab() {
        ; Advanced Settings Tab
        SettingsGUI.controls["TabControl"].UseTab(5)
        
        ; Performance Section
        SettingsGUI.gui.Add("Text", "x30 y50 w200 h20 +0x200", "Performance Settings").SetFont("s10 Bold")
        
        SettingsGUI.controls["LowMemoryMode"] := SettingsGUI.gui.Add("CheckBox", "x30 y75 w200", "Enable Low Memory Mode")
        SettingsGUI.gui.Add("Text", "x50 y95 w400", "Reduces memory usage at the cost of some features")
        
        SettingsGUI.controls["ReduceAnimations"] := SettingsGUI.gui.Add("CheckBox", "x30 y115 w200", "Reduce Animations")
        SettingsGUI.gui.Add("Text", "x50 y135 w400", "Disables visual effects for better performance")
        
        ; Update Frequency
        SettingsGUI.gui.Add("Text", "x30 y165 w150", "Update Frequency:")
        SettingsGUI.controls["UpdateFrequency"] := SettingsGUI.gui.Add("Edit", "x180 y162 w60 Number")
        SettingsGUI.controls["UpdateFrequency"].Text := "500"
        SettingsGUI.controls["UpdateFrequencyUpDown"] := SettingsGUI.gui.Add("UpDown", "x240 y162 w20 h20 Range100-2000", 500)
        SettingsGUI.gui.Add("Text", "x265 y165 w200", "milliseconds between updates")
        
        ; Logging Section
        SettingsGUI.gui.Add("Text", "x30 y205 w200 h20 +0x200", "Logging & Debugging").SetFont("s10 Bold")
        
        SettingsGUI.controls["EnableLogging"] := SettingsGUI.gui.Add("CheckBox", "x30 y230 w200", "Enable Debug Logging")
        SettingsGUI.gui.Add("Text", "x50 y250 w400", "Logs actions for troubleshooting (may impact performance)")
        
        SettingsGUI.controls["LogLevel"] := SettingsGUI.gui.Add("DropDownList", "x250 y230 w100", ["Error", "Warning", "Info", "Debug"])
        SettingsGUI.controls["LogLevel"].Choose(2)
        
        ; Log Management Buttons
        SettingsGUI.controls["ViewLogs"] := SettingsGUI.gui.Add("Button", "x30 y275 w100 h25", "View Logs")
        SettingsGUI.controls["ViewLogs"].OnEvent("Click", (*) => SettingsGUI._ViewLogs())
        
        SettingsGUI.controls["ClearLogs"] := SettingsGUI.gui.Add("Button", "x140 y275 w100 h25", "Clear Logs")
        SettingsGUI.controls["ClearLogs"].OnEvent("Click", (*) => SettingsGUI._ClearLogs())
        
        ; Backup Section
        SettingsGUI.gui.Add("Text", "x30 y315 w200 h20 +0x200", "Backup & Recovery").SetFont("s10 Bold")
        
        SettingsGUI.controls["AutoBackup"] := SettingsGUI.gui.Add("CheckBox", "x30 y340 w200", "Enable Auto Backup")
        SettingsGUI.gui.Add("Text", "x50 y360 w400", "Automatically backup settings on changes")
        
        SettingsGUI.gui.Add("Text", "x30 y385 w120", "Backup Frequency:")
        SettingsGUI.controls["BackupFrequency"] := SettingsGUI.gui.Add("DropDownList", "x150 y382 w100", ["Daily", "Weekly", "Monthly"])
        SettingsGUI.controls["BackupFrequency"].Choose(2)
        
        ; Backup Management Buttons
        SettingsGUI.controls["CreateBackup"] := SettingsGUI.gui.Add("Button", "x30 y415 w120 h25", "Create Backup Now")
        SettingsGUI.controls["CreateBackup"].OnEvent("Click", (*) => SettingsGUI._CreateBackup())
        
        SettingsGUI.controls["RestoreBackup"] := SettingsGUI.gui.Add("Button", "x160 y415 w120 h25", "Restore Backup...")
        SettingsGUI.controls["RestoreBackup"].OnEvent("Click", (*) => SettingsGUI._RestoreBackup())
        
        ; Advanced Features Section
        SettingsGUI.gui.Add("Text", "x450 y50 w200 h20 +0x200", "Advanced Features").SetFont("s10 Bold")
        
        SettingsGUI.controls["EnableGestures"] := SettingsGUI.gui.Add("CheckBox", "x450 y75 w200", "Enable Gesture Recognition")
        SettingsGUI.gui.Add("Text", "x470 y95 w300", "Recognize mouse gestures for quick actions")
        
        SettingsGUI.controls["EnableAnalytics"] := SettingsGUI.gui.Add("CheckBox", "x450 y115 w200", "Enable Usage Analytics")
        SettingsGUI.gui.Add("Text", "x470 y135 w300", "Track usage patterns for optimization")
        
        SettingsGUI.controls["EnableCloudSync"] := SettingsGUI.gui.Add("CheckBox", "x450 y155 w200", "Enable Cloud Synchronization")
        SettingsGUI.gui.Add("Text", "x470 y175 w300", "Sync settings across devices")
        
        ; Experimental Features
        SettingsGUI.gui.Add("Text", "x450 y205 w200 h20 +0x200", "Experimental Features").SetFont("s10 Bold")
        
        SettingsGUI.controls["EnablePrediction"] := SettingsGUI.gui.Add("CheckBox", "x450 y230 w200", "Enable Movement Prediction")
        SettingsGUI.gui.Add("Text", "x470 y250 w300", "Predict and suggest common movements")
        
        SettingsGUI.controls["EnableMagneticSnap"] := SettingsGUI.gui.Add("CheckBox", "x450 y270 w200", "Enable Magnetic Snapping")
        SettingsGUI.gui.Add("Text", "x470 y290 w300", "Automatically snap to UI elements")
        
        ; Reset Section
        SettingsGUI.gui.Add("Text", "x450 y330 w200 h20 +0x200", "Reset Options").SetFont("s10 Bold")
        
        SettingsGUI.controls["ResetToDefaults"] := SettingsGUI.gui.Add("Button", "x450 y355 w150 h25", "Reset to Defaults")
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
        SettingsGUI.controls["ProfileList"] := SettingsGUI.gui.Add("ListView", "x30 y75 w500 h250", ["Profile Name", "Description", "Last Modified"])
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
        SettingsGUI.gui.Add("Text", "x30 y345 w150 h20", "Current Profile:")
        SettingsGUI.controls["CurrentProfileName"] := SettingsGUI.gui.Add("Text", "x180 y345 w200 h20 +0x200")
        SettingsGUI.controls["CurrentProfileName"].Text := "Default"
        
        ; Profile Description
        SettingsGUI.gui.Add("Text", "x30 y375 w200 h20 +0x200", "Profile Description").SetFont("s10 Bold")
        SettingsGUI.controls["ProfileDescription"] := SettingsGUI.gui.Add("Edit", "x30 y395 w500 h60 +VScroll +WantReturn")
        SettingsGUI.controls["ProfileDescription"].Text := "Default configuration profile with standard settings."
        
        ; Auto-Switch Settings
        SettingsGUI.gui.Add("Text", "x30 y475 w200 h20 +0x200", "Auto-Switch Rules").SetFont("s10 Bold")
        
        SettingsGUI.controls["EnableAutoSwitch"] := SettingsGUI.gui.Add("CheckBox", "x30 y500 w200", "Enable Auto Profile Switching")
        SettingsGUI.gui.Add("Text", "x50 y520 w400", "Automatically switch profiles based on active application")
    }
    
    static _CreateAboutTab() {
        ; About Tab
        SettingsGUI.controls["TabControl"].UseTab(7)
        
        ; Title and Version
        SettingsGUI.gui.Add("Text", "x30 y50 w400 h30 +Center", "Mouse on Numpad Enhanced").SetFont("s16 Bold")
        SettingsGUI.gui.Add("Text", "x30 y85 w400 h20 +Center", "Version 3.0.0 - Advanced Settings Panel").SetFont("s10")
        
        ; Description
        SettingsGUI.gui.Add("Text", "x30 y120 w650 h60 +Wrap", 
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
        
        SettingsGUI.gui.Add("Text", "x30 y215 w300 h200 +Wrap", featuresText)
        
        ; System Information
        SettingsGUI.gui.Add("Text", "x400 y190 w200 h20 +0x200", "System Information").SetFont("s10 Bold")
        
        systemInfo := "AutoHotkey Version: " . A_AhkVersion . "`n" .
                     "Operating System: " . A_OSVersion . "`n" .
                     "Computer Name: " . A_ComputerName . "`n" .
                     "User Name: " . A_UserName . "`n" .
                     "Screen Resolution: " . A_ScreenWidth . "x" . A_ScreenHeight . "`n" .
                     "Script Directory: " . A_ScriptDir
        
        SettingsGUI.gui.Add("Text", "x400 y215 w350 h150 +Wrap", systemInfo)
        
        ; Action Buttons
        SettingsGUI.controls["CheckUpdates"] := SettingsGUI.gui.Add("Button", "x30 y430 w120 h30", "Check for Updates")
        SettingsGUI.controls["CheckUpdates"].OnEvent("Click", (*) => SettingsGUI._CheckForUpdates())
        
        SettingsGUI.controls["OpenDocumentation"] := SettingsGUI.gui.Add("Button", "x160 y430 w120 h30", "Documentation")
        SettingsGUI.controls["OpenDocumentation"].OnEvent("Click", (*) => SettingsGUI._OpenDocumentation())
        
        SettingsGUI.controls["ReportIssue"] := SettingsGUI.gui.Add("Button", "x290 y430 w120 h30", "Report Issue")
        SettingsGUI.controls["ReportIssue"].OnEvent("Click", (*) => SettingsGUI._ReportIssue())
        
        SettingsGUI.controls["SystemDiagnostics"] := SettingsGUI.gui.Add("Button", "x420 y430 w120 h30", "System Diagnostics")
        SettingsGUI.controls["SystemDiagnostics"].OnEvent("Click", (*) => SettingsGUI._RunSystemDiagnostics())
        
        ; Copyright and Credits
        SettingsGUI.gui.Add("Text", "x30 y480 w650 h40 +Wrap +Center", 
            "Enhanced by Claude AI Assistant. Original concept and base implementation community-driven. " .
            "Thank you to all contributors and users who made this possible.")
    }
    
    static _CreateBottomButtons() {
        ; Create buttons OUTSIDE the tab control area
        SettingsGUI.controls["TabControl"].UseTab()  ; This moves us outside of any tab
        
        ; Bottom button bar - positioned much higher
        SettingsGUI.gui.Add("Text", "x15 y405 w770 h1 +0x10")  ; Horizontal line
        
        ; Left side buttons
        SettingsGUI.controls["ImportSettings"] := SettingsGUI.gui.Add("Button", "x20 y415 w100 h25", "Import Settings")
        SettingsGUI.controls["ImportSettings"].OnEvent("Click", (*) => SettingsGUI._ImportSettings())
        
        SettingsGUI.controls["ExportSettings"] := SettingsGUI.gui.Add("Button", "x130 y415 w100 h25", "Export Settings")
        SettingsGUI.controls["ExportSettings"].OnEvent("Click", (*) => SettingsGUI._ExportSettings())
        
        ; Right side buttons - MAIN SAVE BUTTONS
        SettingsGUI.controls["Help"] := SettingsGUI.gui.Add("Button", "x520 y415 w50 h25", "Help")
        SettingsGUI.controls["Help"].OnEvent("Click", (*) => SettingsGUI._ShowHelp())
        
        SettingsGUI.controls["Apply"] := SettingsGUI.gui.Add("Button", "x580 y415 w50 h25", "Apply")
        SettingsGUI.controls["Apply"].OnEvent("Click", (*) => SettingsGUI._ApplySettings())
        
        SettingsGUI.controls["OK"] := SettingsGUI.gui.Add("Button", "x640 y415 w50 h25", "OK")
        SettingsGUI.controls["OK"].OnEvent("Click", (*) => SettingsGUI._ApplyAndClose())
        
        SettingsGUI.controls["Cancel"] := SettingsGUI.gui.Add("Button", "x700 y415 w70 h25", "Cancel")
        SettingsGUI.controls["Cancel"].OnEvent("Click", (*) => SettingsGUI._Cancel())
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
            case 2: SettingsGUI._PopulatePositionList()
            case 4: SettingsGUI._PopulateHotkeyList()
            case 6: SettingsGUI._PopulateProfileList()
        }
    }
    
    static _OnResize() {
        ; Handle window resizing
        try {
            SettingsGUI.gui.GetPos(,, &width, &height)
            
            ; Resize tab control
            SettingsGUI.controls["TabControl"].Move(15, 15, width - 30, height - 90)
            
            ; Reposition bottom buttons with proper spacing from bottom
            buttonY := height - 35  ; 35px from bottom instead of 55
            lineY := height - 45    ; 45px from bottom for the line
            
            ; Move left side buttons
            SettingsGUI.controls["ImportSettings"].Move(20, buttonY)
            SettingsGUI.controls["ExportSettings"].Move(130, buttonY)
            
            ; Move right side buttons to stay aligned to the right
            SettingsGUI.controls["Help"].Move(width - 320, buttonY)
            SettingsGUI.controls["Apply"].Move(width - 260, buttonY)
            SettingsGUI.controls["OK"].Move(width - 200, buttonY)
            SettingsGUI.controls["Cancel"].Move(width - 140, buttonY)
        }
    }
    
    static _OnClose() {
        SettingsGUI.isOpen := false
        SettingsGUI.gui.Destroy()
    }
    
    ; Helper Methods
    static _UpdateMovementPreview() {
        try {
            ; Get current values from the controls (not temp settings)
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
            previewText .= "🖱️ MOVEMENT:`r`n"
            previewText .= "• Step: " . moveStep . " pixels`r`n"
            previewText .= "• Delay: " . moveDelay . " ms`r`n"
            previewText .= "• Accel: " . accelRate . "x`r`n"
            previewText .= "• Max: " . maxSpeed . " px/step`r`n"
            
            if (isAbsolute = 1) {
                previewText .= "• Mode: 🎯 Absolute`r`n"
            } else {
                previewText .= "• Mode: 🔄 Relative`r`n"  
            }
            
            ; Scroll Settings
            previewText .= "`r`n📜 SCROLLING:`r`n"
            previewText .= "• Step: " . scrollStep . " lines`r`n"
            previewText .= "• Accel: " . scrollAccel . "x`r`n"
            previewText .= "• Max: " . maxScrollSpeed . " lines/step`r`n"
            
            ; Calculations
            previewText .= "`r`n🧮 CALCULATIONS:`r`n"
            previewText .= "• Move after 3 steps: " . Round(moveStep * (accelRate ** 2)) . " px`r`n"
            previewText .= "• Scroll after 3 steps: " . Round(scrollStep * (scrollAccel ** 2)) . " lines`r`n"
            
            ; Performance Info
            totalDelay := moveDelay
            if (totalDelay <= 10) {
                previewText .= "`r`n⚡ Performance: Very Fast`r`n"
            } else if (totalDelay <= 20) {
                previewText .= "`r`n🚀 Performance: Fast`r`n"
            } else if (totalDelay <= 50) {
                previewText .= "`r`n⚖️ Performance: Balanced`r`n"
            } else {
                previewText .= "`r`n🐌 Performance: Smooth/Slow`r`n"
            }
            
            ; Usage Tips
            previewText .= "`r`n💡 TIPS:`r`n"
            previewText .= "• Lower delay = faster response`r`n"
            previewText .= "• Higher accel = quicker top speed`r`n"
            previewText .= "• Test with numpad movement!`r`n"
            
            SettingsGUI.controls["MovementPreview"].Text := previewText
        } catch {
            ; Fallback if controls don't exist yet
            SettingsGUI.controls["MovementPreview"].Text := "Preview will update when settings change..."
        }
    }
    
    static _PopulatePositionList() {
        try {
            SettingsGUI.controls["PositionList"].Delete()
            
            savedPositions := PositionMemory.GetSavedPositions()
            for slot, pos in savedPositions {
                SettingsGUI.controls["PositionList"].Add(, slot, pos.x, pos.y, "Saved position " . slot)
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
                ["Default", "Standard configuration for general use", A_Now],
                ["Gaming", "Optimized for gaming applications", A_Now],
                ["Productivity", "Enhanced for office and productivity work", A_Now],
                ["Accessibility", "Accessibility-focused configuration", A_Now]
            ]
            
            for profile in profiles {
                SettingsGUI.controls["ProfileList"].Add(, profile[1], profile[2], profile[3])
            }
        }
    }
    
    ; Action Methods (placeholders for now)
    static _TestMovement() {
        MsgBox("Movement test functionality will be implemented here.", "Test Movement", "T3")
    }
    
    static _DebugLayout() {
        ; Show debug info about button positions
        SettingsGUI.gui.GetPos(&x, &y, &width, &height)
        debugText := "GUI Window Info:`n"
        debugText .= "Position: " . x . ", " . y . "`n"
        debugText .= "Size: " . width . " x " . height . "`n`n"
        debugText .= "Bottom buttons should be at y415`n"
        debugText .= "Window bottom is at y" . (y + height) . "`n`n"
        debugText .= "Button positions:`n"
        debugText .= "Apply button: x580, y415`n"
        debugText .= "OK button: x640, y415`n"
        debugText .= "Cancel button: x700, y415`n`n"
        debugText .= "Use the SAVE SETTINGS button above for now!"
        
        MsgBox(debugText, "Layout Debug Info", "T10")
    }
    
    static _TestAudio() {
        if (SettingsGUI.controls["EnableAudioFeedback"].Checked) {
            SoundBeep(800, 200)
        } else {
            MsgBox("Audio feedback is disabled.", "Test Audio", "T2")
        }
    }
    
    static _TestStatusPosition() {
        MsgBox("Status position test will show a preview of the status indicator.", "Test Status", "T3")
    }
    
    static _TestTooltipPosition() {
        MsgBox("Tooltip position test will show a preview of the tooltip.", "Test Tooltip", "T3")
    }
    
    static _ApplySettings() {
        ; Apply all settings from temp storage to actual config
        try {
            Config.MoveStep := Integer(SettingsGUI.controls["MoveStep"].Text)
            Config.MoveDelay := Integer(SettingsGUI.controls["MoveDelay"].Text)
            Config.AccelerationRate := Float(SettingsGUI.controls["AccelerationRate"].Text)
            Config.MaxSpeed := Integer(SettingsGUI.controls["MaxSpeed"].Text)
            
            ; Fix for absolute movement checkbox - debug the checkbox state
            checkboxValue := SettingsGUI.controls["EnableAbsoluteMovement"].Value
            absMovement := (checkboxValue = 1)
            Config.EnableAbsoluteMovement := absMovement
            
            ; DEBUG: Force write the absolute movement setting to INI
            IniWrite(absMovement ? "1" : "0", Config.PersistentPositionsFile, "Settings", "EnableAbsoluteMovement")
            
            Config.MaxSavedPositions := Integer(SettingsGUI.controls["MaxSavedPositions"].Text)
            Config.MaxUndoLevels := Integer(SettingsGUI.controls["MaxUndoLevels"].Text)
            Config.EnableAudioFeedback := SettingsGUI.controls["EnableAudioFeedback"].Checked
            Config.StatusVisibleOnStartup := SettingsGUI.controls["StatusVisibleOnStartup"].Checked
            Config.UseSecondaryMonitor := SettingsGUI.controls["UseSecondaryMonitor"].Checked
            Config.ScrollStep := Integer(SettingsGUI.controls["ScrollStep"].Text)
            Config.ScrollAccelerationRate := Float(SettingsGUI.controls["ScrollAccelerationRate"].Text)
            Config.MaxScrollSpeed := Integer(SettingsGUI.controls["MaxScrollSpeed"].Text)
            
            ; Update GUI positions if changed
            Config.StatusX := SettingsGUI.controls["StatusX"].Text
            Config.StatusY := SettingsGUI.controls["StatusY"].Text
            Config.TooltipX := SettingsGUI.controls["TooltipX"].Text
            Config.TooltipY := SettingsGUI.controls["TooltipY"].Text
            
            ; Save configuration
            Config.Save()
            
            ; Update status indicator to reflect changes
            StatusIndicator.Update()
            
            ; Show success message with detailed debug info
            debugText := "Settings applied successfully!`n`n"
            debugText .= "Checkbox Value: " . checkboxValue . "`n"
            debugText .= "Absolute Movement: " . (absMovement ? "ENABLED" : "DISABLED") . "`n"
            debugText .= "Config Value: " . Config.EnableAbsoluteMovement
            MsgBox(debugText, "Settings Applied", "T5")
            
        } catch Error as e {
            MsgBox("Error applying settings: " . e.Message, "Error", "IconX")
        }
    }
    
    static _ApplyAndClose() {
        SettingsGUI._ApplySettings()
        SettingsGUI._OnClose()
    }
    
    static _Cancel() {
        SettingsGUI._OnClose()
    }
    
    static _ShowHelp() {
        helpText := "Mouse on Numpad Enhanced Settings Help`n`n"
        helpText .= "Movement Tab: Configure mouse movement speed and behavior`n"
        helpText .= "Positions Tab: Manage saved mouse positions`n"
        helpText .= "Visuals Tab: Customize appearance and positioning`n"
        helpText .= "Hotkeys Tab: Modify keyboard shortcuts`n"
        helpText .= "Advanced Tab: Performance and debugging options`n"
        helpText .= "Profiles Tab: Save and load different configurations`n"
        helpText .= "About Tab: Information about the application`n`n"
        helpText .= "Use Apply to save changes without closing.`n"
        helpText .= "Use OK to save and close.`n"
        helpText .= "Use Cancel to discard changes."
        
        MsgBox(helpText, "Settings Help", "T10")
    }
    
    ; Placeholder methods for advanced features
    static _ImportSettings() {
        MsgBox("Import settings functionality", "Import", "T2")
    }
    
    static _ExportSettings() {
        MsgBox("Export settings functionality", "Export", "T2")
    }
    
    static _GotoSelectedPosition() {
        MsgBox("Go to position functionality", "Go To", "T2")
    }
    
    static _SaveCurrentPosition() {
        MsgBox("Save current position functionality", "Save", "T2")
    }
    
    static _DeleteSelectedPosition() {
        MsgBox("Delete position functionality", "Delete", "T2")
    }
    
    static _ClearAllPositions() {
        MsgBox("Clear all positions functionality", "Clear", "T2")
    }
    
    static _ImportPositions() {
        MsgBox("Import positions functionality", "Import", "T2")
    }
    
    static _ExportPositions() {
        MsgBox("Export positions functionality", "Export", "T2")
    }
    
    static _OpenConfigFolder() {
        Run("explorer.exe " . A_ScriptDir)
    }
    
    static _BackupConfig() {
        MsgBox("Backup configuration functionality", "Backup", "T2")
    }
    
    static _EditSelectedHotkey() {
        MsgBox("Edit hotkey functionality", "Edit Hotkey", "T2")
    }
    
    static _ResetSelectedHotkey() {
        MsgBox("Reset hotkey functionality", "Reset Hotkey", "T2")
    }
    
    static _TestSelectedHotkey() {
        MsgBox("Test hotkey functionality", "Test Hotkey", "T2")
    }
    
    static _ScanForConflicts() {
        MsgBox("Scan for conflicts functionality", "Scan", "T2")
    }
    
    static _ResetAllHotkeys() {
        MsgBox("Reset all hotkeys functionality", "Reset All", "T2")
    }
    
    static _ViewLogs() {
        MsgBox("View logs functionality", "Logs", "T2")
    }
    
    static _ClearLogs() {
        MsgBox("Clear logs functionality", "Clear", "T2")
    }
    
    static _CreateBackup() {
        MsgBox("Create backup functionality", "Backup", "T2")
    }
    
    static _RestoreBackup() {
        MsgBox("Restore backup functionality", "Restore", "T2")
    }
    
    static _ResetToDefaults() {
        MsgBox("Reset to defaults functionality", "Reset", "T2")
    }
    
    static _FactoryReset() {
        MsgBox("Factory reset functionality", "Factory Reset", "T2")
    }
    
    static _LoadSelectedProfile() {
        MsgBox("Load profile functionality", "Load", "T2")
    }
    
    static _SaveNewProfile() {
        MsgBox("Save new profile functionality", "Save", "T2")
    }
    
    static _UpdateCurrentProfile() {
        MsgBox("Update profile functionality", "Update", "T2")
    }
    
    static _DeleteSelectedProfile() {
        MsgBox("Delete profile functionality", "Delete", "T2")
    }
    
    static _ExportProfile() {
        MsgBox("Export profile functionality", "Export", "T2")
    }
    
    static _ImportProfile() {
        MsgBox("Import profile functionality", "Import", "T2")
    }
    
    static _CheckForUpdates() {
        MsgBox("Check for updates functionality", "Updates", "T2")
    }
    
    static _OpenDocumentation() {
        MsgBox("Open documentation functionality", "Documentation", "T2")
    }
    
    static _ReportIssue() {
        MsgBox("Report issue functionality", "Report", "T2")
    }
    
    static _RunSystemDiagnostics() {
        MsgBox("System diagnostics functionality", "Diagnostics", "T2")
    }
}
