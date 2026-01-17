---
title: "Phase 3: Enhance Settings GUI"
status: pending
effort: 4h
---

# Phase 3: Enhance Settings GUI

## Problem

Current GUI (2 tabs: Movement, Positions) missing Windows features:
- No hotkey configuration
- No audio volume control
- No advanced settings (max speed, move delay, undo levels)
- No scroll settings

## Windows Reference (SettingsDialog.ahk)

4 tabs:
1. **Movement** - BaseSpeed, MaxSpeed, AccelerationRate, MoveDelay, EnableAbsoluteMovement
2. **Audio** - EnableAudioFeedback, Volume slider
3. **Hotkeys** - All 20+ configurable hotkeys
4. **Visuals** - Theme, StatusIndicator position/size

## Target Layout

### Tab 1: Movement (Expand)

Current:
- Base Speed slider
- Acceleration Factor slider
- Curve dropdown
- Audio toggle

Add:
- **Max Speed** slider (10-200)
- **Move Delay** slider (5-50ms)
- **Enable Absolute Movement** toggle

### Tab 2: Audio (New)

- **Enable Audio Feedback** toggle
- **Volume** slider (0-100)
- **Click Sound** dropdown (beep, click, silent)

### Tab 3: Hotkeys (New)

Grid layout with key capture:

| Action | Key |
|--------|-----|
| Toggle Mode | Numpad+ |
| Move Up | Numpad8 |
| ... | ... |

Implementation: Capture next keypress on focus.

### Tab 4: Advanced (New)

- **Max Undo Levels** spin (1-100)
- **Scroll Step** slider (1-10)
- **Scroll Acceleration Rate** slider (1.0-2.0)
- **Reset All to Defaults** button

## Implementation Steps

1. Refactor `_create_movement_tab` - add max_speed, move_delay, absolute toggle
2. Add `_create_audio_tab` - volume slider, sound type dropdown
3. Add `_create_hotkeys_tab` - grid with key capture buttons
4. Add `_create_advanced_tab` - undo levels, scroll settings
5. Add KeyCaptureButton widget for hotkey editing
6. Wire all controls to ConfigManager

## Files to Modify

| File | Change |
|------|--------|
| `src/mouse_on_numpad/ui/main_window.py` | Expand with 4 tabs |
| `src/mouse_on_numpad/ui/key_capture.py` | NEW: KeyCaptureButton widget |
| `src/mouse_on_numpad/core/config.py` | Add default hotkey mappings |

## Key Capture Widget

```python
class KeyCaptureButton(Gtk.Button):
    """Button that captures next keypress when focused."""

    def __init__(self, action_name: str, current_key: str):
        super().__init__(label=current_key or "Click to set")
        self._action = action_name
        self._capturing = False
        self.connect("clicked", self._start_capture)

    def _start_capture(self, _btn):
        self.set_label("Press key...")
        self._capturing = True
        # Add key event controller
        ctrl = Gtk.EventControllerKey()
        ctrl.connect("key-pressed", self._on_key)
        self.add_controller(ctrl)

    def _on_key(self, ctrl, keyval, keycode, state):
        if self._capturing:
            key_name = Gdk.keyval_name(keyval)
            self.set_label(key_name)
            self._capturing = False
            self.emit("key-captured", key_name)
            return True
        return False
```

## Config Additions

```json
{
    "movement": {
        "max_speed": 100,
        "move_delay": 10,
        "enable_absolute_movement": false,
        "max_undo_levels": 20
    },
    "audio": {
        "enabled": true,
        "volume": 50,
        "sound_type": "beep"
    },
    "scroll": {
        "step": 3,
        "acceleration_rate": 1.5,
        "max_speed": 20
    },
    "hotkeys": {
        "toggle_mode": "KP_Add",
        "move_up": "KP_8",
        "move_down": "KP_2",
        ...
    }
}
```

## Success Criteria

- [ ] 4 tabs visible: Movement, Audio, Hotkeys, Advanced
- [ ] All config values editable via GUI
- [ ] Changes save to config.json immediately
- [ ] Hotkey capture works (click button, press key)
- [ ] Reset to defaults button works

## UI Mockup

```
+-----------------------------------------------------------+
| Mouse on Numpad Settings                              [X] |
+-----------------------------------------------------------+
| [Movement] [Audio] [Hotkeys] [Advanced]                   |
+-----------------------------------------------------------+
| Movement Settings                                         |
|                                                           |
| Base Speed:        [======|=====] 10                      |
| Max Speed:         [============|] 100                    |
| Acceleration:      [====|=======] 1.5                     |
| Move Delay:        [==|=========] 10 ms                   |
| Curve:             [exponential v]                        |
|                                                           |
| [ ] Enable Absolute Movement                              |
+-----------------------------------------------------------+
```

## Dependencies

- Phase 2 must complete first (config keys needed)
- No new external deps
