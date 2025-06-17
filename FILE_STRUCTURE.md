# 📁 Mouse on Numpad Enhanced - Modular File Structure

## 🏗️ Project Organization

The project has been reorganized following best practices for modular AutoHotkey v2 applications:

```
📂 MouseNumpad/
├── 🎯 Main.ahk                    # Main entry point
├── ⚙️ Config.ahk                  # Configuration management
├── 🔄 StateManager.ahk            # Global state management
├── 🖥️ MonitorUtils.ahk            # Monitor detection & positioning
├── 💬 TooltipSystem.ahk           # Tooltip display system
├── 📊 StatusIndicator.ahk         # Status bar management
├── 🖱️ MouseActions.ahk            # Mouse movement & actions
├── 💾 PositionMemory.ahk          # Save/load positions
├── ⌨️ HotkeyManager.ahk           # All hotkey definitions
│
├── 📁 GUI/                        # GUI modules folder
│   ├── 🎨 SettingsGUI_Base.ahk    # Base Settings GUI framework
│   ├── 📋 SettingsGUI_TabManager.ahk  # Tab management system
│   │
│   └── 📁 Tabs/                   # Individual tab modules
│       ├── 🏃 MovementTabModule.ahk   # Movement settings tab
│       ├── 📍 PositionsTabModule.ahk  # Position memory tab
│       ├── 🎨 VisualsTabModule.ahk   # Visual settings tab
│       ├── ⌨️ HotkeysTabModule.ahk    # Hotkey configuration tab
│       ├── ⚡ AdvancedTabModule.ahk   # Advanced settings tab
│       ├── 👤 ProfilesTabModule.ahk   # Profile management tab
│       └── ℹ️ AboutTabModule.ahk      # About information tab
│
├── 📁 Data/                       # Data files (created at runtime)
│   ├── MouseNumpadConfig.ini      # Main configuration file
│   ├── MouseNumpad.log           # Debug log file
│   └── 📁 Backups/               # Configuration backups
│
└── 📁 Docs/                      # Documentation
    ├── README.md                 # Main documentation
    ├── FILE_STRUCTURE.md         # This file
    └── SETTINGS_GUIDE.md         # Settings documentation
```

## 🔧 Module Descriptions

### Core Modules

#### 🎯 **Main.ahk**
- Application entry point
- Initializes all systems
- Manages application lifecycle
- Sets up coordinate modes for proper monitor handling

#### ⚙️ **Config.ahk**
- Centralized configuration management
- INI file loading/saving
- Default values and validation
- Settings persistence

#### 🔄 **StateManager.ahk**
- Global application state
- Mode management (mouse, save, load, inverted)
- Button state tracking
- Script reload functionality

#### 🖥️ **MonitorUtils.ahk**
- Multi-monitor support with negative coordinates
- Monitor detection and caching
- Fullscreen detection
- GUI positioning calculations
- Expression evaluation for dynamic positioning

#### 💬 **TooltipSystem.ahk**
- Dual tooltip system (standard + mouse actions)
- Duration management
- Visual feedback for all actions
- Fullscreen awareness

#### 📊 **StatusIndicator.ahk**
- Real-time status display
- Mode indicators
- Button state visualization
- Temporary message system

#### 🖱️ **MouseActions.ahk**
- Mouse movement with acceleration
- Diagonal movement support
- Scroll wheel functionality
- Movement history and undo system

#### 💾 **PositionMemory.ahk**
- Position saving/loading
- INI file persistence
- Position validation
- Import/export functionality

#### ⌨️ **HotkeyManager.ahk**
- All hotkey definitions
- Context-sensitive hotkeys
- Mode-specific key handling

### GUI Modules

#### 🎨 **SettingsGUI_Base.ahk**
- Main settings window framework
- Window management and resizing
- Bottom button bar
- Tab registration system
- Settings application logic

#### 📋 **SettingsGUI_TabManager.ahk**
- Tab coordination system
- Base tab module class
- Validation framework
- Data collection from all tabs

### Tab Modules

Each tab module extends `BaseTabModule` and implements:
- `CreateControls()` - GUI control creation
- `GetData()` - Retrieve tab data
- `Validate()` - Input validation
- `Refresh()` - Update display

#### 🏃 **MovementTabModule.ahk**
- Movement speed and acceleration
- Scroll settings
- Movement mode configuration
- Real-time preview system

#### 📍 **PositionsTabModule.ahk**
- Position list management
- Import/export positions
- Monitor testing
- Backup/restore functionality
- Real-time position capture

#### 🎨 **VisualsTabModule.ahk**
- Status and tooltip positioning
- Audio feedback settings
- Color theme selection
- Position testing tools

#### ⌨️ **HotkeysTabModule.ahk**
- Hotkey list display
- Conflict detection
- Hotkey testing
- Future: custom hotkey assignment

#### ⚡ **AdvancedTabModule.ahk**
- Performance settings
- Logging configuration
- Experimental features
- Reset options

#### 👤 **ProfilesTabModule.ahk**
- Profile management
- Auto-switch rules
- Import/export profiles
- Profile descriptions

#### ℹ️ **AboutTabModule.ahk**
- Version information
- System diagnostics
- Update checking
- Issue reporting

## 🚀 Benefits of Modular Structure

### 1. **Maintainability**
- Each module has a single, clear responsibility
- Easy to locate and modify specific features
- Reduced code complexity per file
- Clear separation of concerns

### 2. **Scalability**
- Easy to add new tab modules
- Simple to extend existing functionality
- Clean plugin architecture
- Minimal interdependencies

### 3. **Performance**
- Lazy loading of tab content
- Efficient resource management
- Reduced memory footprint
- Faster startup times

### 4. **Development**
- Multiple developers can work simultaneously
- Easier testing of individual components
- Clear API boundaries
- Better version control

### 5. **Customization**
- Users can disable unwanted modules
- Easy to create custom tabs
- Configuration is centralized
- Theme support ready

## 🔄 Module Communication

The modules communicate through:

1. **Event System**: `EventBus` for loose coupling (future implementation)
2. **State Manager**: Centralized state access
3. **Configuration**: Shared configuration system
4. **Direct Calls**: For tightly coupled operations

## 📝 Adding New Features

To add a new tab to the settings:

1. Create `NewTabModule.ahk` in `GUI/Tabs/`
2. Extend `BaseTabModule` class
3. Implement required methods
4. Add to tab list in `SettingsGUI_Base.ahk`
5. Register in `_RegisterTabModules()`
6. Include in `Main.ahk`

Example:
```autohotkey
class NewTabModule extends BaseTabModule {
    CreateControls() {
        ; Add your controls here
    }
    
    GetData() {
        ; Return tab data
    }
    
    Validate() {
        ; Validate input
        return true
    }
}
```

## 🛠️ Development Guidelines

1. **File Naming**: Use PascalCase for class files
2. **Module Independence**: Minimize cross-module dependencies
3. **Error Handling**: Each module handles its own errors
4. **Documentation**: Comment public methods and complex logic
5. **Testing**: Test modules independently when possible

## 🔍 Debugging

- Check `MouseNumpad.log` for errors
- Use `Ctrl+Alt+D` for debug mode
- Monitor `A_LastError` for system errors
- Use message boxes for quick debugging
- Check module initialization order

This modular structure makes the Mouse on Numpad Enhanced application more maintainable, scalable, and easier to enhance with new features!
