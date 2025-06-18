#Requires AutoHotkey v2.0

; ######################################################################################################################
; Fixed Visuals Tab Module - With Working Color Theme Save/Apply
; ######################################################################################################################

class VisualsTabModule extends BaseTabModule {
    CreateControls() {
        ; Status Display Section
        this.gui.Add("Text", "x30 y50 w200 h20 +0x200", "Status Display").SetFont("s10 Bold")

        this.AddControl("StatusVisibleOnStartup", this.gui.Add("CheckBox", "x30 y75 w300",
            "Show Status on Startup"))
        this.controls["StatusVisibleOnStartup"].Value := this.tempSettings["StatusVisibleOnStartup"] ? 1 : 0

        this.AddControl("UseSecondaryMonitor", this.gui.Add("CheckBox", "x30 y100 w300",
            "Use Secondary Monitor"))
        this.controls["UseSecondaryMonitor"].Value := this.tempSettings["UseSecondaryMonitor"] ? 1 : 0

        ; Status Position Section
        this.gui.Add("Text", "x30 y140 w200 h20 +0x200", "Status Position").SetFont("s10 Bold")

        this.gui.Add("Text", "x30 y165 w80", "Status X:")
        this.AddControl("StatusX", this.gui.Add("Edit", "x110 y162 w150"))
        this.controls["StatusX"].Text := Config.Get("Visual.StatusX")
        this.gui.Add("Text", "x270 y165 w200", "X position or expression")

        this.gui.Add("Text", "x30 y190 w80", "Status Y:")
        this.AddControl("StatusY", this.gui.Add("Edit", "x110 y187 w150"))
        this.controls["StatusY"].Text := Config.Get("Visual.TooltipY")
        this.gui.Add("Text", "x270 y190 w200", "Y position or expression")

        ; Tooltip Position Section
        this.gui.Add("Text", "x30 y230 w200 h20 +0x200", "Tooltip Position").SetFont("s10 Bold")

        this.gui.Add("Text", "x30 y255 w80", "Tooltip X:")
        this.AddControl("TooltipX", this.gui.Add("Edit", "x110 y252 w150"))
        this.controls["TooltipX"].Text := Config.Get("Visual.TooltipX")
        this.gui.Add("Text", "x270 y255 w200", "X position or expression")

        this.gui.Add("Text", "x30 y280 w80", "Tooltip Y:")
        this.AddControl("TooltipY", this.gui.Add("Edit", "x110 y277 w150"))
        this.controls["TooltipY"].Text := Config.Get("Visual.TooltipY")
        this.gui.Add("Text", "x270 y280 w200", "Y position or expression")

        ; Audio Feedback Section
        this.gui.Add("Text", "x30 y320 w200 h20 +0x200", "Audio Feedback").SetFont("s10 Bold")

        this.AddControl("EnableAudioFeedback", this.gui.Add("CheckBox", "x30 y345 w200",
            "Enable Audio Feedback"))
        this.controls["EnableAudioFeedback"].Value := this.tempSettings["EnableAudioFeedback"] ? 1 : 0

        ; Test Audio Button
        this.AddControl("TestAudio", this.gui.Add("Button", "x250 y343 w100 h25", "Test Audio"))
        this.controls["TestAudio"].OnEvent("Click", (*) => this._TestAudio())

        ; Color Theme Section
        this.gui.Add("Text", "x450 y50 w200 h20 +0x200", "Color Themes").SetFont("s10 Bold")

        this.gui.Add("Text", "x450 y75 w80", "Theme:")
        this.AddControl("ColorTheme", this.gui.Add("DropDownList", "x530 y72 w150", 
            ColorThemeManager.GetThemeList()))
        
        ; Select current theme - Fixed to properly show saved theme
        currentTheme := Config.get("Visual.ColorTheme") != "" ? Config.get("Visual.ColorTheme") : "Default"
        themeIndex := 1
        themeList := ColorThemeManager.GetThemeList()
        for i, theme in themeList {
            if (theme = currentTheme) {
                this.controls["ColorTheme"].Choose(i)
                break
            }
        }
        
        this.controls["ColorTheme"].OnEvent("Change", (*) => this._OnThemeChange())

        ; Theme Preview Button
        this.AddControl("PreviewTheme", this.gui.Add("Button", "x690 y71 w60 h25", "Preview"))
        this.controls["PreviewTheme"].OnEvent("Click", (*) => this._PreviewTheme())

        ; Preview Section
        this.gui.Add("Text", "x450 y110 w200 h20 +0x200", "Preview").SetFont("s10 Bold")
        this.AddControl("VisualPreview", this.gui.Add("Edit", 
            "x450 y135 w300 h200 +VScroll +ReadOnly +Wrap"))
        this.controls["VisualPreview"].SetFont("s8", "Consolas")
        this._UpdateVisualsPreview()

        ; Position Test Buttons
        this.AddControl("TestStatusPosition", this.gui.Add("Button", "x450 y350 w140 h25",
            "Test Status Position"))
        this.controls["TestStatusPosition"].OnEvent("Click", (*) => this._TestStatusPosition())

        this.AddControl("TestTooltipPosition", this.gui.Add("Button", "x600 y350 w140 h25",
            "Test Tooltip Position"))
        this.controls["TestTooltipPosition"].OnEvent("Click", (*) => this._TestTooltipPosition())

        ; Theme Demo Buttons
        this.gui.Add("Text", "x30 y390 w200 h20 +0x200", "Theme Demonstration").SetFont("s10 Bold")
        
        this.AddControl("DemoTooltips", this.gui.Add("Button", "x30 y415 w120 h25", "Demo Tooltips"))
        this.controls["DemoTooltips"].OnEvent("Click", (*) => this._DemoTooltips())
        
        this.AddControl("DemoStatus", this.gui.Add("Button", "x160 y415 w120 h25", "Demo Status"))
        this.controls["DemoStatus"].OnEvent("Click", (*) => this._DemoStatus())
        
        this.AddControl("ResetTheme", this.gui.Add("Button", "x290 y415 w120 h25", "Reset to Default"))
        this.controls["ResetTheme"].OnEvent("Click", (*) => this._ResetTheme())

        this.AddControl("ApplyThemeNow", this.gui.Add("Button", "x420 y415 w120 h25", "Apply Now"))
        this.controls["ApplyThemeNow"].OnEvent("Click", (*) => this._ApplyThemeNow())
    }

    _OnThemeChange() {
        ; Update preview when theme changes
        this._UpdateVisualsPreview()
        
        ; Get selected theme
        selectedTheme := this.controls["ColorTheme"].Text
        
        ; Show notification
        TooltipSystem.ShowStandard("Theme: " . selectedTheme . " (click Apply to save)", "info", 2000)
    }

    _ApplyThemeNow() {
        ; Get selected theme
        selectedTheme := this.controls["ColorTheme"].Text
        
        ; Apply the theme immediately
        ColorThemeManager.SetTheme(selectedTheme)
        
        ; Update temp settings so it gets saved when Apply/OK is clicked
        this.tempSettings["ColorTheme"] := selectedTheme
        
        ; Force update all components
        StatusIndicator.Update()
        
        ; Show confirmation
        TooltipSystem.ShowStandard("Theme Applied: " . selectedTheme, "success", 2000)
    }

    _PreviewTheme() {
        ; Get selected theme
        selectedTheme := this.controls["ColorTheme"].Text
        
        ; Save current theme
        previousTheme := ColorThemeManager.GetCurrentTheme()
        
        ; Apply theme temporarily
        ColorThemeManager.SetTheme(selectedTheme)
        
        ; Show some tooltips to demonstrate
        TooltipSystem.ShowStandard("Preview: " . selectedTheme, "info", 2000)
        SetTimer(() => StatusIndicator.ShowTemporaryMessage("Preview Status", "success", 1500), -2200)
        
        ; Store previous theme in object property for closure
        this.previousThemeBackup := previousTheme
        
        ; Revert after 5 seconds using bound function
        revertFunc := ObjBindMethod(this, "_RevertPreviewTheme")
        SetTimer(revertFunc, -5000)
    }
    
    _RevertPreviewTheme() {
        ; Revert to previous theme
        if (this.HasOwnProp("previousThemeBackup")) {
            ColorThemeManager.SetTheme(this.previousThemeBackup)
            TooltipSystem.ShowStandard("Preview ended", "info", 1000)
            this.DeleteProp("previousThemeBackup")
        }
    }

    _DemoTooltips() {
        ; Show tooltips in sequence with current theme
        TooltipSystem.ShowStandard("ℹ️ Info Tooltip", "info", 1500)
        SetTimer(() => TooltipSystem.ShowStandard("✅ Success Tooltip", "success", 1500), -1700)
        SetTimer(() => TooltipSystem.ShowStandard("⚠️ Warning Tooltip", "warning", 1500), -3400)
        SetTimer(() => TooltipSystem.ShowStandard("❌ Error Tooltip", "error", 1500), -5100)
        
        ; Show mouse action tooltips
        SetTimer(() => TooltipSystem.ShowMouseAction("🖱️ Mouse Action (Success)", "success"), -7000)
        SetTimer(() => TooltipSystem.ShowMouseAction("🖱️ Mouse Action (Warning)", "warning"), -11200)
    }

    _DemoStatus() {
        ; Save current state
        savedMouseMode := StateManager.IsMouseMode()
        savedSaveMode := StateManager.IsSaveMode()
        savedLoadMode := StateManager.IsLoadMode()
        savedInvertedMode := StateManager.IsInvertedMode()
        
        ; Demo sequence
        MsgBox("Status indicator demonstration will show different states.`n`n" .
            "Watch the status indicator change colors.", "Status Demo", "T2")
        
        ; OFF state
        StateManager._mouseMode := false
        StatusIndicator.Update()
        Sleep(1500)
        
        ; ON state
        StateManager._mouseMode := true
        StateManager._saveMode := false
        StateManager._loadMode := false
        StateManager._invertedMode := false
        StatusIndicator.Update()
        Sleep(1500)
        
        ; SAVE state
        StateManager._saveMode := true
        StatusIndicator.Update()
        Sleep(1500)
        
        ; LOAD state
        StateManager._saveMode := false
        StateManager._loadMode := true
        StatusIndicator.Update()
        Sleep(1500)
        
        ; INVERTED state
        StateManager._loadMode := false
        StateManager._invertedMode := true
        StatusIndicator.Update()
        Sleep(1500)
        
        ; Restore original state
        StateManager._mouseMode := savedMouseMode
        StateManager._saveMode := savedSaveMode
        StateManager._loadMode := savedLoadMode
        StateManager._invertedMode := savedInvertedMode
        StatusIndicator.Update()
    }

    _ResetTheme() {
        ; Reset to default theme
        this.controls["ColorTheme"].Choose(1)
        ColorThemeManager.SetTheme("Default")
        this.tempSettings["ColorTheme"] := "Default"
        this._UpdateVisualsPreview()
        
        MsgBox("Theme reset to Default.", "Theme Reset", "Iconi T2")
    }

    GetData() {
        return Map(
            "enableAudioFeedback", this.controls["EnableAudioFeedback"].Value ? true : false,
            "statusVisibleOnStartup", this.controls["StatusVisibleOnStartup"].Value ? true : false,
            "useSecondaryMonitor", this.controls["UseSecondaryMonitor"].Value ? true : false,
            "statusX", this.controls["StatusX"].Text,
            "statusY", this.controls["StatusY"].Text,
            "tooltipX", this.controls["TooltipX"].Text,
            "tooltipY", this.controls["TooltipY"].Text,
            "colorTheme", this.controls["ColorTheme"].Text
        )
    }

    Validate() {
        ; Validate position expressions
        testExpressions := [
            {name: "Status X", value: this.controls["StatusX"].Text},
            {name: "Status Y", value: this.controls["StatusY"].Text},
            {name: "Tooltip X", value: this.controls["TooltipX"].Text},
            {name: "Tooltip Y", value: this.controls["TooltipY"].Text}
        ]

        for expr in testExpressions {
            if (expr.value = "") {
                MsgBox(expr.name . " cannot be empty", "Validation Error", "IconX")
                return false
            }
            
            ; Try to evaluate the expression
            try {
                result := MonitorUtils.EvaluateExpression(expr.value)
                if (!IsNumber(result)) {
                    MsgBox(expr.name . " must evaluate to a number", "Validation Error", "IconX")
                    return false
                }
            } catch {
                MsgBox(expr.name . " contains an invalid expression", "Validation Error", "IconX")
                return false
            }
        }

        return true
    }

    _UpdateVisualsPreview() {
        try {
            colorTheme := this.controls["ColorTheme"].Text
            statusVisible := this.controls["StatusVisibleOnStartup"].Value
            audioEnabled := this.controls["EnableAudioFeedback"].Value
            secondaryMonitor := this.controls["UseSecondaryMonitor"].Value

            previewText := "=== VISUAL SETTINGS PREVIEW ===`r`n`r`n"
            
            previewText .= "🎨 COLOR THEME: " . colorTheme . "`r`n"
            
            ; Get theme description
            themeDesc := ColorThemeManager.GetThemeDescription(colorTheme)
            if (themeDesc != "") {
                previewText .= "• Description: " . themeDesc . "`r`n"
            }
            
            ; Show theme colors
            if (ColorThemeManager.themes.Has(colorTheme)) {
                previewText .= "`r`nTheme Colors:`r`n"
                colors := ColorThemeManager.themes[colorTheme].colors
                
                previewText .= "• Status OFF: " . colors.statusOff . "`r`n"
                previewText .= "• Status ON: " . colors.statusOn . "`r`n"
                previewText .= "• Save Mode: " . colors.statusSave . "`r`n"
                previewText .= "• Load Mode: " . colors.statusLoad . "`r`n"
                previewText .= "• Inverted: " . colors.statusInverted . "`r`n"
            }

            previewText .= "`r`n📊 DISPLAY SETTINGS:`r`n"
            previewText .= "• Status on startup: " . (statusVisible ? "Yes" : "No") . "`r`n"
            previewText .= "• Secondary monitor: " . (secondaryMonitor ? "Yes" : "No") . "`r`n"
            previewText .= "• Audio feedback: " . (audioEnabled ? "Enabled" : "Disabled") . "`r`n"

            previewText .= "`r`n📍 POSITIONS:`r`n"
            previewText .= "• Status: " . this.controls["StatusX"].Text . ", " . this.controls["StatusY"].Text . "`r`n"
            previewText .= "• Tooltip: " . this.controls["TooltipX"].Text . ", " . this.controls["TooltipY"].Text . "`r`n"

            previewText .= "`r`n💡 THEME FEATURES:`r`n"
            switch colorTheme {
                case "Default":
                    previewText .= "• Standard colors for all modes`r`n"
                    previewText .= "• High visibility status indicators`r`n"
                    previewText .= "• Professional appearance`r`n"
                case "Dark Mode":
                    previewText .= "• Reduced eye strain`r`n"
                    previewText .= "• Muted color palette`r`n"
                    previewText .= "• Ideal for low-light environments`r`n"
                case "High Contrast":
                    previewText .= "• Maximum visibility`r`n"
                    previewText .= "• Pure colors (no gradients)`r`n"
                    previewText .= "• Accessibility focused`r`n"
                case "Minimal":
                    previewText .= "• Clean, distraction-free`r`n"
                    previewText .= "• Grayscale color scheme`r`n"
                    previewText .= "• Subtle visual feedback`r`n"
            }

            previewText .= "`r`n🔧 TIPS:`r`n"
            previewText .= "• Use 'Apply Now' to apply immediately`r`n"
            previewText .= "• Use 'Preview' for temporary test`r`n"
            previewText .= "• 'Demo' buttons show theme in action`r`n"

            this.controls["VisualPreview"].Text := previewText
        } catch {
            this.controls["VisualPreview"].Text := "Preview will update when settings change..."
        }
    }

    _TestAudio() {
        if (this.controls["EnableAudioFeedback"].Value) {
            SoundBeep(800, 200)
            MsgBox("Audio feedback test completed!", "Test Audio", "T2")
        } else {
            MsgBox("Audio feedback is currently disabled.`nEnable it first to test.", "Test Audio", "Icon!")
        }
    }

    _TestStatusPosition() {
        try {
            ; Get evaluated positions
            x := MonitorUtils.EvaluateExpression(this.controls["StatusX"].Text)
            y := MonitorUtils.EvaluateExpression(this.controls["StatusY"].Text)

            ; Create test indicator with current theme colors
            testGui := Gui("+AlwaysOnTop -Caption +ToolWindow", "")
            bgColor := ColorThemeManager.GetColor("statusOn")
            if (SubStr(bgColor, 1, 2) = "0x") {
                bgColor := SubStr(bgColor, 3)
            }
            testGui.BackColor := bgColor
            testGui.SetFont("s10 Bold", "Segoe UI")
            
            textColor := GetContrastingColor(ColorThemeManager.GetColor("statusOn"))
            if (SubStr(textColor, 1, 2) = "0x") {
                textColor := SubStr(textColor, 3)
            }
            testCtrl := testGui.Add("Text", "x5 y5 w110 h20 Center", "Status Position")
            testCtrl.SetFont("c" . textColor)
            
            testGui.Show("x" . x . " y" . y . " w120 h30 NoActivate")

            ; Auto-destroy after 3 seconds
            SetTimer(() => testGui.Destroy(), -3000)

            MsgBox("Status indicator will appear at the configured position for 3 seconds.", 
                "Test Status Position", "T3")
        } catch Error as e {
            MsgBox("Error testing position: " . e.Message, "Test Error", "IconX")
        }
    }

    _TestTooltipPosition() {
        try {
            ; Get evaluated positions
            x := MonitorUtils.EvaluateExpression(this.controls["TooltipX"].Text)
            y := MonitorUtils.EvaluateExpression(this.controls["TooltipY"].Text)

            ; Create test tooltip with current theme colors
            testGui := Gui("+AlwaysOnTop -Caption +ToolWindow", "")
            bgColor := ColorThemeManager.GetColor("tooltipInfo")
            if (SubStr(bgColor, 1, 2) = "0x") {
                bgColor := SubStr(bgColor, 3)
            }
            testGui.BackColor := bgColor
            testGui.SetFont("s10 Bold", "Segoe UI")
            
            textColor := GetContrastingColor(ColorThemeManager.GetColor("tooltipInfo"))
            if (SubStr(textColor, 1, 2) = "0x") {
                textColor := SubStr(textColor, 3)
            }
            testCtrl := testGui.Add("Text", "x5 y5 w110 h20 Center", "Tooltip Position")
            testCtrl.SetFont("c" . textColor)
            
            testGui.Show("x" . x . " y" . y . " w120 h30 NoActivate")

            ; Auto-destroy after 3 seconds
            SetTimer(() => testGui.Destroy(), -3000)

            MsgBox("Tooltip will appear at the configured position for 3 seconds.", 
                "Test Tooltip Position", "T3")
        } catch Error as e {
            MsgBox("Error testing position: " . e.Message, "Test Error", "IconX")
        }
    }
}