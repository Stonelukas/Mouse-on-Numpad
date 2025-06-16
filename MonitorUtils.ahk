#Requires AutoHotkey v2.0

; ######################################################################################################################
; Monitor Utils Module - Monitor detection and positioning functions
; ######################################################################################################################

class MonitorUtils {
    static GetMonitorInfo() {
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

    static GetGuiPosition(which, customX := "", customY := "") {
        try {
            mon := MonitorUtils.GetMonitorInfo()
            
            if (customX != "") {
                xPos := customX
            } else if (which = "tooltip") {
                xPos := Config.TooltipX is Number ? Config.TooltipX : MonitorUtils.EvaluateExpression(Config.TooltipX)
            } else {
                xPos := Config.StatusX is Number ? Config.StatusX : MonitorUtils.EvaluateExpression(Config.StatusX)
            }
            
            if (customY != "") {
                yPos := customY
            } else if (which = "tooltip") {
                yPos := Config.TooltipY is Number ? Config.TooltipY : MonitorUtils.EvaluateExpression(Config.TooltipY)
            } else {
                yPos := Config.StatusY is Number ? Config.StatusY : MonitorUtils.EvaluateExpression(Config.StatusY)
            }
            
            return [mon.left + xPos, mon.top + yPos]
        } catch {
            if (which = "tooltip") {
                return [20, A_ScreenHeight - 80]
            }
            return [Round(A_ScreenWidth * 0.65), 15]
        }
    }

    static EvaluateExpression(expression) {
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

    static GetMonitorForWindow(hwnd) {
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

    static IsFullscreen() {
        try {
            activeWindow := WinGetID("A")
            activeMon := MonitorUtils.GetMonitorForWindow(activeWindow)
            
            WinGetPos(&x, &y, &width, &height, activeWindow)
            return (x <= activeMon.left && 
                    y <= activeMon.top && 
                    width >= activeMon.width && 
                    height >= activeMon.height)
        } catch {
            return false
        }
    }

    static CreatePositionTest(mon, label, x, y) {
        testGui := Gui("+AlwaysOnTop -MaximizeBox -MinimizeBox +LastFound -Caption +Border", "")
        testGui.MarginX := 8
        testGui.MarginY := 4
        testGui.BackColor := "0x4CAF50"
        
        testGui.textCtrl := testGui.Add("Text", "cWhite Center w180 h20", label)
        testGui.textCtrl.SetFont("s9 Bold", "Segoe UI")
        testGui.Show("x" . x . " y" . y . " w196 h28 NoActivate")
        SetTimer(() => testGui.Destroy(), -5000)
    }
}