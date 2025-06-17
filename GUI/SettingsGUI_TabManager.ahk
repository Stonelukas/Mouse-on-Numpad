#Requires AutoHotkey v2.0

; ######################################################################################################################
; Settings Tab Manager - Manages tab modules and coordination
; ######################################################################################################################

class SettingsTabManager {
    __New(gui) {
        this.gui := gui
        this.tabModules := Map()
        this.tabControl := ""
    }
    
    CreateTabControl(options, tabNames) {
        this.tabControl := this.gui.Add("Tab3", options, tabNames)
        return this.tabControl
    }
    
    RegisterModule(tabName, moduleClass) {
        ; Create instance of the module
        module := moduleClass(this.gui, this.tabControl, tabName, SettingsGUI.tempSettings, SettingsGUI.controls)
        this.tabModules[tabName] := module
        return module
    }
    
    ValidateAll() {
        for tabName, module in this.tabModules {
            if (!module.Validate()) {
                ; Switch to the tab with validation error
                this.ShowTab(tabName)
                return false
            }
        }
        return true
    }
    
    GetAllData() {
        allData := Map()
        for tabName, module in this.tabModules {
            allData[tabName] := module.GetData()
        }
        return allData
    }
    
    ShowTab(tabName) {
        ; Find tab index by name
        tabIndex := 1
        for name in ["Movement", "Positions", "Visuals", "Hotkeys", "Advanced", "Profiles", "About"] {
            if (name = tabName) {
                this.tabControl.Value := tabIndex
                break
            }
            tabIndex++
        }
    }
}

; ######################################################################################################################
; Base Tab Module - Foundation for all tab modules
; ######################################################################################################################

class BaseTabModule {
    __New(gui, tabControl, tabName, tempSettings, globalControls) {
        this.gui := gui
        this.tabControl := tabControl
        this.tabName := tabName
        this.tempSettings := tempSettings
        this.globalControls := globalControls
        this.controls := Map()
        this.tabIndex := this._FindTabIndex()
        this.Initialize()
    }
    
    _FindTabIndex() {
        ; Find the index of this tab
        tabNames := ["Movement", "Positions", "Visuals", "Hotkeys", "Advanced", "Profiles", "About"]
        for index, name in tabNames {
            if (name = this.tabName) {
                return index
            }
        }
        return 1
    }
    
    Initialize() {
        ; Set the tab context
        this.tabControl.UseTab(this.tabIndex)
        
        ; Create controls (override in derived classes)
        this.CreateControls()
        
        ; Exit tab context
        this.tabControl.UseTab()
    }
    
    CreateControls() {
        ; Override in derived classes
    }
    
    GetData() {
        ; Override in derived classes to return tab-specific data
        return Map()
    }
    
    Validate() {
        ; Override in derived classes for validation
        return true
    }
    
    Refresh() {
        ; Override in derived classes if refresh is needed
    }
    
    ; Helper method to add controls to both local and global maps
    AddControl(name, control) {
        this.controls[name] := control
        this.globalControls[name] := control
        return control
    }
}