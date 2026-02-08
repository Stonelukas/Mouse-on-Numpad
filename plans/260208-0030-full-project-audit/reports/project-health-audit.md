# Project Health Audit

**Date:** 2026-02-08
**Auditor:** code-reviewer (task #2)
**Scope:** Testing, documentation, packaging, security, UX/features

## Summary

Mouse-on-numpad has evolved significantly beyond Phase 1 "Core Infrastructure" - implemented features include daemon, backends (X11/Wayland/evdev), GUI (GTK4 settings window with 6 tabs), tray icon, scroll control, monitor management, and profile management. **Critical gap: documentation describes Phase 1 (70% complete) but codebase has ~30 Python files implementing Phases 1-4.** Testing is strong (191 test functions, 12 test files). Packaging works but has minor dependency issues. Security model is sound (no privilege escalation, graceful uinput fallback). GUI is feature-complete but roadmap shows "not implemented" for import/export.

## Testing

**Coverage:** 191 test functions across 12 test files, ~2540 total lines
- Tests exist for: core (config, state, logger), input (mouse, hotkeys, position, audio, backends, scroll, monitor), GUI components
- Test structure: pytest + pytest-cov configured (pyproject.toml line 54-56)
- All backend types tested: X11Backend, WaylandBackend, EvdevBackend with mocks

**Gaps:**
- No integration tests for daemon lifecycle (startup, shutdown, signal handling)
- No tests for profiles system (ui/profiles_tab.py created but test_gui_components.py doesn't cover)
- No tests for tray icon (tray_icon.py deleted in git status but daemon.py imports it line 14)
- Missing movement_controller.py tests (file exists but no test_movement_controller.py)
- No E2E tests for full workflow (evdev capture → state change → mouse action)

**Recommendations:**
1. Add daemon integration tests (test_daemon_lifecycle.py)
2. Test profiles save/load/switch functionality
3. Add test for tray icon integration (resolve deleted file first)
4. Create test_movement_controller.py for MovementController class
5. Add E2E test suite (test_e2e_workflow.py) for critical paths

## Documentation

**Accuracy:** **CRITICAL - docs severely outdated**

Mismatches between docs and reality:
1. **README.md**: Still describes AutoHotkey v2 file structure (lines 8-18), not Python project
2. **project-overview-pdr.md**: Says "Phase 1 - 70% complete" (line 229) but codebase has:
   - Phase 1 ✓: core (config, state, logger)
   - Phase 2 ✓: input (daemon, hotkeys, backends, movement, scroll)
   - Phase 3 ✓: position memory, audio feedback
   - Phase 4 ✓: GUI (main_window.py with 6 tabs, hotkeys_tab, profiles_tab, key_capture, status_indicator)
   - Phase 5 partial: Wayland backend exists (backends/wayland_backend.py)
3. **system-architecture.md**: Describes "Phase 1 Core + Scroll Support" but GUI layer fully implemented
4. **ROADMAP_SettingsGUI.md**: Shows features as "not implemented yet" (lines 17-18: import/export) but contradicts checked boxes
5. **HOTKEYS.md** missing entirely (referenced in git status but not in docs/)

**Staleness:**
- Last updated: 2026-01-17/18 (PDR line 4, architecture line 5)
- Git shows 6b8f73d (2026-02-08) with profiles save/load, monitor cycling, status indicator configs
- Gap: ~3 weeks of development undocumented (5 phases worth of features)

**Recommendations:**
1. **URGENT**: Rewrite README.md for Python/Linux project (remove AutoHotkey references)
2. Update project-overview-pdr.md to reflect Phases 1-4 complete, 5 partial, 6 planned
3. Update system-architecture.md with actual daemon + GUI + backends architecture
4. Create codebase audit report (document actual file structure vs planned)
5. Add CHANGELOG.md to track feature additions (missing from docs/)
6. Add HOTKEYS.md back (or document why removed)
7. Mark completed items in roadmaps (don't show "not implemented" if code exists)

## Packaging

**Dependencies:** 7 runtime + 4 dev (pyproject.toml lines 22-38)
- Runtime: pynput, PyGObject, pulsectl, python-xlib, evdev, pystray, Pillow
- Dev: pytest, pytest-cov, ruff, mypy
- All installed successfully (uv pip list shows all present)

**Build Config:**
- Hatchling build system (lines 44-51)
- Entry point: `mouse-on-numpad` → `mouse_on_numpad.main:main` (line 41)
- Wheel packages: src/mouse_on_numpad (line 48)
- Python >=3.10 (line 7)

**Issues:**
1. **Duplicate pytest-cov**: Listed in both dev optional-dependencies (line 34) and dependency-groups (line 74) - redundant
2. **Missing GTK4**: PyGObject listed but GTK4 not specified as system dependency (ui/main_window.py requires GTK 4.0 line 5)
3. **uv.lock missing from pyproject.toml**: uv.lock in git status but no reference in build config
4. **No install instructions**: installation.md exists but README.md doesn't link to it
5. **tray_icon.py deleted**: src/mouse_on_numpad/ui/tray_icon.py deleted (git status line 41) but daemon.py imports from .tray_icon (line 14) - build will fail

**Recommendations:**
1. Remove pytest-cov duplication (keep in dev optional-dependencies only)
2. Add system dependencies section to README (GTK4, udev for uinput, ydotool as fallback)
3. Resolve tray_icon import (either restore file or update daemon.py import)
4. Add [project.urls] section with documentation/homepage/issues
5. Consider lockfile-based installs (reference uv.lock in docs)
6. Test actual package install: `uv pip install -e .` then `mouse-on-numpad --status`

## Security

**Privilege Model:** User-space with graceful degradation
- Daemon runs as unprivileged user (no sudo/root)
- uinput access: Requires /dev/uinput write permission (input group) OR udev rule
- Fallback: ydotool subprocess calls if uinput unavailable (daemon.py lines 48-69)
- Input validation: evdev keycodes only (no arbitrary commands)

**Permission Checks:**
```python
# uinput_mouse.py lines 7-11 (via grep output)
if not os.path.exists("/dev/uinput"):
    raise OSError("/dev/uinput not found")
if not os.access("/dev/uinput", os.W_OK):
    raise PermissionError("Add user to 'input' group: sudo usermod -aG input $USER")
```

**Input Validation:**
- Hotkey capture: GDK keyval → evdev keycode conversion with validation (key_capture_button.py lines 36-40)
- Conflict detection: Prevents duplicate key assignments (test_backends.py confirms validation)
- Config validation: JSON schema with type checking (ConfigManager responsibility)

**Issues:**
- **None found** - security model is sound

**Strengths:**
1. No privilege escalation (user group membership sufficient)
2. Clear error messages guide users to correct permissions
3. Fallback to ydotool prevents hard failure
4. No shell injection risks (subprocess.run with explicit args)
5. Config files XDG-compliant (~/.config/mouse-on-numpad/)

**Recommendations:**
1. Document udev rule in installation.md for uinput access (if not already present)
2. Add security policy (SECURITY.md) for responsible disclosure
3. Consider AppArmor/SELinux profiles for packaging phase

## UX & Features

**Implemented vs Planned:** Major discrepancy

Planned (from project-overview-pdr.md):
- Phase 1 ✓: Config, state, logging
- Phase 2 ⏳: Input layer
- Phase 3 ⏳: Position memory, audio
- Phase 4 ⏳: GUI
- Phase 5 ⏳: Wayland
- Phase 6 ⏳: Packaging

Actually Implemented (from codebase):
- Phase 1 ✓: core/ complete (config.py, state_manager.py, error_logger.py)
- Phase 2 ✓: input/ complete (daemon.py, hotkey_manager.py, mouse_controller.py, scroll_controller.py, movement_controller.py)
- Phase 3 ✓: input/ complete (position_memory.py, audio_feedback.py, monitor_manager.py)
- Phase 4 ✓: ui/ complete (main_window.py with 6 tabs, hotkeys_tab.py, profiles_tab.py, key_capture_button.py, status_indicator.py, keycode_mappings.py)
- Phase 5 ✓: backends/ complete (base.py, x11_backend.py, wayland_backend.py, evdev_backend.py, uinput_mouse.py)
- Phase 6 ⏳: Not started (no RPM/DEB/AUR packages yet)

Recent commits show:
- 6b8f73d: Profile configuration save/load (Phase 5 addition)
- 52fcb98: 4 color theme presets for status indicator
- ef5f6e6: Position, size, opacity config for status
- 13f2659: Alt+Numpad9 monitor cycling
- 60ad622: GTK 3/4 conflict fix (removed TrayIcon import)

**Feature Gaps:**
1. Import/Export settings (UI buttons present but functionality NYI per ROADMAP line 17-18)
2. Packaging distribution (Phase 6 not started)
3. TrayIcon removed (git status shows deleted file, was this intentional?)

**GUI Completeness:** 6 tabs implemented
- Tab 1: Movement (speed, acceleration) ✓
- Tab 2: Audio (volume, feedback) ✓
- Tab 3: Hotkeys (interactive capture, conflict detection) ✓
- Tab 4: Appearance (themes, status indicator) ✓
- Tab 5: Profiles (save/load/switch) ✓
- Tab 6: Advanced (config tweaks) ✓

ROADMAP_SettingsGUI.md shows extensive checklist with many items checked, contradicts "not implemented" notes.

**Recommendations:**
1. Implement import/export or remove UI buttons (avoid "grayed out forever" anti-pattern)
2. Update all docs to reflect actual phase completion
3. Clarify TrayIcon removal (intentional UX decision or WIP?)
4. Create user-facing feature list (separate from dev roadmap)
5. Add keyboard shortcuts documentation (HOTKEYS.md or in GUI help)

## Priority Matrix

| Area | Issue | Severity | Effort | Impact |
|------|-------|----------|--------|--------|
| Docs | README describes AutoHotkey not Python | Critical | 2h | High |
| Docs | PDR says 70% but 80% complete | Critical | 3h | High |
| Packaging | tray_icon import broken | High | 1h | High |
| Testing | No daemon integration tests | Medium | 4h | Medium |
| UX | Import/export UI buttons do nothing | Medium | 6h | Medium |
| Packaging | pytest-cov duplication | Low | 5m | Low |
| Testing | Missing profiles tests | Medium | 3h | Medium |
| Docs | CHANGELOG.md missing | Low | 2h | Medium |
| Docs | System arch outdated | Medium | 2h | Medium |
| Security | No SECURITY.md policy | Low | 1h | Low |

**Severity scale:** Critical = blocks usage, High = breaks build/trust, Medium = limits adoption, Low = polish
**Effort scale:** Time to fix
**Impact scale:** Effect on users/contributors

## Top Recommendations

1. **Fix README.md immediately** - First thing new users see, currently describes wrong project entirely

2. **Resolve tray_icon.py deletion** - Either restore file or update daemon.py import (build currently broken)

3. **Update project-overview-pdr.md phase status** - Phases 1-5 are 80%+ complete, not 70% Phase 1

4. **Add daemon integration tests** - Critical path (daemon lifecycle, signal handling, evdev → state → action) untested

5. **Implement or remove import/export** - UX anti-pattern to show non-functional buttons

6. **Create CHANGELOG.md** - Document 3 weeks of features (profiles, themes, monitor cycling, status config)

7. **Add system dependencies to README** - Users need GTK4, uinput/input group, or ydotool

8. **Test profiles functionality** - New feature (6b8f73d) has no tests

9. **Update system-architecture.md** - Describe actual daemon + GUI + backends architecture, not Phase 1 design

10. **Add E2E test suite** - Validate full workflow (key press → mouse action → state → GUI update)

---

**Overall Assessment:** Project is substantially more complete than documentation suggests (80% vs documented 70% Phase 1). Core functionality solid, security sound, testing reasonable. Primary issues are documentation staleness and minor packaging gaps. Strong foundation for Phase 6 (distribution packaging).
