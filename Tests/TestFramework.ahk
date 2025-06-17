#Requires AutoHotkey v2.0

; ======================================================================================================================
; Base Test Class - All test suites should extend this
; ======================================================================================================================

class TestBase {
    ; Test properties
    testName := ""
    tests := []
    results := Map()
    currentTest := ""
    startTime := 0
    endTime := 0
    
    ; Statistics
    passCount := 0
    failCount := 0
    errorCount := 0
    skipCount := 0
    
    ; Constructor
    __New(name := "") {
        this.testName := name
        this.InitializeTests()
    }
    
    ; Override this to register tests
    InitializeTests() {
        ; To be implemented by child classes
    }
    
    ; Register a test
    RegisterTest(name, method) {
        this.tests.Push({
            name: name,
            method: method,
            result: "",
            message: "",
            duration: 0
        })
    }
    
    ; Run all tests in the suite
    Run() {
        this.startTime := A_TickCount
        this.ResetCounters()
        
        ; Run setup if exists
        if (HasMethod(this, "Setup")) {
            try {
                this.Setup()
            } catch Error as e {
                this.LogError("Setup failed: " . e.Message)
                return this.GetResults()
            }
        }
        
        ; Run each test
        for test in this.tests {
            this.currentTest := test.name
            testStart := A_TickCount
            
            ; Check if we should skip this test
            if (HasMethod(this, "ShouldSkip") && this.ShouldSkip(test.name)) {
                this.SkipTest(test.name, "Test skipped by condition")
                continue
            }
            
            try {
                ; Run test setup if exists
                if (HasMethod(this, "TestSetup")) {
                    this.TestSetup()
                }
                
                ; Run the test - FIXED FOR V2
                testMethod := test.method
                if (Type(testMethod) = "String") {
                    ; If method is a string, call it as a method of this object
                    ; Use ObjBindMethod to create a bound method and call it
                    boundMethod := ObjBindMethod(this, testMethod)
                    boundMethod.Call(this)
                } else {
                    ; If it's already a function reference, just call it
                    testMethod(this)
                }
                
                ; If we get here without error, test passed
                if (test.result = "") {
                    test.result := "PASS"
                    test.message := "Test completed successfully"
                    this.passCount++
                }
                
            } catch TestFailure as failure {
                test.result := "FAIL"
                test.message := failure.Message
                this.failCount++
                
            } catch Error as e {
                test.result := "ERROR"
                test.message := e.Message
                this.errorCount++
            }
            
            finally {
                ; Run test teardown if exists
                if (HasMethod(this, "TestTeardown")) {
                    try {
                        this.TestTeardown()
                    } catch {
                        ; Ignore teardown errors
                    }
                }
                
                test.duration := A_TickCount - testStart
            }
        }
        
        ; Run teardown if exists
        if (HasMethod(this, "Teardown")) {
            try {
                this.Teardown()
            } catch {
                ; Ignore teardown errors
            }
        }
        
        this.endTime := A_TickCount
        return this.GetResults()
    }
    
    ; Reset counters
    ResetCounters() {
        this.passCount := 0
        this.failCount := 0
        this.errorCount := 0
        this.skipCount := 0
    }
    
    ; Get test results
    GetResults() {
        results := Map()
        results["name"] := this.testName
        results["passed"] := this.passCount
        results["failed"] := this.failCount
        results["errors"] := this.errorCount
        results["skipped"] := this.skipCount
        results["total"] := this.tests.Length
        results["duration"] := this.endTime - this.startTime
        results["tests"] := this.tests
        
        return results
    }
    
    ; Get test count
    GetTestCount() {
        return this.tests.Length
    }
    
    ; Get completed test count
    GetCompletedCount() {
        count := 0
        for test in this.tests {
            if (test.result != "") {
                count++
            }
        }
        return count
    }
    
    ; ======================================================================================================================
    ; Assertion Methods
    ; ======================================================================================================================
    
    ; Assert that a condition is true
    AssertTrue(condition, message := "") {
        if (!condition) {
            throw TestFailure(message != "" ? message : "Expected true, got false")
        }
    }
    
    ; Assert that a condition is false
    AssertFalse(condition, message := "") {
        if (condition) {
            throw TestFailure(message != "" ? message : "Expected false, got true")
        }
    }
    
    ; Assert that two values are equal
    AssertEqual(expected, actual, message := "") {
        if (expected != actual) {
            msg := message != "" ? message : "Expected: " . expected . ", Actual: " . actual
            throw TestFailure(msg)
        }
    }
    
    ; Assert that two values are not equal
    AssertNotEqual(expected, actual, message := "") {
        if (expected = actual) {
            msg := message != "" ? message : "Expected values to be different, but both were: " . actual
            throw TestFailure(msg)
        }
    }
    
    ; Assert that a value is greater than another
    AssertGreaterThan(value, threshold, message := "") {
        if (value <= threshold) {
            msg := message != "" ? message : value . " is not greater than " . threshold
            throw TestFailure(msg)
        }
    }
    
    ; Assert that a value is less than another
    AssertLessThan(value, threshold, message := "") {
        if (value >= threshold) {
            msg := message != "" ? message : value . " is not less than " . threshold
            throw TestFailure(msg)
        }
    }
    
    ; Assert that a string contains a substring
    AssertContains(haystack, needle, message := "") {
        if (!InStr(haystack, needle)) {
            msg := message != "" ? message : "'" . haystack . "' does not contain '" . needle . "'"
            throw TestFailure(msg)
        }
    }
    
    ; Assert that a GUI element exists
    AssertGuiElementExists(element, message := "") {
        if (!element || element = "") {
            msg := message != "" ? message : "GUI element does not exist"
            throw TestFailure(msg)
        }
    }
    
    ; Assert that a window exists
    AssertWindowExists(title, message := "") {
        if (!WinExist(title)) {
            msg := message != "" ? message : "Window '" . title . "' does not exist"
            throw TestFailure(msg)
        }
    }
    
    ; ======================================================================================================================
    ; Helper Methods
    ; ======================================================================================================================
    
    ; Mark current test as passed with message
    Pass(message := "") {
        for test in this.tests {
            if (test.name = this.currentTest) {
                test.result := "PASS"
                test.message := message != "" ? message : "Test passed"
                this.passCount++
                break
            }
        }
    }
    
    ; Mark current test as failed
    Fail(message) {
        throw TestFailure(message)
    }
    
    ; Skip a test
    SkipTest(testName, reason := "") {
        for test in this.tests {
            if (test.name = testName) {
                test.result := "SKIP"
                test.message := reason != "" ? reason : "Test skipped"
                this.skipCount++
                break
            }
        }
    }
    
    ; Log an error
    LogError(message) {
        ; Could be extended to write to a log file
        OutputDebug("ERROR in " . this.testName . ": " . message)
    }
    
    ; Wait for a condition with timeout
    WaitForCondition(conditionFunc, timeoutMs := 5000, checkInterval := 100) {
        startTime := A_TickCount
        
        while (A_TickCount - startTime < timeoutMs) {
            if (conditionFunc()) {
                return true
            }
            Sleep(checkInterval)
        }
        
        return false
    }
    
    ; Simulate user input with delay
    SimulateInput(keys, delay := 100) {
        Send(keys)
        Sleep(delay)
    }
    
    ; Take a screenshot for test evidence
    TakeScreenshot(testName := "") {
        if (testName = "") {
            testName := this.currentTest
        }
        
        ; Create screenshots directory if needed
        screenshotDir := "Results\Screenshots"
        if (!DirExist(screenshotDir)) {
            DirCreate(screenshotDir)
        }
        
        ; Generate filename
        timestamp := FormatTime(A_Now, "yyyyMMdd_HHmmss")
        filename := screenshotDir . "\" . testName . "_" . timestamp . ".png"
        
        ; Take screenshot (requires additional screenshot library)
        ; This is a placeholder - implement actual screenshot functionality
        return filename
    }
}

; ======================================================================================================================
; Custom Exception for Test Failures
; ======================================================================================================================

class TestFailure extends Error {
    __New(message) {
        super.__New(message)
    }
}

; ======================================================================================================================
; Test Reporter Class
; ======================================================================================================================

class TestReporter {
    ; Generate a detailed test report
    static GenerateDetailedReport(results) {
        report := "╔══════════════════════════════════════════════════════════════╗`n"
        report .= "║                    TEST EXECUTION REPORT                      ║`n"
        report .= "╚══════════════════════════════════════════════════════════════╝`n`n"
        
        report .= "Generated: " . FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") . "`n"
        report .= "Test Framework Version: 1.0.0`n`n"
        
        ; Overall summary
        totalPass := 0
        totalFail := 0
        totalError := 0
        totalSkip := 0
        totalDuration := 0
        
        for suiteName, suiteResults in results {
            totalPass += suiteResults.Get("passed", 0)
            totalFail += suiteResults.Get("failed", 0)
            totalError += suiteResults.Get("errors", 0)
            totalSkip += suiteResults.Get("skipped", 0)
            totalDuration += suiteResults.Get("duration", 0)
        }
        
        report .= "═══════════════════════════════════════════════════════════════`n"
        report .= "OVERALL SUMMARY`n"
        report .= "═══════════════════════════════════════════════════════════════`n"
        report .= "Total Test Suites: " . results.Count . "`n"
        report .= "Total Tests: " . (totalPass + totalFail + totalError + totalSkip) . "`n"
        report .= "✅ Passed: " . totalPass . "`n"
        report .= "❌ Failed: " . totalFail . "`n"
        report .= "⚠️ Errors: " . totalError . "`n"
        if (totalSkip > 0) {
            report .= "⏭️ Skipped: " . totalSkip . "`n"
        }
        report .= "Total Duration: " . TestReporter.FormatDuration(totalDuration) . "`n`n"
        
        ; Detailed results for each suite
        for suiteName, suiteResults in results {
            report .= "═══════════════════════════════════════════════════════════════`n"
            report .= "TEST SUITE: " . suiteName . "`n"
            report .= "═══════════════════════════════════════════════════════════════`n"
            
            report .= "Duration: " . TestReporter.FormatDuration(suiteResults.Get("duration", 0)) . "`n"
            report .= "Tests Run: " . suiteResults.Get("total", 0) . "`n`n"
            
            ; Individual test results
            if (suiteResults.Has("tests")) {
                for test in suiteResults["tests"] {
                    icon := TestReporter.GetResultIcon(test.result)
                    report .= icon . " " . test.name . "`n"
                    report .= "   Result: " . test.result . "`n"
                    if (test.message != "") {
                        report .= "   Message: " . test.message . "`n"
                    }
                    report .= "   Duration: " . test.duration . "ms`n`n"
                }
            }
        }
        
        return report
    }
    
    ; Format duration in human-readable format
    static FormatDuration(ms) {
        if (ms < 1000) {
            return ms . "ms"
        } else if (ms < 60000) {
            return Round(ms / 1000, 2) . "s"
        } else {
            minutes := ms // 60000
            seconds := Mod(ms, 60000) / 1000
            return minutes . "m " . Round(seconds, 1) . "s"
        }
    }
    
    ; Get icon for test result
    static GetResultIcon(result) {
        switch result {
            case "PASS": return "✅"
            case "FAIL": return "❌"
            case "ERROR": return "⚠️"
            case "SKIP": return "⏭️"
            default: return "❓"
        }
    }
}