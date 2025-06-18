#Requires AutoHotkey v2.0

; ######################################################################################################################
; Movement Tab Module - Movement and scrolling settings
; ######################################################################################################################

class MovementTabModule extends BaseTabModule {
    CreateControls() {
        ; Create a scrollable area for the tab content
        yOffset := 50

        ; Movement Speed Section
        this.gui.Add("Text", "x30 y" . yOffset . " w200 h20 +0x200", "Movement Speed").SetFont("s10 Bold")

        yOffset += 25
        this.gui.Add("Text", "x30 y" . yOffset . " w120", "Move Step:")
        this.AddControl("MoveStep", this.gui.Add("Edit", "x150 y" . (yOffset - 3) . " w60 Number"))
        this.controls["MoveStep"].Text := this.tempSettings["MoveStep"]
        this.controls["MoveStep"].OnEvent("Change", (*) => this._UpdateMovementPreview())
        
        this.AddControl("MoveStepUpDown", this.gui.Add("UpDown", "x210 y" . (yOffset - 3) . " w20 h20 Range1-50", 
            this.tempSettings["MoveStep"]))
        this.controls["MoveStepUpDown"].OnEvent("Change", (*) => this._UpdateMovementPreview())
        this.gui.Add("Text", "x235 y" . yOffset . " w300", "pixels per movement (1-50)")

        yOffset += 25
        this.gui.Add("Text", "x30 y" . yOffset . " w120", "Move Delay:")
        this.AddControl("MoveDelay", this.gui.Add("Edit", "x150 y" . (yOffset - 3) . " w60 Number"))
        this.controls["MoveDelay"].Text := this.tempSettings["MoveDelay"]
        this.controls["MoveDelay"].OnEvent("Change", (*) => this._UpdateMovementPreview())
        
        this.AddControl("MoveDelayUpDown", this.gui.Add("UpDown", "x210 y" . (yOffset - 3) . " w20 h20 Range5-100", 
            this.tempSettings["MoveDelay"]))
        this.controls["MoveDelayUpDown"].OnEvent("Change", (*) => this._UpdateMovementPreview())
        this.gui.Add("Text", "x235 y" . yOffset . " w300", "milliseconds between movements (5-100)")

        ; Acceleration Section
        yOffset += 40
        this.gui.Add("Text", "x30 y" . yOffset . " w200 h20 +0x200", "Acceleration Settings").SetFont("s10 Bold")

        yOffset += 25
        this.gui.Add("Text", "x30 y" . yOffset . " w120", "Acceleration Rate:")
        this.AddControl("AccelerationRate", this.gui.Add("Edit", "x150 y" . (yOffset - 3) . " w60"))
        this.controls["AccelerationRate"].Text := this.tempSettings["AccelerationRate"]
        this.controls["AccelerationRate"].OnEvent("Change", (*) => this._UpdateMovementPreview())
        this.gui.Add("Text", "x235 y" . yOffset . " w300", "multiplier per step (1.0-3.0)")

        yOffset += 25
        this.gui.Add("Text", "x30 y" . yOffset . " w120", "Max Speed:")
        this.AddControl("MaxSpeed", this.gui.Add("Edit", "x150 y" . (yOffset - 3) . " w60 Number"))
        this.controls["MaxSpeed"].Text := this.tempSettings["MaxSpeed"]
        this.controls["MaxSpeed"].OnEvent("Change", (*) => this._UpdateMovementPreview())
        
        this.AddControl("MaxSpeedUpDown", this.gui.Add("UpDown", "x210 y" . (yOffset - 3) . " w20 h20 Range5-100", 
            this.tempSettings["MaxSpeed"]))
        this.controls["MaxSpeedUpDown"].OnEvent("Change", (*) => this._UpdateMovementPreview())
        this.gui.Add("Text", "x235 y" . yOffset . " w300", "maximum pixels per movement (5-100)")

        ; Movement Mode Section
        yOffset += 40
        this.gui.Add("Text", "x30 y" . yOffset . " w200 h20 +0x200", "Movement Modes").SetFont("s10 Bold")

        yOffset += 25
        this.AddControl("EnableAbsoluteMovement", this.gui.Add("CheckBox", "x30 y" . yOffset . " w300",
            "Enable Absolute Movement"))
        this.controls["EnableAbsoluteMovement"].Value := Config.Get("Movement.EnableAbsoluteMovement") ? 1 : 0
        this.controls["EnableAbsoluteMovement"].OnEvent("Click", (*) => this._UpdateMovementPreview())
        yOffset += 20
        this.gui.Add("Text", "x50 y" . yOffset . " w400", "Use absolute coordinates instead of relative movement")

        ; Scroll Settings Section
        yOffset += 40
        this.gui.Add("Text", "x30 y" . yOffset . " w200 h20 +0x200", "Scroll Settings").SetFont("s10 Bold")

        yOffset += 25
        this.gui.Add("Text", "x30 y" . yOffset . " w120", "Scroll Step:")
        this.AddControl("ScrollStep", this.gui.Add("Edit", "x150 y" . (yOffset - 3) . " w60 Number"))
        this.controls["ScrollStep"].Text := this.tempSettings["ScrollStep"]
        this.controls["ScrollStep"].OnEvent("Change", (*) => this._UpdateMovementPreview())
        
        this.AddControl("ScrollStepUpDown", this.gui.Add("UpDown", "x210 y" . (yOffset - 3) . " w20 h20 Range1-10", 
            this.tempSettings["ScrollStep"]))
        this.controls["ScrollStepUpDown"].OnEvent("Change", (*) => this._UpdateMovementPreview())
        this.gui.Add("Text", "x235 y" . yOffset . " w300", "scroll lines per step (1-10)")

        yOffset += 25
        this.gui.Add("Text", "x30 y" . yOffset . " w120", "Scroll Acceleration:")
        this.AddControl("ScrollAccelerationRate", this.gui.Add("Edit", "x150 y" . (yOffset - 3) . " w60"))
        this.controls["ScrollAccelerationRate"].Text := this.tempSettings["ScrollAccelerationRate"]
        this.controls["ScrollAccelerationRate"].OnEvent("Change", (*) => this._UpdateMovementPreview())
        this.gui.Add("Text", "x235 y" . yOffset . " w300", "scroll acceleration multiplier (1.0-3.0)")

        yOffset += 25
        this.gui.Add("Text", "x30 y" . yOffset . " w120", "Max Scroll Speed:")
        this.AddControl("MaxScrollSpeed", this.gui.Add("Edit", "x150 y" . (yOffset - 3) . " w60 Number"))
        this.controls["MaxScrollSpeed"].Text := this.tempSettings["MaxScrollSpeed"]
        this.controls["MaxScrollSpeed"].OnEvent("Change", (*) => this._UpdateMovementPreview())
        
        this.AddControl("MaxScrollSpeedUpDown", this.gui.Add("UpDown", "x210 y" . (yOffset - 3) . " w20 h20 Range1-50", 
            this.tempSettings["MaxScrollSpeed"]))
        this.controls["MaxScrollSpeedUpDown"].OnEvent("Change", (*) => this._UpdateMovementPreview())
        this.gui.Add("Text", "x235 y" . yOffset . " w300", "maximum scroll lines per step (1-50)")

        ; Preview Section
        this.gui.Add("Text", "x450 y50 w300 h20 +0x200", "Movement & Scroll Preview").SetFont("s10 Bold")
        this.AddControl("MovementPreview", this.gui.Add("Edit", "x450 y75 w300 h360 +VScroll +ReadOnly +Wrap"))
        this.controls["MovementPreview"].SetFont("s8", "Consolas")
        this._UpdateMovementPreview()
    }

    GetData() {
        return Map(
            "moveStep", Integer(this.controls["MoveStep"].Text),
            "moveDelay", Integer(this.controls["MoveDelay"].Text),
            "accelerationRate", Float(this.controls["AccelerationRate"].Text),
            "maxSpeed", Integer(this.controls["MaxSpeed"].Text),
            "enableAbsoluteMovement", this.controls["EnableAbsoluteMovement"].Value ? true : false,
            "scrollStep", Integer(this.controls["ScrollStep"].Text),
            "scrollAccelerationRate", Float(this.controls["ScrollAccelerationRate"].Text),
            "maxScrollSpeed", Integer(this.controls["MaxScrollSpeed"].Text)
        )
    }

    Validate() {
        try {
            ; Validate Move Step
            moveStep := Integer(this.controls["MoveStep"].Text)
            if (moveStep < 1 || moveStep > 50) {
                MsgBox("Move Step must be between 1 and 50", "Validation Error", "IconX")
                return false
            }

            ; Validate Move Delay
            moveDelay := Integer(this.controls["MoveDelay"].Text)
            if (moveDelay < 5 || moveDelay > 100) {
                MsgBox("Move Delay must be between 5 and 100 milliseconds", "Validation Error", "IconX")
                return false
            }

            ; Validate Acceleration Rate
            accelRate := Float(this.controls["AccelerationRate"].Text)
            if (accelRate < 1.0 || accelRate > 3.0) {
                MsgBox("Acceleration Rate must be between 1.0 and 3.0", "Validation Error", "IconX")
                return false
            }

            ; Validate Max Speed
            maxSpeed := Integer(this.controls["MaxSpeed"].Text)
            if (maxSpeed < 5 || maxSpeed > 100) {
                MsgBox("Max Speed must be between 5 and 100", "Validation Error", "IconX")
                return false
            }

            ; Validate Scroll Settings
            scrollStep := Integer(this.controls["ScrollStep"].Text)
            if (scrollStep < 1 || scrollStep > 10) {
                MsgBox("Scroll Step must be between 1 and 10", "Validation Error", "IconX")
                return false
            }

            scrollAccel := Float(this.controls["ScrollAccelerationRate"].Text)
            if (scrollAccel < 1.0 || scrollAccel > 3.0) {
                MsgBox("Scroll Acceleration must be between 1.0 and 3.0", "Validation Error", "IconX")
                return false
            }

            maxScroll := Integer(this.controls["MaxScrollSpeed"].Text)
            if (maxScroll < 1 || maxScroll > 50) {
                MsgBox("Max Scroll Speed must be between 1 and 50", "Validation Error", "IconX")
                return false
            }

            return true
        } catch {
            MsgBox("Please enter valid numeric values in all fields", "Validation Error", "IconX")
            return false
        }
    }

    _UpdateMovementPreview() {
        try {
            ; Get current values from the controls
            moveStep := this.controls["MoveStep"].Text
            moveDelay := this.controls["MoveDelay"].Text
            accelRate := this.controls["AccelerationRate"].Text
            maxSpeed := this.controls["MaxSpeed"].Text
            isAbsolute := this.controls["EnableAbsoluteMovement"].Value

            ; Get scroll settings
            scrollStep := this.controls["ScrollStep"].Text
            scrollAccel := this.controls["ScrollAccelerationRate"].Text
            maxScrollSpeed := this.controls["MaxScrollSpeed"].Text

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
            if (IsNumber(moveStep) && IsNumber(accelRate) && IsNumber(maxSpeed) && IsNumber(moveDelay)) {
                previewText .= "`r`n🧮 MOVEMENT CALCULATIONS:`r`n"
                previewText .= "• After 1 step: " . moveStep . " pixels`r`n"
                previewText .= "• After 2 steps: " . Round(moveStep * accelRate) . " pixels`r`n"
                previewText .= "• After 3 steps: " . Round(moveStep * (accelRate ** 2)) . " pixels`r`n"
                previewText .= "• Time to max: ~" . Round(Log(maxSpeed / moveStep) / Log(accelRate) * moveDelay) . " ms`r`n"
            }

            ; Scroll Calculations
            if (IsNumber(scrollStep) && IsNumber(scrollAccel)) {
                previewText .= "`r`n📊 SCROLL CALCULATIONS:`r`n"
                previewText .= "• After 1 step: " . scrollStep . " lines`r`n"
                previewText .= "• After 2 steps: " . Round(scrollStep * scrollAccel) . " lines`r`n"
                previewText .= "• After 3 steps: " . Round(scrollStep * (scrollAccel ** 2)) . " lines`r`n"
            }

            ; Performance Analysis
            if (IsNumber(moveDelay)) {
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
            }

            ; Usage Tips
            previewText .= "`r`n💡 OPTIMIZATION TIPS:`r`n"
            if (IsNumber(moveDelay) && moveDelay > 20) {
                previewText .= "• Lower delay for faster response`r`n"
            }
            if (IsNumber(accelRate) && accelRate < 1.2) {
                previewText .= "• Increase acceleration for quicker speed`r`n"
            }
            if (IsNumber(maxSpeed) && maxSpeed < 20) {
                previewText .= "• Raise max speed for faster movement`r`n"
            }
            previewText .= "• Test with numpad to fine-tune!`r`n"

            this.controls["MovementPreview"].Text := previewText
        } catch {
            this.controls["MovementPreview"].Text := "Preview will update when settings change..."
        }
    }
}