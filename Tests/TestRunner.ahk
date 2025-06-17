; ######################################################################################################################
; Test Suite Structure for Mouse on Numpad Enhanced
; ######################################################################################################################
;
; FOLDER STRUCTURE:
; 📂 MouseNumpad/
; ├── Main.ahk
; ├── Config.ahk
; ├── ... (other modules)
; │
; └── 📁 Tests/
;     ├── TestRunner.ahk              # Main test runner (this file)
;     ├── TestFramework.ahk           # Base test class and utilities
;     ├── TestConfig.ahk              # Test configuration
;     │
;     ├── 📁 GUI/                     # GUI-related tests
;     │   ├── Test_HotkeysTab.ahk     # Hotkeys tab tests
;     │   ├── Test_MovementTab.ahk    # Movement tab tests (future)
;     │   ├── Test_PositionsTab.ahk   # Positions tab tests (future)
;     │   ├── Test_VisualsTab.ahk     # Visuals tab tests (future)
;     │   └── Test_AllTabs.ahk        # Integration tests for all tabs
;     │
;     ├── 📁 Core/                    # Core functionality tests
;     │   ├── Test_StateManager.ahk   # State management tests (future)
;     │   ├── Test_MouseActions.ahk   # Mouse movement tests (future)
;     │   └── Test_Config.ahk         # Configuration tests (future)
;     │
;     └── 📁 Results/                 # Test results storage
;         └── (test result files)
;
; ######################################################################################################################

; ######################################################################################################################
; FILE: Tests/TestRunner.ahk - Main Test Runner
; ######################################################################################################################

#Requires AutoHotkey v2.0

; Include paths setup
#Include "..\Config.ahk"
#Include "..\StateManager.ahk"
#Include "..\MonitorUtils.ahk"
#Include "..\ColorThemeManager.ahk"
#Include "..\TooltipSystem.ahk"
#Include "..\StatusIndicator.ahk"
#Include "..\MouseActions.ahk"
#Include "..\PositionMemory.ahk"
#Include "..\HotkeyManager.ahk"

; Include Settings GUI modules
#Include "..\GUI\SettingsGUI_Base.ahk"
#Include "..\GUI\SettingsGUI_TabManager.ahk"

; Include Tab modules
#Include "..\GUI\Tabs\MovementTabModule.ahk"
#Include "..\GUI\Tabs\PositionsTabModule.ahk"
#Include "..\GUI\Tabs\VisualsTabModule.ahk"
#Include "..\GUI\Tabs\HotkeysTabModule.ahk"
#Include "..\GUI\Tabs\AdvancedTabModule.ahk"
#Include "..\GUI\Tabs\ProfilesTabModule.ahk"
#Include "..\GUI\Tabs\AboutTabModule.ahk"

; Include test framework
#Include "TestFramework.ahk"
#Include "TestConfig.ahk"

#Include "ArrayHelpers.ahk"
; Include test modules
#Include "GUI\Test_HotkeysTab.ahk"
; Future test includes:
#Include "GUI\Test_MovementTab.ahk"
#Include "GUI\Test_PositionsTab.ahk"
#Include "GUI\Test_HotkeysTab.ahk"
#Include "Core\Test_StateManager.ahk"
; #Include "GUI\Test_VisualsTab.ahk"
; #Include "GUI\Test_AllTabs.ahk"
; #Include "Core\Test_MouseActions.ahk"
; #Include "Core\Test_Config.ahk"

; ======================================================================================================================
; Test Runner Class
; ======================================================================================================================

class TestRunner {
    static testSuites := Map()
    static results := Map()
    static currentSuite := ""
    static isRunning := false
    static gui := ""
    
    ; Register test suites
    static RegisterSuite(name, testClass) {
        TestRunner.testSuites[name] := testClass
    }
    
    ; Initialize test environment
    static Initialize() {
        ; Initialize application components needed for testing
        Config.Load()
        StateManager.Initialize()
        ColorThemeManager.Initialize()
        MonitorUtils.Init()
        
        ; Register all test suites
        TestRunner.RegisterTestSuites()
        
        ; Create test results directory if it doesn't exist
        if (!DirExist("Results")) {
            DirCreate("Results")
        }
        
        ; Show test runner GUI
        TestRunner.ShowGUI()
    }
    
    ; Register all available test suites
    static RegisterTestSuites() {
        ; GUI Tests
        TestRunner.RegisterSuite("Hotkeys Tab", Test_HotkeysTab)
        
        ; Future test suites will be registered here:
        ; TestRunner.RegisterSuite("Movement Tab", Test_MovementTab)
        ; TestRunner.RegisterSuite("Positions Tab", Test_PositionsTab)
        ; TestRunner.RegisterSuite("Visuals Tab", Test_VisualsTab)
        ; TestRunner.RegisterSuite("State Manager", Test_StateManager)
        ; TestRunner.RegisterSuite("Mouse Actions", Test_MouseActions)
        ; TestRunner.RegisterSuite("Configuration", Test_Config)
    }
    
    ; Show main test runner GUI
    static ShowGUI() {
        TestRunner.gui := Gui("+Resize", "Mouse on Numpad - Test Suite Runner")
        TestRunner.gui.SetFont("s10")
        
        ; Title
        TestRunner.gui.Add("Text", "Section Center w600", "Test Suite Runner").SetFont("s14 Bold")
        TestRunner.gui.Add("Text", "xm y+5 w600 Center", "Select test suites to run").SetFont("s10")
        
        ; Test suite selection
        TestRunner.gui.Add("Text", "xm y+20 Section", "Available Test Suites:")
        
        ; Create checkboxes for each test suite
        TestRunner.checkboxes := Map()
        yPos := 80
        for suiteName, suiteClass in TestRunner.testSuites {
            cb := TestRunner.gui.Add("CheckBox", "xm y" . yPos . " w300 Checked", suiteName)
            TestRunner.checkboxes[suiteName] := cb
            
            ; Add test count
            if (HasMethod(suiteClass, "GetTestCount")) {
                count := suiteClass.GetTestCount()
                TestRunner.gui.Add("Text", "x+10 y" . yPos . " w100", "(" . count . " tests)")
            }
            
            yPos += 25
        }
        
        ; Control buttons
        TestRunner.gui.Add("Text", "xm y+30 w600 h1 +0x10")  ; Separator
        
        btnY := yPos + 40
        TestRunner.runSelectedBtn := TestRunner.gui.Add("Button", "xm y" . btnY . " w120 h30", "Run Selected")
        TestRunner.runAllBtn := TestRunner.gui.Add("Button", "x+10 w120 h30", "Run All Tests")
        TestRunner.stopBtn := TestRunner.gui.Add("Button", "x+10 w120 h30 Disabled", "Stop Tests")
        TestRunner.resultsBtn := TestRunner.gui.Add("Button", "x+10 w120 h30", "View Last Results")
        
        ; Progress section
        TestRunner.gui.Add("Text", "xm y+20 Section", "Progress:")
        TestRunner.progressBar := TestRunner.gui.Add("Progress", "xm y+5 w600 h20", 0)
        TestRunner.statusText := TestRunner.gui.Add("Text", "xm y+5 w600", "Ready to run tests...")
        
        ; Results summary
        TestRunner.gui.Add("Text", "xm y+20 w600 h1 +0x10")  ; Separator
        TestRunner.resultSummary := TestRunner.gui.Add("Text", "xm y+10 w600 h60", "No tests run yet.")
        
        ; Event handlers
        TestRunner.runSelectedBtn.OnEvent("Click", (*) => TestRunner.RunSelectedTests())
        TestRunner.runAllBtn.OnEvent("Click", (*) => TestRunner.RunAllTests())
        TestRunner.stopBtn.OnEvent("Click", (*) => TestRunner.StopTests())
        TestRunner.resultsBtn.OnEvent("Click", (*) => TestRunner.ShowLastResults())
        
        TestRunner.gui.OnEvent("Close", (*) => TestRunner.OnClose())
        
        ; Show GUI
        TestRunner.gui.Show()
    }
    
    ; Run selected test suites
    static RunSelectedTests() {
        selectedSuites := []
        
        for suiteName, checkbox in TestRunner.checkboxes {
            if (checkbox.Value) {
                selectedSuites.Push(suiteName)
            }
        }
        
        if (selectedSuites.Length = 0) {
            MsgBox("Please select at least one test suite to run.", "No Tests Selected", "Icon!")
            return
        }
        
        TestRunner.RunTests(selectedSuites)
    }
    
    ; Run all test suites
    static RunAllTests() {
        allSuites := []
        for suiteName, _ in TestRunner.testSuites {
            allSuites.Push(suiteName)
        }
        TestRunner.RunTests(allSuites)
    }
    
    ; Run specified test suites
    static RunTests(suiteNames) {
        TestRunner.isRunning := true
        TestRunner.results.Clear()
        
        ; Update UI
        TestRunner.runSelectedBtn.Enabled := false
        TestRunner.runAllBtn.Enabled := false
        TestRunner.stopBtn.Enabled := true
        TestRunner.progressBar.Value := 0
        
        totalTests := 0
        completedTests := 0
        
        ; Count total tests
        for suiteName in suiteNames {
            if (TestRunner.testSuites.Has(suiteName)) {
                suiteClass := TestRunner.testSuites[suiteName]
                if (HasMethod(suiteClass, "GetTestCount")) {
                    totalTests += suiteClass.GetTestCount()
                }
            }
        }
        
        ; Run each test suite
        for suiteName in suiteNames {
            if (!TestRunner.isRunning) {
                break
            }
            
            TestRunner.currentSuite := suiteName
            TestRunner.statusText.Text := "Running: " . suiteName . "..."
            
            if (TestRunner.testSuites.Has(suiteName)) {
                suiteClass := TestRunner.testSuites[suiteName]
                testInstance := suiteClass()
                
                ; Run the test suite
                suiteResults := testInstance.Run()
                TestRunner.results[suiteName] := suiteResults
                
                ; Update progress
                if (HasMethod(testInstance, "GetCompletedCount")) {
                    completedTests += testInstance.GetCompletedCount()
                }
                
                if (totalTests > 0) {
                    TestRunner.progressBar.Value := Round((completedTests / totalTests) * 100)
                }
            }
            
            Sleep(100)
        }
        
        ; Tests completed
        TestRunner.isRunning := false
        TestRunner.runSelectedBtn.Enabled := true
        TestRunner.runAllBtn.Enabled := true
        TestRunner.stopBtn.Enabled := false
        
        TestRunner.statusText.Text := "All tests completed!"
        TestRunner.ShowResultsSummary()
        
        ; Auto-save results
        TestRunner.SaveResults()
    }
    
    ; Stop running tests
    static StopTests() {
        TestRunner.isRunning := false
        TestRunner.statusText.Text := "Tests stopped by user."
    }
    
    ; Show results summary in main GUI
    static ShowResultsSummary() {
        totalPass := 0
        totalFail := 0
        totalError := 0
        totalSkip := 0
        
        summaryText := "===== TEST SUMMARY =====`n"
        
        for suiteName, suiteResults in TestRunner.results {
            pass := suiteResults.Get("passed", 0)
            fail := suiteResults.Get("failed", 0)
            error := suiteResults.Get("errors", 0)
            skip := suiteResults.Get("skipped", 0)
            
            totalPass += pass
            totalFail += fail
            totalError += error
            totalSkip += skip
            
            summaryText .= suiteName . ": "
            summaryText .= "✅ " . pass . " passed, "
            summaryText .= "❌ " . fail . " failed, "
            summaryText .= "⚠️ " . error . " errors"
            if (skip > 0) {
                summaryText .= ", ⏭️ " . skip . " skipped"
            }
            summaryText .= "`n"
        }
        
        summaryText .= "`nTotal: "
        summaryText .= "✅ " . totalPass . " | "
        summaryText .= "❌ " . totalFail . " | "
        summaryText .= "⚠️ " . totalError
        if (totalSkip > 0) {
            summaryText .= " | ⏭️ " . totalSkip
        }
        
        TestRunner.resultSummary.Text := summaryText
    }
    
    ; Show detailed results window
    static ShowLastResults() {
        if (TestRunner.results.Count = 0) {
            MsgBox("No test results available. Run some tests first!", "No Results", "Icon!")
            return
        }
        
        ; Create detailed results window
        resultGui := Gui("+Resize", "Test Results - Detailed Report")
        resultGui.SetFont("s10", "Consolas")
        
        ; Generate detailed report
        report := TestReporter.GenerateDetailedReport(TestRunner.results)
        
        ; Display report
        resultEdit := resultGui.Add("Edit", "w900 h600 +Multi +ReadOnly +VScroll +HScroll", report)
        
        ; Buttons
        copyBtn := resultGui.Add("Button", "w100", "Copy Report")
        copyBtn.OnEvent("Click", (*) => A_Clipboard := report)
        
        saveBtn := resultGui.Add("Button", "x+10 w100", "Save Report")
        saveBtn.OnEvent("Click", (*) => TestRunner.SaveResultsAs())
        
        closeBtn := resultGui.Add("Button", "x+10 w100", "Close")
        closeBtn.OnEvent("Click", (*) => resultGui.Destroy())
        
        resultGui.Show()
    }
    
    ; Save results automatically
    static SaveResults() {
        timestamp := FormatTime(A_Now, "yyyyMMdd_HHmmss")
        filename := "Results\TestResults_" . timestamp . ".txt"
        
        report := TestReporter.GenerateDetailedReport(TestRunner.results)
        
        try {
            FileAppend(report, filename)
        } catch {
            ; Silently fail auto-save
        }
    }
    
    ; Save results with dialog
    static SaveResultsAs() {
        timestamp := FormatTime(A_Now, "yyyyMMdd_HHmmss")
        defaultName := "TestResults_" . timestamp . ".txt"
        
        selectedFile := FileSelect("S", defaultName, "Save Test Results", "Text Files (*.txt)")
        
        if (selectedFile != "") {
            report := TestReporter.GenerateDetailedReport(TestRunner.results)
            try {
                FileAppend(report, selectedFile)
                MsgBox("Test results saved successfully!", "Success", "Iconi T3")
            } catch Error as e {
                MsgBox("Failed to save file: " . e.Message, "Error", "IconX")
            }
        }
    }
    
    ; Clean up on close
    static OnClose() {
        if (TestRunner.isRunning) {
            result := MsgBox("Tests are still running. Stop and exit?", "Confirm Exit", "YesNo Icon?")
            if (result = "Yes") {
                TestRunner.StopTests()
            } else {
                return false
            }
        }
        
        TestRunner.gui.Destroy()
        ExitApp()
    }
}

; ======================================================================================================================
; Start Test Runner
; ======================================================================================================================

; Initialize and show test runner
TestRunner.Initialize()

; Hotkeys for quick access
F1::TestRunner.ShowGUI()
F5::TestRunner.RunAllTests()
Escape::TestRunner.StopTests()