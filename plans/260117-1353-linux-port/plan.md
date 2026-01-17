---
title: "Linux Port: Mouse on Numpad Enhanced"
description: "Port Windows AutoHotkey app to native Linux with Python/GTK"
status: completed
priority: P1
effort: 40h
branch: claude/plan-linux-port-T7fmn
tags: [linux, python, gtk, port]
created: 2026-01-17
---

# Linux Port: Mouse on Numpad Enhanced

Port the Windows AutoHotkey numpad mouse controller to native Linux using Python 3.10+ and GTK 4.

## Quick Reference

| Aspect | Choice |
|--------|--------|
| Language | Python 3.10+ |
| Package Manager | uv |
| GUI Framework | GTK 4 (PyGObject) |
| Input Library | pynput (X11), evdev (fallback) |
| Tray | AppIndicator3 |
| Config | JSON (~/.config/mouse-on-numpad/) |
| Primary Target | Arch Linux (X11) |
| Wayland | XWayland fallback only |

## Phases Overview

| # | Phase | Effort | Status | File |
|---|-------|--------|--------|------|
| 1 | [Core Infrastructure](./phase-01-core-infrastructure.md) | 6h | **completed** | ConfigManager, StateManager, ErrorLogger |
| 2 | [Input Control Layer](./phase-02-input-control-layer.md) | 10h | **completed** | MouseController, HotkeyManager, MonitorManager |
| 3 | [Position Memory & Audio](./phase-03-position-memory-audio.md) | 4h | **completed** | PositionMemory, AudioFeedback |
| 4 | [GUI Implementation](./phase-04-gui-implementation.md) | 10h | **completed** | MainWindow, TrayIcon, StatusIndicator |
| 5 | [Wayland Support](./phase-05-wayland-support.md) | 6h | **completed** | X11/Wayland/Evdev backends |
| 6 | [Packaging & Distribution](./phase-06-packaging-distribution.md) | 4h | **completed** | PKGBUILD, systemd, polkit |

## Key Decisions (Validated)

- **XWayland fallback only** - No compositor plugins for v1
- **MVP GUI first** - 2-3 tabs max, expand later
- **Unit tests only** - Integration tests post-MVP
- **AUR priority** - Defer Flatpak/AppImage
- **Fresh config** - No migration from Windows INI

## Validation Summary

**Validated:** 2026-01-17
**Questions asked:** 8

### Confirmed Decisions

| Decision | User Choice |
|----------|-------------|
| Permissions model | Polkit elevation on demand (once per session) |
| NumLock behavior | NumLock OFF → mouse mode, NumLock ON → numbers |
| Key conflicts | Suppress and consume when mouse mode active |
| Position memory | Store per-monitor-config (remember arrangements) |
| Status indicator | Auto-hide when disabled |
| Audio backend | PipeWire first, PulseAudio fallback |
| Theme system | GTK system theme only (no custom themes) |

### Action Items

- [ ] **Phase 2:** Implement NumLock-based toggle (OFF=mouse, ON=numbers) instead of Numpad*
- [ ] **Phase 2:** Add polkit policy file for input device access
- [ ] **Phase 3:** Store position slots per monitor configuration hash
- [ ] **Phase 3:** Add PipeWire support with pulsectl fallback
- [ ] **Phase 4:** Remove custom theme system, use GTK CSS provider for system theme
- [ ] **Phase 4:** Implement auto-hide for status indicator
- [ ] **Phase 6:** Add polkit .policy file to packaging

## Directory Structure (Target)

```
mouse-on-numpad-linux/
src/
  core/       # config, state, theme, logging
  input/      # mouse, hotkey, monitor, audio
  backends/   # x11, wayland, evdev
  ui/         # GTK app, window, tray, widgets
data/         # icons, themes
tests/        # pytest
packaging/    # PKGBUILD, .desktop, .service
```

## Dependencies

```toml
# pyproject.toml
[project]
requires-python = ">=3.10"
dependencies = [
  "pynput>=1.7.6",
  "PyGObject>=3.44.0",
  "pulsectl>=23.5.0",
  "python-xlib>=0.33",
]
```

## Success Criteria (MVP)

- [ ] Mouse movement via numpad (8/2/4/6 directions)
- [ ] Mouse clicks (5/0/Enter for L/R/M)
- [ ] Scroll via Alt+numpad
- [ ] Toggle enable/disable (NumLock OFF = mouse mode)
- [ ] 9 position memory slots
- [ ] Basic settings GUI
- [ ] Works on Arch Linux with X11

## Links

- Source: [LINUX_PORT_PLAN.md](../../LINUX_PORT_PLAN.md)
- Reports: [./reports/](./reports/)
