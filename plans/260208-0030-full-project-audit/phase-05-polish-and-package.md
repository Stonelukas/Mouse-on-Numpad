# Phase 5: Polish & Package

## Context
- Parent plan: [plan.md](plan.md)
- Depends on: [Phase 3](phase-03-update-documentation.md), [Phase 4](phase-04-expand-test-coverage.md)
- Source: Both audit reports

## Overview
- **Priority:** Medium
- **Effort:** 4h
- **Status:** completed
- **Description:** Code quality polish, packaging fixes, and minor UX improvements

## Key Insights
- Magic numbers throughout daemon.py (keycodes, multipliers) — extract to constants
- Config reload polls every 1s — wasteful, use inotify or signals
- Log flush on every write — buffer non-critical levels
- Import/export buttons in GUI do nothing — implement or remove
- pyproject.toml missing `[project.urls]` section
- No SECURITY.md policy

## Requirements
- Zero magic numbers in hot paths
- Config reload uses efficient mechanism (not polling)
- Packaging metadata complete (urls, classifiers)
- No non-functional UI elements

## Related Code Files
- `src/mouse_on_numpad/daemon.py` (or refactored daemon/) — extract constants
- `src/mouse_on_numpad/input/movement_controller.py` — replace config reload loop
- `src/mouse_on_numpad/core/error_logger.py` — optimize flush strategy
- `src/mouse_on_numpad/ui/profiles_tab.py` — implement or remove import/export
- `pyproject.toml` — add project.urls, fix classifiers

## Implementation Steps

### Code Quality
<!-- Updated: Validation Session 1 - Keep polling, remove import/export buttons -->
1. Extract all magic numbers to named constants (keycodes → `KEYCODE_*`, multipliers → `*_MULTIPLIER`)
2. ~~Replace config reload loop~~ — DEFERRED (polling acceptable per validation)
3. Buffer non-critical log levels (DEBUG, INFO) — flush only on ERROR/WARNING
4. Add subprocess error handling for ydotool/xdotool calls (check=True or handle returncode)
5. Add input validation for numeric config values (speed, acceleration ranges)

### Packaging
6. Add `[project.urls]` to pyproject.toml (homepage, docs, issues)
7. Update classifiers to reflect GTK4 (not just GTK)
8. Create SECURITY.md with disclosure policy
9. Verify `uv run hatchling build` produces valid wheel

### UX
<!-- Updated: Validation Session 1 - Remove non-functional buttons per user decision -->
10. Remove import/export buttons from profiles_tab.py (YAGNI — re-add when feature built)
11. Add keyboard shortcut help (tooltip or help tab)

## Todo List
- [ ] Extract magic numbers to named constants
- [ ] ~~Replace config reload polling~~ DEFERRED
- [ ] Optimize log flush strategy
- [ ] Add subprocess error handling
- [ ] Add config value range validation
- [ ] Add project.urls to pyproject.toml
- [ ] Create SECURITY.md
- [ ] Remove import/export buttons from profiles_tab.py
- [ ] Verify wheel build

## Success Criteria
- `ruff check src/` clean
- `mypy --strict src/` passes
- No magic numbers in daemon code
- Config reload uses signal/inotify (not timer loop)
- `uv run hatchling build` succeeds
- All UI buttons are functional or removed

## Risk Assessment
- **Low**: Polish changes, no architectural impact
- Signal-based config reload needs testing on all target distros
- Import/export implementation adds scope — may defer to future phase

## Security Considerations
- SECURITY.md establishes responsible disclosure process
- Subprocess check=True prevents silent command failures
- Config validation prevents invalid numeric values (negative speed, etc.)

## Next Steps
- After this phase, project is ready for distribution packaging (Phase 6 from original roadmap)
- Consider CI/CD setup (GitHub Actions) for automated testing
