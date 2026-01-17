# Default Hotkeys

These are the defaults mapped in `daemon.py` and available when Mouse Mode is enabled.

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