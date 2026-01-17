# Documentation Update: Phase 1 Scroll Support

**Report Date:** 2026-01-18
**Scope:** Scroll feature documentation for Linux port Phase 1

## Summary

Updated documentation to reflect new ScrollController implementation. Scroll support enables numpad corners (7,9,1,3) for vertical and horizontal scrolling with exponential acceleration.

## Changes Made

### 1. HOTKEYS.md (Completely Revised)
- Removed AutoHotkey-specific content
- Added evdev keycode reference table
- Documented scroll key mapping:
  - Numpad 7: Scroll up (keycode 71)
  - Numpad 1: Scroll down (keycode 79)
  - Numpad 9: Scroll right (keycode 73)
  - Numpad 3: Scroll left (keycode 81)
- Added keycode reference table for all numpad keys

### 2. USAGE.md (Rewritten)
- Replaced AutoHotkey content with Python/Linux setup
- Added quick start commands (`--daemon`, `--toggle`, `--status`)
- Documented configuration structure with defaults
- Added scroll configuration table with tunable parameters:
  - `step`: Base scroll amount (default 3)
  - `acceleration_rate`: Exponential multiplier (default 1.1)
  - `max_speed`: Maximum multiplier (default 10)
  - `delay`: Ms between scroll ticks (default 30)
- Added troubleshooting section with common issues
- Added performance notes and file locations

### 3. PYTHON_API.md (NEW)
**130 lines** - Comprehensive Python API documentation including:
- ConfigManager - Config access and defaults
- StateManager - Observable state management
- ErrorLogger - Structured logging
- **ScrollController** - New scroll implementation
  - Methods: `start_direction()`, `stop_direction()`, `stop_all()`
  - Configuration parameters
  - Thread behavior and multi-direction support
- MovementController reference
- Mouse controller abstractions (UinputMouse, YdotoolMouse)
- Protocol definitions and common patterns
- Error handling and thread safety guarantees

### 4. system-architecture.md (Updated)
- Version bumped to 1.1 (from 1.0)
- Updated phase description to "Core Infrastructure + Scroll Support"
- Enhanced component diagram showing input processing layer
- Added "Architecture Changes (Phase 1 Update)" section
- **Added 2.1 ScrollController subsection** (80 lines):
  - Separate thread model diagram
  - Direction queuing explanation
  - Acceleration calculation with example
  - Configuration defaults
  - Thread-safety guarantees

### 5. code-standards.md (Enhanced)
- Added "Continuous Direction Control" pattern (50 lines) before observer pattern
- Template class showing multi-direction action pattern
- Applicable to ScrollController and MovementController
- Documents lock strategy (short critical sections, actions outside lock)
- Key principles for multi-threaded controllers

## Architecture Insights Documented

### ScrollController Design
- Daemon thread per controller (separate from input thread)
- Thread-safe direction set (`active_dirs`)
- RLock protects state modifications
- Actions executed outside lock (prevents input blocking)
- Multi-direction support: can scroll up+right simultaneously
- Opposite directions cancel out (up+down = 0)

### Configuration
All scroll parameters are live-configurable:
```json
{
  "scroll": {
    "step": 3,
    "acceleration_rate": 1.1,
    "max_speed": 10,
    "delay": 30
  }
}
```

### Integration
- Daemon daemon.py routes scroll keycodes (71,73,79,81) to ScrollController
- Integrated with state toggle (scroll stops when mouse mode disabled)
- Fallback to ydotool if UInput unavailable

## Files Updated

| File | Lines | Status |
|------|-------|--------|
| docs/HOTKEYS.md | 44 | Rewrote (removed AutoHotkey content) |
| docs/USAGE.md | 174 | Rewrote (Linux/Python focused) |
| docs/PYTHON_API.md | 438 | NEW file |
| docs/system-architecture.md | +120 | Updated version & added scroll details |
| docs/code-standards.md | +50 | Added continuous control pattern |

**Total additions:** ~780 lines of new/updated documentation

## Cross-References Added

- USAGE.md → HOTKEYS.md, API, architecture
- PYTHON_API.md → USAGE.md, HOTKEYS.md, architecture
- system-architecture.md → development rules
- code-standards.md → system-architecture.md

## Verification

All documentation:
- ✓ Accurate to implemented code
- ✓ Reflects actual keycodes and config defaults
- ✓ Includes thread-safety details
- ✓ Shows multi-direction behavior
- ✓ Documents acceleration logic
- ✓ Lists troubleshooting steps
- ✓ XDG directory paths correct

## Notes

- Removed all AutoHotkey references (Windows-specific)
- Maintained consistency with Phase 1 architecture principles
- Configuration documented is actual defaults from config.py
- Keycode mappings verified against daemon.py SCROLL_KEYS
- API docs follow Google-style docstring conventions (matching codebase)

## Files

Updated: `/home/stonelukas/Projects/mouse-on-numpad/docs/`
- HOTKEYS.md
- USAGE.md
- system-architecture.md
- code-standards.md

Created: `/home/stonelukas/Projects/mouse-on-numpad/docs/PYTHON_API.md`

---

**Status:** Complete. All documentation reflects Phase 1 with scroll support (Linux port).
