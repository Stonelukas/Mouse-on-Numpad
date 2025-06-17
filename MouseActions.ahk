#Requires AutoHotkey v2.0

; ######################################################################################################################
; Mouse Actions - Core mouse movement and click functionality
; ######################################################################################################################

class MouseActions {
    ; Movement state
    static moveTimer := ""
    static currentDirection := ""
    static isMoving := false
    
    ; Start continuous movement
    static StartMove(direction) {
        if (!State.mouseMode) {
            return
        }
        
        ; Stop any existing movement
        MouseActions.StopMove()
        
        ; Set direction and start moving
        MouseActions.currentDirection := direction
        MouseActions.isMoving := true
        
        ; Show direction arrow
        TooltipSystem.ShowArrow(direction)
        
        ; Perform first move immediately
        MouseActions.PerformMove()
        
        ; Set up continuous movement
        MouseActions.moveTimer := () => MouseActions.PerformMove()
        SetTimer(MouseActions.moveTimer, Config.MoveDelay)
    }
    
    ; Stop movement
    static StopMove() {
        if (MouseActions.moveTimer) {
            SetTimer(MouseActions.moveTimer, 0)
            MouseActions.moveTimer := ""
        }
        
        MouseActions.isMoving := false
        State.ResetMovement()
    }
    
    ; Perform single movement
    static PerformMove() {
        if (!MouseActions.isMoving || !State.mouseMode) {
            MouseActions.StopMove()
            return
        }
        
        ; Get current position
        MouseGetPos(&x, &y)
        
        ; Save position for undo
        State.AddToHistory(x, y)
        
        ; Calculate movement
        moveDistance := MouseActions.CalculateMoveDistance()
        
        ; Apply movement based on direction
        switch MouseActions.currentDirection {
            case "up":
                y -= moveDistance
            case "down":
                y += moveDistance
            case "left":
                x -= moveDistance
            case "right":
                x += moveDistance
            case "up-left":
                x -= moveDistance
                y -= moveDistance
            case "up-right":
                x += moveDistance
                y -= moveDistance
            case "down-left":
                x -= moveDistance
                y += moveDistance
            case "down-right":
                x += moveDistance
                y += moveDistance
        }
        
        ; Apply invert mode if active
        if (State.invertMode) {
            MouseGetPos(&currentX, &currentY)
            x := currentX - (x - currentX)
            y := currentY - (y - currentY)
        }
        
        ; Constrain to monitor bounds
        pos := MonitorUtils.GetSafePosition(x, y)
        
        ; Move mouse
        MouseMove(pos.x, pos.y, 0)
        
        ; Track movement
        State.moveCount++
        State.consecutiveMoves++
        State.lastMoveTime := A_TickCount
        
        ; Track in performance monitor
        if (Config.EnableAnalytics) {
            PerformanceMonitor.TrackMove()
        }
    }
    
    ; Calculate move distance with acceleration
    static CalculateMoveDistance() {
        ; Base step
        distance := Config.MoveStep
        
        ; Apply acceleration
        if (Config.AccelerationRate > 1 && State.consecutiveMoves > 0) {
            acceleratedDistance := distance * (Config.AccelerationRate ** State.consecutiveMoves)
            distance := Min(acceleratedDistance, Config.MaxSpeed)
        }
        
        State.currentSpeed := distance
        return Round(distance)
    }
    
    ; Perform click
    static Click(button := "left") {
        if (!State.mouseMode) {
            return
        }
        
        ; Perform click
        Click(button)
        
        ; Show feedback
        clickText := button = "left" ? "🖱️ Left Click" : "🖱️ Right Click"
        TooltipSystem.ShowMouseAction(clickText, 1000)
        
        ; Track click
        if (Config.EnableAnalytics) {
            PerformanceMonitor.TrackClick(button)
            AnalyticsSystem.LogEvent("mouse_click", {button: button})
        }
        
        ; Audio feedback
        if (Config.EnableAudioFeedback) {
            SoundBeep(button = "left" ? 800 : 600, 100)
        }
    }
    
    ; Scroll wheel
    static Scroll(direction) {
        if (!State.mouseMode) {
            return
        }
        
        ; Calculate scroll amount
        scrollAmount := MouseActions.CalculateScrollAmount()
        
        ; Perform scroll
        if (direction = "up") {
            Click("WheelUp " . scrollAmount)
        } else {
            Click("WheelDown " . scrollAmount)
        }
        
        ; Show feedback
        scrollText := direction = "up" ? "🖱️ Scroll ↑" : "🖱️ Scroll ↓"
        TooltipSystem.ShowMouseAction(scrollText . " (" . scrollAmount . ")", 800)
        
        ; Track scroll
        if (Config.EnableAnalytics) {
            PerformanceMonitor.TrackScroll(direction)
        }
    }
    
    ; Calculate scroll amount with acceleration
    static CalculateScrollAmount() {
        amount := Config.ScrollStep
        
        if (Config.ScrollAccelerationRate > 1) {
            ; Simple acceleration based on recent activity
            if (A_TickCount - State.lastMoveTime < 1000) {
                amount := Min(amount * Config.ScrollAccelerationRate, Config.MaxScrollSpeed)
            }
        }
        
        return Round(amount)
    }
    
    ; Undo last movement
    static Undo() {
        if (State.undoHistory.Length < 2) {
            TooltipSystem.ShowTemporary("Nothing to undo", "warning")
            return
        }
        
        ; Remove current position
        State.undoHistory.Pop()
        
        ; Get previous position
        if (State.undoHistory.Length > 0) {
            lastPos := State.undoHistory[State.undoHistory.Length]
            
            ; Move to previous position
            MouseMove(lastPos.x, lastPos.y, 0)
            
            ; Show feedback
            TooltipSystem.ShowTemporary("↶ Undo", "info")
            
            ; Audio feedback
            if (Config.EnableAudioFeedback) {
                SoundBeep(500, 100)
            }
        }
    }
}