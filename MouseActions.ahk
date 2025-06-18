#Requires AutoHotkey v2.0

; ######################################################################################################################
; Mouse Actions Module - Mouse movement, scrolling, and undo functionality
; ######################################################################################################################

class MouseActions {
    ; Mouse position history for undo functionality
    static mousePositionHistory := []

    static MoveDiagonal(key, baseDx, baseDy) {
        ; Ensure we're using screen coordinates
        CoordMode("Mouse", "Screen")
        
        MouseGetPos(&currentX, &currentY)
        MouseActions.mousePositionHistory.Push({x: currentX, y: currentY})
        if (MouseActions.mousePositionHistory.Length > Config.get("Movement.MaxUndoLevels")) {
            MouseActions.mousePositionHistory.RemoveAt(1)
        }
        
        currentSpeed := 1.0
        
        while GetKeyState(key, "P") {
            finalDx := 0
            finalDy := 0
            feedbackDirection := ""
            
            upPressed := GetKeyState("Numpad8", "P")
            downPressed := GetKeyState("Numpad2", "P")
            leftPressed := GetKeyState("Numpad4", "P")
            rightPressed := GetKeyState("Numpad6", "P")
            
            if (upPressed && leftPressed) {
                finalDx := -Config.get("Movement.BaseSpeed")
                finalDy := -Config.get("Movement.BaseSpeed")
                feedbackDirection := "up-left"
            } else if (upPressed && rightPressed) {
                finalDx := Config.get("Movement.BaseSpeed")
                finalDy := -Config.get("Movement.BaseSpeed")
                feedbackDirection := "up-right"
            } else if (downPressed && leftPressed) {
                finalDx := -Config.get("Movement.BaseSpeed")
                finalDy := Config.get("Movement.BaseSpeed")
                feedbackDirection := "down-left"
            } else if (downPressed && rightPressed) {
                finalDx := Config.get("Movement.BaseSpeed")
                finalDy := Config.get("Movement.BaseSpeed")
                feedbackDirection := "down-right"
            } else if (upPressed) {
                finalDy := -Config.get("Movement.BaseSpeed")
                feedbackDirection := "up"
            } else if (downPressed) {
                finalDy := Config.get("Movement.BaseSpeed")
                feedbackDirection := "down"
            } else if (leftPressed) {
                finalDx := -Config.get("Movement.BaseSpeed")
                feedbackDirection := "left"
            } else if (rightPressed) {
                finalDx := Config.get("Movement.BaseSpeed")
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
                if (Config.get("Movement.EnableAbsoluteMovement")) {
                    MouseGetPos(&currentAbsX, &currentAbsY)
                    MouseMove(currentAbsX + accelDx, currentAbsY + accelDy, 0)
                } else {
                    MouseMove(accelDx, accelDy, 0, "R")
                }
            }
            
            currentSpeed := currentSpeed * Config.get("Movement.AccelerationRate")
            if (currentSpeed > Config.get("Movement.MaxSpeed") / Config.get("Movement.BaseSpeed")) {
                currentSpeed := Config.get("Movement.MaxSpeed") / Config.get("Movement.BaseSpeed")
            }
            
            Sleep(Config.get("Movement.MoveDelay"))
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

    static ScrollWithAcceleration(direction, key) {
        currentScrollSpeed := 1.0
        
        while GetKeyState(key, "P") {
            scrollAmount := Round(Config.get("Movement.ScrollStep") * currentScrollSpeed)
            
            if (scrollAmount < 1) {
                scrollAmount := 1
            }
            
            Loop scrollAmount {
                Send("{Wheel" . direction . "}")
            }
            
            currentScrollSpeed := currentScrollSpeed * Config.get("Movement.ScrollAccelerationRate")
            
            if (currentScrollSpeed > Config.get("Movement.MaxScrollSpeed") / Config.get("Movement.ScrollStep")) {
                currentScrollSpeed := Config.get("Movement.MaxScrollSpeed") / Config.get("Movement.ScrollStep")
            }
            
            Sleep(Config.get("Movement.MoveDelay"))
        }
    }

    static UndoLastMovement() {
        if (MouseActions.mousePositionHistory.Length <= 1) {
            StatusIndicator.ShowTemporaryMessage("❌ NO UNDO", "error")
            if (Config.get("Visual.EnableAudioFeedback")) {
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
        
        if (Config.get("Visual.EnableAudioFeedback")) {
            SoundBeep(650, 100)
        }
    }

    static GetPositionHistory() {
        return MouseActions.mousePositionHistory
    }

    static AddToHistory(x, y) {
        ; x and y should already be in screen coordinates
        MouseActions.mousePositionHistory.Push({x: x, y: y})
        if (MouseActions.mousePositionHistory.Length > Config.get("Movement.MaxUndoLevels")) {
            MouseActions.mousePositionHistory.RemoveAt(1)
        }
    }
}