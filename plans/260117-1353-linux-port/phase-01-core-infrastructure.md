---
phase: 1
title: "Core Infrastructure"
status: completed
priority: P1
effort: 6h
completion: 100%
completed: 2026-01-17
---

# Phase 1: Core Infrastructure

## Context

- Parent: [plan.md](./plan.md)
- Source: [LINUX_PORT_PLAN.md](../../LINUX_PORT_PLAN.md) Section 3 Phase 1
- Dependencies: None (foundation phase)

## Overview

Establish Python project structure and implement core utilities: configuration management, state management, logging, and theme system.

## Key Insights

- Use uv package manager (modern Python tooling)
- XDG config directories for Linux compliance
- Thread-safe state management for GUI updates
- Observable pattern enables reactive UI

## Requirements

### Functional
- JSON config persistence at ~/.config/mouse-on-numpad/
- Global state with change notifications
- Structured logging with rotation
- 7 color themes from Windows version

### Non-Functional
- Thread-safe state access
- Config backup before write
- XDG Base Directory compliance

## Architecture

```
src/
  __init__.py
  main.py              # Entry point
  core/
    __init__.py
    config.py          # ConfigManager (JSON)
    state_manager.py   # StateManager (observable)
    theme_manager.py   # ThemeManager
    error_logger.py    # ErrorLogger (Python logging)
```

### Config Schema (config.json)
```json
{
  "movement": {
    "base_speed": 10,
    "acceleration": 1.5,
    "curve": "exponential"
  },
  "audio": {
    "enabled": true,
    "volume": 50
  },
  "theme": "dark",
  "status_bar": {
    "enabled": true,
    "position": "top-right"
  }
}
```

## Related Code Files

### Create
- `src/__init__.py`
- `src/main.py`
- `src/core/__init__.py`
- `src/core/config.py`
- `src/core/state_manager.py`
- `src/core/theme_manager.py`
- `src/core/error_logger.py`
- `pyproject.toml`
- `tests/test_config.py`
- `tests/test_state_manager.py`

## Implementation Steps

1. Initialize project with pyproject.toml (uv)
   - Define metadata, dependencies, entry points
   - Configure pytest, ruff, mypy

2. Create ConfigManager class
   - Load/save JSON from XDG path
   - Implement backup system (copy before write)
   - Add defaults and validation
   - Support nested access (config.get("movement.speed"))

3. Create StateManager class
   - Define state schema: enabled, mode, current_position
   - Implement observer pattern (subscribe/notify)
   - Add thread locks for concurrent access
   - Include toggle methods

4. Create ThemeManager class
   - Port 7 themes from Windows (Dark, Light, Ocean, etc.)
   - Store in data/themes.json
   - Provide get_color(element) API

5. Create ErrorLogger class
   - Wrap Python logging module
   - Configure rotating file handler
   - Set levels: DEBUG, INFO, WARNING, ERROR
   - Log to ~/.local/share/mouse-on-numpad/logs/

6. Write unit tests
   - Test config load/save/defaults
   - Test state toggle and notifications
   - Test theme loading

## Todo List

- [x] Create pyproject.toml with uv config
- [x] Implement ConfigManager with JSON persistence
- [x] Implement StateManager with observer pattern
- [x] Implement ThemeManager with 7 themes (DEFERRED per validation - GTK system theme only)
- [x] Implement ErrorLogger with rotation
- [x] Create src/main.py entry point
- [x] Write pytest tests for core modules (37 tests, 79% coverage)
- [x] Verify XDG paths work correctly

## Issues Resolved

- [x] pytest-cov dependency resolved (uv handles via pyproject.toml)
- [x] Package installed via uv (entry point configured)
- [x] Ruff linting errors fixed
- [x] StateManager callback exception logging added
- [x] Toggle race condition handled with thread locks
- [x] Log flush optimization applied

**All critical items resolved. Phase ready for Phase 2 dependency chain.**

## Success Criteria - ALL MET

- [x] `uv run python -m mouse_on_numpad` starts without error (VERIFIED)
- [x] Config file created at ~/.config/mouse-on-numpad/config.json (VERIFIED)
- [x] State changes trigger registered callbacks (VERIFIED)
- [x] Theme system deferred per validation (GTK system theme only - Phase 4)
- [x] Log files rotate properly (VERIFIED)
- [x] pytest passes with 79% coverage on core/ (37 tests all passing)

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| XDG path issues on non-standard setups | Low | Fallback to ~/.mouse-on-numpad |
| Thread safety bugs | Medium | Use threading.Lock, write tests |
| JSON schema changes break config | Low | Version config, migration helper |

## Security Considerations

- Config files: user-only read/write (0600)
- Log files: no sensitive data logged
- No credentials stored

## Next Steps

After Phase 1 complete:
- Phase 2: Input Control Layer (depends on StateManager)
