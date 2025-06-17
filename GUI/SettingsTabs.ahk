#Requires AutoHotkey v2.0

; ######################################################################################################################
; Settings GUI Tabs - All tab creation methods
; ######################################################################################################################

; This file extends the SettingsGUI class with tab creation methods
; It should be included by SettingsGUI.ahk

; Movement Tab
SettingsGUI._CreateMovementTab := (*) {
    ; Movement Settings Tab
    SettingsGUI.controls["TabControl"].UseTab(1)

    ; Movement Speed Section
    movementGroup := SettingsGUI.gui.Add("GroupBox", "x20 y50 w400 h130", " 🎯 Movement Speed ")
    movementGroup.SetFont("s10 Bold", "Segoe UI")
    if (SettingsGUI.isDarkMode) {
        movementGroup.Opt("cWhite")
    }

    yOffset := 80
    moveStepLabel := SettingsGUI.gui.Add("Text", "x40 y" . yOffset . " w120", "Move Step:")
    if (SettingsGUI.isDarkMode) {
        moveStepLabel.Opt("cE0E0E0")
    }
    SettingsGUI.controls["MoveStep"] := SettingsGUI.gui.Add("Edit", "x160 y" . (yOffset - 3) . " w60 Number")
    SettingsGUI.controls["MoveStep"].Text := SettingsGUI.tempSettings["MoveStep"]
    SettingsGUI.controls["MoveStep"].OnEvent("Change", (*) => SettingsGUI._UpdateMovementPreview())
    SettingsGUI.controls["MoveStepUpDown"] := SettingsGUI.gui.Add("UpDown", "x220 y" . (yOffset - 3) .
    " w20 h20 Range1-50", SettingsGUI.tempSettings["MoveStep"])
    moveStepDesc := SettingsGUI.gui.Add("Text", "x245 y" . yOffset . " w150", "pixels per movement")
    if (SettingsGUI.isDarkMode) {
        moveStepDesc.Opt("cSilver")
    }

    yOffset += 30
    moveDelayLabel := SettingsGUI.gui.Add("Text", "x40 y" . yOffset . " w120", "Move Delay:")
    if (SettingsGUI.isDarkMode) {
        moveDelayLabel.Opt("cE0E0E0")
    }
    SettingsGUI.controls["MoveDelay"] := SettingsGUI.gui.Add("Edit", "x160 y" . (yOffset - 3) . " w60 Number")
    SettingsGUI.controls["MoveDelay"].Text := SettingsGUI.tempSettings["MoveDelay"]
    SettingsGUI.controls["MoveDelay"].OnEvent("Change", (*) => SettingsGUI._UpdateMovementPreview())
    SettingsGUI.controls["MoveDelayUpDown"] := SettingsGUI.gui.Add("UpDown", "x220 y" . (yOffset - 3) .
    " w20 h20 Range5-100", SettingsGUI.tempSettings["MoveDelay"])
    moveDelayDesc := SettingsGUI.gui.Add("Text", "x245 y" . yOffset . " w150", "milliseconds delay")
    if (SettingsGUI.isDarkMode) {
        moveDelayDesc.Opt("cSilver")
    }

    ; Acceleration Section
    accelGroup := SettingsGUI.gui.Add("GroupBox", "x20 y190 w400 h130", " ⚡ Acceleration Settings ")
    accelGroup.SetFont("s10 Bold", "Segoe UI")
    if (SettingsGUI.isDarkMode) {
        accelGroup.Opt("cWhite")
    }

    yOffset := 220
    accelRateLabel := SettingsGUI.gui.Add("Text", "x40 y" . yOffset . " w120", "Acceleration Rate:")
    if (SettingsGUI.isDarkMode) {
        accelRateLabel.Opt("cE0E0E0")
    }
    SettingsGUI.controls["AccelerationRate"] := SettingsGUI.gui.Add("Edit", "x160 y" . (yOffset - 3) . " w60")
    SettingsGUI.controls["AccelerationRate"].Text := SettingsGUI.tempSettings["AccelerationRate"]
    SettingsGUI.controls["AccelerationRate"].OnEvent("Change", (*) => SettingsGUI._UpdateMovementPreview())
    accelRateDesc := SettingsGUI.gui.Add("Text", "x245 y" . yOffset . " w150", "multiplier per step")
    if (SettingsGUI.isDarkMode) {
        accelRateDesc.Opt("cSilver")
    }

    yOffset += 30
    maxSpeedLabel := SettingsGUI.gui.Add("Text", "x40 y" . yOffset . " w120", "Max Speed:")
    if (SettingsGUI.isDarkMode) {
        maxSpeedLabel.Opt("cE0E0E0")
    }
    SettingsGUI.controls["MaxSpeed"] := SettingsGUI.gui.Add("Edit", "x160 y" . (yOffset - 3) . " w60 Number")
    SettingsGUI.controls["MaxSpeed"].Text := SettingsGUI.tempSettings["MaxSpeed"]
    SettingsGUI.controls["MaxSpeed"].OnEvent("Change", (*) => SettingsGUI._UpdateMovementPreview())
    SettingsGUI.controls["MaxSpeedUpDown"] := SettingsGUI.gui.Add("UpDown", "x220 y" . (yOffset - 3) .
    " w20 h20 Range5-100", SettingsGUI.tempSettings["MaxSpeed"])
    maxSpeedDesc := SettingsGUI.gui.Add("Text", "x245 y" . yOffset . " w150", "maximum pixels/move")
    if (SettingsGUI.isDarkMode) {
        maxSpeedDesc.Opt("cSilver")
    }

    ; Movement Mode Section
    modeGroup := SettingsGUI.gui.Add("GroupBox", "x20 y330 w400 h70", " 🎮 Movement Modes ")
    modeGroup.SetFont("s10 Bold", "Segoe UI")
    if (SettingsGUI.isDarkMode) {
        modeGroup.Opt("cWhite")
    }

    SettingsGUI.controls["EnableAbsoluteMovement"] := SettingsGUI.gui.Add("CheckBox", "x40 y355 w300",
        "Enable Absolute Movement")
    SettingsGUI.controls["EnableAbsoluteMovement"].Value := Config.EnableAbsoluteMovement ? 1 : 0
    SettingsGUI.controls["EnableAbsoluteMovement"].OnEvent("Click", (*) => SettingsGUI._UpdateMovementPreview())
    if (SettingsGUI.isDarkMode) {
        SettingsGUI.controls["EnableAbsoluteMovement"].Opt("cWhite")
    }
    absDesc := SettingsGUI.gui.Add("Text", "x60 y375 w340",
        "Use absolute coordinates instead of relative movement")
    absDesc.SetFont("s8")
    if (SettingsGUI.isDarkMode) {
        absDesc.Opt("cSilver")
    }

    ; Scroll Settings Section
    scrollGroup := SettingsGUI.gui.Add("GroupBox", "x20 y410 w400 h90", " 📜 Scroll Settings ")
    scrollGroup.SetFont("s10 Bold", "Segoe UI")
    if (SettingsGUI.isDarkMode) {
        scrollGroup.Opt("cWhite")
    }

    scrollStepLabel := SettingsGUI.gui.Add("Text", "x40 y440 w120", "Scroll Step:")
    if (SettingsGUI.isDarkMode) {
        scrollStepLabel.Opt("cE0E0E0")
    }
    SettingsGUI.controls["ScrollStep"] := SettingsGUI.gui.Add("Edit", "x160 y437 w60 Number")
    SettingsGUI.controls["ScrollStep"].Text := SettingsGUI.tempSettings["ScrollStep"]
    SettingsGUI.controls["ScrollStep"].OnEvent("Change", (*) => SettingsGUI._UpdateMovementPreview())
    SettingsGUI.controls["ScrollStepUpDown"] := SettingsGUI.gui.Add("UpDown", "x220 y437 w20 h20 Range1-10", 
        SettingsGUI.tempSettings["ScrollStep"])
    scrollStepDesc := SettingsGUI.gui.Add("Text", "x245 y440 w150", "lines per step")
    if (SettingsGUI.isDarkMode) {
        scrollStepDesc.Opt("cSilver")
    }

    ; Preview Section
    previewGroup := SettingsGUI.gui.Add("GroupBox", "x440 y50 w320 h450", " 📊 Movement Preview ")
    previewGroup.SetFont("s10 Bold", "Segoe UI")
    if (SettingsGUI.isDarkMode) {
        previewGroup.Opt("cWhite")
    }
    
    SettingsGUI.controls["MovementPreview"] := SettingsGUI.gui.Add("Edit",
        "x450 y75 w300 h415 +VScroll +ReadOnly +Wrap")
    SettingsGUI.controls["MovementPreview"].SetFont("s8", "Consolas")
    SettingsGUI._UpdateMovementPreview()
}

; Position Tab
SettingsGUI._CreatePositionTab := (*) {
    SettingsGUI.controls["TabControl"].UseTab(2)

    ; Position Slots Section
    slotGroup := SettingsGUI.gui.Add("GroupBox", "x20 y50 w400 h100", " 💾 Position Memory ")
    slotGroup.SetFont("s10 Bold", "Segoe UI")
    if (SettingsGUI.isDarkMode) {
        slotGroup.Opt("cWhite")
    }

    maxPosLabel := SettingsGUI.gui.Add("Text", "x40 y85 w150", "Maximum Saved Positions:")
    if (SettingsGUI.isDarkMode) {
        maxPosLabel.Opt("cE0E0E0")
    }
    SettingsGUI.controls["MaxSavedPositions"] := SettingsGUI.gui.Add("Edit", "x190 y82 w60 Number")
    SettingsGUI.controls["MaxSavedPositions"].Text := SettingsGUI.tempSettings["MaxSavedPositions"]
    SettingsGUI.controls["MaxSavedPositionsUpDown"] := SettingsGUI.gui.Add("UpDown", "x250 y82 w20 h20 Range1-100",
        SettingsGUI.tempSettings["MaxSavedPositions"])
    maxPosDesc := SettingsGUI.gui.Add("Text", "x275 y85 w130", "(1-100 slots)")
    if (SettingsGUI.isDarkMode) {
        maxPosDesc.Opt("cSilver")
    }

    maxUndoLabel := SettingsGUI.gui.Add("Text", "x40 y110 w150", "Maximum Undo Levels:")
    if (SettingsGUI.isDarkMode) {
        maxUndoLabel.Opt("cE0E0E0")
    }
    SettingsGUI.controls["MaxUndoLevels"] := SettingsGUI.gui.Add("Edit", "x190 y107 w60 Number")
    SettingsGUI.controls["MaxUndoLevels"].Text := SettingsGUI.tempSettings["MaxUndoLevels"]
    SettingsGUI.controls["MaxUndoLevelsUpDown"] := SettingsGUI.gui.Add("UpDown", "x250 y107 w20 h20 Range1-50",
        SettingsGUI.tempSettings["MaxUndoLevels"])
    maxUndoDesc := SettingsGUI.gui.Add("Text", "x275 y110 w130", "(1-50 steps)")
    if (SettingsGUI.isDarkMode) {
        maxUndoDesc.Opt("cSilver")
    }

    ; Current Positions Section
    posListGroup := SettingsGUI.gui.Add("GroupBox", "x20 y160 w520 h200", " 📍 Saved Positions ")
    posListGroup.SetFont("s10 Bold", "Segoe UI")
    if (SettingsGUI.isDarkMode) {
        posListGroup.Opt("cWhite")
    }

    ; Position List
    SettingsGUI.controls["PositionList"] := SettingsGUI.gui.Add("ListView", "x30 y185 w500 h150", 
        ["Slot", "X", "Y", "Description"])
    SettingsGUI.controls["PositionList"].ModifyCol(1, 50)
    SettingsGUI.controls["PositionList"].ModifyCol(2, 80)
    SettingsGUI.controls["PositionList"].ModifyCol(3, 80)
    SettingsGUI.controls["PositionList"].ModifyCol(4, 280)
    SettingsGUI.controls["PositionList"].OnEvent("DoubleClick", (*) => SettingsGUI._GotoSelectedPosition())

    ; Position Management Buttons
    SettingsGUI.controls["GotoPosition"] := SettingsGUI.gui.Add("Button", "x550 y185 w120 h25", "Go to Position")
    SettingsGUI.controls["GotoPosition"].OnEvent("Click", (*) => SettingsGUI._GotoSelectedPosition())

    SettingsGUI.controls["PreviewPosition"] := SettingsGUI.gui.Add("Button", "x550 y215 w120 h25", "Preview")
    SettingsGUI.controls["PreviewPosition"].OnEvent("Click", (*) => SettingsGUI._PreviewSelectedPosition())

    SettingsGUI.controls["SaveCurrentPos"] := SettingsGUI.gui.Add("Button", "x550 y245 w120 h25", "Save Mouse Pos")
    SettingsGUI.controls["SaveCurrentPos"].OnEvent("Click", (*) => SettingsGUI._SaveCurrentPosition())

    SettingsGUI.controls["DeletePosition"] := SettingsGUI.gui.Add("Button", "x550 y275 w120 h25", "Delete Position")
    SettingsGUI.controls["DeletePosition"].OnEvent("Click", (*) => SettingsGUI._DeleteSelectedPosition())

    SettingsGUI.controls["ClearAllPositions"] := SettingsGUI.gui.Add("Button", "x550 y305 w120 h25", "Clear All")
    SettingsGUI.controls["ClearAllPositions"].OnEvent("Click", (*) => SettingsGUI._ClearAllPositions())

    ; Import/Export buttons
    SettingsGUI.controls["ImportPositions"] := SettingsGUI.gui.Add("Button", "x30 y345 w120 h25", "Import...")
    SettingsGUI.controls["ImportPositions"].OnEvent("Click", (*) => SettingsGUI._ImportPositions())

    SettingsGUI.controls["ExportPositions"] := SettingsGUI.gui.Add("Button", "x160 y345 w120 h25", "Export...")
    SettingsGUI.controls["ExportPositions"].OnEvent("Click", (*) => SettingsGUI._ExportPositions())

    SettingsGUI._PopulatePositionList()
}

; Visuals Tab
SettingsGUI._CreateVisualsTab := (*) {
    SettingsGUI.controls["TabControl"].UseTab(3)

    ; Status Display Section
    statusGroup := SettingsGUI.gui.Add("GroupBox", "x20 y50 w400 h100", " 📺 Status Display ")
    statusGroup.SetFont("s10 Bold", "Segoe UI")
    if (SettingsGUI.isDarkMode) {
        statusGroup.Opt("cWhite")
    }

    SettingsGUI.controls["StatusVisibleOnStartup"] := SettingsGUI.gui.Add("CheckBox", "x40 y85 w300",
        "Show Status on Startup")
    SettingsGUI.controls["StatusVisibleOnStartup"].Value := SettingsGUI.tempSettings["StatusVisibleOnStartup"] ? 1 : 0
    if (SettingsGUI.isDarkMode) {
        SettingsGUI.controls["StatusVisibleOnStartup"].Opt("cWhite")
    }

    SettingsGUI.controls["UseSecondaryMonitor"] := SettingsGUI.gui.Add("CheckBox", "x40 y110 w300",
        "Use Secondary Monitor")
    SettingsGUI.controls["UseSecondaryMonitor"].Value := SettingsGUI.tempSettings["UseSecondaryMonitor"] ? 1 : 0
    if (SettingsGUI.isDarkMode) {
        SettingsGUI.controls["UseSecondaryMonitor"].Opt("cWhite")
    }

    ; Audio Feedback Section
    audioGroup := SettingsGUI.gui.Add("GroupBox", "x20 y160 w400 h70", " 🔊 Audio Feedback ")
    audioGroup.SetFont("s10 Bold", "Segoe UI")
    if (SettingsGUI.isDarkMode) {
        audioGroup.Opt("cWhite")
    }

    SettingsGUI.controls["EnableAudioFeedback"] := SettingsGUI.gui.Add("CheckBox", "x40 y195 w200",
        "Enable Audio Feedback")
    SettingsGUI.controls["EnableAudioFeedback"].Value := SettingsGUI.tempSettings["EnableAudioFeedback"] ? 1 : 0
    if (SettingsGUI.isDarkMode) {
        SettingsGUI.controls["EnableAudioFeedback"].Opt("cWhite")
    }

    SettingsGUI.controls["TestAudio"] := SettingsGUI.gui.Add("Button", "x260 y193 w100 h25", "Test Audio")
    SettingsGUI.controls["TestAudio"].OnEvent("Click", (*) => SettingsGUI._TestAudio())

    ; Color Theme Section
    themeGroup := SettingsGUI.gui.Add("GroupBox", "x440 y50 w320 h180", " 🎨 Color Themes ")
    themeGroup.SetFont("s10 Bold", "Segoe UI")
    if (SettingsGUI.isDarkMode) {
        themeGroup.Opt("cWhite")
    }

    themeLabel := SettingsGUI.gui.Add("Text", "x460 y85 w80", "Theme:")
    if (SettingsGUI.isDarkMode) {
        themeLabel.Opt("cE0E0E0")
    }
    SettingsGUI.controls["ColorTheme"] := SettingsGUI.gui.Add("DropDownList", "x540 y82 w150", 
        ["Default", "Dark Mode", "High Contrast", "Minimal"])
    
    ; Find and select current theme
    themeIndex := 1
    themeNames := ["Default", "Dark Mode", "High Contrast", "Minimal"]
    Loop themeNames.Length {
        if (themeNames[A_Index] = SettingsGUI.tempSettings["ColorTheme"]) {
            themeIndex := A_Index
            break
        }
    }
    SettingsGUI.controls["ColorTheme"].Choose(themeIndex)
    SettingsGUI.controls["ColorTheme"].OnEvent("Change", (*) => SettingsGUI._UpdateVisualsPreview())

    ; Apply Theme Button
    SettingsGUI.controls["ApplyTheme"] := SettingsGUI.gui.Add("Button", "x460 y195 w140 h25", "Apply Theme Now")
    SettingsGUI.controls["ApplyTheme"].OnEvent("Click", (*) => SettingsGUI._ApplyThemeNow())

    ; Preview Section
    previewGroup := SettingsGUI.gui.Add("GroupBox", "x440 y240 w320 h220", " 📊 Preview ")
    previewGroup.SetFont("s10 Bold", "Segoe UI")
    if (SettingsGUI.isDarkMode) {
        previewGroup.Opt("cWhite")
    }
    
    SettingsGUI.controls["VisualPreview"] := SettingsGUI.gui.Add("Edit", 
        "x450 y265 w300 h185 +VScroll +ReadOnly +Wrap")
    SettingsGUI.controls["VisualPreview"].SetFont("s8", "Consolas")
    SettingsGUI._UpdateVisualsPreview()
}

SettingsGUI._CreateHotkeysTab := (*) {
    ; Hotkey Customization Tab
    SettingsGUI.controls["TabControl"].UseTab(4)

    ; Hotkey List Section
    hotkeyGroup := SettingsGUI.gui.Add("GroupBox", "x20 y50 w760 h340", " ⌨️ Hotkey Configuration ")
    hotkeyGroup.SetFont("s10 Bold", "Segoe UI")
    if (SettingsGUI.isDarkMode) {
    hotkeyGroup.Opt("cWhite")
    }

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
    conflictGroup := SettingsGUI.gui.Add("GroupBox", "x20 y400 w760 h60", " ⚠️ Conflict Detection ")
    conflictGroup.SetFont("s10 Bold", "Segoe UI")
    if (SettingsGUI.isDarkMode) {
    conflictGroup.Opt("cWhite")
    }

    SettingsGUI.controls["ConflictStatus"] := SettingsGUI.gui.Add("Text", "x40 y430 w450 h20")
    SettingsGUI.controls["ConflictStatus"].Text := "No conflicts detected"
    if (SettingsGUI.isDarkMode) {
    SettingsGUI.controls["ConflictStatus"].Opt("cLime")
    }

    SettingsGUI.controls["ScanConflicts"] := SettingsGUI.gui.Add("Button", "x510 y427 w120 h25",
    "Scan for Conflicts")
    SettingsGUI.controls["ScanConflicts"].OnEvent("Click", (*) => SettingsGUI._ScanForConflicts())

    SettingsGUI.controls["ResetAllHotkeys"] := SettingsGUI.gui.Add("Button", "x640 y427 w120 h25", "Reset All")
    SettingsGUI.controls["ResetAllHotkeys"].OnEvent("Click", (*) => SettingsGUI._ResetAllHotkeys())
}

SettingsGUI._CreateAdvancedTab := (*) {
    ; Advanced Settings Tab with scrollable content
    SettingsGUI.controls["TabControl"].UseTab(5)

    ; Performance Section
    perfGroup := SettingsGUI.gui.Add("GroupBox", "x20 y50 w370 h170", " ⚡ Performance Settings ")
    perfGroup.SetFont("s10 Bold", "Segoe UI")
    if (SettingsGUI.isDarkMode) {
        perfGroup.Opt("cWhite")
    }

    SettingsGUI.controls["LowMemoryMode"] := SettingsGUI.gui.Add("CheckBox", "x40 y85 w200",
        "Enable Low Memory Mode")
    if (SettingsGUI.isDarkMode) {
        SettingsGUI.controls["LowMemoryMode"].Opt("cWhite")
    }
    lowMemDesc := SettingsGUI.gui.Add("Text", "x60 y105 w300", "Reduces memory usage at the cost of some features")
    lowMemDesc.SetFont("s8")
    if (SettingsGUI.isDarkMode) {
        lowMemDesc.Opt("cSilver")
    }

    SettingsGUI.controls["ReduceAnimations"] := SettingsGUI.gui.Add("CheckBox", "x40 y125 w200",
        "Reduce Animations")
    if (SettingsGUI.isDarkMode) {
        SettingsGUI.controls["ReduceAnimations"].Opt("cWhite")
    }
    reduceAnimDesc := SettingsGUI.gui.Add("Text", "x60 y145 w300", "Disables visual effects for better performance"
    )
    reduceAnimDesc.SetFont("s8")
    if (SettingsGUI.isDarkMode) {
        reduceAnimDesc.Opt("cSilver")
    }

    ; Update Frequency
    updateFreqLabel := SettingsGUI.gui.Add("Text", "x40 y175 w150", "Update Frequency:")
    if (SettingsGUI.isDarkMode) {
        updateFreqLabel.Opt("cE0E0E0")
    }
    SettingsGUI.controls["UpdateFrequency"] := SettingsGUI.gui.Add("Edit", "x190 y172 w60 Number")
    SettingsGUI.controls["UpdateFrequency"].Text := "500"
    SettingsGUI.controls["UpdateFrequencyUpDown"] := SettingsGUI.gui.Add("UpDown",
        "x250 y172 w20 h20 Range100-2000", 500)
    updateFreqDesc := SettingsGUI.gui.Add("Text", "x275 y175 w100", "ms between updates")
    if (SettingsGUI.isDarkMode) {
        updateFreqDesc.Opt("cSilver")
    }

    ; Logging Section
    logGroup := SettingsGUI.gui.Add("GroupBox", "x20 y230 w370 h120", " 📝 Logging & Debugging ")
    logGroup.SetFont("s10 Bold", "Segoe UI")
    if (SettingsGUI.isDarkMode) {
        logGroup.Opt("cWhite")
    }

    SettingsGUI.controls["EnableLogging"] := SettingsGUI.gui.Add("CheckBox", "x40 y260 w200",
        "Enable Debug Logging")
    if (SettingsGUI.isDarkMode) {
        SettingsGUI.controls["EnableLogging"].Opt("cWhite")
    }
    enableLogDesc := SettingsGUI.gui.Add("Text", "x60 y280 w300", "Logs actions for troubleshooting")
    enableLogDesc.SetFont("s8")
    if (SettingsGUI.isDarkMode) {
        enableLogDesc.Opt("cSilver")
    }

    SettingsGUI.controls["LogLevel"] := SettingsGUI.gui.Add("DropDownList", "x260 y258 w100", ["Error", "Warning",
        "Info", "Debug"])
    SettingsGUI.controls["LogLevel"].Choose(2)

    ; Log Management Buttons
    SettingsGUI.controls["ViewLogs"] := SettingsGUI.gui.Add("Button", "x40 y305 w100 h25", "View Logs")
    SettingsGUI.controls["ViewLogs"].OnEvent("Click", (*) => SettingsGUI._ViewLogs())

    SettingsGUI.controls["ClearLogs"] := SettingsGUI.gui.Add("Button", "x150 y305 w100 h25", "Clear Logs")
    SettingsGUI.controls["ClearLogs"].OnEvent("Click", (*) => SettingsGUI._ClearLogs())

    ; Advanced Features Section
    advGroup := SettingsGUI.gui.Add("GroupBox", "x410 y50 w370 h200", " 🚀 Advanced Features ")
    advGroup.SetFont("s10 Bold", "Segoe UI")
    if (SettingsGUI.isDarkMode) {
        advGroup.Opt("cWhite")
    }

    SettingsGUI.controls["EnableGestures"] := SettingsGUI.gui.Add("CheckBox", "x430 y85 w200",
        "Enable Gesture Recognition")
    if (SettingsGUI.isDarkMode) {
        SettingsGUI.controls["EnableGestures"].Opt("cWhite")
    }
    gestureDesc := SettingsGUI.gui.Add("Text", "x450 y105 w300", "Recognize mouse gestures for quick actions")
    gestureDesc.SetFont("s8")
    if (SettingsGUI.isDarkMode) {
        gestureDesc.Opt("cSilver")
    }

    SettingsGUI.controls["EnableAnalytics"] := SettingsGUI.gui.Add("CheckBox", "x430 y125 w200",
        "Enable Usage Analytics")
    if (SettingsGUI.isDarkMode) {
        SettingsGUI.controls["EnableAnalytics"].Opt("cWhite")
    }
    analyticsDesc := SettingsGUI.gui.Add("Text", "x450 y145 w300", "Track usage patterns for optimization")
    analyticsDesc.SetFont("s8")
    if (SettingsGUI.isDarkMode) {
        analyticsDesc.Opt("cSilver")
    }

    SettingsGUI.controls["EnableCloudSync"] := SettingsGUI.gui.Add("CheckBox", "x430 y165 w200",
        "Enable Cloud Synchronization")
    if (SettingsGUI.isDarkMode) {
        SettingsGUI.controls["EnableCloudSync"].Opt("cWhite")
    }
    cloudDesc := SettingsGUI.gui.Add("Text", "x450 y185 w300", "Sync settings across devices")
    cloudDesc.SetFont("s8")
    if (SettingsGUI.isDarkMode) {
        cloudDesc.Opt("cSilver")
    }

    ; Experimental Features
    expGroup := SettingsGUI.gui.Add("GroupBox", "x410 y260 w370 h140", " 🧪 Experimental Features ")
    expGroup.SetFont("s10 Bold", "Segoe UI")
    if (SettingsGUI.isDarkMode) {
        expGroup.Opt("cWhite")
    }

    SettingsGUI.controls["EnablePrediction"] := SettingsGUI.gui.Add("CheckBox", "x430 y290 w200",
        "Enable Movement Prediction")
    if (SettingsGUI.isDarkMode) {
        SettingsGUI.controls["EnablePrediction"].Opt("cWhite")
    }
    predictionDesc := SettingsGUI.gui.Add("Text", "x450 y310 w300", "Predict and suggest common movements")
    predictionDesc.SetFont("s8")
    if (SettingsGUI.isDarkMode) {
        predictionDesc.Opt("cSilver")
    }

    SettingsGUI.controls["EnableMagneticSnap"] := SettingsGUI.gui.Add("CheckBox", "x430 y330 w200",
        "Enable Magnetic Snapping")
    if (SettingsGUI.isDarkMode) {
        SettingsGUI.controls["EnableMagneticSnap"].Opt("cWhite")
    }
    magneticDesc := SettingsGUI.gui.Add("Text", "x450 y350 w300", "Automatically snap to UI elements")
    magneticDesc.SetFont("s8")
    if (SettingsGUI.isDarkMode) {
        magneticDesc.Opt("cSilver")
    }

    ; Reset Section
    resetGroup := SettingsGUI.gui.Add("GroupBox", "x20 y360 w370 h100", " 🔄 Reset Options ")
    resetGroup.SetFont("s10 Bold", "Segoe UI")
    if (SettingsGUI.isDarkMode) {
        resetGroup.Opt("cWhite")
    }

    SettingsGUI.controls["ResetToDefaults"] := SettingsGUI.gui.Add("Button", "x40 y395 w150 h25",
        "Reset to Defaults")
    SettingsGUI.controls["ResetToDefaults"].OnEvent("Click", (*) => SettingsGUI._ResetToDefaults())

    SettingsGUI.controls["FactoryReset"] := SettingsGUI.gui.Add("Button", "x40 y425 w150 h25", "Factory Reset")
    SettingsGUI.controls["FactoryReset"].OnEvent("Click", (*) => SettingsGUI._FactoryReset())
}

SettingsGUI._CreateProfilesTab := (*) {
    ; Profiles Management Tab
    SettingsGUI.controls["TabControl"].UseTab(6)

    ; Profile List Section
    profileListGroup := SettingsGUI.gui.Add("GroupBox", "x20 y50 w540 h240", " 👤 Configuration Profiles ")
    profileListGroup.SetFont("s10 Bold", "Segoe UI")
    if (SettingsGUI.isDarkMode) {
        profileListGroup.Opt("cWhite")
    }

    ; Profile ListView
    SettingsGUI.controls["ProfileList"] := SettingsGUI.gui.Add("ListView", "x30 y75 w500 h200", ["Profile Name",
        "Description", "Last Modified"])
    SettingsGUI.controls["ProfileList"].ModifyCol(1, 150)
    SettingsGUI.controls["ProfileList"].ModifyCol(2, 250)
    SettingsGUI.controls["ProfileList"].ModifyCol(3, 100)

    ; Populate with default profiles
    SettingsGUI._PopulateProfileList()

    ; Profile Management Buttons
    SettingsGUI.controls["LoadProfile"] := SettingsGUI.gui.Add("Button", "x570 y75 w120 h25", "Load Profile")
    SettingsGUI.controls["LoadProfile"].OnEvent("Click", (*) => SettingsGUI._LoadSelectedProfile())

    SettingsGUI.controls["SaveProfile"] := SettingsGUI.gui.Add("Button", "x570 y105 w120 h25", "Save as New...")
    SettingsGUI.controls["SaveProfile"].OnEvent("Click", (*) => SettingsGUI._SaveNewProfile())

    SettingsGUI.controls["UpdateProfile"] := SettingsGUI.gui.Add("Button", "x570 y135 w120 h25", "Update Current")
    SettingsGUI.controls["UpdateProfile"].OnEvent("Click", (*) => SettingsGUI._UpdateCurrentProfile())

    SettingsGUI.controls["DeleteProfile"] := SettingsGUI.gui.Add("Button", "x570 y165 w120 h25", "Delete Profile")
    SettingsGUI.controls["DeleteProfile"].OnEvent("Click", (*) => SettingsGUI._DeleteSelectedProfile())

    SettingsGUI.controls["ExportProfile"] := SettingsGUI.gui.Add("Button", "x570 y195 w120 h25", "Export...")
    SettingsGUI.controls["ExportProfile"].OnEvent("Click", (*) => SettingsGUI._ExportProfile())

    SettingsGUI.controls["ImportProfile"] := SettingsGUI.gui.Add("Button", "x570 y225 w120 h25", "Import...")
    SettingsGUI.controls["ImportProfile"].OnEvent("Click", (*) => SettingsGUI._ImportProfile())

    ; Current Profile Info
    currentLabel := SettingsGUI.gui.Add("Text", "x30 y295 w150 h20", "Current Profile:")
    if (SettingsGUI.isDarkMode) {
        currentLabel.Opt("cE0E0E0")
    }
    SettingsGUI.controls["CurrentProfileName"] := SettingsGUI.gui.Add("Text", "x180 y295 w200 h20 +0x200")
    SettingsGUI.controls["CurrentProfileName"].Text := "Default"
    SettingsGUI.controls["CurrentProfileName"].SetFont("Bold")
    if (SettingsGUI.isDarkMode) {
        SettingsGUI.controls["CurrentProfileName"].Opt("cLime")
    }

    ; Profile Description
    descGroup := SettingsGUI.gui.Add("GroupBox", "x20 y320 w760 h100", " 📝 Profile Description ")
    descGroup.SetFont("s10 Bold", "Segoe UI")
    if (SettingsGUI.isDarkMode) {
        descGroup.Opt("cWhite")
    }

    SettingsGUI.controls["ProfileDescription"] := SettingsGUI.gui.Add("Edit",
        "x30 y345 w740 h65 +VScroll +WantReturn")
    SettingsGUI.controls["ProfileDescription"].Text := "Default configuration profile with standard settings."

    ; Auto-Switch Settings
    autoGroup := SettingsGUI.gui.Add("GroupBox", "x20 y430 w760 h40", " 🔄 Auto-Switch Rules ")
    autoGroup.SetFont("s10 Bold", "Segoe UI")
    if (SettingsGUI.isDarkMode) {
        autoGroup.Opt("cWhite")
    }

    SettingsGUI.controls["EnableAutoSwitch"] := SettingsGUI.gui.Add("CheckBox", "x40 y450 w220",
        "Enable Auto Profile Switching")
    if (SettingsGUI.isDarkMode) {
        SettingsGUI.controls["EnableAutoSwitch"].Opt("cWhite")
    }
    autoSwitchDesc := SettingsGUI.gui.Add("Text", "x270 y450 w400",
        "Automatically switch profiles based on active application")
    if (SettingsGUI.isDarkMode) {
        autoSwitchDesc.Opt("cSilver")
    }
}



SettingsGUI._CreateAboutTab := (*) {
    ; About Tab
    SettingsGUI.controls["TabControl"].UseTab(7)

    ; About GroupBox
    aboutGroup := SettingsGUI.gui.Add("GroupBox", "x20 y50 w760 h420", " ℹ️ About Mouse on Numpad Enhanced ")
    aboutGroup.SetFont("s10 Bold", "Segoe UI")
    if (SettingsGUI.isDarkMode) {
        aboutGroup.Opt("cWhite")
    }

    ; Title and Version
    titleText := SettingsGUI.gui.Add("Text", "x30 y80 w740 h30 +Center", "Mouse on Numpad Enhanced")
    titleText.SetFont("s16 Bold")
    if (SettingsGUI.isDarkMode) {
        titleText.Opt("cWhite")
    }

    versionText := SettingsGUI.gui.Add("Text", "x30 y115 w740 h20 +Center",
        "Version 3.0.0 - Advanced Settings Panel")
    versionText.SetFont("s10")
    if (SettingsGUI.isDarkMode) {
        versionText.Opt("cSilver")
    }

    ; Description
    descText := SettingsGUI.gui.Add("Text", "x30 y150 w740 h60 +Wrap",
        "A comprehensive mouse control system using the numeric keypad. This enhanced version includes " .
        "advanced features like gesture recognition, analytics, profile management, and cloud synchronization.")
    if (SettingsGUI.isDarkMode) {
        descText.Opt("cE0E0E0")
    }

    ; Features List
    featuresLabel := SettingsGUI.gui.Add("Text", "x30 y220 w200 h20 +0x200", "Key Features")
    featuresLabel.SetFont("s10 Bold")
    if (SettingsGUI.isDarkMode) {
        featuresLabel.Opt("cWhite")
    }

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

    featuresContent := SettingsGUI.gui.Add("Text", "x30 y245 w340 h200 +Wrap", featuresText)
    if (SettingsGUI.isDarkMode) {
        featuresContent.Opt("cE0E0E0")
    }

    ; System Information
    sysInfoLabel := SettingsGUI.gui.Add("Text", "x400 y220 w200 h20 +0x200", "System Information")
    sysInfoLabel.SetFont("s10 Bold")
    if (SettingsGUI.isDarkMode) {
        sysInfoLabel.Opt("cWhite")
    }

    systemInfo := "AutoHotkey Version: " . A_AhkVersion . "`n" .
        "Operating System: " . A_OSVersion . "`n" .
        "Computer Name: " . A_ComputerName . "`n" .
        "User Name: " . A_UserName . "`n" .
        "Screen Resolution: " . A_ScreenWidth . "x" . A_ScreenHeight . "`n" .
        "Script Directory: " . A_ScriptDir

    sysInfoContent := SettingsGUI.gui.Add("Text", "x400 y245 w370 h150 +Wrap", systemInfo)
    if (SettingsGUI.isDarkMode) {
        sysInfoContent.Opt("cE0E0E0")
    }

    ; Action Buttons
    SettingsGUI.controls["CheckUpdates"] := SettingsGUI.gui.Add("Button", "x30 y410 w120 h30", "Check for Updates")
    SettingsGUI.controls["CheckUpdates"].OnEvent("Click", (*) => SettingsGUI._CheckForUpdates())

    SettingsGUI.controls["OpenDocumentation"] := SettingsGUI.gui.Add("Button", "x160 y410 w120 h30",
        "Documentation")
    SettingsGUI.controls["OpenDocumentation"].OnEvent("Click", (*) => SettingsGUI._OpenDocumentation())

    SettingsGUI.controls["ReportIssue"] := SettingsGUI.gui.Add("Button", "x290 y410 w120 h30", "Report Issue")
    SettingsGUI.controls["ReportIssue"].OnEvent("Click", (*) => SettingsGUI._ReportIssue())

    SettingsGUI.controls["SystemDiagnostics"] := SettingsGUI.gui.Add("Button", "x420 y410 w120 h30",
        "System Diagnostics")
    SettingsGUI.controls["SystemDiagnostics"].OnEvent("Click", (*) => SettingsGUI._RunSystemDiagnostics())

    ; Copyright and Credits
    creditText := SettingsGUI.gui.Add("Text", "x30 y455 w740 h20 +Wrap +Center",
        "Enhanced by Claude AI Assistant. Original concept and base implementation community-driven.")
    creditText.SetFont("s8")
    if (SettingsGUI.isDarkMode) {
        creditText.Opt("cSilver")
    }
}
; Continue with other tabs...
; Due to space, I'll indicate that the other tab methods follow the same pattern
;  _CreateProfilesTab(), _CreateAboutTab()