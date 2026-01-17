---
phase: 5
title: "Wayland Support"
status: pending
priority: P3
effort: 6h
---

# Phase 5: Wayland Support

## Context

- Parent: [plan.md](./plan.md)
- Source: [LINUX_PORT_PLAN.md](../../LINUX_PORT_PLAN.md) Section 3 Phase 5
- Dependencies: Phase 2 (InputController)

## Overview

Add Wayland compatibility via XWayland fallback. **V1 scope: No compositor plugins.** Document limitations and provide clear user guidance.

## Key Insights

- Wayland security model blocks global hotkeys
- Mouse position queries limited without focus
- XWayland provides X11 compatibility layer
- evdev backend works for input simulation

## Requirements

### Functional
- Detect Wayland vs X11 session
- Auto-fallback to XWayland
- evdev backend for input when needed
- Clear error messages for unsupported scenarios

### Non-Functional
- Graceful degradation
- User-friendly documentation
- No compositor-specific code (v1)

## Architecture

```
src/
  backends/
    __init__.py
    base.py            # Abstract InputBackend
    x11_backend.py     # X11 via pynput
    wayland_backend.py # XWayland fallback
    evdev_backend.py   # Direct kernel input
```

### Backend Selection
```python
def get_backend() -> InputBackend:
    session_type = os.environ.get("XDG_SESSION_TYPE")

    if session_type == "x11":
        return X11Backend()
    elif session_type == "wayland":
        # Force XWayland mode
        os.environ["GDK_BACKEND"] = "x11"
        return WaylandBackend()  # Uses X11 under XWayland
    else:
        return EvdevBackend()  # Fallback
```

## Related Code Files

### Create
- `src/backends/__init__.py`
- `src/backends/base.py`
- `src/backends/x11_backend.py`
- `src/backends/wayland_backend.py`
- `src/backends/evdev_backend.py`
- `docs/wayland-support.md`

## Implementation Steps

1. Create InputBackend abstract class
   ```python
   from abc import ABC, abstractmethod

   class InputBackend(ABC):
       @abstractmethod
       def move_mouse(self, x: int, y: int) -> None: ...

       @abstractmethod
       def click(self, button: str) -> None: ...

       @abstractmethod
       def register_hotkey(self, key, callback) -> None: ...

       @abstractmethod
       def get_mouse_position(self) -> tuple[int, int]: ...
   ```

2. Implement X11Backend
   - Wrap pynput mouse/keyboard
   - Full feature support
   - Default backend for X11 sessions

3. Implement WaylandBackend
   - Detect Wayland session
   - Set GDK_BACKEND=x11 for GTK
   - Use pynput (runs under XWayland)
   - Log warning about XWayland mode

4. Implement EvdevBackend (fallback)
   - Use python-evdev for input
   - Create virtual input device (uinput)
   - Requires input group membership
   - Limited: no global hotkey capture

5. Create backend auto-detection
   - Check XDG_SESSION_TYPE
   - Check WAYLAND_DISPLAY
   - Fallback chain: X11 -> Wayland -> evdev

6. Write Wayland documentation
   - Explain limitations
   - Setup instructions for XWayland
   - Compositor-specific notes (GNOME, KDE, Sway)
   - Troubleshooting guide

7. Add session detection to startup
   - Log detected session type
   - Show notification if Wayland with limitations
   - Offer to run with GDK_BACKEND=x11

## Todo List

- [ ] Create InputBackend abstract interface
- [ ] Implement X11Backend wrapping pynput
- [ ] Implement WaylandBackend with XWayland
- [ ] Implement EvdevBackend fallback
- [ ] Add auto-detection for session type
- [ ] Set GDK_BACKEND=x11 for Wayland
- [ ] Write Wayland documentation
- [ ] Test on GNOME Wayland
- [ ] Test on KDE Wayland
- [ ] Add user notification for limitations

## Success Criteria

- [ ] App detects X11 vs Wayland session
- [ ] On Wayland, auto-falls back to XWayland
- [ ] Mouse control works under XWayland
- [ ] Hotkeys work under XWayland
- [ ] GUI renders correctly on Wayland
- [ ] Clear message shown for pure Wayland limitations
- [ ] Documentation covers setup steps

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| XWayland not available | High | Document requirement |
| Hotkeys fail on Wayland | High | XWayland fallback |
| evdev requires root/input group | Medium | Document permissions |
| GTK rendering issues | Low | Force X11 backend |

## Security Considerations

- evdev requires input group membership
- uinput device creation needs permissions
- Document required setup for users

## Wayland Limitations (v1)

| Feature | X11 | Wayland (XWayland) | Wayland (Native) |
|---------|-----|--------------------|------------------|
| Mouse movement | Full | Full | Via evdev only |
| Global hotkeys | Full | Full | Not supported |
| Mouse position query | Full | Full | Not supported |
| GUI | Full | Full | Full |

## Next Steps

After Phase 5 complete:
- App works on both X11 and Wayland (via XWayland)
- Phase 6: Packaging for distribution
- Future: Native Wayland with compositor plugins
