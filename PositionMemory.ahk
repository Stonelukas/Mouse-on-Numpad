#Requires AutoHotkey v2.0

; ######################################################################################################################
; Position Memory - Save and load mouse positions
; ######################################################################################################################

class PositionMemory {
    ; Save position to slot
    static SavePosition(slot) {
        ; Get current mouse position
        MouseGetPos(&x, &y)
        
        ; Save to INI file
        IniWrite(x, Config.PersistentPositionsFile, "Position" . slot, "X")
        IniWrite(y, Config.PersistentPositionsFile, "Position" . slot, "Y")
        IniWrite(A_Now, Config.PersistentPositionsFile, "Position" . slot, "SavedAt")
        
        ; Get monitor info
        monIndex := MonitorUtils.GetMonitorAtPoint(x, y)
        IniWrite(monIndex, Config.PersistentPositionsFile, "Position" . slot, "Monitor")
        
        ; Show feedback
        TooltipSystem.ShowMouseAction("💾 Position " . slot . " saved!`nX: " . x . ", Y: " . y, 2000)
        
        ; Log event
        if (Config.EnableAnalytics) {
            AnalyticsSystem.LogEvent("position_save", {
                slot: slot,
                x: x,
                y: y,
                monitor: monIndex
            })
        }
        
        ; Audio feedback
        if (Config.EnableAudioFeedback) {
            SoundBeep(1000, 100)
        }
    }
    
    ; Load position from slot
    static LoadPosition(slot) {
        ; Read position from INI
        x := IniRead(Config.PersistentPositionsFile, "Position" . slot, "X", "")
        y := IniRead(Config.PersistentPositionsFile, "Position" . slot, "Y", "")
        
        if (x = "" || y = "") {
            TooltipSystem.ShowTemporary("❌ Position " . slot . " not saved", "error")
            return
        }
        
        ; Convert to numbers
        x := Integer(x)
        y := Integer(y)
        
        ; Save current position for undo
        MouseGetPos(&currentX, &currentY)
        State.AddToHistory(currentX, currentY)
        
        ; Check if position is on screen
        monIndex := MonitorUtils.GetMonitorAtPoint(x, y)
        if (monIndex == 0) {
            ; Position is off-screen, constrain to nearest monitor
            pos := MonitorUtils.GetSafePosition(x, y)
            x := pos.x
            y := pos.y
            TooltipSystem.ShowTemporary("⚠️ Position adjusted to stay on screen", "warning", 1500)
        }
        
        ; Move to position
        MouseMove(x, y, 0)
        
        ; Show feedback
        TooltipSystem.ShowMouseAction("📂 Position " . slot . " loaded!`nX: " . x . ", Y: " . y, 2000)
        
        ; Log event
        if (Config.EnableAnalytics) {
            AnalyticsSystem.LogEvent("position_load", {
                slot: slot,
                x: x,
                y: y
            })
        }
        
        ; Audio feedback
        if (Config.EnableAudioFeedback) {
            SoundBeep(800, 100)
        }
    }
    
    ; Clear position slot
    static ClearPosition(slot) {
        ; Delete from INI
        IniDelete(Config.PersistentPositionsFile, "Position" . slot)
        
        ; Show feedback
        TooltipSystem.ShowTemporary("🗑️ Position " . slot . " cleared", "info")
    }
    
    ; Clear all positions
    static ClearAllPositions() {
        loop Config.MaxSavedPositions {
            IniDelete(Config.PersistentPositionsFile, "Position" . A_Index)
        }
        
        TooltipSystem.ShowTemporary("🗑️ All positions cleared", "info")
    }
    
    ; Get position info
    static GetPositionInfo(slot) {
        x := IniRead(Config.PersistentPositionsFile, "Position" . slot, "X", "")
        y := IniRead(Config.PersistentPositionsFile, "Position" . slot, "Y", "")
        savedAt := IniRead(Config.PersistentPositionsFile, "Position" . slot, "SavedAt", "")
        monitor := IniRead(Config.PersistentPositionsFile, "Position" . slot, "Monitor", "")
        
        if (x = "" || y = "") {
            return ""
        }
        
        return {
            x: Integer(x),
            y: Integer(y),
            savedAt: savedAt,
            monitor: monitor != "" ? Integer(monitor) : 0
        }
    }
    
    ; Export positions
    static ExportPositions(filename) {
        try {
            ; Create export data
            exportData := "; Mouse on Numpad - Exported Positions`n"
            exportData .= "; Exported: " . A_Now . "`n`n"
            
            ; Add all saved positions
            loop Config.MaxSavedPositions {
                info := PositionMemory.GetPositionInfo(A_Index)
                if (info != "") {
                    exportData .= "[Position" . A_Index . "]`n"
                    exportData .= "X=" . info.x . "`n"
                    exportData .= "Y=" . info.y . "`n"
                    exportData .= "SavedAt=" . info.savedAt . "`n"
                    exportData .= "Monitor=" . info.monitor . "`n`n"
                }
            }
            
            ; Save to file
            FileAppend(exportData, filename)
            
            TooltipSystem.ShowTemporary("✅ Positions exported successfully", "success")
            
        } catch Error as e {
            TooltipSystem.ShowTemporary("❌ Export failed: " . e.Message, "error")
        }
    }
    
    ; Import positions
    static ImportPositions(filename) {
        try {
            if (!FileExist(filename)) {
                throw Error("File not found")
            }
            
            ; Read file content
            content := FileRead(filename)
            
            ; Parse and import positions
            ; (Simple implementation - could be improved)
            loop Config.MaxSavedPositions {
                section := "Position" . A_Index
                x := IniRead(filename, section, "X", "")
                y := IniRead(filename, section, "Y", "")
                
                if (x != "" && y != "") {
                    IniWrite(x, Config.PersistentPositionsFile, section, "X")
                    IniWrite(y, Config.PersistentPositionsFile, section, "Y")
                    
                    savedAt := IniRead(filename, section, "SavedAt", A_Now)
                    monitor := IniRead(filename, section, "Monitor", "0")
                    
                    IniWrite(savedAt, Config.PersistentPositionsFile, section, "SavedAt")
                    IniWrite(monitor, Config.PersistentPositionsFile, section, "Monitor")
                }
            }
            
            TooltipSystem.ShowTemporary("✅ Positions imported successfully", "success")
            
        } catch Error as e {
            TooltipSystem.ShowTemporary("❌ Import failed: " . e.Message, "error")
        }
    }
}