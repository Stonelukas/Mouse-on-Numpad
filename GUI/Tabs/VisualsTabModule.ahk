#Requires AutoHotkey v2.0

; ######################################################################################################################
; Visuals Tab Module - Visual and audio settings
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
        this.controls["StatusX"].Text := Config.StatusX
        this.gui.Add("Text", "x270 y165 w200", "X position or expression")

        this.gui.Add("Text", "x30 y190 w80", "Status Y:")
        this.AddControl("StatusY", this.gui.Add("Edit", "x110 y187 w150"))
        this.controls["StatusY"].Text := Config.StatusY
        this.gui.Add("Text", "x270 y190 w200", "Y position or expression")

        ; Tooltip Position Section
        this.gui.Add("Text", "x30 y230 w200 h20 +0x200", "Tooltip Position").SetFont("s10 Bold")

        this.gui.Add("Text", "x30 y255 w80", "Tooltip X:")
        this.AddControl("TooltipX", this.gui.Add("Edit", "x110 y252 w150"))
        this.controls["TooltipX"].Text := Config.TooltipX
        this.gui.Add("Text", "x270 y255 w200", "X position or expression")

        this.gui.Add("Text", "x30 y280 w80", "Tooltip Y:")
        this.AddControl("TooltipY", this.gui.Add("Edit", "x110 y277 w150"))
        this.controls["TooltipY"].Text := Config.TooltipY
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
            ["Default", "Dark Mode", "High Contrast", "Minimal"]))
        this.controls["ColorTheme"].Choose(1)
        this.controls["ColorTheme"].OnEvent("Change", (*) => this._UpdateVisualsPreview())

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
            
            previewText .= "🎨 COLOR THEME:`r`n"
            previewText .= "• Current Theme: " . colorTheme . "`r`n"
            
            ; Theme-specific colors
            switch colorTheme {
                case "Default":
                    previewText .= "• Primary: Blue/Green`r`n"
                    previewText .= "• Status: Multi-color`r`n"
                    previewText .= "• Background: Light`r`n"
                case "Dark Mode":
                    previewText .= "• Primary: Dark Blue`r`n"
                    previewText .= "• Status: Muted colors`r`n"
                    previewText .= "• Background: Dark`r`n"
                case "High Contrast":
                    previewText .= "• Primary: Black/White`r`n"
                    previewText .= "• Status: High visibility`r`n"
                    previewText .= "• Background: White`r`n"
                case "Minimal":
                    previewText .= "• Primary: Grayscale`r`n"
                    previewText .= "• Status: Minimal colors`r`n"
                    previewText .= "• Background: Light gray`r`n"
            }

            previewText .= "`r`n📊 DISPLAY SETTINGS:`r`n"
            previewText .= "• Status on startup: " . (statusVisible ? "Yes" : "No") . "`r`n"
            previewText .= "• Secondary monitor: " . (secondaryMonitor ? "Yes" : "No") . "`r`n"
            previewText .= "• Audio feedback: " . (audioEnabled ? "Enabled" : "Disabled") . "`r`n"

            previewText .= "`r`n📍 POSITIONS:`r`n"
            previewText .= "• Status: " . this.controls["StatusX"].Text . ", " . this.controls["StatusY"].Text . "`r`n"
            previewText .= "• Tooltip: " . this.controls["TooltipX"].Text . ", " . this.controls["TooltipY"].Text . "`r`n"

            previewText .= "`r`n💡 TIPS:`r`n"
            if (!statusVisible) {
                previewText .= "• Press Ctrl+Numpad+ to toggle status`r`n"
            }
            if (secondaryMonitor && MonitorGetCount() < 2) {
                previewText .= "• Only one monitor detected!`r`n"
            }
            previewText .= "• Position expressions support A_ScreenWidth/Height`r`n"

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

            ; Create test indicator
            testGui := Gui("+AlwaysOnTop -Caption +ToolWindow", "")
            testGui.BackColor := "0x4CAF50"
            testGui.SetFont("s10 Bold", "Segoe UI")
            testGui.Add("Text", "x5 y5 w110 h20 Center cWhite", "Status Position")
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

            ; Create test tooltip
            testGui := Gui("+AlwaysOnTop -Caption +ToolWindow", "")
            testGui.BackColor := "0x2196F3"
            testGui.SetFont("s10 Bold", "Segoe UI")
            testGui.Add("Text", "x5 y5 w110 h20 Center cWhite", "Tooltip Position")
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