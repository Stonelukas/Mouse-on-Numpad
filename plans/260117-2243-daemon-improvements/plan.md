---
title: "Daemon Improvements: Fluidity, Diagonals, GUI"
description: "Fix movement fluidity, diagonal handling, and enhance settings GUI to match Windows features"
status: pending
priority: P1
effort: 10h
branch: claude/plan-linux-port-T7fmn
tags: [daemon, performance, gui, usability]
created: 2026-01-17
---

# Daemon Improvements Plan

## Overview

Current Linux port has 3 key issues:
1. **Movement stutters** - Each move spawns subprocess (`ydotool`), ~50ms overhead per call
2. **Diagonals incomplete** - No acceleration, no smooth multi-key detection
3. **GUI minimal** - Missing Windows features: hotkeys tab, max speed, scroll, undo levels

## Windows Reference (feature parity target)

From `MouseActions.ahk`:
- Continuous movement with acceleration (`_MoveContinuous`)
- Multi-key diagonal detection (hold 2 keys = diagonal)
- Config: BaseSpeed, AccelerationRate, MaxSpeed, MoveDelay, ScrollStep
- Undo movement history (MaxUndoLevels)
- Inverted mode toggle

From `HotkeyManager.ahk`:
- 9 hotkey categories: movement, click, hold, scroll, special
- Scroll with acceleration (Alt+Numpad combos)
- Toggle holds (left/right/middle button)

## Phases

| Phase | Title | Status | Effort |
|-------|-------|--------|--------|
| 1 | [Fix Movement Fluidity](./phase-01-movement-fluidity.md) | ✅ complete (8/10) | 3h |
| 2 | [Improve Diagonal & Acceleration](./phase-02-diagonal-acceleration.md) | pending | 3h |
| 3 | [Enhance Settings GUI](./phase-03-settings-gui.md) | pending | 4h |

## Key Decisions

1. **Replace ydotool subprocess** with persistent socket or direct uinput
2. **Acceleration model** - Match Windows exponential curve
3. **GUI tabs** - Add Hotkeys + Audio + Advanced (match Windows 4-tab layout)

## Success Criteria

- [x] Smooth 60fps-like movement (no stutters) - Phase 1 complete
- [ ] Diagonal movement with acceleration works
- [ ] GUI has all Windows settings exposed
- [ ] Scroll with acceleration
- [ ] Undo movement history

## Dependencies

- evdev (already used for input)
- ydotool OR python-uinput for mouse output
- GTK 4 (already used)

## Validation Summary

**Validated:** 2026-01-17
**Questions asked:** 4

### Confirmed Decisions
- Mouse Backend: Direct UInput (with ydotool auto-fallback)
- Acceleration: Windows-style exponential curve
- GUI Features: Full Windows parity (4 tabs)
- Fallback: Auto-detect UInput, fall back to ydotool

### Action Items
- [x] Plan confirmed - proceed to implementation
