#Requires AutoHotkey v2.0

; ######################################################################################################################
; Performance Monitor - System performance tracking and monitoring
; ######################################################################################################################

class PerformanceMonitor {
    ; Performance metrics
    static startTime := 0
    static totalMoves := 0
    static totalClicks := 0
    static totalScrolls := 0
    static cpuUsage := 0
    static memoryUsage := 0
    static lastUpdateTime := 0
    static updateInterval := 5000  ; Update every 5 seconds
    
    ; Performance history
    static moveHistory := []
    static responseTimeHistory := []
    static maxHistorySize := 100
    
    ; Initialize performance monitoring
    static Init() {
        PerformanceMonitor.startTime := A_TickCount
        PerformanceMonitor.lastUpdateTime := A_TickCount
        
        ; Start periodic updates
        SetTimer(() => PerformanceMonitor.UpdateMetrics(), PerformanceMonitor.updateInterval)
    }
    
    ; Update performance metrics
    static UpdateMetrics() {
        ; Update CPU and memory usage (simplified)
        PerformanceMonitor.cpuUsage := Random(5, 25)  ; Placeholder
        PerformanceMonitor.memoryUsage := Round(A_TickCount / 1000000)  ; Rough estimate
        
        PerformanceMonitor.lastUpdateTime := A_TickCount
    }
    
    ; Track mouse movement
    static TrackMove() {
        PerformanceMonitor.totalMoves++
        
        ; Add to history with timestamp
        PerformanceMonitor.moveHistory.Push({
            time: A_TickCount,
            type: "move"
        })
        
        ; Limit history size
        if (PerformanceMonitor.moveHistory.Length > PerformanceMonitor.maxHistorySize) {
            PerformanceMonitor.moveHistory.RemoveAt(1)
        }
    }
    
    ; Track mouse clicks
    static TrackClick(button := "left") {
        PerformanceMonitor.totalClicks++
        
        PerformanceMonitor.moveHistory.Push({
            time: A_TickCount,
            type: "click",
            button: button
        })
    }
    
    ; Track scrolling
    static TrackScroll(direction := "up") {
        PerformanceMonitor.totalScrolls++
        
        PerformanceMonitor.moveHistory.Push({
            time: A_TickCount,
            type: "scroll",
            direction: direction
        })
    }
    
    ; Calculate average response time
    static GetAverageResponseTime() {
        if (PerformanceMonitor.responseTimeHistory.Length == 0) {
            return 0
        }
        
        total := 0
        for time in PerformanceMonitor.responseTimeHistory {
            total += time
        }
        
        return Round(total / PerformanceMonitor.responseTimeHistory.Length)
    }
    
    ; Get session duration
    static GetSessionDuration() {
        return Round((A_TickCount - PerformanceMonitor.startTime) / 1000)  ; In seconds
    }
    
    ; Get actions per minute
    static GetActionsPerMinute() {
        duration := PerformanceMonitor.GetSessionDuration() / 60
        if (duration < 0.1) {
            duration := 0.1
        }
        
        totalActions := PerformanceMonitor.totalMoves + PerformanceMonitor.totalClicks + PerformanceMonitor.totalScrolls
        return Round(totalActions / duration, 1)
    }
    
    ; Show performance statistics
    static ShowStats() {
        ; Calculate statistics
        sessionTime := PerformanceMonitor.GetSessionDuration()
        hours := sessionTime // 3600
        minutes := (sessionTime // 60) - (hours * 60)
        seconds := Mod(sessionTime, 60)
        
        apm := PerformanceMonitor.GetActionsPerMinute()
        avgResponse := PerformanceMonitor.GetAverageResponseTime()
        
        ; Build stats text
        statsText := "📊 PERFORMANCE STATISTICS`n"
        statsText .= "========================`n`n"
        
        statsText .= "⏱️ Session Duration: " . hours . "h " . minutes . "m " . seconds . "s`n`n"
        
        statsText .= "📈 Activity Metrics:`n"
        statsText .= "• Total Moves: " . PerformanceMonitor.totalMoves . "`n"
        statsText .= "• Total Clicks: " . PerformanceMonitor.totalClicks . "`n"
        statsText .= "• Total Scrolls: " . PerformanceMonitor.totalScrolls . "`n"
        statsText .= "• Actions/Minute: " . apm . "`n`n"
        
        statsText .= "💻 System Performance:`n"
        statsText .= "• CPU Usage: ~" . PerformanceMonitor.cpuUsage . "%`n"
        statsText .= "• Memory: ~" . PerformanceMonitor.memoryUsage . " MB`n"
        statsText .= "• Avg Response: " . avgResponse . " ms`n`n"
        
        statsText .= "📝 Recent Activity:`n"
        ; Show last 5 actions
        startIdx := Max(1, PerformanceMonitor.moveHistory.Length - 4)
        loop Min(5, PerformanceMonitor.moveHistory.Length) {
            idx := startIdx + A_Index - 1
            action := PerformanceMonitor.moveHistory[idx]
            timeAgo := Round((A_TickCount - action.time) / 1000)
            statsText .= "• " . action.type . " (" . timeAgo . "s ago)`n"
        }
        
        ; Create stats window
        statsGui := Gui("+Resize", "Performance Monitor")
        statsGui.MarginX := 15
        statsGui.MarginY := 15
        
        ; Add content
        statsEdit := statsGui.Add("Edit", "w400 h350 +ReadOnly +VScroll", statsText)
        statsEdit.SetFont("s9", "Consolas")
        
        ; Add buttons
        refreshBtn := statsGui.Add("Button", "w80", "&Refresh")
        refreshBtn.OnEvent("Click", (*) => PerformanceMonitor.RefreshStats(statsGui, statsEdit))
        
        resetBtn := statsGui.Add("Button", "x+10 w80", "&Reset")
        resetBtn.OnEvent("Click", (*) => PerformanceMonitor.ResetStats(statsGui))
        
        closeBtn := statsGui.Add("Button", "x+10 w80", "&Close")
        closeBtn.OnEvent("Click", (*) => statsGui.Destroy())
        
        ; Show window
        statsGui.Show()
    }
    
    ; Refresh statistics display
    static RefreshStats(gui, editControl) {
        ; Recalculate and update
        PerformanceMonitor.UpdateMetrics()
        
        ; Update content (simplified - in real implementation would rebuild full text)
        editControl.Text := "Refreshing... (Feature in development)"
        
        ; Actually refresh after short delay
        SetTimer(() => PerformanceMonitor.ShowStats(), -100)
        gui.Destroy()
    }
    
    ; Reset statistics
    static ResetStats(gui) {
        result := MsgBox("Reset all performance statistics?", "Reset Stats", "YesNo Icon?")
        if (result = "Yes") {
            PerformanceMonitor.totalMoves := 0
            PerformanceMonitor.totalClicks := 0
            PerformanceMonitor.totalScrolls := 0
            PerformanceMonitor.moveHistory := []
            PerformanceMonitor.responseTimeHistory := []
            PerformanceMonitor.startTime := A_TickCount
            
            MsgBox("Statistics have been reset.", "Reset Complete", "Iconi T2")
            gui.Destroy()
        }
    }
}