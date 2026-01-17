# Linux Port Plan: Mouse on Numpad Enhanced

## Executive Summary

This document outlines a comprehensive plan to port **Mouse on Numpad Enhanced** from Windows (AutoHotkey v2.0) to Linux. The application transforms the numpad into a dedicated mouse control interface with features including mouse movement, clicking, scrolling, position memory, and a full settings GUI.

**Current State**: Windows-only AutoHotkey application (~170+ Windows API calls, ~600+ lines affected)
**Target**: Native Linux application supporting X11 and Wayland display servers

---

## Table of Contents

1. [Technology Selection](#1-technology-selection)
2. [Architecture Design](#2-architecture-design)
3. [Phase-by-Phase Implementation](#3-phase-by-phase-implementation)
4. [Module Migration Guide](#4-module-migration-guide)
5. [Testing Strategy](#5-testing-strategy)
6. [Deployment & Packaging](#6-deployment--packaging)
7. [Risk Assessment](#7-risk-assessment)

---

## 1. Technology Selection

### 1.1 Primary Language: Python 3.10+

**Rationale:**
- Excellent library ecosystem for input control (pynput, python-xlib, evdev)
- Strong GUI framework options (GTK, Qt, Tkinter)
- Rapid development cycle similar to AutoHotkey
- Large community and extensive documentation
- Cross-platform potential for future macOS port

**Alternative Considered:** Rust
- Pros: Performance, safety, native binaries
- Cons: Longer development time, steeper learning curve
- Decision: Use Python for v1, consider Rust rewrite for v2 if performance issues arise

### 1.2 Input Control Layer

| Feature | X11 Solution | Wayland Solution |
|---------|--------------|------------------|
| Mouse Movement | `python-xlib` or `pynput` | `python-evdev` with uinput |
| Mouse Clicks | `python-xlib` or `pynput` | `python-evdev` with uinput |
| Scroll Wheel | `python-xlib` or `pynput` | `python-evdev` with uinput |
| Hotkey Capture | `python-xlib` XGrabKey | `libinput` + compositor protocol |
| Mouse Position | `python-xlib` XQueryPointer | Compositor-specific (limited) |

**Recommended Approach:**
```
Primary:   pynput (cross-platform, handles X11 automatically)
Fallback:  python-evdev (direct kernel input, works on Wayland)
```

### 1.3 GUI Framework: GTK 4 with PyGObject

**Rationale:**
- Native look and feel on GNOME, well-integrated on other DEs
- Modern async capabilities
- Excellent theme support (matches our color theme system)
- Better Wayland support than alternatives

**Alternative:** Qt 6 with PySide6
- Pros: True cross-platform, polished look
- Cons: Larger dependency footprint, licensing considerations
- Decision: Start with GTK 4, abstract GUI layer for potential Qt backend later

### 1.4 Configuration Storage

| Aspect | Windows (Current) | Linux (Proposed) |
|--------|-------------------|------------------|
| Format | INI files | JSON (human-readable, structured) |
| Location | Script directory | `~/.config/mouse-on-numpad/` (XDG compliant) |
| Files | `MouseNumpadConfig.ini`, `positions.dat` | `config.json`, `positions.json` |

### 1.5 Audio Feedback

- **Primary:** PulseAudio via `pulsectl` library
- **Fallback:** ALSA via `simpleaudio` or system `paplay` command
- Generate tones programmatically to match Windows `SoundBeep()` behavior

### 1.6 System Integration

| Feature | Implementation |
|---------|---------------|
| Autostart | XDG autostart desktop entry |
| Background daemon | systemd user service |
| System tray | AppIndicator3 (GTK) |
| Notifications | libnotify via `notify2` |

---

## 2. Architecture Design

### 2.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        User Interface Layer                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │ Settings GUI │  │ System Tray  │  │ Status Indicator     │   │
│  │   (GTK 4)    │  │ (AppIndicator)│  │ (Floating Window)   │   │
│  └──────────────┘  └──────────────┘  └──────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Application Core Layer                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │   Config    │  │   State     │  │   Position Memory       │  │
│  │  Manager    │  │  Manager    │  │   (9 slots)             │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │   Theme     │  │   Error     │  │   Profile Manager       │  │
│  │  Manager    │  │  Logger     │  │                         │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Platform Abstraction Layer                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    InputController                        │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐   │   │
│  │  │   Mouse     │  │   Hotkey    │  │   Monitor       │   │   │
│  │  │ Controller  │  │  Listener   │  │   Manager       │   │   │
│  │  └─────────────┘  └─────────────┘  └─────────────────┘   │   │
│  └──────────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    AudioController                        │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Backend Layer                             │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐     │
│  │  X11 Backend   │  │ Wayland Backend│  │  evdev Backend │     │
│  │  (python-xlib) │  │ (compositor)   │  │  (fallback)    │     │
│  └────────────────┘  └────────────────┘  └────────────────┘     │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 Directory Structure

```
mouse-on-numpad-linux/
├── src/
│   ├── __init__.py
│   ├── main.py                      # Entry point
│   │
│   ├── core/                        # Application Core Layer
│   │   ├── __init__.py
│   │   ├── config.py                # Configuration management (JSON)
│   │   ├── state_manager.py         # Global application state
│   │   ├── position_memory.py       # Save/load position slots
│   │   ├── theme_manager.py         # Color themes
│   │   ├── profile_manager.py       # User profiles
│   │   └── error_logger.py          # Logging system
│   │
│   ├── input/                       # Platform Abstraction Layer
│   │   ├── __init__.py
│   │   ├── mouse_controller.py      # Mouse movement/clicks
│   │   ├── hotkey_manager.py        # Hotkey registration
│   │   ├── monitor_manager.py       # Multi-monitor support
│   │   └── audio_manager.py         # Sound feedback
│   │
│   ├── backends/                    # Backend Layer
│   │   ├── __init__.py
│   │   ├── x11_backend.py           # X11 implementation
│   │   ├── wayland_backend.py       # Wayland implementation
│   │   └── evdev_backend.py         # Direct input fallback
│   │
│   └── ui/                          # User Interface Layer
│       ├── __init__.py
│       ├── app.py                   # GTK Application class
│       ├── main_window.py           # Settings window
│       ├── status_indicator.py      # Floating status bar
│       ├── system_tray.py           # Tray icon
│       ├── widgets/                 # Custom widgets
│       │   ├── __init__.py
│       │   ├── position_grid.py     # Position memory grid
│       │   ├── speed_slider.py      # Speed control slider
│       │   └── theme_selector.py    # Theme dropdown
│       └── tabs/                    # Settings tabs
│           ├── __init__.py
│           ├── movement_tab.py
│           ├── positions_tab.py
│           ├── visuals_tab.py
│           ├── hotkeys_tab.py
│           ├── advanced_tab.py
│           ├── profiles_tab.py
│           └── about_tab.py
│
├── data/
│   ├── icons/                       # Application icons
│   │   ├── app-icon.svg
│   │   └── tray-icon.svg
│   └── themes/                      # Theme definitions
│       └── themes.json
│
├── tests/
│   ├── __init__.py
│   ├── test_config.py
│   ├── test_state_manager.py
│   ├── test_mouse_controller.py
│   ├── test_hotkey_manager.py
│   └── test_monitor_manager.py
│
├── packaging/
│   ├── mouse-on-numpad.desktop      # XDG desktop entry
│   ├── mouse-on-numpad.service      # systemd user service
│   ├── PKGBUILD                     # Arch Linux package
│   ├── debian/                      # Debian packaging
│   └── flatpak/                     # Flatpak manifest
│
├── pyproject.toml                   # Project metadata & dependencies
├── requirements.txt                 # Pip dependencies
├── README.md
├── LICENSE
└── CHANGELOG.md
```

---

## 3. Phase-by-Phase Implementation

### Phase 1: Core Infrastructure (Foundation)

**Goal:** Establish project structure and core utilities

**Tasks:**
1. Set up Python project with `pyproject.toml`
2. Implement `ConfigManager` with JSON storage
   - Migrate INI key-value structure to JSON
   - Support XDG config directories
   - Implement backup system
3. Implement `StateManager` (port from StateManager.ahk)
   - Thread-safe state access
   - Observable pattern for UI updates
4. Implement `ErrorLogger` with Python's logging module
5. Create `ThemeManager` (port color themes)
6. Write unit tests for core modules

**Deliverables:**
- Working config system with JSON persistence
- State management with change notifications
- Logging infrastructure
- Test suite for core modules

---

### Phase 2: Input Control Layer (Critical Path)

**Goal:** Implement mouse and keyboard control for X11

**Tasks:**
1. Create `MouseController` abstract interface
2. Implement X11 backend using `pynput`:
   - `move_to(x, y)` - Absolute positioning
   - `move_relative(dx, dy)` - Relative movement
   - `click(button)` - Mouse button control
   - `scroll(direction, amount)` - Wheel scrolling
   - `get_position()` - Current cursor position
3. Implement acceleration curves (port from MouseActions.ahk)
   - Linear, exponential, and S-curve options
   - Configurable base speed and acceleration factor
4. Implement `HotkeyManager`:
   - Register numpad hotkeys globally
   - Handle modifier keys (Shift, Ctrl, Alt)
   - Support hotkey enable/disable toggle
5. Implement `MonitorManager`:
   - Detect all monitors via Xrandr
   - Handle virtual screen coordinates
   - Support negative coordinates for multi-monitor
6. Write integration tests

**Key Challenge: Numpad Key Codes**

Windows AutoHotkey uses symbolic names like `NumpadAdd`. Linux uses keycodes:

| Windows Name | X11 Keysym | evdev Code |
|--------------|------------|------------|
| Numpad0 | KP_Insert / KP_0 | KEY_KP0 |
| Numpad1 | KP_End / KP_1 | KEY_KP1 |
| ... | ... | ... |
| NumpadAdd | KP_Add | KEY_KPPLUS |
| NumpadSub | KP_Subtract | KEY_KPMINUS |
| NumpadMult | KP_Multiply | KEY_KPASTERISK |
| NumpadDiv | KP_Divide | KEY_KPSLASH |
| NumpadEnter | KP_Enter | KEY_KPENTER |

**Deliverables:**
- Functional mouse control on X11
- Working hotkey capture for numpad
- Multi-monitor coordinate handling
- Integration tests passing

---

### Phase 3: Position Memory & Audio

**Goal:** Complete non-GUI functionality

**Tasks:**
1. Implement `PositionMemory`:
   - 9 position slots (matching original)
   - JSON persistence
   - Undo/redo history (10 levels)
2. Implement `AudioManager`:
   - Beep generation for feedback
   - Volume control
   - Configurable enable/disable
3. Create command-line interface for headless operation:
   ```bash
   mouse-on-numpad --daemon        # Run in background
   mouse-on-numpad --toggle        # Enable/disable
   mouse-on-numpad --save 1        # Save position to slot 1
   mouse-on-numpad --load 1        # Load position from slot 1
   mouse-on-numpad --status        # Show current state
   ```

**Deliverables:**
- Full position memory system
- Audio feedback working
- CLI for scripting and testing
- All core features functional without GUI

---

### Phase 4: GUI Implementation (GTK 4)

**Goal:** Create settings GUI matching Windows version

**Tasks:**
1. Create `GTKApplication` with main window
2. Implement settings window (800x600 with 7 tabs):
   - **Movement Tab**: Speed sliders, acceleration curves
   - **Positions Tab**: Position grid with save/load/clear
   - **Visuals Tab**: Theme selector, status bar settings
   - **Hotkeys Tab**: Hotkey display and customization
   - **Advanced Tab**: Logging, performance settings
   - **Profiles Tab**: Profile management
   - **About Tab**: Version info, system details
3. Implement `StatusIndicator`:
   - Floating window with current state
   - Theme-aware colors
   - Position on selected monitor
4. Implement system tray icon:
   - Toggle enable/disable
   - Quick access to settings
   - Exit option
5. Apply color themes from `ThemeManager`

**Deliverables:**
- Complete settings GUI
- Status indicator matching Windows version
- System tray integration
- All 7 color themes working

---

### Phase 5: Wayland Support

**Goal:** Add Wayland compatibility

**Challenges:**
- Wayland restricts global hotkey capture (security model)
- Mouse position queries are limited
- Solutions require compositor-specific protocols

**Tasks:**
1. Implement Wayland backend using `python-evdev`:
   - Create virtual input device
   - Handle mouse movement via uinput
2. Research compositor-specific solutions:
   - **GNOME**: dbus interface for hotkeys
   - **KDE**: KGlobalAccel
   - **Sway/wlroots**: wlr-input-inhibitor protocol
3. Implement fallback mode:
   - Detect Wayland session
   - Prompt user to run under XWayland if needed
   - Provide clear documentation on limitations

**Deliverables:**
- Basic Wayland support via evdev
- Documentation of compositor-specific setups
- Graceful fallback to XWayland

---

### Phase 6: Packaging & Distribution

**Goal:** Make installation easy across distributions

**Tasks:**
1. Create XDG desktop entry for application menu
2. Create systemd user service for daemon mode
3. Package for major distributions:
   - **Arch Linux**: PKGBUILD for AUR
   - **Debian/Ubuntu**: .deb package
   - **Fedora**: .rpm spec file
   - **Flatpak**: Universal package
   - **AppImage**: Portable binary
4. Set up CI/CD for automated builds
5. Write installation documentation

**Deliverables:**
- Packages for 5+ distribution methods
- Automated release pipeline
- Comprehensive installation docs

---

## 4. Module Migration Guide

### 4.1 Direct Port Mappings

| Windows Module | Linux Module | Notes |
|----------------|--------------|-------|
| `Main.ahk` | `main.py` | Entry point, initialization |
| `Config.ahk` | `core/config.py` | INI → JSON migration |
| `StateManager.ahk` | `core/state_manager.py` | Add thread safety |
| `MouseActions.ahk` | `input/mouse_controller.py` | pynput backend |
| `PositionMemory.ahk` | `core/position_memory.py` | INI → JSON migration |
| `HotkeyManager.ahk` | `input/hotkey_manager.py` | X11 keygrab |
| `MonitorUtils.ahk` | `input/monitor_manager.py` | Xrandr queries |
| `TooltipSystem.ahk` | `ui/status_indicator.py` | GTK window |
| `StatusIndicator.ahk` | `ui/status_indicator.py` | Merge with tooltips |
| `ColorThemeManager.ahk` | `core/theme_manager.py` | Direct port |
| `ColorHelpers.ahk` | (inline in theme_manager) | Simple utilities |
| `ErrorLogger.ahk` | `core/error_logger.py` | Python logging |
| `SettingsGUI_Base.ahk` | `ui/main_window.py` | GTK implementation |
| `SettingsGUI_TabManager.ahk` | `ui/main_window.py` | GTK notebook widget |
| `Tabs/*.ahk` | `ui/tabs/*.py` | Individual tab modules |

### 4.2 API Translation Reference

#### Mouse Control

```python
# Windows (AutoHotkey)
MouseMove(x, y, speed)
MouseGetPos(&x, &y)
Click("left")
Send("{WheelUp 3}")

# Linux (pynput)
from pynput.mouse import Controller, Button
mouse = Controller()
mouse.position = (x, y)
x, y = mouse.position
mouse.click(Button.left)
mouse.scroll(0, 3)  # Scroll up 3
```

#### Hotkey Registration

```python
# Windows (AutoHotkey)
Hotkey("Numpad5", MouseClick)
Hotkey("NumpadAdd", ToggleMode)

# Linux (pynput)
from pynput import keyboard
def on_press(key):
    if key == keyboard.Key.kp_5:
        mouse_click()
    elif key == keyboard.KeyCode.from_vk(0xffab):  # KP_Add
        toggle_mode()

listener = keyboard.Listener(on_press=on_press, suppress=True)
listener.start()
```

#### Monitor Detection

```python
# Windows (AutoHotkey)
MonitorGetCount()
MonitorGet(n, &left, &top, &right, &bottom)
MonitorGetPrimary()

# Linux (Xlib + Xrandr)
from Xlib import display
from Xlib.ext import randr

d = display.Display()
screen = d.screen()
resources = randr.get_screen_resources(screen.root)
for output in resources.outputs:
    info = randr.get_output_info(screen.root, output, 0)
    # Parse geometry from CRTC
```

#### Configuration

```python
# Windows (AutoHotkey)
IniRead(value, "config.ini", "Section", "Key", "default")
IniWrite(value, "config.ini", "Section", "Key")

# Linux (Python JSON)
import json
from pathlib import Path

config_path = Path.home() / ".config" / "mouse-on-numpad" / "config.json"

def load_config():
    with open(config_path) as f:
        return json.load(f)

def save_config(config):
    with open(config_path, 'w') as f:
        json.dump(config, f, indent=2)
```

---

## 5. Testing Strategy

### 5.1 Unit Tests

- **Coverage Target:** 80%+
- **Framework:** pytest
- **Mock Strategy:** Mock pynput/Xlib for CI testing

```python
# Example: test_state_manager.py
def test_toggle_enabled():
    state = StateManager()
    assert state.enabled == True
    state.toggle()
    assert state.enabled == False
```

### 5.2 Integration Tests

- Test mouse movement on actual X11 display
- Test hotkey capture in isolated environment
- Use Xvfb for headless GUI testing

```python
# Example: test_mouse_integration.py
@pytest.mark.integration
def test_mouse_move_to_position():
    controller = MouseController()
    controller.move_to(100, 100)
    x, y = controller.get_position()
    assert (x, y) == (100, 100)
```

### 5.3 Manual Testing Matrix

| Test Case | Ubuntu 24.04 | Fedora 40 | Arch | Wayland |
|-----------|--------------|-----------|------|---------|
| Basic mouse movement | | | | |
| Numpad hotkeys | | | | |
| Multi-monitor | | | | |
| Position save/load | | | | |
| Settings GUI | | | | |
| System tray | | | | |
| Autostart | | | | |

### 5.4 Performance Testing

- Measure input latency (target: <10ms)
- Memory usage monitoring
- CPU usage in idle state (target: <1%)

---

## 6. Deployment & Packaging

### 6.1 Dependencies

```toml
# pyproject.toml
[project]
name = "mouse-on-numpad"
version = "1.0.0"
requires-python = ">=3.10"
dependencies = [
    "pynput>=1.7.6",
    "PyGObject>=3.44.0",
    "pulsectl>=23.5.0",
    "python-xlib>=0.33",
]

[project.optional-dependencies]
wayland = ["python-evdev>=1.6.0"]
dev = ["pytest>=7.0", "black", "mypy", "ruff"]
```

### 6.2 XDG Desktop Entry

```ini
# packaging/mouse-on-numpad.desktop
[Desktop Entry]
Type=Application
Name=Mouse on Numpad
Comment=Control your mouse with the numpad
Exec=mouse-on-numpad
Icon=mouse-on-numpad
Categories=Utility;Accessibility;
Keywords=mouse;numpad;accessibility;
StartupNotify=false
```

### 6.3 systemd User Service

```ini
# packaging/mouse-on-numpad.service
[Unit]
Description=Mouse on Numpad Enhanced
After=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/bin/mouse-on-numpad --daemon
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
```

### 6.4 Installation Methods

| Method | Command | Notes |
|--------|---------|-------|
| pip | `pip install mouse-on-numpad` | PyPI package |
| Arch AUR | `yay -S mouse-on-numpad` | AUR helper |
| Flatpak | `flatpak install mouse-on-numpad` | Sandboxed |
| AppImage | Download and run | Portable |
| From source | `pip install .` | Development |

---

## 7. Risk Assessment

### 7.1 Technical Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Wayland hotkey restrictions | High | High | Document XWayland fallback, research compositor APIs |
| pynput NumLock issues | Medium | Medium | Implement raw keysym handling fallback |
| GTK 4 learning curve | Medium | Low | Use existing tutorials, start with simple widgets |
| Multi-monitor edge cases | Medium | Medium | Extensive testing on various setups |
| Performance on older hardware | Low | Low | Profile and optimize critical paths |

### 7.2 Scope Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Feature creep | Medium | Medium | Stick to original feature set for v1 |
| GUI complexity | High | High | Start with minimal GUI, iterate |
| Compatibility matrix | Medium | Medium | Focus on Ubuntu LTS first, expand later |

### 7.3 Wayland-Specific Challenges

**Problem:** Wayland's security model prevents applications from:
- Capturing global hotkeys
- Querying mouse position from other applications
- Moving mouse cursor globally (without focus)

**Solutions:**

1. **For GNOME (most common):**
   - Use `gnome-shell` extension for hotkeys
   - Or use D-Bus with Settings Portal

2. **For KDE Plasma:**
   - KGlobalAccel service integration

3. **For wlroots-based (Sway, etc.):**
   - wlr-input-inhibitor protocol
   - Or wtype for input simulation

4. **Universal Fallback:**
   - Run application under XWayland (`GDK_BACKEND=x11`)
   - Document this requirement clearly

---

## 8. Success Criteria

### Minimum Viable Product (MVP)

- [ ] Mouse movement via numpad (8/2/4/6)
- [ ] Mouse clicks via numpad (5/0/Enter)
- [ ] Scroll via Alt+numpad
- [ ] Enable/disable toggle (Numpad*)
- [ ] Position memory (9 slots)
- [ ] Basic settings GUI
- [ ] Works on Ubuntu 24.04 LTS with X11

### Full Release (v1.0)

- [ ] All MVP features
- [ ] Full settings GUI with 7 tabs
- [ ] 7 color themes
- [ ] System tray integration
- [ ] Autostart support
- [ ] Multi-monitor support
- [ ] Audio feedback
- [ ] Works on major distributions
- [ ] Basic Wayland support

### Future Enhancements (v2.0+)

- [ ] Native Wayland with compositor plugins
- [ ] macOS port
- [ ] Custom gesture support
- [ ] Voice control integration
- [ ] Rust rewrite for performance

---

## Appendix A: Reference Links

- [pynput documentation](https://pynput.readthedocs.io/)
- [PyGObject GTK 4 tutorial](https://pygobject.readthedocs.io/)
- [python-xlib documentation](https://python-xlib.github.io/)
- [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
- [Wayland Input Method Protocol](https://wayland.freedesktop.org/docs/html/)
- [evdev Python library](https://python-evdev.readthedocs.io/)

---

## Appendix B: Original Windows Feature List

Preserved for reference - all features to be implemented:

1. **Mouse Movement**
   - Numpad 8/2/4/6 for direction
   - Diagonal movement (7/9/1/3)
   - Configurable speed and acceleration

2. **Mouse Buttons**
   - Numpad 5: Left click
   - Numpad 0: Right click
   - Numpad Enter: Middle click
   - Numpad Del: Double click

3. **Scrolling**
   - Alt+Numpad 8/2: Vertical scroll
   - Alt+Numpad 4/6: Horizontal scroll
   - Acceleration support

4. **Position Memory**
   - Ctrl+Numpad 1-9: Save position
   - Numpad 1-9: Load position
   - Shift+Numpad 1-9: Clear position

5. **Mode Controls**
   - Numpad *: Toggle enable/disable
   - Numpad /: Toggle inverted mode
   - Numpad +: Open settings
   - Numpad -: Reload/restart

6. **Settings GUI**
   - 7 tabs with full configuration
   - Profile management
   - Theme selection

7. **Status Indicator**
   - Floating display showing mode
   - Customizable position and appearance

---

*Document Version: 1.0*
*Created: January 2026*
*Last Updated: January 2026*
