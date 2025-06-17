#Requires AutoHotkey v2.0

; ######################################################################################################################
; Monitor Utilities - Monitor detection and positioning
; ######################################################################################################################

class MonitorUtils {
    ; Cache monitor info
    static monitors := []
    static primaryMonitor := 1
    static lastRefresh := 0
    static refreshInterval := 5000  ; Refresh every 5 seconds
    
    ; Refresh monitor information
    static Refresh() {
        MonitorUtils.monitors := []
        monCount := MonitorGetCount()
        
        loop monCount {
            MonitorGet(A_Index, &left, &top, &right, &bottom)
            MonitorGetWorkArea(A_Index, &workLeft, &workTop, &workRight, &workBottom)
            
            monInfo := {
                index: A_Index,
                left: left,
                top: top,
                right: right,
                bottom: bottom,
                width: right - left,
                height: bottom - top,
                workLeft: workLeft,
                workTop: workTop,
                workRight: workRight,
                workBottom: workBottom,
                workWidth: workRight - workLeft,
                workHeight: workBottom - workTop,
                isPrimary: MonitorGetPrimary() = A_Index
            }
            
            MonitorUtils.monitors.Push(monInfo)
            
            if (monInfo.isPrimary) {
                MonitorUtils.primaryMonitor := A_Index
            }
        }
        
        MonitorUtils.lastRefresh := A_TickCount
    }
    
    ; Get monitor info (with auto-refresh)
    static GetMonitorInfo(monitorIndex := 0) {
        ; Auto-refresh if needed
        if (A_TickCount - MonitorUtils.lastRefresh > MonitorUtils.refreshInterval) {
            MonitorUtils.Refresh()
        }
        
        ; Default to primary or secondary based on config
        if (monitorIndex == 0) {
            if (Config.UseSecondaryMonitor && MonitorUtils.monitors.Length > 1) {
                monitorIndex := MonitorUtils.primaryMonitor = 1 ? 2 : 1
            } else {
                monitorIndex := MonitorUtils.primaryMonitor
            }
        }
        
        ; Return monitor info
        if (monitorIndex > 0 && monitorIndex <= MonitorUtils.monitors.Length) {
            return MonitorUtils.monitors[monitorIndex]
        }
        
        ; Fallback to primary
        return MonitorUtils.monitors[MonitorUtils.primaryMonitor]
    }
    
    ; Get all monitors
    static GetAllMonitors() {
        if (A_TickCount - MonitorUtils.lastRefresh > MonitorUtils.refreshInterval) {
            MonitorUtils.Refresh()
        }
        
        return {
            monitors: MonitorUtils.monitors,
            count: MonitorUtils.monitors.Length,
            primary: MonitorUtils.monitors[MonitorUtils.primaryMonitor],
            primaryIndex: MonitorUtils.primaryMonitor
        }
    }
    
    ; Get monitor at specific point
    static GetMonitorAtPoint(x, y) {
        MonitorUtils.Refresh()
        
        for monitor in MonitorUtils.monitors {
            if (x >= monitor.left && x < monitor.right && y >= monitor.top && y < monitor.bottom) {
                return monitor.index
            }
        }
        
        return 0  ; Not found
    }
    
    ; Check if window is fullscreen
    static IsFullscreen(winTitle := "A") {
        if (!WinExist(winTitle)) {
            return false
        }
        
        ; Get window position
        WinGetPos(&winX, &winY, &winW, &winH, winTitle)
        
        ; Get monitor info for window
        monIndex := MonitorUtils.GetMonitorAtPoint(winX + winW/2, winY + winH/2)
        if (monIndex == 0) {
            return false
        }
        
        mon := MonitorUtils.monitors[monIndex]
        
        ; Check if window covers entire monitor
        return (winX <= mon.left && winY <= mon.top && 
                winX + winW >= mon.right && winY + winH >= mon.bottom)
    }
    
    ; Evaluate position expression
    static EvaluateExpression(expr) {
        ; Replace A_ScreenWidth and A_ScreenHeight with actual values
        expr := StrReplace(expr, "A_ScreenWidth", A_ScreenWidth)
        expr := StrReplace(expr, "A_ScreenHeight", A_ScreenHeight)
        
        ; Try to evaluate the expression
        try {
            ; Use a simple evaluation method
            if (InStr(expr, "Round")) {
                ; Handle Round function
                expr := StrReplace(expr, "Round(", "")
                expr := StrReplace(expr, ")", "")
            }
            
            ; Evaluate basic math
            if (InStr(expr, "*")) {
                parts := StrSplit(expr, "*")
                if (parts.Length == 2) {
                    return Round(Float(Trim(parts[1])) * Float(Trim(parts[2])))
                }
            }
            
            if (InStr(expr, "-")) {
                parts := StrSplit(expr, "-")
                if (parts.Length == 2) {
                    return Integer(Trim(parts[1])) - Integer(Trim(parts[2]))
                }
            }
            
            ; Try to convert to number
            return Integer(expr)
            
        } catch {
            ; Return default value on error
            return 100
        }
    }
    
    ; Get safe position within monitor bounds
    static GetSafePosition(x, y, monitorIndex := 0) {
        mon := MonitorUtils.GetMonitorInfo(monitorIndex)
        
        ; Constrain to monitor bounds
        x := Max(mon.left, Min(x, mon.right - 1))
        y := Max(mon.top, Min(y, mon.bottom - 1))
        
        return {x: x, y: y}
    }
}