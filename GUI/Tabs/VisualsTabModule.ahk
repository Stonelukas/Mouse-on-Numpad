#Requires AutoHotkey v2.0

; ######################################################################################################################
; Visuals Tab Module - Visual settings and theme configuration
; ######################################################################################################################

class VisualsTabModule extends BaseTabModule {
    CreateControls() {
        ; Create visual settings controls
        yOffset := 50

        ; Theme Section
        this.gui.Add("Text", "x30 y" . yOffset . " w200 h20 +0x200", "Color Theme").SetFont("s10 Bold")
        
        yOffset += 25
        this.gui.Add("Text", "x30 y" . yOffset . " w120", "Theme:")
        this.AddControl("ColorTheme", this.gui.Add("DropDownList", "x150 y" . (yOffset - 3) . " w200", 
            ["Default", "Dark Mode", "High Contrast", "Ocean", "Forest", "Sunset", "Minimal"]))
        
        ; Set current theme
        currentTheme := this.tempSettings["ColorTheme"]
        themes := ["Default", "Dark Mode", "High Contrast", "Ocean", "Forest", "Sunset", "Minimal"]
        for index, theme in themes {
            if (theme = currentTheme) {
                this.controls["ColorTheme"].Choose(index)
                break
            }
        }
        
        this.controls["ColorTheme"].OnEvent("Change", (*) => this._PreviewTheme())
        
        yOffset += 25
        this.AddControl("PreviewTheme", this.gui.Add("Button", "x150 y" . yOffset . " w100 h25", "Preview Theme"))
        this.controls["PreviewTheme"].OnEvent("Click", (*) => this._PreviewTheme())
        
        ; Audio Feedback Section
        yOffset += 40
        this.gui.Add("Text", "x30 y" . yOffset . " w200 h20 +0x200", "Audio Feedback").SetFont("s10 Bold")
        
        yOffset += 25
        this.AddControl("EnableAudioFeedback", this.gui.Add("CheckBox", "x30 y" . yOffset . " w300", "Enable audio feedback"))
        this.controls["EnableAudioFeedback"].Checked := this.tempSettings["EnableAudioFeedback"]
        
        ; Status Display Section
        yOffset += 40
        this.gui.Add("Text", "x30 y" . yOffset . " w200 h20 +0x200", "Status Display").SetFont("s10 Bold")
        
        yOffset += 25
        this.AddControl("StatusVisibleOnStartup", this.gui.Add("CheckBox", "x30 y" . yOffset . " w300", "Show status display on startup"))
        this.controls["StatusVisibleOnStartup"].Checked := this.tempSettings["StatusVisibleOnStartup"]
        
        yOffset += 25
        this.AddControl("UseSecondaryMonitor", this.gui.Add("CheckBox", "x30 y" . yOffset . " w300", "Use secondary monitor"))
        this.controls["UseSecondaryMonitor"].Checked := this.tempSettings["UseSecondaryMonitor"]
        
        ; Position Settings Section
        yOffset += 40
        this.gui.Add("Text", "x30 y" . yOffset . " w200 h20 +0x200", "Position Settings").SetFont("s10 Bold")
        
        yOffset += 25
        this.gui.Add("Text", "x30 y" . yOffset . " w120", "Status Position X:")
        this.AddControl("StatusX", this.gui.Add("Edit", "x150 y" . (yOffset - 3) . " w100"))
        this.controls["StatusX"].Text := Config.Get("Visual.StatusX", "A_ScreenWidth - 200")
        
        this.AddControl("TestStatusPos", this.gui.Add("Button", "x260 y" . (yOffset - 3) . " w80 h20", "Test"))
        this.controls["TestStatusPos"].OnEvent("Click", (*) => this._TestStatusPosition())
        
        yOffset += 25
        this.gui.Add("Text", "x30 y" . yOffset . " w120", "Status Position Y:")
        this.AddControl("StatusY", this.gui.Add("Edit", "x150 y" . (yOffset - 3) . " w100"))
        this.controls["StatusY"].Text := Config.Get("Visual.StatusY", "50")
        
        yOffset += 25
        this.gui.Add("Text", "x30 y" . yOffset . " w120", "Tooltip Position X:")
        this.AddControl("TooltipX", this.gui.Add("Edit", "x150 y" . (yOffset - 3) . " w100"))
        this.controls["TooltipX"].Text := Config.Get("Visual.TooltipX", "A_ScreenWidth // 2")
        
        this.AddControl("TestTooltipPos", this.gui.Add("Button", "x260 y" . (yOffset - 3) . " w80 h20", "Test"))
        this.controls["TestTooltipPos"].OnEvent("Click", (*) => this._TestTooltipPosition())
        
        yOffset += 25
        this.gui.Add("Text", "x30 y" . yOffset . " w120", "Tooltip Position Y:")
        this.AddControl("TooltipY", this.gui.Add("Edit", "x150 y" . (yOffset - 3) . " w100"))
        this.controls["TooltipY"].Text := Config.Get("Visual.TooltipY", "A_ScreenHeight - 100")
        
        ; Help text
        yOffset += 40
        this.gui.Add("Text", "x30 y" . yOffset . " w500 h60", 
            "Position values can use expressions like:`n" .
            "• A_ScreenWidth - 200 (right side of screen)`n" .
            "• A_ScreenHeight // 2 (middle of screen)`n" .
            "• 50 (fixed pixel position)")
    }
    
    _PreviewTheme() {
        ; Get selected theme
        selectedIndex := this.controls["ColorTheme"].Value
        themes := ["Default", "Dark Mode", "High Contrast", "Ocean", "Forest", "Sunset", "Minimal"]
        
        if (selectedIndex >= 1 && selectedIndex <= themes.Length) {
            selectedTheme := themes[selectedIndex]
            
            ; Apply theme temporarily
            ColorThemeManager.SetTheme(selectedTheme)
            
            ; Show preview message
            TooltipSystem.ShowStandard("Theme preview: " . selectedTheme, "success", 2000)
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
            
            ; Use ColorThemeManager.GetContrastingColor
            textColor := ColorThemeManager.GetContrastingColor(ColorThemeManager.GetColor("statusOn"))
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
            
            ; Use ColorThemeManager.GetContrastingColor
            textColor := ColorThemeManager.GetContrastingColor(ColorThemeManager.GetColor("tooltipInfo"))
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
    
    GetData() {
        ; Return visual settings data
        data := Map()
        data["enableAudioFeedback"] := this.controls["EnableAudioFeedback"].Checked
        data["statusVisibleOnStartup"] := this.controls["StatusVisibleOnStartup"].Checked
        data["useSecondaryMonitor"] := this.controls["UseSecondaryMonitor"].Checked
        data["statusX"] := this.controls["StatusX"].Text
        data["statusY"] := this.controls["StatusY"].Text
        data["tooltipX"] := this.controls["TooltipX"].Text
        data["tooltipY"] := this.controls["TooltipY"].Text
        
        ; Get selected theme
        selectedIndex := this.controls["ColorTheme"].Value
        themes := ["Default", "Dark Mode", "High Contrast", "Ocean", "Forest", "Sunset", "Minimal"]
        if (selectedIndex >= 1 && selectedIndex <= themes.Length) {
            data["colorTheme"] := themes[selectedIndex]
        }
        
        return data
    }
    
    Validate() {
        ; Validate position expressions
        try {
            MonitorUtils.EvaluateExpression(this.controls["StatusX"].Text)
            MonitorUtils.EvaluateExpression(this.controls["StatusY"].Text)
            MonitorUtils.EvaluateExpression(this.controls["TooltipX"].Text)
            MonitorUtils.EvaluateExpression(this.controls["TooltipY"].Text)
        } catch Error as e {
            MsgBox("Invalid position expression: " . e.Message, "Validation Error", "IconX")
            return false
        }
        
        return true
    }
    
    Refresh() {
        ; Refresh controls with current settings
        this.controls["EnableAudioFeedback"].Checked := this.tempSettings["EnableAudioFeedback"]
        this.controls["StatusVisibleOnStartup"].Checked := this.tempSettings["StatusVisibleOnStartup"]
        this.controls["UseSecondaryMonitor"].Checked := this.tempSettings["UseSecondaryMonitor"]
        
        ; Update theme selection
        currentTheme := this.tempSettings["ColorTheme"]
        themes := ["Default", "Dark Mode", "High Contrast", "Ocean", "Forest", "Sunset", "Minimal"]
        for index, theme in themes {
            if (theme = currentTheme) {
                this.controls["ColorTheme"].Choose(index)
                break
            }
        }
    }
}