# Phase 1: Fix Build Blockers

## Context
- Parent plan: [plan.md](plan.md)
- Source: [Code Quality Audit](reports/code-quality-audit.md), [Project Health Audit](reports/project-health-audit.md)

## Overview
- **Priority:** Critical
- **Effort:** 4h (expanded: tray icon rewrite added per validation)
- **Status:** completed
- **Description:** Fix issues that prevent the project from building and running

## Key Insights
- `tray_icon.py` deleted (git status shows `D src/mouse_on_numpad/ui/tray_icon.py`) but `daemon.py` line 14 still imports it
- Recent commit 60ad622 removed TrayIcon import to prevent GTK 3/4 conflict — but root `tray_icon.py` may still have import issues
- pytest-cov listed in both `[project.optional-dependencies]` and `[dependency-groups]` in pyproject.toml
- `callable` (lowercase) used in `profiles_tab.py:165` instead of `Callable` — type error

## Requirements
- Build must succeed: `uv pip install -e .` → `mouse-on-numpad --status` works
- `uv run pytest` passes without import errors
- No type errors from lowercase `callable`

## Related Code Files
- `src/mouse_on_numpad/daemon.py` — remove or update tray_icon import
- `src/mouse_on_numpad/tray_icon.py` — check if root-level copy exists and is valid
- `src/mouse_on_numpad/ui/tray_icon.py` — deleted, confirm intentional
- `pyproject.toml` — fix pytest-cov duplication
- `src/mouse_on_numpad/ui/profiles_tab.py` — fix `callable` → `Callable`

## Implementation Steps
<!-- Updated: Validation Session 1 - Tray icon: restore with GTK4-native approach -->
1. Check if `src/mouse_on_numpad/tray_icon.py` (root-level) exists and what it exports
2. Rewrite tray_icon using GTK4-native approach (Gtk.StatusIcon or Gio.Notification) — no pystray
3. Update daemon.py import to use new GTK4 tray icon
4. Remove `pystray` and `Pillow` from pyproject.toml dependencies (no longer needed)
5. Fix `profiles_tab.py:165` — change `callable` to `Callable[[str], None]`
6. Remove duplicate `pytest-cov` from `[dependency-groups]` in `pyproject.toml`
7. Run `uv pip install -e .` and verify `mouse-on-numpad --status` works
8. Run `uv run pytest` and confirm all tests pass

## Todo List
- [ ] Rewrite tray_icon.py with GTK4-native approach
- [ ] Update daemon.py to use new tray icon
- [ ] Remove pystray and Pillow from pyproject.toml
- [ ] Fix lowercase `callable` type hint (profiles_tab.py)
- [ ] Remove pytest-cov duplication (pyproject.toml)
- [ ] Verify build succeeds
- [ ] Verify tests pass

## Success Criteria
- `uv pip install -e .` completes without error
- `mouse-on-numpad --status` runs
- `uv run pytest` passes
- `ruff check src/` clean

## Risk Assessment
- **Low risk**: These are isolated fixes, no architectural changes
- Removing tray_icon import might disable tray functionality — confirm with user if tray is needed

## Next Steps
- Unblocks Phase 2 (refactoring) and Phase 3 (docs)
