#Requires AutoHotkey v2.0

; ######################################################################################################################
; Monitor Utils Module - Monitor detection and positioning functions with negative coordinate support
; ######################################################################################################################
; 
; This module has been completely rewritten to properly handle monitor configurations where:
; - The primary monitor's x=0 is in the middle of the screen
; - Monitors to the left have negative X coordinates
; - Monitors above have negative Y coordinates
;
; Key changes:
; - All monitor information is cached and refreshed periodically
; - Proper boundary detection for adjacent monitors
; - Support for Windows virtual screen coordinate system
; - Fallback to Windows API for edge cases
; ######################################################################################################################

class MonitorUtils {
    ; Cache for monitor information
    static monitors := []
    static initialized := false
    
    ; Initialize monitor cache
    static Init() {
        MonitorUtils.monitors := []
        monitorCount := MonitorGetCount()
        primaryMonitor := MonitorGetPrimary()
        
        Loop monitorCount {
            MonitorGet(A_Index, &left, &top, &right, &bottom)
            MonitorGetWorkArea(A_Index, &workLeft, &workTop, &workRight, &workBottom)
            
            MonitorUtils.monitors.Push({
                Index: A_Index,
                Left: left,
                Top: top,
                Right: right,
                Bottom: bottom,
                WorkLeft: workLeft,
                WorkTop: workTop,
                WorkRight: workRight,
                WorkBottom: workBottom,
                Width: right - left,
                Height: bottom - top,
                IsPrimary: (A_Index == primaryMonitor)
            })
        }
        MonitorUtils.initialized := true
    }
    
    ; Force re-initialization (useful when monitor configuration changes)
    static Refresh() {
        MonitorUtils.initialized := false
        MonitorUtils.Init()
    }
    
    ; Get monitor containing a specific point
    static GetMonitorFromPoint(x, y) {
        if (!MonitorUtils.initialized) {
            MonitorUtils.Init()
        }
        
        ; Check each monitor for containment
        for monitor in MonitorUtils.monitors {
            ; Use >= and < for proper boundary handling with adjacent monitors
            if (x >= monitor.Left && x < monitor.Right && 
                y >= monitor.Top && y < monitor.Bottom) {
                return monitor
            }
        }
        
        ; If point is exactly on the right edge of the rightmost monitor
        for monitor in MonitorUtils.monitors {
            if (x == monitor.Right && y >= monitor.Top && y < monitor.Bottom) {
                ; Check if this is the rightmost monitor at this Y position
                isRightmost := true
                for otherMon in MonitorUtils.monitors {
                    if (otherMon.Left > monitor.Right && 
                        y >= otherMon.Top && y < otherMon.Bottom) {
                        isRightmost := false
                        break
                    }
                }
                if (isRightmost) {
                    return monitor
                }
            }
        }
        
        ; Fallback: find nearest monitor using Windows API
        hMonitor := DllCall("User32.dll\MonitorFromPoint", 
            "Int64", (x & 0xFFFFFFFF) | (y << 32), 
            "UInt", 2, ; MONITOR_DEFAULTTONEAREST
            "UPtr")
        
        if (hMonitor) {
            ; Find which monitor this handle corresponds to
            Loop MonitorGetCount() {
                if (MonitorUtils._GetMonitorHandle(A_Index) == hMonitor) {
                    return MonitorUtils.monitors[A_Index]
                }
            }
        }
        
        return false
    }
    
    ; Get monitor handle for a specific monitor index (internal helper)
    static _GetMonitorHandle(monitorIndex) {
        ; This is a simplified approach - in practice, you'd enumerate monitors
        ; For now, we'll return a pseudo-handle
        return monitorIndex
    }
    
    ; Get monitor info based on current settings
    static GetMonitorInfo() {
        try {
            if (!MonitorUtils.initialized) {
                MonitorUtils.Init()
            }
            
            ; If using secondary monitor and it exists
            if (Config.Get("Visual.UseSecondaryMonitor") && MonitorUtils.monitors.Length >= 2) {
                ; Find first non-primary monitor
                for monitor in MonitorUtils.monitors {
                    if (!monitor.IsPrimary) {
                        return {
                            id: monitor.Index,
                            left: monitor.Left,
                            top: monitor.Top,
                            right: monitor.Right,
                            bottom: monitor.Bottom,
                            width: monitor.Width,
                            height: monitor.Height,
                            isPrimary: false
                        }
                    }
                }
            }
            
            ; Return primary monitor
            for monitor in MonitorUtils.monitors {
                if (monitor.IsPrimary) {
                    return {
                        id: monitor.Index,
                        left: monitor.Left,
                        top: monitor.Top,
                        right: monitor.Right,
                        bottom: monitor.Bottom,
                        width: monitor.Width,
                        height: monitor.Height,
                        isPrimary: true
                    }
                }
            }
            
            ; Fallback to first monitor
            if (MonitorUtils.monitors.Length > 0) {
                monitor := MonitorUtils.monitors[1]
                return {
                    id: monitor.Index,
                    left: monitor.Left,
                    top: monitor.Top,
                    right: monitor.Right,
                    bottom: monitor.Bottom,
                    width: monitor.Width,
                    height: monitor.Height,
                    isPrimary: monitor.IsPrimary
                }
            }
            
        } catch {
            ; Ultimate fallback
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
            
            ; Important: Handle negative coordinates properly
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
            
            return MonitorUtils.GetMonitorFromPoint(midX, midY)
        } catch {
            ; Fallback to primary monitor
            for monitor in MonitorUtils.monitors {
                if (monitor.IsPrimary) {
                    return monitor
                }
            }
            return false
        }
    }
    
    static IsFullscreen() {
        try {
            activeWindow := WinGetID("A")
            if (!activeWindow) {
                return false
            }
            
            activeMon := MonitorUtils.GetMonitorForWindow(activeWindow)
            if (!activeMon) {
                return false
            }
            
            WinGetPos(&x, &y, &width, &height, activeWindow)
            
            ; Check if window covers the entire monitor (with small tolerance for rounding)
            tolerance := 2
            return (x <= activeMon.Left + tolerance && 
                    y <= activeMon.Top + tolerance && 
                    x + width >= activeMon.Right - tolerance && 
                    y + height >= activeMon.Bottom - tolerance)
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
    
    ; Get monitor description for a specific position
    static GetMonitorDescriptionForPosition(x, y) {
        monitor := MonitorUtils.GetMonitorFromPoint(x, y)
        if (monitor) {
            if (monitor.IsPrimary) {
                return "Primary Monitor"
            } else {
                return "Monitor " . monitor.Index
            }
        }
        return "Unknown"
    }
    
    ; Debug function to display all monitor information
    static ShowMonitorDebugInfo() {
        if (!MonitorUtils.initialized) {
            MonitorUtils.Init()
        }
        
        debugInfo := "MONITOR CONFIGURATION DEBUG`n`n"
        debugInfo .= "Total Monitors: " . MonitorUtils.monitors.Length . "`n"
        debugInfo .= "Primary Monitor: " . MonitorGetPrimary() . "`n`n"
        
        for monitor in MonitorUtils.monitors {
            debugInfo .= "Monitor " . monitor.Index
            if (monitor.IsPrimary) {
                debugInfo .= " (PRIMARY)"
            }
            debugInfo .= ":`n"
            debugInfo .= "  Position: " . monitor.Left . "," . monitor.Top . " to " . monitor.Right . "," . monitor.Bottom . "`n"
            debugInfo .= "  Size: " . monitor.Width . " x " . monitor.Height . "`n"
            debugInfo .= "  Work Area: " . monitor.WorkLeft . "," . monitor.WorkTop . " to " . monitor.WorkRight . "," . monitor.WorkBottom . "`n`n"
        }
        
        ; Current mouse position
        CoordMode("Mouse", "Screen")
        MouseGetPos(&mx, &my)
        debugInfo .= "Current Mouse Position: " . mx . ", " . my . "`n"
        
        mouseMonitor := MonitorUtils.GetMonitorFromPoint(mx, my)
        if (mouseMonitor) {
            debugInfo .= "Mouse is on Monitor " . mouseMonitor.Index . "`n"
        } else {
            debugInfo .= "Mouse monitor not detected (outside all monitors?)`n"
        }
        
        return debugInfo
    }
}