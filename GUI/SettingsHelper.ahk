#Requires AutoHotkey v2.0

; ######################################################################################################################
; Settings GUI Helpers - Helper methods and preview updates
; ######################################################################################################################

; Update Movement Preview
SettingsGUI._UpdateMovementPreview := (*) {
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
        if (IsNumber(moveStep) && IsNumber(accelRate)) {
            previewText .= "• After 2 steps: " . Round(moveStep * accelRate) . " pixels`r`n"
            previewText .= "• After 3 steps: " . Round(moveStep * (accelRate ** 2)) . " pixels`r`n"
            if (accelRate > 1 && IsNumber(maxSpeed)) {
                previewText .= "• Time to max: ~" . Round(Log(maxSpeed / moveStep) / Log(accelRate) * moveDelay) . " ms`r`n"
            }
        }

        ; Scroll Calculations
        previewText .= "`r`n📊 SCROLL CALCULATIONS:`r`n"
        previewText .= "• After 1 step: " . scrollStep . " lines`r`n"
        if (IsNumber(scrollStep) && IsNumber(scrollAccel)) {
            previewText .= "• After 2 steps: " . Round(scrollStep * scrollAccel) . " lines`r`n"
            previewText .= "• After 3 steps: " . Round(scrollStep * (scrollAccel ** 2))