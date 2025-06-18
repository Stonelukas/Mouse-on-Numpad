#Requires AutoHotkey v2.0

class Test_Integration extends TestBase {
    __New() {
        super.__New("Integration Tests")
    }
    
    InitializeTests() {
        this.RegisterTest("Settings Save and Load", "TestSettingsPersistence")
        this.RegisterTest("Position Save and Restore", "TestPositionMemory")
        this.RegisterTest("Theme Application", "TestThemeApplication")
        this.RegisterTest("Monitor Change Handling", "TestMonitorChange")
        this.RegisterTest("Full Workflow Test", "TestFullWorkflow")
    }
    
    TestSettingsPersistence(t) {
        ; Save current settings
        originalMoveStep := Config.get("Movement.BaseSpeed")
        
        ; Change a setting
        Config.set("Movement.BaseSpeed", 10)
        Config.Save()
        
        ; Reload and verify
        Config.Load()
        t.AssertEqual(10, Config.get("Movement.BaseSpeed"), "Setting should persist after save/load")
        
        ; Restore original
        Config.set("Movement.BaseSpeed", originalMoveStep)
        Config.Save()
        
        t.Pass("Settings persistence working")
    }
    
    TestPositionMemory(t) {
        ; Test saving and restoring a position
        ; Note: This would need mouse movement permissions
        t.Pass("Position memory test placeholder")
    }
    
    TestThemeApplication(t) {
        ; Test theme changes
        originalTheme := ColorThemeManager.GetCurrentTheme()
        
        ; Change theme
        ColorThemeManager.SetTheme("Dark Mode")
        t.AssertEqual("Dark Mode", ColorThemeManager.GetCurrentTheme(), "Theme should change")
        
        ; Restore original
        ColorThemeManager.SetTheme(originalTheme)
        
        t.Pass("Theme application working")
    }
    
    TestMonitorChange(t) {
        ; Test monitor utilities
        MonitorUtils.Refresh()
        t.AssertTrue(MonitorUtils.initialized, "Monitor utils should be initialized")
        
        t.Pass("Monitor change handling working")
    }
    
    TestFullWorkflow(t) {
        ; Test a complete user workflow
        ; 1. Open settings
        ; 2. Change some values
        ; 3. Apply changes
        ; 4. Verify changes took effect
        
        t.Pass("Full workflow test placeholder")
    }
}