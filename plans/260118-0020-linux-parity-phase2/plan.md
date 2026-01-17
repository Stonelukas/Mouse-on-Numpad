---
title: "Linux Parity Phase 2 - Advanced Features"
description: "Add remaining Windows features to Linux port"
status: pending
priority: P2
effort: 6h
branch: claude/plan-linux-port-T7fmn
tags: [feature-parity, gui, config]
created: 2026-01-18
---

# Linux Parity Phase 2

## Goal
Bring Linux port to full feature parity with Windows AHK version.

## Phases

| Phase | Description | Effort | Status |
|-------|-------------|--------|--------|
| 1 | [Hotkey Customization](phase-01-hotkey-customization.md) | 1.5h | Pending |
| 2 | [Secondary Monitor](phase-02-secondary-monitor.md) | 45m | Pending |
| 3 | [Status Indicator Config](phase-03-status-config.md) | 1h | Pending |
| 4 | [Color Themes](phase-04-color-themes.md) | 1h | Pending |
| 5 | [Profiles System](phase-05-profiles.md) | 1.5h | Pending |

## Gap Analysis (Windows vs Linux)

### Core Features (Done ✅)
- Movement with acceleration
- Click actions (left/right/middle)
- Scroll support
- Click hold toggle
- Undo movement
- Position memory (5 slots)
- Settings GUI (4 tabs)

### Missing Features
| Feature | Windows | Linux |
|---------|---------|-------|
| Hotkey customization | GUI tab | ❌ Hardcoded |
| Secondary monitor toggle | Alt+Numpad9 | ❌ |
| Status size/opacity | Configurable | ❌ Fixed |
| Color themes | 5+ themes | ❌ |
| Profiles | Save/load | ❌ |
| Tooltip position | Configurable | ❌ Fixed |
| Monitor test | Ctrl+Alt+Numpad9 | ❌ |

## Key Files
- `src/mouse_on_numpad/daemon.py` - Hotkey handling
- `src/mouse_on_numpad/ui/main_window.py` - Settings GUI
- `src/mouse_on_numpad/core/config.py` - Configuration
- `src/mouse_on_numpad/ui/status_indicator.py` - Overlay

## Dependencies
- Phase 1 enables user to customize controls
- Phase 3-4 improve visual experience
- Phase 5 requires Phase 1 (hotkeys stored in profiles)
