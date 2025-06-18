; ######################################################################################################################
; Mouse Actions Module - Complete fixed version with all corrections
; ######################################################################################################################

#Requires AutoHotkey v2.0

class MouseActions {
    static mousePositionHistory := []
    static scrollAccelerationTimer := ""
    
    ; Main movement method with multiple directions
    static MoveInDirection(direction) {
        ; Save starting position in screen coordinates
        CoordMode("Mouse", "Screen")
        MouseGetPos(&startX, &startY)
        MouseActions.AddToHistory(startX, startY)
        
        ; Determine movement based on direction
        switch direction {
            case "Left":
                MouseActions._MoveContinuous("Numpad4", -1, 0, "←")
            case "Right":
                MouseActions._MoveContinuous("Numpad6", 1, 0, "→")
            case "Up":
                MouseActions._MoveContinuous("Numpad8", 0, -1, "↑")
            case "Down":
                MouseActions._MoveContinuous("Numpad2", 0, 1, "↓")
            case "UpLeft":
                MouseActions._MoveContinuous("Numpad7", -1, -1, "↖")
            case "UpRight":
                MouseActions._MoveContinuous("Numpad9", 1, -1, "↗")
            case "DownLeft":
                MouseActions._MoveContinuous("Numpad1", -1, 1, "↙")
            case "DownRight":
                MouseActions._MoveContinuous("Numpad3", 1, 1, "↘")
        }
    }
    
    ; Perform click action
    static PerformClick(button := "Left") {
        Click(button)
        
        if (Config.Get("Visual.EnableAudioFeedback", false)) {
            switch button {
                case "Left": SoundBeep(600, 50)
                case "Right": SoundBeep(500, 50)
                case "Middle": SoundBeep(700, 50)
            }
        }
    }
    
    ; Continuous movement with acceleration
    static _MoveContinuous(key, dirX, dirY, arrow) {
        currentSpeed := 1.0
        
        ; Ensure we're using screen coordinates
        CoordMode("Mouse", "Screen")
        
        while GetKeyState(key, "P") {
            ; Calculate movement with acceleration
            moveX := Round(dirX * Config.Get("Movement.BaseSpeed") * currentSpeed)
            moveY := Round(dirY * Config.Get("Movement.BaseSpeed") * currentSpeed)
            
            ; Apply inverted mode if active
            if (StateManager.IsInvertedMode()) {
                moveX := -moveX
                moveY := -moveY
            }
            
            ; Perform movement
            if (Config.Get("Movement.EnableAbsoluteMovement")) {
                MouseGetPos(&currentX, &currentY)
                MouseMove(currentX + moveX, currentY + moveY, 0)
            } else {
                MouseMove(moveX, moveY, 0, "R")
            }
            
            ; Show direction tooltip
            TooltipSystem.ShowStandard(arrow, "info")
            
            ; Update acceleration
            currentSpeed := currentSpeed * Config.Get("Movement.AccelerationRate")
            if (currentSpeed > Config.Get("Movement.MaxSpeed") / Config.Get("Movement.BaseSpeed")) {
                currentSpeed := Config.Get("Movement.MaxSpeed") / Config.Get("Movement.BaseSpeed")
            }
            
            Sleep(Config.Get("Movement.MoveDelay"))
        }
    }
    
    ; Multi-key diagonal movement support
    static MoveDiagonal(keys) {
        currentSpeed := 1.0
        
        ; Ensure we're using screen coordinates  
        CoordMode("Mouse", "Screen")
        MouseGetPos(&startX, &startY)
        MouseActions.AddToHistory(startX, startY)
        
        while (GetKeyState(keys[1], "P") || GetKeyState(keys[2], "P")) {
            ; Check which keys are pressed
            upPressed := GetKeyState("Numpad8", "P")
            downPressed := GetKeyState("Numpad2", "P")
            leftPressed := GetKeyState("Numpad4", "P")
            rightPressed := GetKeyState("Numpad6", "P")
            
            ; Calculate final direction
            finalDx := 0
            finalDy := 0
            feedbackDirection := ""
            
            if (upPressed && leftPressed) {
                finalDx := -Config.Get("Movement.BaseSpeed")
                finalDy := -Config.Get("Movement.BaseSpeed")
                feedbackDirection := "up-left"
            } else if (upPressed && rightPressed) {
                finalDx := Config.Get("Movement.BaseSpeed")
                finalDy := -Config.Get("Movement.BaseSpeed")
                feedbackDirection := "up-right"
            } else if (downPressed && leftPressed) {
                finalDx := -Config.Get("Movement.BaseSpeed")
                finalDy := Config.Get("Movement.BaseSpeed")
                feedbackDirection := "down-left"
            } else if (downPressed && rightPressed) {
                finalDx := Config.Get("Movement.BaseSpeed")
                finalDy := Config.Get("Movement.BaseSpeed")
                feedbackDirection := "down-right"
            } else if (upPressed) {
                finalDy := -Config.Get("Movement.BaseSpeed")
                feedbackDirection := "up"
            } else if (downPressed) {
                finalDy := Config.Get("Movement.BaseSpeed")
                feedbackDirection := "down"
            } else if (leftPressed) {
                finalDx := -Config.Get("Movement.BaseSpeed")
                feedbackDirection := "left"
            } else if (rightPressed) {
                finalDx := Config.Get("Movement.BaseSpeed")
                feedbackDirection := "right"
            }
            
            if (feedbackDirection != "") {
                arrow := MouseActions._GetDirectionArrow(feedbackDirection)
                TooltipSystem.ShowStandard(arrow, "info")
            }
            
            accelDx := Round(finalDx * currentSpeed)
            accelDy := Round(finalDy * currentSpeed)
            
            if (StateManager.IsInvertedMode()) {
                accelDx := -accelDx
                accelDy := -accelDy
            }
            
            if (accelDx != 0 || accelDy != 0) {
                if (Config.Get("Movement.EnableAbsoluteMovement")) {
                    MouseGetPos(&currentAbsX, &currentAbsY)
                    MouseMove(currentAbsX + accelDx, currentAbsY + accelDy, 0)
                } else {
                    MouseMove(accelDx, accelDy, 0, "R")
                }
            }
            
            currentSpeed := currentSpeed * Config.Get("Movement.AccelerationRate")
            if (currentSpeed > Config.Get("Movement.MaxSpeed") / Config.Get("Movement.BaseSpeed")) {
                currentSpeed := Config.Get("Movement.MaxSpeed") / Config.Get("Movement.BaseSpeed")
            }
            
            Sleep(Config.Get("Movement.MoveDelay"))
        }
    }

    static _GetDirectionArrow(direction) {
        switch direction {
            case "up": return "↑"
            case "down": return "↓"
            case "left": return "←"
            case "right": return "→"
            case "up-left": return "↖"
            case "up-right": return "↗"
            case "down-left": return "↙"
            case "down-right": return "↘"
            default: return ""
        }
    }

    ; Fixed ScrollWithAcceleration method
    static ScrollWithAcceleration(direction, key) {
        currentScrollSpeed := 1.0
        
        ; Extract the actual key without modifier
        ; For Alt+Numpad8, we need to check for Numpad8 while Alt is held
        actualKey := key
        if (InStr(key, "!")) {
            actualKey := StrReplace(key, "!", "")  ; Remove Alt modifier
        }
        
        while GetKeyState(actualKey, "P") {
            scrollAmount := Round(Config.Get("Movement.ScrollStep") * currentScrollSpeed)
            
            if (scrollAmount < 1) {
                scrollAmount := 1
            }
            
            Loop scrollAmount {
                Send("{Wheel" . direction . "}")
            }
            
            currentScrollSpeed := currentScrollSpeed * Config.Get("Movement.ScrollAccelerationRate")
            
            if (currentScrollSpeed > Config.Get("Movement.MaxScrollSpeed") / Config.Get("Movement.ScrollStep")) {
                currentScrollSpeed := Config.Get("Movement.MaxScrollSpeed") / Config.Get("Movement.ScrollStep")
            }
            
            Sleep(Config.Get("Movement.MoveDelay"))
        }
    }

    static UndoLastMove() {
        MouseActions.UndoLastMovement()
    }

    static UndoLastMovement() {
        if (MouseActions.mousePositionHistory.Length <= 1) {
            StatusIndicator.ShowTemporaryMessage("❌ NO UNDO", "error")
            if (Config.Get("Visual.EnableAudioFeedback")) {
                SoundBeep(200, 150)
            }
            return
        }
        
        ; Ensure we're using screen coordinates
        CoordMode("Mouse", "Screen")
        
        MouseActions.mousePositionHistory.Pop()
        pos := MouseActions.mousePositionHistory.Pop()
        MouseMove(pos.x, pos.y, 10)
        MouseActions.mousePositionHistory.Push(pos)
        
        StatusIndicator.ShowTemporaryMessage("↶ UNDONE", "success")
        
        if (Config.Get("Visual.EnableAudioFeedback")) {
            SoundBeep(650, 100)
        }
    }

    static GetPositionHistory() {
        return MouseActions.mousePositionHistory
    }

    static AddToHistory(x, y) {
        ; x and y should already be in screen coordinates
        MouseActions.mousePositionHistory.Push({x: x, y: y})
        if (MouseActions.mousePositionHistory.Length > Config.Get("Movement.MaxUndoLevels")) {
            MouseActions.mousePositionHistory.RemoveAt(1)
        }
    }
}