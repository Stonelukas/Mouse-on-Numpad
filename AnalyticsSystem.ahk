#Requires AutoHotkey v2.0

; ######################################################################################################################
; Analytics System - Usage tracking and analytics
; ######################################################################################################################

class AnalyticsSystem {
    ; Analytics data
    static events := []
    static sessionData := Map()
    static sessionStartTime := 0
    static logFile := A_ScriptDir . "\analytics.log"
    static reportDir := A_ScriptDir . "\reports"
    
    ; Event types
    static eventTypes := Map(
        "startup", "Application Started",
        "shutdown", "Application Closed",
        "mouse_move", "Mouse Movement",
        "mouse_click", "Mouse Click",
        "position_save", "Position Saved",
        "position_load", "Position Loaded",
        "settings_change", "Settings Changed",
        "error", "Error Occurred"
    )
    
    ; Initialize analytics
    static Init() {
        AnalyticsSystem.sessionStartTime := A_TickCount
        
        ; Create directories if needed
        if (!DirExist(AnalyticsSystem.reportDir)) {
            DirCreate(AnalyticsSystem.reportDir)
        }
        
        ; Initialize session data
        AnalyticsSystem.sessionData["startTime"] := A_Now
        AnalyticsSystem.sessionData["version"] := APP_VERSION
        AnalyticsSystem.sessionData["events"] := 0
        
        ; Log startup event
        AnalyticsSystem.LogEvent("startup", {
            version: APP_VERSION,
            timestamp: A_Now
        })
    }
    
    ; Log an event
    static LogEvent(eventType, data := "") {
        if (!Config.EnableAnalytics) {
            return
        }
        
        ; Create event object
        event := Map()
        event["type"] := eventType
        event["timestamp"] := A_TickCount
        event["time"] := A_Now
        
        if (data != "") {
            event["data"] := data
        }
        
        ; Add to events array
        AnalyticsSystem.events.Push(event)
        AnalyticsSystem.sessionData["events"]++
        
        ; Write to log file if logging enabled
        if (Config.EnableLogging) {
            AnalyticsSystem.WriteToLog(event)
        }
    }
    
    ; Write event to log file
    static WriteToLog(event) {
        try {
            logEntry := FormatTime(event["time"], "yyyy-MM-dd HH:mm:ss") . " | "
            logEntry .= event["type"] . " | "
            
            if (event.Has("data") && IsObject(event["data"])) {
                ; Convert data to string
                dataStr := ""
                for key, value in event["data"] {
                    dataStr .= key . "=" . value . " "
                }
                logEntry .= dataStr
            }
            
            logEntry .= "`n"
            
            ; Append to log file
            FileAppend(logEntry, AnalyticsSystem.logFile)
            
        } catch Error as e {
            ; Silently fail - don't interrupt user
        }
    }
    
    ; Save session data
    static SaveSession() {
        if (!Config.EnableAnalytics || AnalyticsSystem.events.Length == 0) {
            return
        }
        
        ; Calculate session duration
        duration := Round((A_TickCount - AnalyticsSystem.sessionStartTime) / 1000)
        AnalyticsSystem.sessionData["duration"] := duration
        AnalyticsSystem.sessionData["endTime"] := A_Now
        
        ; Create session report
        timestamp := FormatTime(, "yyyyMMdd_HHmmss")
        reportFile := AnalyticsSystem.reportDir . "\session_" . timestamp . ".txt"
        
        try {
            report := AnalyticsSystem.GenerateReport()
            FileAppend(report, reportFile)
        } catch Error as e {
            ; Silently fail
        }
    }
    
    ; Generate analytics report
    static GenerateReport() {
        report := "MOUSE ON NUMPAD - ANALYTICS REPORT`n"
        report .= "==================================`n`n"
        
        ; Session info
        report .= "Session Information:`n"
        report .= "• Start Time: " . AnalyticsSystem.sessionData["startTime"] . "`n"
        report .= "• End Time: " . AnalyticsSystem.sessionData["endTime"] . "`n"
        report .= "• Duration: " . AnalyticsSystem.FormatDuration(AnalyticsSystem.sessionData["duration"]) . "`n"
        report .= "• Total Events: " . AnalyticsSystem.events.Length . "`n`n"
        
        ; Event summary
        report .= "Event Summary:`n"
        eventCounts := Map()
        
        for event in AnalyticsSystem.events {
            eventType := event["type"]
            if (!eventCounts.Has(eventType)) {
                eventCounts[eventType] := 0
            }
            eventCounts[eventType]++
        }
        
        for eventType, count in eventCounts {
            description := AnalyticsSystem.eventTypes.Has(eventType) ? AnalyticsSystem.eventTypes[eventType] : eventType
            report .= "• " . description . ": " . count . "`n"
        }
        
        report .= "`n"
        
        ; Performance metrics
        if (PerformanceMonitor.totalMoves > 0) {
            report .= "Performance Metrics:`n"
            report .= "• Total Moves: " . PerformanceMonitor.totalMoves . "`n"
            report .= "• Total Clicks: " . PerformanceMonitor.totalClicks . "`n"
            report .= "• Actions/Minute: " . PerformanceMonitor.GetActionsPerMinute() . "`n`n"
        }
        
        ; Most used features
        report .= "Feature Usage:`n"
        report .= "• Mouse Mode Toggles: " . AnalyticsSystem.CountEvents("toggle_mouse") . "`n"
        report .= "• Settings Opened: " . AnalyticsSystem.CountEvents("settings_open") . "`n"
        report .= "• Positions Saved: " . AnalyticsSystem.CountEvents("position_save") . "`n"
        report .= "• Positions Loaded: " . AnalyticsSystem.CountEvents("position_load") . "`n"
        
        return report
    }
    
    ; Show analytics report
    static ShowReport() {
        ; Generate current report
        AnalyticsSystem.sessionData["endTime"] := A_Now
        AnalyticsSystem.sessionData["duration"] := Round((A_TickCount - AnalyticsSystem.sessionStartTime) / 1000)
        
        reportText := AnalyticsSystem.GenerateReport()
        
        ; Create report window
        reportGui := Gui("+Resize", "Analytics Report")
        reportGui.MarginX := 15
        reportGui.MarginY := 15
        
        ; Add report content
        reportEdit := reportGui.Add("Edit", "w500 h400 +ReadOnly +VScroll", reportText)
        reportEdit.SetFont("s9", "Consolas")
        
        ; Add buttons
        saveBtn := reportGui.Add("Button", "w100", "&Save Report")
        saveBtn.OnEvent("Click", (*) => AnalyticsSystem.SaveReportDialog(reportText))
        
        clearBtn := reportGui.Add("Button", "x+10 w100", "&Clear Data")
        clearBtn.OnEvent("Click", (*) => AnalyticsSystem.ClearAnalytics(reportGui))
        
        closeBtn := reportGui.Add("Button", "x+10 w100", "&Close")
        closeBtn.OnEvent("Click", (*) => reportGui.Destroy())
        
        ; Show window
        reportGui.Show()
    }
    
    ; Save report with dialog
    static SaveReportDialog(reportText) {
        ; Create filename
        timestamp := FormatTime(, "yyyyMMdd_HHmmss")
        filename := "analytics_report_" . timestamp . ".txt"
        
        ; Save to reports directory
        filepath := AnalyticsSystem.reportDir . "\" . filename
        
        try {
            FileAppend(reportText, filepath)
            MsgBox("Report saved to:`n" . filepath, "Report Saved", "Iconi")
        } catch Error as e {
            MsgBox("Failed to save report: " . e.Message, "Save Error", "IconX")
        }
    }
    
    ; Clear analytics data
    static ClearAnalytics(gui) {
        result := MsgBox("Clear all analytics data?`n`nThis will reset all tracking data but keep your settings.", 
            "Clear Analytics", "YesNo Icon?")
        
        if (result = "Yes") {
            AnalyticsSystem.events := []
            AnalyticsSystem.sessionData.Clear()
            AnalyticsSystem.sessionStartTime := A_TickCount
            AnalyticsSystem.Init()
            
            MsgBox("Analytics data has been cleared.", "Clear Complete", "Iconi T2")
            gui.Destroy()
        }
    }
    
    ; Count specific event types
    static CountEvents(eventType) {
        count := 0
        for event in AnalyticsSystem.events {
            if (event["type"] = eventType) {
                count++
            }
        }
        return count
    }
    
    ; Format duration for display
    static FormatDuration(seconds) {
        hours := seconds // 3600
        minutes := (seconds // 60) - (hours * 60)
        secs := Mod(seconds, 60)
        
        if (hours > 0) {
            return hours . "h " . minutes . "m " . secs . "s"
        } else if (minutes > 0) {
            return minutes . "m " . secs . "s"
        } else {
            return secs . "s"
        }
    }
}