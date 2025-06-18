; Replace these two functions in your VisualsTabModule.ahk file:

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
        
        ; FIXED: Use ColorThemeManager.GetContrastingColor
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
        
        ; FIXED: Use ColorThemeManager.GetContrastingColor
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