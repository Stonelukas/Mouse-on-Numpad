#Requires AutoHotkey v2.0

; ######################################################################################################################
; Script: Mouse on Numpad Enhanced with Separate Tooltip System
; Version: 2.1.3
; Features:
; - Comprehensive numpad mouse control
; - Full secondary monitor support
; - Improved positioning and fullscreen detection
; - SEPARATE tooltip system for mouse actions
; ######################################################################################################################

; ======================================================================================================================
; I. Configuration and Initial Setup
; ======================================================================================================================

class Config {
    ; Movement settings
    static MoveStep := 4
    static MoveDelay := 15
    static AccelerationRate := 1.1
    static MaxSpeed := 30
    static EnableAbsoluteMovement := false

    ; Undo settings
    static MaxUndoLevels := 10

    ; Position memory
    static MaxSavedPositions := 5
    static PersistentPositionsFile := "MouseNumpadConfig.ini"

    ; GUI settings
    static TooltipX := 20
    static TooltipY := "A_ScreenHeight - 80"
    static StatusX := "Round(A_ScreenWidth * 0.65)"
    static StatusY := 15
    static StatusVisibleOnStartup := true
    static FeedbackDurationShort := 200
    static FeedbackDurationLong := 3000
    static EnableAudioFeedback := false
    static UseSecondaryMonitor := false

    ; Scroll settings
    static ScrollStep := 1
    static ScrollAccelerationRate := 1.1
    static MaxScrollSpeed := 10

    ; Hotkey settings
    static PrefixKey := ""
    static InvertModeToggleKey := "NumpadClear"
    static AbsoluteMovementToggleKey := "NumpadIns"

    static Load() {
        ; Load settings from INI file
        tempMoveStep := IniRead(Config.PersistentPositionsFile, "Settings", "MoveStep", Config.MoveStep)
        tempMoveDelay := IniRead(Config.PersistentPositionsFile, "Settings", "MoveDelay", Config.MoveDelay)
        tempAccelerationRate := IniRead(Config.PersistentPositionsFile, "Settings", "AccelerationRate", Config.AccelerationRate)
        tempMaxSpeed := IniRead(Config.PersistentPositionsFile, "Settings", "MaxSpeed", Config.MaxSpeed)
        tempMaxUndoLevels := IniRead(Config.PersistentPositionsFile, "Settings", "MaxUndoLevels", Config.MaxUndoLevels)
        tempMaxSavedPositions := IniRead(Config.PersistentPositionsFile, "Settings", "MaxSavedPositions", Config.MaxSavedPositions)
        tempEnableAudioFeedback := IniRead(Config.PersistentPositionsFile, "Settings", "EnableAudioFeedback", Config.EnableAudioFeedback)
        tempStatusVisibleOnStartup := IniRead(Config.PersistentPositionsFile, "Settings", "StatusVisibleOnStartup", Config.StatusVisibleOnStartup)
        tempScrollStep := IniRead(Config.PersistentPositionsFile, "Settings", "ScrollStep", Config.ScrollStep)
        tempScrollAccelerationRate := IniRead(Config.PersistentPositionsFile, "Settings", "ScrollAccelerationRate", Config.ScrollAccelerationRate)
        tempMaxScrollSpeed := IniRead(Config.PersistentPositionsFile, "Settings", "MaxScrollSpeed", Config.MaxScrollSpeed)
        tempPrefixKey := IniRead(Config.PersistentPositionsFile, "Settings", "PrefixKey", Config.PrefixKey)
        tempInvertModeToggleKey := IniRead(Config.PersistentPositionsFile, "Settings", "InvertModeToggleKey", Config.InvertModeToggleKey)
        tempAbsoluteMovementToggleKey := IniRead(Config.PersistentPositionsFile, "Settings", "AbsoluteMovementToggleKey", Config.AbsoluteMovementToggleKey)
        tempEnableAbsoluteMovement := IniRead(Config.PersistentPositionsFile, "Settings", "EnableAbsoluteMovement", Config.EnableAbsoluteMovement)
        tempUseSecondaryMonitor := IniRead(Config.PersistentPositionsFile, "Settings", "UseSecondaryMonitor", Config.UseSecondaryMonitor)

        ; Apply valid settings
        if (tempMoveStep != "" && IsNumber(tempMoveStep))
            Config.MoveStep := Number(tempMoveStep)
        if (tempMoveDelay != "" && IsNumber(tempMoveDelay))
            Config.MoveDelay := Number(tempMoveDelay)
        if (tempAccelerationRate != "" && IsNumber(tempAccelerationRate))
            Config.AccelerationRate := Number(tempAccelerationRate)
        if (tempMaxSpeed != "" && IsNumber(tempMaxSpeed))
            Config.MaxSpeed := Number(tempMaxSpeed)
        if (tempMaxUndoLevels != "" && IsNumber(tempMaxUndoLevels))
            Config.MaxUndoLevels := Number(tempMaxUndoLevels)
        if (tempMaxSavedPositions != "" && IsNumber(tempMaxSavedPositions))
            Config.MaxSavedPositions := Number(tempMaxSavedPositions)
        if (tempEnableAudioFeedback != "")
            Config.EnableAudioFeedback := (tempEnableAudioFeedback = "true" || tempEnableAudioFeedback = "1")
        if (tempStatusVisibleOnStartup != "")
            Config.StatusVisibleOnStartup := (tempStatusVisibleOnStartup = "true" || tempStatusVisibleOnStartup = "1")
        if (tempScrollStep != "" && IsNumber(tempScrollStep))
            Config.ScrollStep := Number(tempScrollStep)
        if (tempScrollAccelerationRate != "" && IsNumber(tempScrollAccelerationRate))
            Config.ScrollAccelerationRate := Number(tempScrollAccelerationRate)
        if (tempMaxScrollSpeed != "" && IsNumber(tempMaxScrollSpeed))
            Config.MaxScrollSpeed := Number(tempMaxScrollSpeed)
        if (tempPrefixKey != "")
            Config.PrefixKey := tempPrefixKey
        if (tempInvertModeToggleKey != "")
            Config.InvertModeToggleKey := tempInvertModeToggleKey
        if (tempAbsoluteMovementToggleKey != "")
            Config.AbsoluteMovementToggleKey := tempAbsoluteMovementToggleKey
        if (tempEnableAbsoluteMovement != "")
            Config.EnableAbsoluteMovement := (tempEnableAbsoluteMovement = "true" || tempEnableAbsoluteMovement = "1")
        if (tempUseSecondaryMonitor != "")
            Config.UseSecondaryMonitor := (tempUseSecondaryMonitor = "true" || tempUseSecondaryMonitor = "1")

        ; GUI positions
        tempTooltipX := IniRead(Config.PersistentPositionsFile, "GUI", "TooltipX", Config.TooltipX)
        tempTooltipY := IniRead(Config.PersistentPositionsFile, "GUI", "TooltipY", Config.TooltipY)
        tempStatusX := IniRead(Config.PersistentPositionsFile, "GUI", "StatusX", Config.StatusX)
        tempStatusY := IniRead(Config.PersistentPositionsFile, "GUI", "StatusY", Config.StatusY)
        
        if (tempTooltipX != "")
            Config.TooltipX := tempTooltipX
        if (tempTooltipY != "")
            Config.TooltipY := tempTooltipY
        if (tempStatusX != "")
            Config.StatusX := tempStatusX
        if (tempStatusY != "")
            Config.StatusY := tempStatusY
    }

    static Save() {
        ; Save settings to INI file
        IniWrite(Config.MoveStep, Config.PersistentPositionsFile, "Settings", "MoveStep")
        IniWrite(Config.MoveDelay, Config.PersistentPositionsFile, "Settings", "MoveDelay")
        IniWrite(Config.AccelerationRate, Config.PersistentPositionsFile, "Settings", "AccelerationRate")
        IniWrite(Config.MaxSpeed, Config.PersistentPositionsFile, "Settings", "MaxSpeed")
        IniWrite(Config.MaxUndoLevels, Config.PersistentPositionsFile, "Settings", "MaxUndoLevels")
        IniWrite(Config.MaxSavedPositions, Config.PersistentPositionsFile, "Settings", "MaxSavedPositions")
        IniWrite(Config.EnableAudioFeedback, Config.PersistentPositionsFile, "Settings", "EnableAudioFeedback")
        IniWrite(Config.StatusVisibleOnStartup, Config.PersistentPositionsFile, "Settings", "StatusVisibleOnStartup")
        IniWrite(Config.ScrollStep, Config.PersistentPositionsFile, "Settings", "ScrollStep")
        IniWrite(Config.ScrollAccelerationRate, Config.PersistentPositionsFile, "Settings", "ScrollAccelerationRate")
        IniWrite(Config.MaxScrollSpeed, Config.PersistentPositionsFile, "Settings", "MaxScrollSpeed")
        IniWrite(Config.PrefixKey, Config.PersistentPositionsFile, "Settings", "PrefixKey")
        IniWrite(Config.InvertModeToggleKey, Config.PersistentPositionsFile, "Settings", "InvertModeToggleKey")
        IniWrite(Config.AbsoluteMovementToggleKey, Config.PersistentPositionsFile, "Settings", "AbsoluteMovementToggleKey")
        IniWrite(Config.EnableAbsoluteMovement, Config.PersistentPositionsFile, "Settings", "EnableAbsoluteMovement")
        IniWrite(Config.UseSecondaryMonitor, Config.PersistentPositionsFile, "Settings", "UseSecondaryMonitor")

        IniWrite(Config.TooltipX, Config.PersistentPositionsFile, "GUI", "TooltipX")
        IniWrite(Config.TooltipY, Config.PersistentPositionsFile, "GUI", "TooltipY")
        IniWrite(Config.StatusX, Config.PersistentPositionsFile, "GUI", "StatusX")
        IniWrite(Config.StatusY, Config.PersistentPositionsFile, "GUI", "StatusY")
    }
}

; State variables
mouseMode := false
invertedMode := false
saveMode := false
loadMode := false
statusVisible := false
isReloading := false
lastLoadedSlot := 0
showingPositionFeedback := false

; Mouse button states
leftButtonHeld := false
rightButtonHeld := false
middleButtonHeld := false

; Mouse position memory
savedPositions := Map()
mousePositionHistory := []

; GUI elements
globalTooltip := ""
mouseTooltip := ""  ; Separate tooltip for mouse actions
statusIndicator := ""

; Timers
fullscreenCheckTimer := ""
leftClickHoldTimer := ""
mouseTooltipTimer := ""

; ======================================================================================================================
; II. Enhanced Monitor and Positioning Functions
; ======================================================================================================================

getMonitorInfo() {
    try {
        monitorCount := MonitorGetCount()
        primaryMonitor := MonitorGetPrimary()
        
        if (!Config.UseSecondaryMonitor || monitorCount < 2) {
            MonitorGet(primaryMonitor, &left, &top, &right, &bottom)
            return {
                id: primaryMonitor,
                left: left,
                top: top,
                right: right,
                bottom: bottom,
                width: right - left,
                height: bottom - top,
                isPrimary: true
            }
        }
        
        Loop monitorCount {
            if (A_Index != primaryMonitor) {
                MonitorGet(A_Index, &left, &top, &right, &bottom)
                return {
                    id: A_Index,
                    left: left,
                    top: top,
                    right: right,
                    bottom: bottom,
                    width: right - left,
                    height: bottom - top,
                    isPrimary: false
                }
            }
        }
        
        MonitorGet(primaryMonitor, &left, &top, &right, &bottom)
        return {
            id: primaryMonitor,
            left: left,
            top: top,
            right: right,
            bottom: bottom,
            width: right - left,
            height: bottom - top,
            isPrimary: true
        }
    } catch {
        return {
            left: 0,
            top: 0,
            right: A_ScreenWidth,
            bottom: A_ScreenHeight,
            width: A_ScreenWidth,
            height: A_ScreenHeight,
            isPrimary: true
        }
    }
}

getGuiPosition(which, customX := "", customY := "") {
    try {
        mon := getMonitorInfo()
        
        if (customX != "") {
            xPos := customX
        } else if (which = "tooltip") {
            xPos := Config.TooltipX is Number ? Config.TooltipX : EvaluateExpression(Config.TooltipX)
        } else {
            xPos := Config.StatusX is Number ? Config.StatusX : EvaluateExpression(Config.StatusX)
        }
        
        if (customY != "") {
            yPos := customY
        } else if (which = "tooltip") {
            yPos := Config.TooltipY is Number ? Config.TooltipY : EvaluateExpression(Config.TooltipY)
        } else {
            yPos := Config.StatusY is Number ? Config.StatusY : EvaluateExpression(Config.StatusY)
        }
        
        return [mon.left + xPos, mon.top + yPos]
    } catch {
        if (which = "tooltip") {
            return [20, A_ScreenHeight - 80]
        }
        return [Round(A_ScreenWidth * 0.65), 15]
    }
}

EvaluateExpression(expression) {
    try {
        if (expression = "A_ScreenHeight - 80") {
            return A_ScreenHeight - 80
        } else if (expression = "Round(A_ScreenWidth * 0.65)") {
            return Round(A_ScreenWidth * 0.65)
        } else if (IsNumber(expression)) {
            return Number(expression)
        } else {
            return %expression%
        }
    } catch {
        return 0
    }
}

getMonitorForWindow(hwnd) {
    try {
        WinGetPos(&x, &y, &width, &height, hwnd)
        midX := x + width // 2
        midY := y + height // 2
        
        monitorCount := MonitorGetCount()
        Loop monitorCount {
            MonitorGet(A_Index, &left, &top, &right, &bottom)
            if (midX >= left && midX <= right && midY >= top && midY <= bottom) {
                return {
                    id: A_Index,
                    left: left,
                    top: top,
                    right: right,
                    bottom: bottom,
                    width: right - left,
                    height: bottom - top
                }
            }
        }
    }
    
    MonitorGet(MonitorGetPrimary(), &left, &top, &right, &bottom)
    return {
        left: left,
        top: top,
        right: right,
        bottom: bottom,
        width: right - left,
        height: bottom - top
    }
}

; ======================================================================================================================
; III. SEPARATE TOOLTIP SYSTEMS
; ======================================================================================================================

initializeTooltip() {
    global globalTooltip
    
    globalTooltip := Gui("+AlwaysOnTop -MaximizeBox -MinimizeBox +LastFound -Caption +Border", "")
    globalTooltip.BackColor := "0x607D8B"
    globalTooltip.MarginX := 5
    globalTooltip.MarginY := 2
    
    globalTooltip.textCtrl := globalTooltip.Add("Text", "cWhite Center w50 h16", "")
    globalTooltip.textCtrl.SetFont("s8 Bold", "Segoe UI")
    
    pos := getGuiPosition("tooltip")
    globalTooltip.Move(pos[1], pos[2], 60, 22)
    globalTooltip.Show("NoActivate")
    WinSetTransparent(0, globalTooltip.Hwnd)
}

initializeMouseTooltip() {
    global mouseTooltip
    
    mouseTooltip := Gui("+AlwaysOnTop -MaximizeBox -MinimizeBox +LastFound -Caption +Border", "")
    mouseTooltip.BackColor := "0x4CAF50"
    mouseTooltip.MarginX := 8
    mouseTooltip.MarginY := 4
    
    mouseTooltip.textCtrl := mouseTooltip.Add("Text", "cWhite Center w120 h20", "")
    mouseTooltip.textCtrl.SetFont("s9 Bold", "Segoe UI")
    
    pos := getGuiPosition("tooltip")
    mouseTooltip.Move(pos[1], pos[2] - 30, 140, 28)  ; Position above regular tooltip
    mouseTooltip.Show("NoActivate")
    WinSetTransparent(0, mouseTooltip.Hwnd)
}

; Simple tooltip for movement arrows - uses the original system
showBeautifulTooltip(text, type := "info", duration := "") {
    global globalTooltip, statusVisible
    
    if (!statusVisible || isFullscreen()) {
        return
    }
    
    globalTooltip.BackColor := getTooltipColor(type)
    globalTooltip.textCtrl.Text := text
    
    textLength := StrLen(text)
    if (text == "↑" || text == "↓" || text == "←" || text == "→" || text == "↖" || text == "↗" || text == "↙" || text == "↘") {
        tooltipWidth := 40
        textWidth := 30
    } else {
        tooltipWidth := (textLength * 9) + 24
        textWidth := tooltipWidth - 16
        if (tooltipWidth < 60) {
            tooltipWidth := 60
            textWidth := 44
        }
        if (tooltipWidth > 250) {
            tooltipWidth := 250
            textWidth := 234
        }
    }
    
    globalTooltip.textCtrl.Move(8, 2, textWidth, 18)
    
    pos := getGuiPosition("tooltip")
    globalTooltip.Move(pos[1], pos[2], tooltipWidth, 22)
    
    WinSetTransparent(255, globalTooltip.Hwnd)
    
    if (duration != "") {
        displayDuration := duration
    } else if (text == "↑" || text == "↓" || text == "←" || text == "→" || text == "↖" || text == "↗" || text == "↙" || text == "↘") {
        displayDuration := Config.FeedbackDurationShort
    } else {
        displayDuration := Config.FeedbackDurationLong
    }
    
    SetTimer(() => WinSetTransparent(0, globalTooltip.Hwnd), -displayDuration)
}

; Dedicated mouse tooltip that stays visible for full duration
showMouseActionTooltip(text, type := "success") {
    global mouseTooltip, statusVisible, mouseTooltipTimer
    
    if (!statusVisible || isFullscreen()) {
        return
    }
    
    ; Cancel any existing mouse tooltip timer
    if (mouseTooltipTimer != "") {
        SetTimer(mouseTooltipTimer, 0)
        mouseTooltipTimer := ""
    }
    
    ; Set color based on type
    switch type {
        case "success": mouseTooltip.BackColor := "0x4CAF50"
        case "warning": mouseTooltip.BackColor := "0xFF9800"
        case "info": mouseTooltip.BackColor := "0x2196F3"
        case "error": mouseTooltip.BackColor := "0xF44336"
        default: mouseTooltip.BackColor := "0x4CAF50"
    }
    
    mouseTooltip.textCtrl.Text := text
    
    ; Calculate width based on text
    textLength := StrLen(text)
    tooltipWidth := (textLength * 10) + 30
    if (tooltipWidth < 120) tooltipWidth := 120
    if (tooltipWidth > 300) tooltipWidth := 300
    textWidth := tooltipWidth - 20
    
    mouseTooltip.textCtrl.Move(10, 4, textWidth, 20)
    
    pos := getGuiPosition("tooltip")
    mouseTooltip.Move(pos[1], pos[2] - 35, tooltipWidth, 28)
    
    ; Show for exactly 4 seconds
    WinSetTransparent(255, mouseTooltip.Hwnd)
    
    ; Set timer to hide after 4 seconds - this should NOT be interrupted
    mouseTooltipTimer := () => WinSetTransparent(0, mouseTooltip.Hwnd)
    SetTimer(mouseTooltipTimer, -4000)
}

hideTooltip() {
    global globalTooltip
    WinSetTransparent(0, globalTooltip.Hwnd)
    if (!statusVisible) {
        globalTooltip.Hide()
    }
}

showBeautifulTooltipForced(text, type := "info") {
    global globalTooltip
    
    globalTooltip.BackColor := getTooltipColor(type)
    globalTooltip.textCtrl.Text := text
    
    textLength := StrLen(text)
    tooltipWidth := (textLength * 9) + 24
    if (tooltipWidth < 60) tooltipWidth := 60
    if (tooltipWidth > 250) tooltipWidth := 250
    
    pos := getGuiPosition("tooltip")
    globalTooltip.Move(pos[1], pos[2], tooltipWidth, 22)
    
    WinSetTransparent(255, globalTooltip.Hwnd)
    globalTooltip.Show("NoActivate")
    
    SetTimer(() => WinSetTransparent(0, globalTooltip.Hwnd), -1000)
}

initializeStatusIndicator() {
    global statusIndicator
    
    statusIndicator := Gui("+AlwaysOnTop -MaximizeBox -MinimizeBox +LastFound -Caption +Border", "")
    statusIndicator.BackColor := "0xF44336"
    statusIndicator.MarginX := 4
    statusIndicator.MarginY := 2
    
    statusIndicator.textCtrl := statusIndicator.Add("Text", "cWhite Left h18", "⌨️ OFF • 🔄 Relative")
    statusIndicator.textCtrl.SetFont("s8 Bold", "Segoe UI")
    
    pos := getGuiPosition("status")
    statusIndicator.Show("x" . pos[1] . " y" . pos[2] . " w116 h22 NoActivate")
}

updateStatusIndicator() {
    global statusIndicator, mouseMode, invertedMode, saveMode, loadMode
    global leftButtonHeld, rightButtonHeld, middleButtonHeld
    
    mainStatus := ""
    backgroundColor := ""
    
    if (!mouseMode) {
        backgroundColor := "0xF44336"
        mainStatus := "⌨️ OFF"
        invertedMode := false
    } else if (saveMode) {
        backgroundColor := "0x9C27B0"
        mainStatus := "💾 SAVE"
    } else if (loadMode) {
        backgroundColor := "0x2196F3"
        mainStatus := "📂 LOAD"
    } else if (invertedMode) {
        backgroundColor := "0xFF9800"
        mainStatus := "🔄 INV"
    } else {
        backgroundColor := "0x4CAF50"
        mainStatus := "🖱️ ON"
    }
    
    movementMode := Config.EnableAbsoluteMovement ? "🎯 ABS" : "🔄 REL"
    
    heldButtons := ""
    if (leftButtonHeld || GetKeyState("LButton", "P")) {
        heldButtons := heldButtons . "🖱️L"
    }
    if (rightButtonHeld || GetKeyState("RButton", "P")) {
        heldButtons := heldButtons . "🖱️R"
    }
    if (middleButtonHeld || GetKeyState("MButton", "P")) {
        heldButtons := heldButtons . "🖱️M"
    }
    
    if (heldButtons != "") {
        combinedText := mainStatus . "•" . movementMode . "•" . heldButtons
    } else {
        combinedText := mainStatus . "•" . movementMode
    }
    
    keyboardEmojis := StrLen(combinedText) - StrLen(StrReplace(combinedText, "⌨️", ""))
    mouseEmojis := StrLen(combinedText) - StrLen(StrReplace(combinedText, "🖱️", ""))
    arrowEmojis := StrLen(combinedText) - StrLen(StrReplace(combinedText, "🔄", ""))
    targetEmojis := StrLen(combinedText) - StrLen(StrReplace(combinedText, "🎯", ""))
    saveEmojis := StrLen(combinedText) - StrLen(StrReplace(combinedText, "💾", ""))
    loadEmojis := StrLen(combinedText) - StrLen(StrReplace(combinedText, "📂", ""))
    
    totalEmojis := keyboardEmojis + mouseEmojis + arrowEmojis + targetEmojis + saveEmojis + loadEmojis
    regularChars := StrLen(combinedText) - totalEmojis
    
    textWidth := (regularChars * 5) + (totalEmojis * 8)
    guiWidth := textWidth + 8
    
    if (guiWidth < 60) {
        guiWidth := 60
    }
    
    statusIndicator.BackColor := backgroundColor
    statusIndicator.textCtrl.Text := combinedText
    statusIndicator.textCtrl.Move(2, 2, textWidth + 4, 18)
    
    pos := getGuiPosition("status")
    statusIndicator.Move(pos[1], pos[2], guiWidth, 22)
    
    updateStatusVisibility()
}

updateStatusIndicatorForLeftHold() {
    updateStatusIndicator()
}

isFullscreen() {
    try {
        activeWindow := WinGetID("A")
        activeMon := getMonitorForWindow(activeWindow)
        
        WinGetPos(&x, &y, &width, &height, activeWindow)
        return (x <= activeMon.left && 
                y <= activeMon.top && 
                width >= activeMon.width && 
                height >= activeMon.height)
    } catch {
        return false
    }
}

updateStatusVisibility() {
    global statusIndicator, statusVisible, globalTooltip, mouseTooltip

    if (!statusVisible || isFullscreen()) {
        try {
            statusIndicator.Hide()
            if (globalTooltip != "") {
                globalTooltip.Hide()
            }
            if (mouseTooltip != "") {
                mouseTooltip.Hide()
            }
        }
    } else {
        try {
            statusIndicator.Show("NoActivate")
            if (globalTooltip != "") {
                globalTooltip.Show("NoActivate")
                WinSetTransparent(0, globalTooltip.Hwnd)
            }
            if (mouseTooltip != "") {
                mouseTooltip.Show("NoActivate")
                WinSetTransparent(0, mouseTooltip.Hwnd)
            }
        }
    }
}

toggleStatusVisibility() {
    global statusVisible, globalTooltip
    
    statusVisible := !statusVisible
    updateStatusVisibility()
    
    tempStatusGui := Gui("+AlwaysOnTop -MaximizeBox -MinimizeBox +LastFound -Caption +Border", "")
    tempStatusGui.MarginX := 8
    tempStatusGui.MarginY := 4
    
    if (statusVisible) {
        tempStatusGui.BackColor := "0x4CAF50"
        statusText := "Status ON"
    } else {
        tempStatusGui.BackColor := "0xFF9800"  
        statusText := "Status OFF"
    }
    
    textLength := StrLen(statusText)
    guiWidth := (textLength * 8) + 20
    if (guiWidth < 80) guiWidth := 80
    textWidth := guiWidth - 16
    
    tempStatusGui.textCtrl := tempStatusGui.Add("Text", "cWhite Center w" . textWidth . " h18", statusText)
    tempStatusGui.textCtrl.SetFont("s9 Bold", "Segoe UI")
    
    pos := getGuiPosition("tooltip")
    tempStatusGui.Show("x" . pos[1] . " y" . pos[2] . " w" . guiWidth . " h26 NoActivate")
    
    SetTimer(() => tempStatusGui.Destroy(), -3000)

    if (Config.EnableAudioFeedback) {
        SoundBeep(statusVisible ? 800 : 400, 150)
    }
}

toggleSecondaryMonitor() {
    Config.UseSecondaryMonitor := !Config.UseSecondaryMonitor
    
    ; Update all GUI positions immediately
    updateStatusIndicator()
    
    ; Create a temporary GUI for the toggle feedback
    tempGui := Gui("+AlwaysOnTop -MaximizeBox -MinimizeBox +LastFound -Caption +Border", "")
    tempGui.MarginX := 8
    tempGui.MarginY := 4
    
    if (Config.UseSecondaryMonitor) {
        tempGui.BackColor := "0x4CAF50"
        statusText := "Secondary Monitor ON"
    } else {
        tempGui.BackColor := "0xFF9800"
        statusText := "Secondary Monitor OFF"
    }
    
    textLength := StrLen(statusText)
    guiWidth := (textLength * 8) + 20
    if (guiWidth < 120) guiWidth := 120
    textWidth := guiWidth - 16
    
    tempGui.textCtrl := tempGui.Add("Text", "cWhite Center w" . textWidth . " h18", statusText)
    tempGui.textCtrl.SetFont("s9 Bold", "Segoe UI")
    
    pos := getGuiPosition("tooltip")
    tempGui.Show("x" . pos[1] . " y" . pos[2] . " w" . guiWidth . " h26 NoActivate")
    
    SetTimer(() => tempGui.Destroy(), -3000)

    if (Config.EnableAudioFeedback) {
        SoundBeep(Config.UseSecondaryMonitor ? 900 : 500, 150)
    }
}

getTooltipColor(type) {
    switch type {
        case "success": return "0x4CAF50"
        case "warning": return "0xFF9800"
        case "info": return "0x2196F3"
        case "error": return "0xF44336"
        default: return "0x607D8B"
    }
}

checkFullscreenPeriodically() {
    updateStatusVisibility()
    
    global globalTooltip, mouseTooltip, statusVisible
    if ((!statusVisible || isFullscreen())) {
        try {
            if (globalTooltip != "") {
                globalTooltip.Hide()
            }
            if (mouseTooltip != "") {
                mouseTooltip.Hide()
            }
        }
    }
}

; ======================================================================================================================
; IV. Mouse Movement and Actions
; ======================================================================================================================

moveDiagonalOrSingle(key, baseDx, baseDy) {
    global mousePositionHistory, invertedMode
    
    MouseGetPos(&currentX, &currentY)
    mousePositionHistory.Push({x: currentX, y: currentY})
    if (mousePositionHistory.Length > Config.MaxUndoLevels) {
        mousePositionHistory.RemoveAt(1)
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
            arrow := ""
            switch feedbackDirection {
                case "up": arrow := "↑"
                case "down": arrow := "↓"
                case "left": arrow := "←"
                case "right": arrow := "→"
                case "up-left": arrow := "↖"
                case "up-right": arrow := "↗"
                case "down-left": arrow := "↙"
                case "down-right": arrow := "↘"
            }
            showBeautifulTooltip(arrow, "info")
        }
        
        accelDx := Round(finalDx * currentSpeed)
        accelDy := Round(finalDy * currentSpeed)
        
        if (invertedMode) {
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

scrollWithAcceleration(direction, key) {
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

; ======================================================================================================================
; V. Position Memory and Undo
; ======================================================================================================================

saveMousePosition(slot) {
    global savedPositions, statusIndicator
    
    if (slot < 1 || slot > Config.MaxSavedPositions) {
        showBeautifulTooltip("Invalid Slot!", "error")
        return
    }
    
    MouseGetPos(&x, &y)
    savedPositions[slot] := {x: x, y: y}

    statusIndicator.BackColor := "0x4CAF50"
    statusIndicator.textCtrl.Text := "💾 SAVED " . slot
    
    if (Config.EnableAudioFeedback) {
        SoundBeep(700, 100)
    }
    
    Sleep(300)
    updateStatusIndicator()
}

restoreMousePosition(slot) {
    global savedPositions, statusIndicator, showingPositionFeedback, mousePositionHistory
    
    if (slot < 1 || slot > Config.MaxSavedPositions) {
        showBeautifulTooltip("Invalid Slot!", "error")
        return
    }
    
    if (!savedPositions.Has(slot)) {
        statusIndicator.BackColor := "0xF44336"
        statusIndicator.textCtrl.Text := "❌ NO POS " . slot
        if (Config.EnableAudioFeedback) {
            SoundBeep(200, 150)
        }
        showingPositionFeedback := true
        SetTimer(delayedStatusUpdateFromPosition, -800)
        return
    }
    
    MouseGetPos(&currentX, &currentY)
    mousePositionHistory.Push({x: currentX, y: currentY})
    if (mousePositionHistory.Length > Config.MaxUndoLevels) {
        mousePositionHistory.RemoveAt(1)
    }
    
    pos := savedPositions[slot]
    MouseMove(pos.x, pos.y, 10)
    
    statusIndicator.BackColor := "0x2196F3"
    statusIndicator.textCtrl.Text := "📍 POS " . slot
    
    if (Config.EnableAudioFeedback) {
        SoundBeep(500, 100)
    }
    
    showingPositionFeedback := true
    SetTimer(delayedStatusUpdateFromPosition, -800)
}

delayedStatusUpdate() {
    updateStatusIndicator()
}

delayedStatusUpdateFromPosition() {
    global showingPositionFeedback
    showingPositionFeedback := false
    updateStatusIndicator()
}

toggleSaveMode() {
    global saveMode, loadMode
    
    saveMode := !saveMode
    loadMode := false
    updateStatusIndicator()

    if (Config.EnableAudioFeedback) {
        SoundBeep(saveMode ? 750 : 350, 100)
    }
}

toggleLoadMode() {
    global saveMode, loadMode, lastLoadedSlot
    
    loadMode := !loadMode
    saveMode := false
    
    if (!loadMode) {
        lastLoadedSlot := 0
    }
    
    updateStatusIndicator()

    if (Config.EnableAudioFeedback) {
        SoundBeep(loadMode ? 750 : 350, 100)
    }
}

handlePositionSlot(slot) {
    global saveMode, loadMode, lastLoadedSlot, showingPositionFeedback
    
    if (saveMode) {
        saveMode := false
        saveMousePosition(slot)
    } else if (loadMode) {
        if (lastLoadedSlot == slot) {
            loadMode := false
            lastLoadedSlot := 0
            restoreMousePosition(slot)
        } else {
            lastLoadedSlot := slot
            restoreMousePosition(slot)
        }
    }
}

undoLastMovement() {
    global mousePositionHistory, statusIndicator
    
    if (mousePositionHistory.Length <= 1) {
        statusIndicator.BackColor := "0xF44336"
        statusIndicator.textCtrl.Text := "❌ NO UNDO"
        if (Config.EnableAudioFeedback) {
            SoundBeep(200, 150)
        }
        SetTimer(() => updateStatusIndicator(), -800)
        return
    }
    
    mousePositionHistory.Pop()
    pos := mousePositionHistory.Pop()
    MouseMove(pos.x, pos.y, 10)
    mousePositionHistory.Push(pos)
    
    statusIndicator.BackColor := "0x9C27B0"
    statusIndicator.textCtrl.Text := "↶ UNDONE"
    
    if (Config.EnableAudioFeedback) {
        SoundBeep(650, 100)
    }
    
    SetTimer(() => updateStatusIndicator(), -400)
}

; ======================================================================================================================
; VI. Script Lifecycle and Mode Management
; ======================================================================================================================

toggleMouseMode() {
    global mouseMode, saveMode, loadMode
    mouseMode := !mouseMode
    saveMode := false
    loadMode := false
    updateStatusIndicator()

    if (Config.EnableAudioFeedback) {
        SoundBeep(mouseMode ? 900 : 400, 150)
    }
}

toggleInvertedMode() {
    global invertedMode
    invertedMode := !invertedMode
    updateStatusIndicator()

    if (Config.EnableAudioFeedback) {
        SoundBeep(invertedMode ? 600 : 300, 100)
    }
}

toggleAbsoluteMovementMode() {
    Config.EnableAbsoluteMovement := !Config.EnableAbsoluteMovement
    updateStatusIndicator()

    if (Config.EnableAudioFeedback) {
        SoundBeep(Config.EnableAbsoluteMovement ? 850 : 450, 150)
    }
}

loadSavedPositions() {
    global savedPositions
    
    savedPositions := Map()
    
    Loop Config.MaxSavedPositions {
        x := IniRead(Config.PersistentPositionsFile, "Positions", "Slot" . A_Index . "X", "")
        y := IniRead(Config.PersistentPositionsFile, "Positions", "Slot" . A_Index . "Y", "")
        
        if (x != "" && y != "") {
            savedPositions[A_Index] := {x: x, y: y}
        }
    }
}

saveSavedPositions() {
    global savedPositions
    
    IniDelete(Config.PersistentPositionsFile, "Positions")
    
    for slot, pos in savedPositions {
        IniWrite(pos.x, Config.PersistentPositionsFile, "Positions", "Slot" . slot . "X")
        IniWrite(pos.y, Config.PersistentPositionsFile, "Positions", "Slot" . slot . "Y")
    }
}

onScriptExit(ExitReason, ExitCode) {
    global globalTooltip, mouseTooltip, statusIndicator, isReloading

    if (!isReloading) {
        Config.Save()
    }
    
    saveSavedPositions()

    if (globalTooltip != "") {
        globalTooltip.Destroy()
    }
    if (mouseTooltip != "") {
        mouseTooltip.Destroy()
    }
    if (statusIndicator != "") {
        statusIndicator.Destroy()
    }

    SetTimer(checkFullscreenPeriodically, 0)
}

reloadScript() {
    global isReloading
    isReloading := true
    saveSavedPositions()
    Reload
}

reloadWithGUI() {
    reloadGui := Gui("+AlwaysOnTop -MaximizeBox -MinimizeBox +LastFound -Caption +Border", "")
    reloadGui.BackColor := "0xFF9800"
    reloadGui.MarginX := 15
    reloadGui.MarginY := 10
    
    reloadText := reloadGui.Add("Text", "cWhite Center w200 h30", "🔄 Reloading Script...")
    reloadText.SetFont("s12 Bold", "Segoe UI")
    
    centerX := A_ScreenWidth // 2 - 115
    centerY := A_ScreenHeight // 2 - 25
    reloadGui.Show("x" . centerX . " y" . centerY . " w230 h50 NoActivate")
    
    Sleep(1000)
    reloadScript()
}

; ======================================================================================================================
; VII. Hotkey Definitions
; ======================================================================================================================

; Global Hotkeys (Always Active)
NumpadAdd::toggleMouseMode()
NumpadMult::toggleSaveMode()
NumpadSub::toggleLoadMode()
NumpadDiv::undoLastMovement()
^NumpadAdd::toggleStatusVisibility()
^!r::reloadWithGUI()

; Secondary Monitor Toggle - Alt+Numpad9
!Numpad9::toggleSecondaryMonitor()

; Monitor Test - Ctrl+Alt+Numpad9 (shows monitor layout test)
^!Numpad9::{
    mon := getMonitorInfo()
    monType := mon.isPrimary ? "PRIMARY" : "SECONDARY"
    
    createPositionTest(mon, "TOP-LEFT", mon.left + 20, mon.top + 20)
    createPositionTest(mon, "TOP-RIGHT", mon.right - 220, mon.top + 20)
    createPositionTest(mon, "BOTTOM-LEFT", mon.left + 20, mon.bottom - 60)
    createPositionTest(mon, "BOTTOM-RIGHT", mon.right - 220, mon.bottom - 60)
    createPositionTest(mon, "CENTER", mon.left + (mon.width//2) - 100, 
                       mon.top + (mon.height//2) - 15)
    
    result := monType " Monitor`n"
            . "Size: " mon.width "x" mon.height "`n"
            . "Position: " mon.left "," mon.top
    showBeautifulTooltipForced(result, "info")
}

createPositionTest(mon, label, x, y) {
    testGui := Gui("+AlwaysOnTop -MaximizeBox -MinimizeBox +LastFound -Caption +Border", "")
    testGui.MarginX := 8
    testGui.MarginY := 4
    testGui.BackColor := "0x4CAF50"
    
    testGui.textCtrl := testGui.Add("Text", "cWhite Center w180 h20", label)
    testGui.textCtrl.SetFont("s9 Bold", "Segoe UI")
    testGui.Show("x" . x . " y" . y . " w196 h28 NoActivate")
    SetTimer(() => testGui.Destroy(), -5000)
}

; Position Memory Hotkeys (Active only when in Save Mode or Load Mode)
#HotIf (saveMode || loadMode)

Numpad4::handlePositionSlot(1)
Numpad5::handlePositionSlot(2)
Numpad6::handlePositionSlot(3)
Numpad8::handlePositionSlot(4)
Numpad0::handlePositionSlot(5)

#HotIf

; Mouse Mode Hotkeys (Active only when Mouse Mode is ON and NOT in Save/Load Mode)
#HotIf mouseMode && !saveMode && !loadMode

Numpad8::moveDiagonalOrSingle("Numpad8", 0, -Config.MoveStep)
Numpad2::moveDiagonalOrSingle("Numpad2", 0, Config.MoveStep)
Numpad4::moveDiagonalOrSingle("Numpad4", -Config.MoveStep, 0)
Numpad6::moveDiagonalOrSingle("Numpad6", Config.MoveStep, 0)

Numpad5::{
    global leftClickHoldTimer, leftButtonHeld
    
    leftButtonHeld := true
    Click("Left", , , , , "D")
    showMouseActionTooltip("🖱️ Left Held", "success")
    
    if (Config.EnableAudioFeedback) {
        SoundBeep(500, 50)
    }
    
    updateStatusIndicator()
    leftClickHoldTimer := SetTimer(updateStatusIndicatorForLeftHold, 250)
    
    KeyWait("Numpad5")
    
    leftButtonHeld := false
    if (leftClickHoldTimer != "") {
        SetTimer(leftClickHoldTimer, 0)
        leftClickHoldTimer := ""
    }
    
    Click("Left", , , , , "U")
    showMouseActionTooltip("🖱️ Left Released", "info")
    
    if (Config.EnableAudioFeedback) {
        SoundBeep(400, 50)
    }
    
    updateStatusIndicator()
}

NumpadClear::{
    global leftButtonHeld
    
    if (leftButtonHeld) {
        leftButtonHeld := false
        Click("Left", , , , , "U")
        showMouseActionTooltip("🖱️ Left Released", "info")
        
        if (Config.EnableAudioFeedback) {
            SoundBeep(400, 100)
        }
    } else {
        leftButtonHeld := true
        Click("Left", , , , , "D")
        showMouseActionTooltip("🖱️ Left Held", "success")
        
        if (Config.EnableAudioFeedback) {
            SoundBeep(500, 100)
        }
    }
    
    Sleep(150)
    updateStatusIndicator()
}

Numpad0::Click("right")

NumpadIns::{
    global rightButtonHeld
    
    if (rightButtonHeld) {
        rightButtonHeld := false
        Click("Right", , , , , "U")
        showMouseActionTooltip("🖱️ Right Released", "warning")
        
        if (Config.EnableAudioFeedback) {
            SoundBeep(400, 100)
        }
    } else {
        rightButtonHeld := true
        Click("Right", , , , , "D")
        showMouseActionTooltip("🖱️ Right Held", "success")
        
        if (Config.EnableAudioFeedback) {
            SoundBeep(600, 100)
        }
    }
    
    Sleep(150)
    updateStatusIndicator()
}

NumpadDot::{
    global invertedMode, rightButtonHeld
    
    wasInvertedMode := invertedMode
    wasRightHeld := rightButtonHeld
    
    if (wasInvertedMode && wasRightHeld) {
        toggleInvertedMode()
        rightButtonHeld := false
        Click("Right", , , , , "U")
        showMouseActionTooltip("🔄🖱️ Both Off", "warning")
        Sleep(150)
        updateStatusIndicator()
    } else if (wasInvertedMode && !wasRightHeld) {
        rightButtonHeld := true
        Click("Right", , , , , "D")
        showMouseActionTooltip("🖱️ Right Added", "success")
        Sleep(150)
        updateStatusIndicator()
    } else if (!wasInvertedMode && wasRightHeld) {
        toggleInvertedMode()
        showMouseActionTooltip("🔄 Inverted Added", "success")
        Sleep(150)
        updateStatusIndicator()
    } else {
        toggleInvertedMode()
        Sleep(100)
        rightButtonHeld := true
        Click("Right", , , , , "D")
        showMouseActionTooltip("🔄🖱️ Both On", "success")
        Sleep(150)
        updateStatusIndicator()
    }
}

NumpadEnter::Click("middle")

+NumpadEnter::{
    global middleButtonHeld
    
    if (middleButtonHeld) {
        middleButtonHeld := false
        Click("Middle", , , , , "U")
        showMouseActionTooltip("🖱️ Middle Released", "warning")
        
        if (Config.EnableAudioFeedback) {
            SoundBeep(350, 100)
        }
    } else {
        middleButtonHeld := true
        Click("Middle", , , , , "D")
        showMouseActionTooltip("🖱️ Middle Held", "success")
        
        if (Config.EnableAudioFeedback) {
            SoundBeep(550, 100)
        }
    }
    
    Sleep(150)
    updateStatusIndicator()
}

Numpad7::scrollWithAcceleration("Up", "Numpad7")
Numpad1::scrollWithAcceleration("Down", "Numpad1")
Numpad9::scrollWithAcceleration("Left", "Numpad9")
Numpad3::scrollWithAcceleration("Right", "Numpad3")

#HotIf

; ======================================================================================================================
; VIII. Script Initialization
; ======================================================================================================================

initialize() {
    global statusVisible
    
    Config.Load()
    statusVisible := Config.StatusVisibleOnStartup

    OnExit(onScriptExit)

    initializeTooltip()
    initializeMouseTooltip()
    initializeStatusIndicator()

    loadSavedPositions()

    updateStatusIndicator()

    SetTimer(checkFullscreenPeriodically, 500)
}

; Start the script
initialize()