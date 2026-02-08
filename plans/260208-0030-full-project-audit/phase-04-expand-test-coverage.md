# Phase 4: Expand Test Coverage

## Context
- Parent plan: [plan.md](plan.md)
- Depends on: [Phase 2](phase-02-refactor-god-classes.md) (test refactored code)
- Source: [Project Health Audit](reports/project-health-audit.md)

## Overview
- **Priority:** High
- **Effort:** 6h
- **Status:** completed
- **Description:** Fill test gaps — daemon lifecycle, profiles, movement controller, and E2E workflow

## Key Insights
- Current: 191 test functions, 12 test files — good foundation
- Missing: daemon integration tests, profiles tests, movement_controller tests
- No E2E tests for full workflow (key press → mouse action → state update)
- tray_icon tests irrelevant if tray_icon removed
- Backends well-tested with mocks

## Requirements
- Target 80%+ code coverage (currently ~60% estimated)
- All critical paths tested: daemon lifecycle, hotkey dispatch, movement
- Profile save/load/switch tested
- No mocks that bypass real logic (test real behavior where possible)

## Related Code Files

### New test files to create
- `tests/test_daemon_lifecycle.py` — start/stop/signal handling
- `tests/test_profiles.py` — save/load/switch/delete profiles
- `tests/test_movement_controller.py` — direction start/stop/acceleration
- `tests/test_e2e_workflow.py` — integrated key → action → state flow

### Existing test files (reference)
- `tests/test_config.py` — 11 tests
- `tests/test_state_manager.py` — 18 tests
- `tests/test_error_logger.py` — 8 tests
- Other test files for backends, hotkeys, scroll, etc.

## Implementation Steps
1. Create `tests/test_daemon_lifecycle.py`: test init, start, stop, signal handling, cleanup
2. Create `tests/test_profiles.py`: test save, load, switch, delete, conflict detection
3. Create `tests/test_movement_controller.py`: test direction queuing, acceleration, stop_all
4. Create `tests/test_e2e_workflow.py`: test key event → daemon dispatch → mouse action → state change
5. Run full suite: `uv run pytest --cov=src/mouse_on_numpad --cov-report=term-missing`
6. Identify remaining gaps from coverage report
7. Add targeted tests for uncovered branches

## Todo List
- [ ] Write daemon lifecycle tests
- [ ] Write profiles tests
- [ ] Write movement controller tests
- [ ] Write E2E workflow tests
- [ ] Achieve 80%+ coverage
- [ ] Fix any failing tests

## Success Criteria
- `uv run pytest` passes with 80%+ coverage
- Daemon start/stop/signal handling tested
- Profile CRUD operations tested
- Movement acceleration curve tested
- At least 1 E2E test covering key → action → state

## Risk Assessment
- **Medium**: Daemon tests need evdev mocking (device access)
- **Mitigation**: Use `unittest.mock.patch` for /dev/uinput and evdev devices
- E2E tests may be flaky if timing-dependent — use deterministic delays

## Next Steps
- Coverage report feeds back into Phase 5 (polish) for any remaining gaps
