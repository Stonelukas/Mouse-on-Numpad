#Requires AutoHotkey v2.0

; ######################################################################################################################
; Simple Error Logging System - Minimal logging for better debugging
; ######################################################################################################################

class ErrorLogger {
    static logFile := A_ScriptDir . "\debug.log"
    static maxLogSize := 1024 * 1024  ; 1MB max log size
    static isEnabled := false
    
    ; Initialize logging system
    static Initialize() {
        ; Enable logging only if debug mode is enabled in config
        try {
            ErrorLogger.isEnabled := Config.Get("Debug.EnableLogging", false)
        } catch {
            ErrorLogger.isEnabled := false
        }
        
        if (ErrorLogger.isEnabled) {
            ErrorLogger.Log("INFO", "Mouse on Numpad Enhanced - Logging initialized")
        }
    }
    
    ; Log an error message
    static LogError(message, location := "") {
        if (!ErrorLogger.isEnabled)
            return
        
        fullMessage := "ERROR"
        if (location) {
            fullMessage .= " [" . location . "]"
        }
        fullMessage .= ": " . message
        
        ErrorLogger.Log("ERROR", fullMessage)
    }
    ; Log a warning message
    static LogWarning(message, location := "") {
        if (!ErrorLogger.isEnabled)
            return
        
        fullMessage := "WARNING"
        if (location) {
            fullMessage .= " [" . location . "]"
        }
        fullMessage .= ": " . message
        
        ErrorLogger.Log("WARNING", fullMessage)
    }
    ; Log an info message
    ; Log an info message
    static LogInfo(message, location := "") {
        if (!ErrorLogger.isEnabled)
            return
        
        fullMessage := "INFO"
        if (location) {
            fullMessage .= " [" . location . "]"
        }
        fullMessage .= ": " . message
        
        ErrorLogger.Log("INFO", fullMessage)
    }
    ; Core logging method
    ; Core logging method
    static Log(level, message) {
        if (!ErrorLogger.isEnabled)
            return
        
        try {
            if (FileExist(ErrorLogger.logFile)) {
                fileInfo := FileGetAttrib(ErrorLogger.logFile)
                if (FileGetSize(ErrorLogger.logFile) > ErrorLogger.maxLogSize) {
                    ; Rotate log file
                    if (FileExist(ErrorLogger.logFile . ".old")) {
                        FileDelete(ErrorLogger.logFile . ".old")
                    }
                    FileMove(ErrorLogger.logFile, ErrorLogger.logFile . ".old")
                }
            }
            
            ; Format timestamp
            timestamp := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
            
            ; Write log entry
            logEntry := timestamp . " [" . level . "] " . message . "`n"
            FileAppend(logEntry, ErrorLogger.logFile)
            
        } catch Error as e {
            ; If logging fails, just continue - don't crash the app
        }
    }
    
    ; Clear log file
    static ClearLog() {
        try {
            if (FileExist(ErrorLogger.logFile)) {
                FileDelete(ErrorLogger.logFile)
            }
            ErrorLogger.Log("INFO", "Log file cleared")
        } catch {
            ; Ignore errors when clearing log
        }
    }
    
    ; Get recent log entries
    static GetRecentEntries(lineCount := 50) {
        if (!FileExist(ErrorLogger.logFile)) {
            return "No log file found."
        }
        
        try {
            content := FileRead(ErrorLogger.logFile)
            lines := StrSplit(content, "`n")
            
            ; Get last N lines
            result := ""
            startIndex := Max(1, lines.Length - lineCount)
            for i in Range(startIndex, lines.Length) {
                if (lines[i] != "") {
                    result .= lines[i] . "`n"
                }
            }
            
            return result
        } catch {
            return "Error reading log file."
        }
    }
}

; Helper function to get range
Range(start, end) {
    arr := []
    loop (end - start + 1) {
        arr.Push(start + A_Index - 1)
    }
    return arr
}