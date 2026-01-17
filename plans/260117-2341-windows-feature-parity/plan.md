---
title: "Windows Feature Parity"
description: "Add missing features from Windows AHK version to Linux port"
status: pending
priority: P2
effort: 3h
branch: claude/plan-linux-port-T7fmn
tags: [feature-parity, daemon, input]
created: 2026-01-17
---

# Windows Feature Parity Plan

## Goal
Bring Linux port to feature parity with Windows AHK version.

## Phases

| Phase | Description | Effort | Status |
|-------|-------------|--------|--------|
| 1 | [Scroll Support](phase-01-scroll-support.md) | 30m | Complete |
| 2 | [Click Hold](phase-02-click-hold.md) | 30m | Complete |
| 3 | [Undo Movement](phase-03-undo-movement.md) | 45m | Complete |
| 4 | [Position Memory Integration](phase-04-position-memory.md) | 45m | Pending |

## Key Files
- `src/mouse_on_numpad/daemon.py` - Main hotkey handling
- `src/mouse_on_numpad/input/movement_controller.py` - Movement logic
- `src/mouse_on_numpad/input/position_memory.py` - Position slots (exists, needs wiring)

## Windows Key Mappings to Implement
| Key | Windows Function | Linux Status |
|-----|-----------------|--------------|
| Numpad 7/1 | Scroll up/down | ✅ |
| Numpad 9/3 | Scroll left/right | ✅ |
| NumpadDot | Hold left click | ✅ |
| NumpadDiv | Undo last move | ✅ |
| NumpadMult | Save position mode | ❌ |
| NumpadSub | Load position mode | ❌ |
