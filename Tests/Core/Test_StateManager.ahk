#Requires AutoHotkey v2.0

class Test_StateManager extends TestBase {
    __New() {
        super.__New("State Manager Tests")
    }
    
    InitializeTests() {
        this.RegisterTest("Initial State", "TestInitialState")
        this.RegisterTest("Toggle Mouse Mode", "TestToggleMouseMode")
        this.RegisterTest("Toggle Save Mode", "TestToggleSaveMode")
        this.RegisterTest("Toggle Load Mode", "TestToggleLoadMode")
        this.RegisterTest("Mode Exclusivity", "TestModeExclusivity")
        this.RegisterTest("Button State Management", "TestButtonStates")
    }
    
    Setup() {
        ; Save current state
        this.savedMouseMode := StateManager.IsMouseMode()
        this.savedSaveMode := StateManager.IsSaveMode()
        this.savedLoadMode := StateManager.IsLoadMode()
        
        ; Reset to known state
        StateManager._mouseMode := false
        StateManager._saveMode := false
        StateManager._loadMode := false
    }
    
    Teardown() {
        ; Restore original state
        StateManager._mouseMode := this.savedMouseMode
        StateManager._saveMode := this.savedSaveMode
        StateManager._loadMode := this.savedLoadMode
    }
    
    TestInitialState(t) {
        t.AssertFalse(StateManager.IsMouseMode(), "Mouse mode should be off initially")
        t.AssertFalse(StateManager.IsSaveMode(), "Save mode should be off initially")
        t.AssertFalse(StateManager.IsLoadMode(), "Load mode should be off initially")
        t.Pass("Initial state verified")
    }
    
    TestToggleMouseMode(t) {
        ; Test toggling on
        StateManager.ToggleMouseMode()
        t.AssertTrue(StateManager.IsMouseMode(), "Mouse mode should be on after toggle")
        
        ; Test toggling off
        StateManager.ToggleMouseMode()
        t.AssertFalse(StateManager.IsMouseMode(), "Mouse mode should be off after second toggle")
        
        t.Pass("Mouse mode toggle working correctly")
    }
    
    TestToggleSaveMode(t) {
        ; Enable save mode
        StateManager.ToggleSaveMode()
        t.AssertTrue(StateManager.IsSaveMode(), "Save mode should be on")
        t.AssertFalse(StateManager.IsLoadMode(), "Load mode should be off when save mode is on")
        
        t.Pass("Save mode toggle working correctly")
    }
    
    TestToggleLoadMode(t) {
        ; Enable load mode
        StateManager.ToggleLoadMode()
        t.AssertTrue(StateManager.IsLoadMode(), "Load mode should be on")
        t.AssertFalse(StateManager.IsSaveMode(), "Save mode should be off when load mode is on")
        
        t.Pass("Load mode toggle working correctly")
    }
    
    TestModeExclusivity(t) {
        ; Enable save mode
        StateManager._saveMode := true
        StateManager._loadMode := false
        
        ; Toggle load mode - should disable save mode
        StateManager.ToggleLoadMode()
        t.AssertTrue(StateManager.IsLoadMode(), "Load mode should be on")
        t.AssertFalse(StateManager.IsSaveMode(), "Save mode should be off")
        
        ; Toggle save mode - should disable load mode
        StateManager.ToggleSaveMode()
        t.AssertTrue(StateManager.IsSaveMode(), "Save mode should be on")
        t.AssertFalse(StateManager.IsLoadMode(), "Load mode should be off")
        
        t.Pass("Mode exclusivity maintained")
    }
    
    TestButtonStates(t) {
        ; Test left button state
        StateManager.SetLeftButtonHeld(true)
        t.AssertTrue(StateManager.IsLeftButtonHeld(), "Left button should be held")
        
        StateManager.SetLeftButtonHeld(false)
        t.AssertFalse(StateManager.IsLeftButtonHeld(), "Left button should not be held")
        
        ; Test right button state
        StateManager.SetRightButtonHeld(true)
        t.AssertTrue(StateManager.IsRightButtonHeld(), "Right button should be held")
        
        StateManager.SetRightButtonHeld(false)
        t.AssertFalse(StateManager.IsRightButtonHeld(), "Right button should not be held")
        
        t.Pass("Button states working correctly")
    }
}