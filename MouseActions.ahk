#Requires AutoHotkey v2.0

; ######################################################################################################################
; Mouse Actions Module - Mouse movement, scrolling, and undo functionality
; ######################################################################################################################

class MouseActions {
    ; Mouse position history for undo functionality
    static mousePositionHistory := []

    static MoveDiagonal(key, baseDx, baseDy) {
        MouseGetPos(&currentX, &currentY)
        MouseActions.mousePositionHistory.Push({x: currentX, y: currentY})
        if (MouseActions.mousePositionHistory.Length > Config.MaxUndoLevels) {
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
                finalDx := -Config.MoveStep
                finalDy := -Config.MoveStep
                feedbackDirection := "up-left"
            } else if (upPressed && rightPressed) {
                finalDx := Config.MoveStep
                finalDy := -Config.MoveStep
                feedbackDirection := "up-right"
            } else if (downPressed && leftPressed) {
                finalDx := -Config.MoveStep
                finalDy := Config.MoveStep
                feedbackDirection := "down-left"
            } else if (downPressed && rightPressed) {
                finalDx := Config.MoveStep
                finalDy := Config.MoveStep
                feedbackDirection := "down-right"
            } else if (upPressed) {
                finalDy := -Config.MoveStep
                feedbackDirection := "up"
            } else if (downPressed) {
                finalDy := Config.MoveStep
                feedbackDirection := "down"
            } else if (leftPressed) {
                finalDx := -Config.MoveStep
                feedbackDirection := "left"
            } else if (rightPressed) {
                finalDx := Config.MoveStep
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
                if (Config.EnableAbsoluteMovement) {
                    MouseGetPos(&currentAbsX, &currentAbsY)
                    MouseMove(currentAbsX + accelDx, currentAbsY + accelDy, 0)
                } else {
                    MouseMove(accelDx, accelDy, 0, "R")
                }
            }
            
            currentSpeed := currentSpeed * Config.AccelerationRate
            if (currentSpeed > Config.MaxSpeed / Config.MoveStep) {
                currentSpeed := Config.MaxSpeed / Config.MoveStep
            }
            
            Sleep(Config.MoveDelay)
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
            scrollAmount := Round(Config.ScrollStep * currentScrollSpeed)
            
            if (scrollAmount < 1) {
                scrollAmount := 1
            }
            
            Loop scrollAmount {
                Send("{Wheel" . direction . "}")
            }
            
            currentScrollSpeed := currentScrollSpeed * Config.ScrollAccelerationRate
            
            if (currentScrollSpeed > Config.MaxScrollSpeed / Config.ScrollStep) {
                currentScrollSpeed := Config.MaxScrollSpeed / Config.ScrollStep
            }
            
            Sleep(Config.MoveDelay)
        }
    }

    static UndoLastMovement() {
        if (MouseActions.mousePositionHistory.Length <= 1) {
            StatusIndicator.ShowTemporaryMessage("❌ NO UNDO", "error")
            if (Config.EnableAudioFeedback) {
                SoundBeep(200, 150)
            }
            return
        }
        
        MouseActions.mousePositionHistory.Pop()
        pos := MouseActions.mousePositionHistory.Pop()
        MouseMove(pos.x, pos.y, 10)
        MouseActions.mousePositionHistory.Push(pos)
        
        StatusIndicator.ShowTemporaryMessage("↶ UNDONE", "success")
        
        if (Config.EnableAudioFeedback) {
            SoundBeep(650, 100)
        }
    }

    static GetPositionHistory() {
        return MouseActions.mousePositionHistory
    }

    static AddToHistory(x, y) {
        MouseActions.mousePositionHistory.Push({x: x, y: y})
        if (MouseActions.mousePositionHistory.Length > Config.MaxUndoLevels) {
            MouseActions.mousePositionHistory.RemoveAt(1)
        }
    }
}