; ######################################################################################################################
; Hotkey Manager Module - Complete with all hold features and NumpadDot
; ######################################################################################################################

#Requires AutoHotkey v2.0

class HotkeyManager {
    static hotkeys := Map()
    static isInitialized := false
    
    ; Initialize all hotkeys
    static Initialize() {
        if (HotkeyManager.isInitialized) {
            return
        }
        
        ; Load hotkey configuration
        HotkeyManager.RegisterHotkeys()
        HotkeyManager.isInitialized := true
    }
    
    ; Register all hotkeys from config
    static RegisterHotkeys() {
        ; Clear existing hotkeys
        for key, info in HotkeyManager.hotkeys {
            if (info.currentKey != "" && info.currentKey != "None") {
                try {
                    Hotkey(info.currentKey, "Off")
                }
            }
        }
        HotkeyManager.hotkeys.Clear()
        
        ; Define all hotkeys with their handlers
        hotkeyDefs := Map(
            "ToggleMouseMode", {
                handler: ObjBindMethod(HotkeyManager, "ToggleMouseMode"),
                default: "NumpadAdd",
                description: "Toggle Mouse Mode"
            },
            "SaveMode", {
                handler: ObjBindMethod(HotkeyManager, "EnterSaveMode"),
                default: "NumpadMult",
                description: "Save Position Mode"
            },
            "LoadMode", {
                handler: ObjBindMethod(HotkeyManager, "EnterLoadMode"),
                default: "NumpadSub",
                description: "Load Position Mode"
            },
            "UndoMove", {
                handler: ObjBindMethod(HotkeyManager, "UndoLastMove"),
                default: "NumpadDiv",
                description: "Undo Last Move"
            },
            "ToggleStatus", {
                handler: ObjBindMethod(HotkeyManager, "ToggleStatusIndicator"),
                default: "^NumpadAdd",
                description: "Toggle Status"
            },
            "ReloadScript", {
                handler: ObjBindMethod(HotkeyManager, "ReloadApplication"),
                default: "^!r",
                description: "Reload Script"
            },
            "OpenSettings", {
                handler: ObjBindMethod(HotkeyManager, "ShowSettings"),
                default: "^!s",
                description: "Open Settings"
            },
            "SecondaryMonitor", {
                handler: ObjBindMethod(HotkeyManager, "ToggleSecondaryMonitor"),
                default: "!Numpad9",
                description: "Secondary Monitor"
            },
            "MonitorTest", {
                handler: ObjBindMethod(HotkeyManager, "TestMonitors"),
                default: "^!Numpad9",
                description: "Monitor Test"
            }
        )
        
        ; Movement hotkeys
        movementKeys := Map(
            "MoveLeft", {
                handler: (*) => MouseActions.MoveInDirection("Left"), 
                default: "Numpad4",
                description: "Move Left"
            },
            "MoveRight", {
                handler: (*) => MouseActions.MoveInDirection("Right"), 
                default: "Numpad6",
                description: "Move Right"
            },
            "MoveUp", {
                handler: (*) => MouseActions.MoveInDirection("Up"), 
                default: "Numpad8",
                description: "Move Up"
            },
            "MoveDown", {
                handler: (*) => MouseActions.MoveInDirection("Down"), 
                default: "Numpad2",
                description: "Move Down"
            },
            "MoveDiagNW", {
                handler: (*) => MouseActions.MoveInDirection("UpLeft"), 
                default: "Numpad8 + Numpad4",
                description: "Move Diagonal Up-Left"
            },
            "MoveDiagNE", {
                handler: (*) => MouseActions.MoveInDirection("UpRight"), 
                default: "Numpad8 + Numpad6",
                description: "Move Diagonal Up-Right"
            },
            "MoveDiagSW", {
                handler: (*) => MouseActions.MoveInDirection("DownLeft"), 
                default: "Nunpad4 + Numpad2",
                description: "Move Diagonal Down-Left"
            },
            "MoveDiagSE", {
                handler: (*) => MouseActions.MoveInDirection("DownRight"), 
                default: "Numpad6 + Numpad2",
                description: "Move Diagonal Down-Right"
            }
        )
        
        ; Click action hotkeys
        clickKeys := Map(
            "MouseClick", {
                handler: (*) => MouseActions.PerformClick(), 
                default: "Numpad5",
                description: "Left Click"
            },
            "RightClick", {
                handler: (*) => MouseActions.PerformClick("Right"), 
                default: "Numpad0",
                description: "Right Click"
            },
            "MiddleClick", {
                handler: (*) => MouseActions.PerformClick("Middle"), 
                default: "NumpadEnter",
                description: "Middle Click"
            }
        )
        
        ; Hold toggle hotkeys
        holdKeys := Map(
            "ToggleLeftHold", {
                handler: ObjBindMethod(HotkeyManager, "ToggleLeftButtonHold"),
                default: "NumpadClear",
                description: "Toggle Left Hold"
            },
            "ToggleRightHold", {
                handler: ObjBindMethod(HotkeyManager, "ToggleRightButtonHold"),
                default: "NumpadIns",
                description: "Toggle Right Hold"
            },
            "ToggleMiddleHold", {
                handler: ObjBindMethod(HotkeyManager, "ToggleMiddleButtonHold"),
                default: "+NumpadEnter",
                description: "Toggle Middle Hold"
            },
            "SpecialNumpadDot", {
                handler: ObjBindMethod(HotkeyManager, "NumpadDotSpecial"),
                default: "NumpadDot",
                description: "Inverted Mode + Right Hold"
            }
        )
        
        ; Scroll hotkeys
        scrollKeys := Map(
            "ScrollUp", {
                handler: (*) => MouseActions.ScrollWithAcceleration("Up", "Numpad7"),
                default: "Numpad7",
                description: "Scroll Up"
            },
            "ScrollDown", {
                handler: (*) => MouseActions.ScrollWithAcceleration("Down", "Numpad1"),
                default: "Numpad1",
                description: "Scroll Down"
            },
            "ScrollLeft", {
                handler: (*) => MouseActions.ScrollWithAcceleration("Left", "Numpad9"),
                default: "Numpad9",
                description: "Scroll Left"
            },
            "ScrollRight", {
                handler: (*) => MouseActions.ScrollWithAcceleration("Right", "Numpad3"),
                default: "Numpad3",
                description: "Scroll Right"
            }
        )
        
        ; Special mode hotkeys
        specialKeys := Map(
            "ToggleInverted", {
                handler: ObjBindMethod(HotkeyManager, "ToggleInvertedMode"),
                default: "!Numpad1",
                description: "Toggle Inverted Mode"
            }
        )
        
        ; Merge all hotkey definitions
        for key, info in movementKeys {
            hotkeyDefs[key] := info
        }
        for key, info in clickKeys {
            hotkeyDefs[key] := info
        }
        for key, info in holdKeys {
            hotkeyDefs[key] := info
        }
        for key, info in scrollKeys {
            hotkeyDefs[key] := info
        }
        for key, info in specialKeys {
            hotkeyDefs[key] := info
        }
        
        ; Register each hotkey
        for configKey, info in hotkeyDefs {
            ; Get the actual key from config or use default
            actualKey := Config.Get("Hotkeys." . configKey, info.default)
            
            if (actualKey != "" && actualKey != "None") {
                try {
                    ; Create the hotkey
                    Hotkey(actualKey, info.handler)
                    
                    ; Store in our map
                    HotkeyManager.hotkeys[configKey] := {
                        currentKey: actualKey,
                        handler: info.handler,
                        default: info.default,
                        description: info.description
                    }
                } catch as e {
                    ; Log error but continue
                    ToolTip("Failed to register hotkey " . actualKey . ": " . e.Message, , , 2)
                    SetTimer(() => ToolTip(, , , 2), -3000)
                }
            }
        }
        
        ; Set up conditional hotkeys for mouse mode
        HotkeyManager.UpdateMovementHotkeys()
    }
    
    ; Update movement hotkeys based on mouse mode state
    static UpdateMovementHotkeys() {
        ; Movement and click keys that only work in mouse mode
        conditionalKeys := ["MoveLeft", "MoveRight", "MoveUp", "MoveDown", 
                           "MoveDiagNW", "MoveDiagNE", "MoveDiagSW", "MoveDiagSE",
                           "MouseClick", "RightClick", "MiddleClick",
                           "ToggleLeftHold", "ToggleRightHold", "ToggleMiddleHold",
                           "ScrollUp", "ScrollDown", "ScrollLeft", "ScrollRight",
                           "SpecialNumpadDot", "ToggleInverted"]
        
        for key in conditionalKeys {
            if (HotkeyManager.hotkeys.Has(key)) {
                hotkeyInfo := HotkeyManager.hotkeys[key]
                if (hotkeyInfo.currentKey != "" && hotkeyInfo.currentKey != "None") {
                    try {
                        if (StateManager.isMouseModeActive) {
                            Hotkey(hotkeyInfo.currentKey, "On")
                        } else {
                            Hotkey(hotkeyInfo.currentKey, "Off")
                        }
                    }
                }
            }
        }
    }
    
    ; Update a single hotkey binding
    static UpdateHotkey(configKey, newKey) {
        ; Remove old hotkey if exists
        if (HotkeyManager.hotkeys.Has(configKey)) {
            oldInfo := HotkeyManager.hotkeys[configKey]
            if (oldInfo.currentKey != "" && oldInfo.currentKey != "None") {
                try {
                    Hotkey(oldInfo.currentKey, "Off")
                }
            }
            
            ; Set new hotkey
            if (newKey != "" && newKey != "None") {
                try {
                    Hotkey(newKey, oldInfo.handler)
                    oldInfo.currentKey := newKey
                } catch as e {
                    return false
                }
            }
        }
        
        return true
    }
    
    ; =====================================
    ; Hotkey Handler Methods
    ; =====================================
    
    static ToggleMouseMode(*) {
        StateManager.ToggleMouseMode()
        HotkeyManager.UpdateMovementHotkeys()
    }
    
    static EnterSaveMode(*) {
        if (StateManager.isMouseModeActive) {
            StateManager.SetMode("Save")
            TooltipSystem.Show("Save Mode: Press 0-9 to save current position", 2000)
        }
    }
    
    static EnterLoadMode(*) {
        if (StateManager.isMouseModeActive) {
            StateManager.SetMode("Load")
            TooltipSystem.Show("Load Mode: Press 0-9 to load saved position", 2000)
        }
    }
    
    static UndoLastMove(*) {
        if (StateManager.isMouseModeActive) {
            MouseActions.UndoLastMove()
        }
    }
    
    static ToggleStatusIndicator(*) {
        StatusIndicator.Toggle()
    }
    
    static ReloadApplication(*) {
        TooltipSystem.Show("Reloading application...", 1000)
        Sleep(1000)
        Reload()
    }
    
    static ShowSettings(*) {
        SettingsGUI.Show()
    }
    
    static ToggleSecondaryMonitor(*) {
        MonitorUtils.ToggleSecondaryMonitor()
    }
    
    static TestMonitors(*) {
        MonitorUtils.ShowMonitorTest()
    }
    
    ; Click hold toggle methods
    static ToggleLeftButtonHold(*) {
        if (StateManager.IsLeftButtonHeld()) {
            StateManager.SetLeftButtonHeld(false)
            Click("Left", , , , , "U")
            TooltipSystem.ShowMouseAction("🖱️ Left Released", "warning")
            
            if (Config.Get("Visual.AudioFeedback", false)) {
                SoundBeep(400, 100)
            }
        } else {
            StateManager.SetLeftButtonHeld(true)
            Click("Left", , , , , "D")
            TooltipSystem.ShowMouseAction("🖱️ Left Held", "success")
            
            if (Config.Get("Visual.AudioFeedback", false)) {
                SoundBeep(500, 100)
            }
        }
        
        Sleep(150)
        StatusIndicator.Update()
    }
    
    static ToggleRightButtonHold(*) {
        if (StateManager.IsRightButtonHeld()) {
            StateManager.SetRightButtonHeld(false)
            Click("Right", , , , , "U")
            TooltipSystem.ShowMouseAction("🖱️ Right Released", "warning")
            
            if (Config.Get("Visual.AudioFeedback", false)) {
                SoundBeep(400, 100)
            }
        } else {
            StateManager.SetRightButtonHeld(true)
            Click("Right", , , , , "D")
            TooltipSystem.ShowMouseAction("🖱️ Right Held", "success")
            
            if (Config.Get("Visual.AudioFeedback", false)) {
                SoundBeep(600, 100)
            }
        }
        
        Sleep(150)
        StatusIndicator.Update()
    }
    
    static ToggleMiddleButtonHold(*) {
        if (StateManager.IsMiddleButtonHeld()) {
            StateManager.SetMiddleButtonHeld(false)
            Click("Middle", , , , , "U")
            TooltipSystem.ShowMouseAction("🖱️ Middle Released", "warning")
            
            if (Config.Get("Visual.AudioFeedback", false)) {
                SoundBeep(350, 100)
            }
        } else {
            StateManager.SetMiddleButtonHeld(true)
            Click("Middle", , , , , "D")
            TooltipSystem.ShowMouseAction("🖱️ Middle Held", "success")
            
            if (Config.Get("Visual.AudioFeedback", false)) {
                SoundBeep(550, 100)
            }
        }
        
        Sleep(150)
        StatusIndicator.Update()
    }
    
    ; Special NumpadDot functionality
    static NumpadDotSpecial(*) {
        wasInvertedMode := StateManager.IsInvertedMode()
        wasRightHeld := StateManager.IsRightButtonHeld()
        
        if (wasInvertedMode && wasRightHeld) {
            StateManager.ToggleInvertedMode()
            StateManager.SetRightButtonHeld(false)
            Click("Right", , , , , "U")
            TooltipSystem.ShowMouseAction("🔄🖱️ Both Off", "warning")
            Sleep(150)
            StatusIndicator.Update()
        } else if (wasInvertedMode && !wasRightHeld) {
            StateManager.SetRightButtonHeld(true)
            Click("Right", , , , , "D")
            TooltipSystem.ShowMouseAction("🖱️ Right Added", "success")
            Sleep(150)
            StatusIndicator.Update()
        } else if (!wasInvertedMode && wasRightHeld) {
            StateManager.ToggleInvertedMode()
            TooltipSystem.ShowMouseAction("🔄 Inverted Added", "success")
            Sleep(150)
            StatusIndicator.Update()
        } else {
            StateManager.ToggleInvertedMode()
            Sleep(100)
            StateManager.SetRightButtonHeld(true)
            Click("Right", , , , , "D")
            TooltipSystem.ShowMouseAction("🔄🖱️ Both On", "success")
            Sleep(150)
            StatusIndicator.Update()
        }
    }
    
    ; Toggle inverted mode
    static ToggleInvertedMode(*) {
        wasInvertedMode := StateManager.IsInvertedMode()
        
        if (wasInvertedMode) {
            StateManager.ToggleInvertedMode()
            TooltipSystem.ShowMouseAction("🔄 Inverted Off", "warning")
            Sleep(150)
            StatusIndicator.Update()
        } else {
            StateManager.ToggleInvertedMode()
            TooltipSystem.ShowMouseAction("🔄 Inverted On", "success")
            Sleep(150)
            StatusIndicator.Update()
        }
    }
    
    ; Get all registered hotkeys for display
    static GetHotkeyList() {
        list := []
        
        ; Create a proper order for display
        orderedKeys := [
            "ToggleMouseMode", "SaveMode", "LoadMode", "UndoMove",
            "ToggleStatus", "ReloadScript", "OpenSettings",
            "SecondaryMonitor", "MonitorTest",
            "MoveLeft", "MoveRight", "MoveUp", "MoveDown",
            "MoveDiagNW", "MoveDiagNE", "MoveDiagSW", "MoveDiagSE",
            "MouseClick", "RightClick", "MiddleClick",
            "ToggleLeftHold", "ToggleRightHold", "ToggleMiddleHold",
            "ScrollUp", "ScrollDown", "ScrollLeft", "ScrollRight",
            "SpecialNumpadDot", "ToggleInverted"
        ]
        
        for configKey in orderedKeys {
            if (HotkeyManager.hotkeys.Has(configKey)) {
                info := HotkeyManager.hotkeys[configKey]
                list.Push({
                    configKey: configKey,
                    description: info.description,
                    currentKey: info.currentKey,
                    default: info.default
                })
            }
        }
        
        return list
    }
}