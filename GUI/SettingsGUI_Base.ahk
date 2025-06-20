#Requires AutoHotkey v2.0

; ######################################################################################################################
; Settings GUI Base Module - Core GUI framework and management
; ######################################################################################################################

class SettingsGUI {
    static gui := ""
    static currentTab := 1
    static tabs := []
    static controls := Map()
    static isOpen := false
    static tempSettings := Map()
    static tabManager := ""
    static tabModules := Map()

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

        ; Create tab manager
        SettingsGUI.tabManager := SettingsTabManager(SettingsGUI.gui)

        ; Create tab control with explicit height to leave room for buttons
        SettingsGUI.controls["TabControl"] := SettingsGUI.tabManager.CreateTabControl(
            "x10 y10 w780 h500",
            ["Movement", "Positions", "Visuals", "Hotkeys", "Advanced", "Profiles", "About"]
        )

        ; Apply clipping style to prevent overlapping issues
        SettingsGUI.controls["TabControl"].Opt("+0x4000000")  ; WS_CLIPSIBLINGS

        ; Tab change event
        SettingsGUI.controls["TabControl"].OnEvent("Change", (*) => SettingsGUI._OnTabChange())

        ; Register all tab modules
        SettingsGUI._RegisterTabModules()

        ; CRITICAL: Exit tab control scope before adding bottom buttons
        SettingsGUI.controls["TabControl"].UseTab()

        ; Create the bottom button bar AFTER exiting tab scope
        SettingsGUI._CreateBottomButtonBar()

        ; Show first tab AFTER creating all controls
        SettingsGUI._ShowTab(1)

        ; Position and show GUI LAST - this ensures proper rendering
        centerX := (A_ScreenWidth - 800) // 2
        centerY := (A_ScreenHeight - 600) // 2
        SettingsGUI.gui.Show("x" . centerX . " y" . centerY . " w800 h600")
    }

    static _RegisterTabModules() {
        ; Register each tab module with the tab manager
        SettingsGUI.tabModules["Movement"] := SettingsGUI.tabManager.RegisterModule("Movement", MovementTabModule)
        SettingsGUI.tabModules["Positions"] := SettingsGUI.tabManager.RegisterModule("Positions", PositionsTabModule)
        SettingsGUI.tabModules["Visuals"] := SettingsGUI.tabManager.RegisterModule("Visuals", VisualsTabModule)
        SettingsGUI.tabModules["Hotkeys"] := SettingsGUI.tabManager.RegisterModule("Hotkeys", HotkeysTabModule)
        SettingsGUI.tabModules["Advanced"] := SettingsGUI.tabManager.RegisterModule("Advanced", AdvancedTabModule)
        SettingsGUI.tabModules["Profiles"] := SettingsGUI.tabManager.RegisterModule("Profiles", ProfilesTabModule)
        SettingsGUI.tabModules["About"] := SettingsGUI.tabManager.RegisterModule("About", AboutTabModule)
    }

    static _InitializeTempSettings() {
        ; Copy current settings to temp storage for preview
        ; Movement Settings
        SettingsGUI.tempSettings["MoveStep"] := Config.Get("Movement.BaseSpeed")
        SettingsGUI.tempSettings["MoveDelay"] := Config.Get("Movement.MoveDelay")
        SettingsGUI.tempSettings["AccelerationRate"] := Config.Get("Movement.AccelerationRate")
        SettingsGUI.tempSettings["MaxSpeed"] := Config.Get("Movement.MaxSpeed")
        SettingsGUI.tempSettings["EnableAbsoluteMovement"] := Config.Get("Movement.EnableAbsoluteMovement")
        SettingsGUI.tempSettings["MaxSavedPositions"] := Config.Get("Positions.MaxSaved")
        SettingsGUI.tempSettings["MaxUndoLevels"] := Config.Get("Movement.MaxUndoLevels")
        SettingsGUI.tempSettings["EnableAudioFeedback"] := Config.Get("Visual.EnableAudioFeedback")
        SettingsGUI.tempSettings["StatusVisibleOnStartup"] := Config.StatusVisibleOnStartup
        SettingsGUI.tempSettings["UseSecondaryMonitor"] := Config.Get("Visual.UseSecondaryMonitor")
        SettingsGUI.tempSettings["ScrollStep"] := Config.Get("Movement.ScrollStep")
        SettingsGUI.tempSettings["ScrollAccelerationRate"] := Config.Get("Movement.ScrollAccelerationRate")
        SettingsGUI.tempSettings["MaxScrollSpeed"] := Config.Get("Movement.MaxScrollSpeed")
        ; Visuals Settings
        SettingsGUI.tempSettings["ColorTheme"] := Config.Get("Visual.ColorTheme")
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

    ; Event Handlers
    static _OnTabChange() {
        currentTab := SettingsGUI.controls["TabControl"].Value
        SettingsGUI._ShowTab(currentTab)
    }

    static _ShowTab(tabNumber) {
        SettingsGUI.currentTab := tabNumber

        ; Get tab name from index
        tabNames := ["Movement", "Positions", "Visuals", "Hotkeys", "Advanced", "Profiles", "About"]
        if (tabNumber >= 1 && tabNumber <= tabNames.Length) {
            tabName := tabNames[tabNumber]
            if (SettingsGUI.tabModules.Has(tabName)) {
                ; Call the tab module's refresh method if it exists
                module := SettingsGUI.tabModules[tabName]
                if (HasMethod(module, "Refresh")) {
                    module.Refresh()
                }
            }
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

    ; Main Action Methods
    static _ApplySettings() {
        ; First validate all tabs
        if (!SettingsGUI.tabManager.ValidateAll()) {
            MsgBox("Please correct the validation errors before applying settings.", "Validation Error", "IconX")
            return
        }

        ; CRITICAL FIX: This line was missing - Get data from all tabs
        allData := SettingsGUI.tabManager.GetAllData()

        ; Movement Settings
        if (allData.Has("Movement")) {
            movementData := allData["Movement"]
            ; OLD (INCORRECT):
            ; Config.Get("Movement.BaseSpeed") := movementData["moveStep"]

            ; NEW (CORRECT):
            Config.Set("Movement.BaseSpeed", movementData["moveStep"])
            Config.Set("Movement.MoveDelay", movementData["moveDelay"])
            Config.Set("Movement.AccelerationRate", movementData["accelerationRate"])
            Config.Set("Movement.MaxSpeed", movementData["maxSpeed"])
            Config.Set("Movement.EnableAbsoluteMovement", movementData["enableAbsoluteMovement"])
            Config.Set("Movement.ScrollStep", movementData["scrollStep"])
            Config.Set("Movement.ScrollAccelerationRate", movementData["scrollAccelerationRate"])
            Config.Set("Movement.MaxScrollSpeed", movementData["maxScrollSpeed"])
        }

        ; Position Settings
        if (allData.Has("Positions")) {
            positionData := allData["Positions"]
            Config.Set("Positions.MaxSaved", positionData["maxSavedPositions"])
            Config.Set("Movement.MaxUndoLevels", positionData["maxUndoLevels"])
        }

        ; Visual Settings
        if (allData.Has("Visuals")) {
            visualData := allData["Visuals"]
            Config.Set("Visual.EnableAudioFeedback", visualData["enableAudioFeedback"])
            Config.Set("Visual.StatusVisibleOnStartup", visualData["statusVisibleOnStartup"])
            Config.Set("Visual.UseSecondaryMonitor", visualData["useSecondaryMonitor"])
            Config.Set("Visual.StatusX", visualData["statusX"])
            Config.Set("Visual.StatusY", visualData["statusY"])
            Config.Set("Visual.TooltipX", visualData["tooltipX"])
            Config.Set("Visual.TooltipY", visualData["tooltipY"])
            Config.Set("Visual.ColorTheme", visualData["colorTheme"])

            ; Apply and save the color theme
            if (visualData.Has("colorTheme")) {
                Config.Set("Visual.ColorTheme", visualData["colorTheme"])
                ColorThemeManager.SetTheme(visualData["colorTheme"])
            }
        }

        ; Save configuration
        Config.Save()

        ; Update status indicator to reflect changes
        StatusIndicator.Update()

        ; Show success message
        MsgBox("Settings have been applied successfully!", "Settings Applied", "Iconi T3")
    }

    static _OKButtonClick() {
        ; Validate all tabs
        if (!SettingsGUI.tabManager.ValidateAll()) {
            MsgBox("Please correct the validation errors before saving.", "Validation Error", "IconX")
            return
        }
    
        ; CRITICAL FIX: Get data from all tabs
        allData := SettingsGUI.tabManager.GetAllData()
    
        ; Apply settings from each tab
        try {
            ; Movement Settings
            if (allData.Has("Movement")) {
                movementData := allData["Movement"]
                Config.Set("Movement.BaseSpeed", movementData["moveStep"])
                Config.Set("Movement.MoveDelay", movementData["moveDelay"])
                Config.Set("Movement.AccelerationRate", movementData["accelerationRate"])
                Config.Set("Movement.MaxSpeed", movementData["maxSpeed"])
                Config.Set("Movement.EnableAbsoluteMovement", movementData["enableAbsoluteMovement"])
                Config.Set("Movement.ScrollStep", movementData["scrollStep"])
                Config.Set("Movement.ScrollAccelerationRate", movementData["scrollAccelerationRate"])
                Config.Set("Movement.MaxScrollSpeed", movementData["maxScrollSpeed"])
            }
    
            ; Position Settings
            if (allData.Has("Positions")) {
                positionData := allData["Positions"]
                Config.Set("Positions.MaxSaved", positionData["maxSavedPositions"])
                Config.Set("Movement.MaxUndoLevels", positionData["maxUndoLevels"])
            }
    
            ; Visual Settings
            if (allData.Has("Visuals")) {
                visualData := allData["Visuals"]
                Config.Set("Visual.EnableAudioFeedback", visualData["enableAudioFeedback"])
                Config.Set("Visual.StatusVisibleOnStartup", visualData["statusVisibleOnStartup"])
                Config.Set("Visual.UseSecondaryMonitor", visualData["useSecondaryMonitor"])
                Config.Set("Visual.StatusX", visualData["statusX"])
                Config.Set("Visual.StatusY", visualData["statusY"])
                Config.Set("Visual.TooltipX", visualData["tooltipX"])
                Config.Set("Visual.TooltipY", visualData["tooltipY"])
                Config.Set("Visual.ColorTheme", visualData["colorTheme"])
                
                ; Apply and save the color theme
                if (visualData.Has("colorTheme")) {
                    Config.Set("Visual.ColorTheme", visualData["colorTheme"])
                    ColorThemeManager.SetTheme(visualData["colorTheme"])
                }
            }
    
            ; Save configuration
            Config.Save()
    
            ; Update status indicator to reflect changes
            StatusIndicator.Update()
    
            ; Close the GUI
            SettingsGUI._OnClose()
    
        } catch Error as e {
            MsgBox("Error saving settings: " . e.Message . "`n`nPlease check your input values.", 
                "Settings Error", "IconX")
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

    ; Placeholder methods for import/export
    static _ImportSettings() {
        MsgBox("Import settings functionality will be implemented in a future update.", "Import Settings", "Iconi T3")
    }

    static _ExportSettings() {
        MsgBox("Export settings functionality will be implemented in a future update.", "Export Settings", "Iconi T3")
    }
}
