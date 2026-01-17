# Hotkeys & Customization

## Overview

Mouse on Numpad uses numpad keys to control mouse movement and actions. All hotkeys are **fully customizable** via the Settings GUI (Hotkeys tab) and persist in `config.json`.

Default assignments are shown below, but these can be changed through the interactive key capture interface.

## Mode Control
- Numpad +: Toggle Mouse Mode ON/OFF
- Numpad *: Enter Save Position Mode
- Numpad -: Enter Load Position Mode

## Mouse Movement (when Mouse Mode ON)
- Numpad 8/2/4/6: Move Up/Down/Left/Right (accelerates while held)
- Numpad 7/9/1/3: Diagonal Movement via multi-key hold
- Numpad 5: Left Click
- Numpad 0: Right Click
- Numpad Enter: Middle Click

## Scroll Control (when Mouse Mode ON)
- Numpad 7: Scroll Up
- Numpad 1: Scroll Down
- Numpad 9: Scroll Right (horizontal)
- Numpad 3: Scroll Left (horizontal)

**Note:** Scroll supports exponential acceleration while held (configurable).

## Position Memory
- Numpad 1-9 (in Load/Save Mode): Load/Save Position Slot
- Numpad 0: Right Click (in normal mode) or special slot in memory mode

## Key Mapping Reference (evdev keycodes)

| Numpad Key | Keycode | Function |
|------------|---------|----------|
| 7 | 71 | Scroll Up |
| 8 | 72 | Move Up |
| 9 | 73 | Scroll Right |
| 4 | 75 | Move Left |
| 5 | 76 | Left Click |
| 6 | 77 | Move Right |
| 1 | 79 | Scroll Down |
| 2 | 80 | Move Down |
| 3 | 81 | Scroll Left |
| 0 | 82 | Right Click |
| + | 78 | Toggle Mode |
| * | 55 | Enter Save Mode |
| - | 74 | Enter Load Mode |
| Enter | 96 | Middle Click |

---

## Phase 1: Customization Feature

### Hotkeys Tab in Settings GUI

Users can now customize any hotkey assignment via the interactive **Hotkeys tab** in the Settings GUI:

1. **Open Settings**: Press Ctrl+Alt+S or use the GUI launcher
2. **Navigate to Hotkeys tab**: Select the "Hotkeys" tab
3. **Reassign a key**: Click any key button and press the desired numpad key
4. **Escape to cancel**: Press Escape during capture to cancel without saving
5. **View conflicts**: Click "Scan for Conflicts" to detect duplicate assignments
6. **Reset to defaults**: Click "Reset All" to restore original mappings

### Key Features

#### Interactive Key Capture
- Click a hotkey button to enter capture mode
- Press any numpad key to assign it
- Visual feedback shows current assignment
- Escape cancels the operation

#### Conflict Detection
- "Scan for Conflicts" button detects duplicate key assignments
- Prevents multiple actions from triggering the same key
- Conflict status displayed below scan button

#### Persistent Configuration
- All changes saved to `~/.config/mouse-on-numpad/config.json`
- Configuration loaded automatically on daemon restart
- Backup created before each write (`.json.bak`)

#### Position Slots
- Separate section for position memory slots (1-5)
- Used in Save/Load Position mode
- Independent from main hotkey mappings

### Configuration Structure

Hotkeys stored in `config.json`:

```json
{
  "hotkeys": {
    "toggle_mode": 78,      // KEY_KPPLUS
    "save_mode": 55,        // KEY_KPASTERISK
    "load_mode": 74,        // KEY_KPMINUS
    "undo": 98,             // KEY_KPSLASH
    "left_click": 76,       // KEY_KP5
    "right_click": 82,      // KEY_KP0
    "middle_click": 96,     // KEY_KPENTER
    "hold_left": 83,        // KEY_KPDOT
    "move_up": 72,          // KEY_KP8
    "move_down": 80,        // KEY_KP2
    "move_left": 75,        // KEY_KP4
    "move_right": 77,       // KEY_KP6
    "scroll_up": 71,        // KEY_KP7
    "scroll_down": 79,      // KEY_KP1
    "scroll_right": 73,     // KEY_KP9
    "scroll_left": 81,      // KEY_KP3
    "slot_1": 75,           // Position slot 1 (KEY_KP4)
    "slot_2": 76,           // Position slot 2 (KEY_KP5)
    "slot_3": 77,           // Position slot 3 (KEY_KP6)
    "slot_4": 72,           // Position slot 4 (KEY_KP8)
    "slot_5": 82            // Position slot 5 (KEY_KP0)
  }
}
```

### Implementation Details

**Related Source Files:**
- `src/mouse_on_numpad/ui/hotkeys_tab.py` - Main hotkeys UI component
- `src/mouse_on_numpad/ui/key_capture_button.py` - Interactive key capture button widget
- `src/mouse_on_numpad/ui/keycode_mappings.py` - Keycode constants and display names
- `src/mouse_on_numpad/daemon.py` - Loads hotkeys from config on startup

**Key Classes:**
- `HotkeysTab` - GTK 4 settings tab with grid layout
- `KeyCaptureButton` - Interactive button for capturing key presses
- `HOTKEY_LABELS` - Mapping of action names to human-readable labels