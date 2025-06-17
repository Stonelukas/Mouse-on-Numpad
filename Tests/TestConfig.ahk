; ######################################################################################################################
; FILE: Tests/TestConfig.ahk - Test Configuration Settings
; ######################################################################################################################

#Requires AutoHotkey v2.0

; ======================================================================================================================
; Test Configuration Class
; ======================================================================================================================

class TestConfig {
    ; Test execution settings
    static DefaultTimeout := 5000        ; Default timeout for operations (ms)
    static CheckInterval := 100          ; Default interval for condition checks (ms)
    static DelayBetweenTests := 200      ; Delay between individual tests (ms)
    static DelayBetweenSuites := 500     ; Delay between test suites (ms)
    
    ; GUI interaction settings
    static GuiLoadDelay := 500           ; Time to wait for GUIs to load (ms)
    static ButtonClickDelay := 200       ; Delay after button clicks (ms)
    static InputDelay := 50              ; Delay between keystrokes (ms)
    static DialogWaitTime := 1500        ; Time to wait for dialogs (ms)
    
    ; Screenshot settings
    static TakeScreenshotsOnFail := true ; Take screenshots when tests fail
    static ScreenshotFormat := "png"     ; Screenshot file format
    static ScreenshotQuality := 100      ; Screenshot quality (1-100)
    
    ; Logging settings
    static EnableDebugLogging := true    ; Enable detailed debug logs
    static LogToFile := true             ; Write logs to file
    static LogFileName := "test_debug.log"
    static MaxLogFileSize := 10485760    ; 10MB max log file size
    
    ; Report settings
    static GenerateHTMLReport := false   ; Generate HTML reports (future feature)
    static GenerateJSONReport := false   ; Generate JSON reports (future feature)
    static AutoOpenReport := true        ; Automatically open report after tests
    
    ; Test categories to run
    static RunCategories := Map(
        "GUI", true,
        "Core", true,
        "Integration", true,
        "Performance", false,    ; Disabled by default
        "Stress", false         ; Disabled by default
    )
    
    ; Environment settings
    static TestEnvironment := "Development"  ; Development, Staging, Production
    static MockExternalServices := true      ; Mock external dependencies
    
    ; Get configuration value
    static Get(key, defaultValue := "") {
        if (TestConfig.HasOwnProp(key)) {
            return TestConfig.%key%
        }
        return defaultValue
    }
    
    ; Set configuration value
    static Set(key, value) {
        if (TestConfig.HasOwnProp(key)) {
            TestConfig.%key% := value
            return true
        }
        return false
    }
    
    ; Load configuration from INI file
    static LoadFromFile(filename := "test_config.ini") {
        if (!FileExist(filename)) {
            return false
        }
        
        ; Read execution settings
        TestConfig.DefaultTimeout := IniRead(filename, "Execution", "DefaultTimeout", TestConfig.DefaultTimeout)
        TestConfig.CheckInterval := IniRead(filename, "Execution", "CheckInterval", TestConfig.CheckInterval)
        TestConfig.DelayBetweenTests := IniRead(filename, "Execution", "DelayBetweenTests", TestConfig.DelayBetweenTests)
        TestConfig.DelayBetweenSuites := IniRead(filename, "Execution", "DelayBetweenSuites", TestConfig.DelayBetweenSuites)
        
        ; Read GUI settings
        TestConfig.GuiLoadDelay := IniRead(filename, "GUI", "GuiLoadDelay", TestConfig.GuiLoadDelay)
        TestConfig.ButtonClickDelay := IniRead(filename, "GUI", "ButtonClickDelay", TestConfig.ButtonClickDelay)
        TestConfig.InputDelay := IniRead(filename, "GUI", "InputDelay", TestConfig.InputDelay)
        TestConfig.DialogWaitTime := IniRead(filename, "GUI", "DialogWaitTime", TestConfig.DialogWaitTime)
        
        ; Read screenshot settings
        TestConfig.TakeScreenshotsOnFail := IniRead(filename, "Screenshots", "TakeOnFail", TestConfig.TakeScreenshotsOnFail)
        TestConfig.ScreenshotFormat := IniRead(filename, "Screenshots", "Format", TestConfig.ScreenshotFormat)
        TestConfig.ScreenshotQuality := IniRead(filename, "Screenshots", "Quality", TestConfig.ScreenshotQuality)
        
        ; Read logging settings
        TestConfig.EnableDebugLogging := IniRead(filename, "Logging", "EnableDebug", TestConfig.EnableDebugLogging)
        TestConfig.LogToFile := IniRead(filename, "Logging", "LogToFile", TestConfig.LogToFile)
        TestConfig.LogFileName := IniRead(filename, "Logging", "FileName", TestConfig.LogFileName)
        
        return true
    }
    
    ; Save configuration to INI file
    static SaveToFile(filename := "test_config.ini") {
        ; Write execution settings
        IniWrite(TestConfig.DefaultTimeout, filename, "Execution", "DefaultTimeout")
        IniWrite(TestConfig.CheckInterval, filename, "Execution", "CheckInterval")
        IniWrite(TestConfig.DelayBetweenTests, filename, "Execution", "DelayBetweenTests")
        IniWrite(TestConfig.DelayBetweenSuites, filename, "Execution", "DelayBetweenSuites")
        
        ; Write GUI settings
        IniWrite(TestConfig.GuiLoadDelay, filename, "GUI", "GuiLoadDelay")
        IniWrite(TestConfig.ButtonClickDelay, filename, "GUI", "ButtonClickDelay")
        IniWrite(TestConfig.InputDelay, filename, "GUI", "InputDelay")
        IniWrite(TestConfig.DialogWaitTime, filename, "GUI", "DialogWaitTime")
        
        ; Write screenshot settings
        IniWrite(TestConfig.TakeScreenshotsOnFail, filename, "Screenshots", "TakeOnFail")
        IniWrite(TestConfig.ScreenshotFormat, filename, "Screenshots", "Format")
        IniWrite(TestConfig.ScreenshotQuality, filename, "Screenshots", "Quality")
        
        ; Write logging settings
        IniWrite(TestConfig.EnableDebugLogging, filename, "Logging", "EnableDebug")
        IniWrite(TestConfig.LogToFile, filename, "Logging", "LogToFile")
        IniWrite(TestConfig.LogFileName, filename, "Logging", "FileName")
        
        return true
    }
}

; ======================================================================================================================
; Test Logger Class
; ======================================================================================================================

class TestLogger {
    static logFile := ""
    static isInitialized := false
    
    ; Initialize logger
    static Initialize() {
        if (TestConfig.LogToFile && !TestLogger.isInitialized) {
            TestLogger.logFile := FileOpen(TestConfig.LogFileName, "a")
            TestLogger.isInitialized := true
            TestLogger.Log("Test Logger Initialized", "INFO")
        }
    }
    
    ; Log a message
    static Log(message, level := "INFO") {
        timestamp := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
        logEntry := timestamp . " [" . level . "] " . message
        
        ; Output to debug console
        if (TestConfig.EnableDebugLogging) {
            OutputDebug(logEntry)
        }
        
        ; Write to file
        if (TestConfig.LogToFile && TestLogger.logFile) {
            TestLogger.logFile.WriteLine(logEntry)
            TestLogger.logFile.Read(0)  ; Flush
        }
    }
    
    ; Log debug message
    static Debug(message) {
        if (TestConfig.EnableDebugLogging) {
            TestLogger.Log(message, "DEBUG")
        }
    }
    
    ; Log info message
    static Info(message) {
        TestLogger.Log(message, "INFO")
    }
    
    ; Log warning message
    static Warn(message) {
        TestLogger.Log(message, "WARN")
    }
    
    ; Log error message
    static Error(message) {
        TestLogger.Log(message, "ERROR")
    }
    
    ; Close logger
    static Close() {
        if (TestLogger.logFile) {
            TestLogger.logFile.Close()
            TestLogger.isInitialized := false
        }
    }
}

; Initialize logger on load
TestLogger.Initialize()

; ======================================================================================================================
; Test Utilities
; ======================================================================================================================

class TestUtils {
    ; Generate unique test ID
    static GenerateTestId() {
        return FormatTime(A_Now, "yyyyMMddHHmmss") . "_" . Random(1000, 9999)
    }
    
    ; Clean test data
    static CleanTestData(pattern := "test_*") {
        ; Clean up temporary test files
        Loop Files, pattern {
            try {
                FileDelete(A_LoopFileFullPath)
            } catch {
                ; Ignore errors
            }
        }
    }
    
    ; Create test data directory
    static CreateTestDataDir() {
        testDataDir := "TestData"
        if (!DirExist(testDataDir)) {
            DirCreate(testDataDir)
        }
        return testDataDir
    }
    
    ; Wait for GUI to be ready
    static WaitForGui(title, timeout := "") {
        if (timeout = "") {
            timeout := TestConfig.GuiLoadDelay
        }
        
        if (WinWait(title, , timeout / 1000)) {
            Sleep(100)  ; Extra time for GUI to be fully ready
            return true
        }
        return false
    }
    
    ; Close all test windows
    static CloseAllTestWindows() {
        ; Close settings GUI if open
        if (WinExist("Mouse on Numpad Enhanced - Settings")) {
            WinClose()
        }
        
        ; Close any test dialogs
        windows := ["Test Hotkey", "Edit Hotkey", "Reset Hotkey", "No Selection", "Scan Complete"]
        for window in windows {
            if (WinExist(window)) {
                WinClose()
            }
        }
    }
    
    ; Capture window for evidence
    static CaptureWindow(windowTitle, filename := "") {
        if (filename = "") {
            filename := "capture_" . TestUtils.GenerateTestId() . ".png"
        }
        
        if (WinExist(windowTitle)) {
            ; This would need a screenshot library implementation
            ; Placeholder for now
            return filename
        }
        return ""
    }
}