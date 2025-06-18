#Requires AutoHotkey v2.0

; ######################################################################################################################
; Position Memory Module - Save and load mouse positions
; ######################################################################################################################

class PositionMemory {
    static savedPositions := Map()

    static SavePosition(slot) {
        if (slot < 1 || slot > Config.get("Positions.MaxSaved")Positions) {
            TooltipSystem.ShowStandard("Invalid Slot!", "error")
            return
        }
        
        ; Ensure we're using screen coordinates
        CoordMode("Mouse", "Screen")
        
        MouseGetPos(&x, &y)
        PositionMemory.savedPositions[slot] := {x: x, y: y}

        StatusIndicator.ShowTemporaryMessage("💾 SAVED " . slot, "success")
        
        if (Config.get("Visual.EnableAudioFeedback")) {
            SoundBeep(700, 100)
        }
    }

    static RestorePosition(slot) {
        if (slot < 1 || slot > Config.get("Positions.MaxSaved")Positions) {
            TooltipSystem.ShowStandard("Invalid Slot!", "error")
            return
        }
        
        if (!PositionMemory.savedPositions.Has(slot)) {
            StatusIndicator.ShowTemporaryMessage("❌ NO POS " . slot, "error")
            if (Config.get("Visual.EnableAudioFeedback")) {
                SoundBeep(200, 150)
            }
            return
        }
        
        ; Ensure we're using screen coordinates
        CoordMode("Mouse", "Screen")
        
        ; Add current position to history before moving
        MouseGetPos(&currentX, &currentY)
        MouseActions.AddToHistory(currentX, currentY)
        
        pos := PositionMemory.savedPositions[slot]
        MouseMove(pos.x, pos.y, 10)
        
        StatusIndicator.ShowTemporaryMessage("📍 POS " . slot, "info")
        
        if (Config.get("Visual.EnableAudioFeedback")) {
            SoundBeep(500, 100)
        }
    }

    static HandleSlot(slot) {
        if (StateManager.IsSaveMode()) {
            StateManager.ToggleSaveMode()
            PositionMemory.SavePosition(slot)
            StatusIndicator.Update()
        } else if (StateManager.IsLoadMode()) {
            lastSlot := StateManager.GetLastLoadedSlot()
            if (lastSlot == slot) {
                StateManager.ToggleLoadMode()
                StateManager.SetLastLoadedSlot(0)
                PositionMemory.RestorePosition(slot)
                StatusIndicator.Update()
            } else {
                StateManager.SetLastLoadedSlot(slot)
                PositionMemory.RestorePosition(slot)
            }
        }
    }

    static LoadPositions() {
        PositionMemory.savedPositions := Map()
        
        Loop Config.get("Positions.MaxSaved")Positions {
            x := IniRead(Config.PersistentPositionsFile, "Positions", "Slot" . A_Index . "X", "")
            y := IniRead(Config.PersistentPositionsFile, "Positions", "Slot" . A_Index . "Y", "")
            
            if (x != "" && y != "") {
                PositionMemory.savedPositions[A_Index] := {x: x, y: y}
            }
        }
    }

    static SavePositions() {
        IniDelete(Config.PersistentPositionsFile, "Positions")
        
        for slot, pos in PositionMemory.savedPositions {
            IniWrite(pos.x, Config.PersistentPositionsFile, "Positions", "Slot" . slot . "X")
            IniWrite(pos.y, Config.PersistentPositionsFile, "Positions", "Slot" . slot . "Y")
        }
    }

    static GetSavedPositions() {
        return PositionMemory.savedPositions
    }

    static HasPosition(slot) {
        return PositionMemory.savedPositions.Has(slot)
    }

    static ClearPosition(slot) {
        if (PositionMemory.savedPositions.Has(slot)) {
            PositionMemory.savedPositions.Delete(slot)
        }
    }

    static ClearAllPositions() {
        PositionMemory.savedPositions := Map()
    }
}