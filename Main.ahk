#Requires AutoHotkey v2.0
#SingleInstance Force

; ######################################################################################################################
; MOUSE ON NUMPAD ENHANCED - Main Entry Point
; ######################################################################################################################
; This script allows you to control your mouse using the numpad keys
; Version: 3.0.0 - Modular Architecture with Enhanced Features
; ######################################################################################################################

; Initialize application metadata
A_ScriptName := "Mouse on Numpad Enhanced"
global APP_VERSION := "3.0.0"
global APP_AUTHOR := "Enhanced by Claude AI Assistant"

; ======================================================================================================================
; CORE MODULE INCLUDES
; ======================================================================================================================

; Configuration Management
#Include Config.ahk              ; Core configuration and settings
; #Include EnhancedConfig.ahk    ; Advanced configuration features (merged into Config.ahk)

; State Management
#Include StateManager.ahk        ; Global state management

; System Utilities
#Include MonitorUtils.ahk        ; Monitor detection and positioning
#Include PerformanceMonitor.ahk  ; Performance tracking

; UI Components
#Include TooltipSystem.ahk       ; Tooltip display system
#Include StatusIndicator.ahk     ; Status bar management

; Settings GUI Components
#Include GUI\SettingsGUI.ahk          ; Main settings GUI class
#Include GUI\SettingsTabs.ahk         ; Tab creation methods
#Include GUI\SettingsHelper.ahk       ; Helper methods and previews
#Include GUI\SettingsListPopulators.ahk  ; List population methods
#Include GUI\SettingsActionHandlers.ahk   ; Action button handlers
#Include GUI\SettingsDarkMode.ahk     ; Dark mode implementation

; Core Functionality
#Include MouseActions.ahk        ; Mouse movement and actions
#Include PositionMemory.ahk      ; Position save/load system

; Analytics and Cloud
#Include AnalyticsSystem.ahk     ; Usage analytics
#Include CloudSyncManager.ahk    ; Cloud synchronization

; Hotkey Definitions (loaded last)
#Include HotkeyManager.ahk       ; All hotkey definitions

; ======================================================================================================================
; INITIALIZATION
; ======================================================================================================================

; Initialize configuration first
Config.Init()

; Set up tray menu
A_TrayMenu.Delete()  ; Remove default items
A_TrayMenu.Add("&Settings", (*) => SettingsGUI.Show())
A_TrayMenu.Add("&Toggle Script", (*) => State.ToggleMouseMode())
A_TrayMenu.Add()  ; Separator
A_TrayMenu.Add("&Performance Monitor", (*) => PerformanceMonitor.ShowStats())
A_TrayMenu.Add("&Analytics Report", (*) => AnalyticsSystem.ShowReport())
A_TrayMenu.Add()  ; Separator
A_TrayMenu.Add("&Reload Script", (*) => Reload())
A_TrayMenu.Add("E&xit", (*) => ExitScript())

; Set tray icon and tip
TraySetIcon("Shell32.dll", 45)  ; Mouse icon
A_IconTip := A_ScriptName . " v" . APP_VERSION . "`nCtrl+Alt+T to toggle"

; ======================================================================================================================
; STARTUP SEQUENCE
; ======================================================================================================================

; Initialize enhanced features if enabled
if (Config.EnableAnalytics) {
    AnalyticsSystem.Init()
}

if (Config.EnableCloudSync) {
    CloudSyncManager.Init()
}

; Initialize UI components
StatusIndicator.Init()
TooltipSystem.Init()

; Initialize performance monitoring
PerformanceMonitor.Init()

; Start with disabled state
State.mouseMode := false
StatusIndicator.Update()

; Show welcome message
if (Config.ShowWelcomeOnStartup) {
    ShowWelcomeMessage()
}

; Log startup
if (Config.EnableLogging) {
    AnalyticsSystem.LogEvent("startup", {
        version: APP_VERSION,
        monitors: MonitorGetCount(),
        resolution: A_ScreenWidth . "x" . A_ScreenHeight
    })
}

; ======================================================================================================================
; WELCOME MESSAGE
; ======================================================================================================================

ShowWelcomeMessage() {
    welcomeText := A_ScriptName . " v" . APP_VERSION . " Started!`n`n"
    welcomeText .= "🎯 Quick Start Guide:`n"
    welcomeText .= "• Ctrl+Alt+T: Toggle mouse control`n"
    welcomeText .= "• Numpad keys: Move mouse`n"
    welcomeText .= "• Numpad 5: Left click`n"
    welcomeText .= "• Numpad .: Right click`n"
    welcomeText .= "• Ctrl+Alt+Shift+S: Open settings`n`n"
    welcomeText .= "📌 New Features:`n"
    welcomeText .= "• Enhanced settings interface`n"
    welcomeText .= "• Performance monitoring`n"
    welcomeText .= "• Usage analytics`n"
    welcomeText .= "• Cloud synchronization`n"
    welcomeText .= "• Multiple configuration profiles"
    
    ; Create a styled welcome GUI
    welcomeGui := Gui("+AlwaysOnTop -MaximizeBox -MinimizeBox", "Welcome!")
    welcomeGui.MarginX := 20
    welcomeGui.MarginY := 15
    welcomeGui.BackColor := "White"
    
    ; Add icon and title
    welcomeGui.SetFont("s14 Bold", "Segoe UI")
    welcomeGui.Add("Text", "Center w400", "🖱️ " . A_ScriptName)
    
    welcomeGui.SetFont("s10 Normal", "Segoe UI")
    welcomeGui.Add("Text", "w400 h300", welcomeText)
    
    ; Add checkbox for startup preference
    dontShowAgain := welcomeGui.Add("CheckBox", "w400", "Don't show this message on startup")
    
    ; Add buttons
    settingsBtn := welcomeGui.Add("Button", "w120", "&Open Settings")
    settingsBtn.OnEvent("Click", (*) => (welcomeGui.Destroy(), SettingsGUI.Show()))
    
    okBtn := welcomeGui.Add("Button", "x+10 w120 Default", "&OK")
    okBtn.OnEvent("Click", (*) => CloseWelcome())
    
    CloseWelcome() {
        if (dontShowAgain.Value) {
            Config.ShowWelcomeOnStartup := false
            Config.Save()
        }
        welcomeGui.Destroy()
    }
    
    ; Show centered
    welcomeGui.Show("w450")
}

; ======================================================================================================================
; EXIT HANDLER
; ======================================================================================================================

ExitScript() {
    ; Log shutdown
    if (Config.EnableLogging) {
        AnalyticsSystem.LogEvent("shutdown", {
            sessionDuration: A_TickCount,
            totalMoves: State.moveCount
        })
    }
    
    ; Save any pending analytics
    if (Config.EnableAnalytics) {
        AnalyticsSystem.SaveSession()
    }
    
    ; Sync to cloud if enabled
    if (Config.EnableCloudSync && CloudSyncManager.IsConnected()) {
        CloudSyncManager.SyncNow()
    }
    
    ; Clean up UI components
    StatusIndicator.Destroy()
    TooltipSystem.CleanUp()
    
    ; Exit
    ExitApp()
}

; ======================================================================================================================
; SCRIPT COMPLETE
; ======================================================================================================================