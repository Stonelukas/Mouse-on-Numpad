# Code Standards & Guidelines

**Document Version:** 1.0
**Updated:** 2026-01-17
**Applies To:** Python codebase (src/mouse_on_numpad/)

---

## Overview

These standards ensure code quality, maintainability, and consistency across the Mouse on Numpad project. All code in `src/mouse_on_numpad/` must follow these guidelines.

**Key Principles:**
- **YAGNI:** You Aren't Gonna Need It (don't over-engineer)
- **KISS:** Keep It Simple, Stupid (clarity over cleverness)
- **DRY:** Don't Repeat Yourself (reusable components)

---

## Python Style & Formatting

### File Structure

```python
"""Module docstring - what does this module do.

Module-level documentation describing the module's purpose,
main classes/functions, and usage examples.
"""

from __future__ import annotations

import copy
import json
import os
from pathlib import Path
from typing import Any, Callable
import logging

from .config import ConfigManager  # Relative imports after external


class MyClass:
    """Class docstring."""
    pass


def my_function() -> None:
    """Function docstring."""
    pass
```

**Rules:**
- Module docstring first
- `from __future__ import annotations` for forward references
- External imports, then relative imports
- One blank line between imports and code
- Two blank lines between top-level definitions

### Naming Conventions

| Element | Format | Example |
|---------|--------|---------|
| Modules | snake_case | config.py, state_manager.py |
| Classes | PascalCase | ConfigManager, StateManager |
| Functions | snake_case | load_config(), toggle_state() |
| Constants | UPPER_SNAKE_CASE | MAX_RETRIES, DEFAULT_TIMEOUT |
| Private methods | _snake_case | _load(), _notify() |
| Type aliases | PascalCase | MouseMode, StateDict |

### Type Hints

**Mandatory:** All function signatures must have type hints.

```python
# Good: Clear parameter and return types
def get_config(key: str, default: Any = None) -> Any:
    """Get config value with optional default."""
    return self._config.get(key, default)

# Good: Complex types using typing module
from typing import Callable

def subscribe(key: str, callback: Callable[[str, Any], None]) -> None:
    """Subscribe to state changes."""
    pass

# Good: Optional type
def load(path: Path | None = None) -> dict[str, Any]:
    """Load config from path or use default."""
    pass

# Bad: Missing return type
def load(self, path=None):
    pass

# Bad: Using 'any' instead of specific type
def process(self, data: any) -> any:
    pass
```

**Type Checking:**
- Project uses mypy in strict mode
- `mypy --strict src/` must pass
- Use `# type: ignore` only with justification comment

### Line Length

- **Maximum:** 100 characters (ruff configuration)
- **Exceptions:** URLs, long strings, docstrings may exceed
- **Tool:** `ruff format` auto-wraps

```python
# Good: Line under 100 chars
def complex_function(param1: str, param2: int, param3: bool) -> dict:
    pass

# Good: Wrapped for clarity
def very_long_function(
    parameter_one: str,
    parameter_two: int,
    parameter_three: bool,
) -> dict[str, Any]:
    pass
```

### Documentation Strings (Docstrings)

**Format:** Google-style docstrings with type hints.

```python
def get(self, key: str, default: Any = None) -> Any:
    """Get configuration value using dot notation.

    Args:
        key: Config key using dot notation (e.g., 'movement.base_speed')
        default: Value returned if key not found (default: None)

    Returns:
        Config value if found, else default value

    Raises:
        KeyError: If key is invalid format

    Example:
        >>> config.get("movement.base_speed")
        10
        >>> config.get("nonexistent", default=None)
        None
    """
```

**Docstring Elements:**
- One-line summary (imperative mood)
- Extended description (if needed)
- Args section with types and descriptions
- Returns section with type and description
- Raises section (if applicable)
- Example section (for public APIs)

### Comments

**Philosophy:** Code should be self-documenting. Comments explain *why*, not *what*.

```python
# Bad: Redundant comment
counter += 1  # Increment counter

# Good: Explains intent
# Skip first item since CSV headers are in row 0
data = rows[1:]

# Good: Explains non-obvious behavior
# Use RLock instead of Lock to allow recursive acquisition
# in callbacks that modify state
_lock = threading.RLock()

# Good: TODOs with context
# TODO: Phase 2 - Add audio feedback for state toggle
# Current implementation is silent
```

---

## Architecture & Design

### Module Organization

**Rule:** Keep modules under 200 lines for optimal context.

```
src/mouse_on_numpad/
├── core/              # Core utilities
│   ├── config.py      # ConfigManager only (~160 lines)
│   ├── state_manager.py # StateManager only (~190 lines)
│   └── error_logger.py # ErrorLogger only (~140 lines)
├── input/             # Phase 2 - Input handlers
│   ├── handler.py
│   └── numpad_mapper.py
├── audio/             # Phase 3 - Audio system
│   └── audio_controller.py
├── gui/               # Phase 4 - GTK application
│   ├── main_window.py
│   └── dialogs/
└── main.py            # CLI entry point
```

**When to Split:** If a module exceeds 200 lines:
1. Identify logical subsystems
2. Create new module for one subsystem
3. Import and re-export in parent `__init__.py`

Example (ConfigManager grows too large):
```python
# Before: config.py (300 lines) ❌

# After:
# config.py (90 lines) - Main class
# config_schema.py (50 lines) - Validation
# config_xdg.py (40 lines) - XDG path logic
```

### Error Handling

**Strategy:** Handle predictable errors, fail fast on unexpected.

```python
# Good: Handle expected failure modes
try:
    with open(self._config_file, encoding="utf-8") as f:
        self._config = json.load(f)
except FileNotFoundError:
    logger.info("Config not found, creating defaults")
    self._config = copy.deepcopy(self.DEFAULT_CONFIG)
    self._save()
except json.JSONDecodeError as e:
    logger.error("Config corrupted: %s", e)
    self._config = copy.deepcopy(self.DEFAULT_CONFIG)
    self._save()
except OSError as e:
    # Unexpected: Permission denied, disk issues, etc.
    logger.error("Cannot read config: %s", e)
    raise  # Don't hide permission errors

# Bad: Too broad, hides bugs
except Exception:
    pass  # Silent failure

# Bad: Raises but doesn't log context
except Exception as e:
    raise  # Lost context
```

### Thread Safety

**Rules:**
1. All mutable state must be protected by a lock
2. Lock must be acquired for entire read-modify-write sequence
3. Don't hold locks across I/O operations (reading files, network)
4. Document lock strategy in class docstring

```python
class StateManager:
    """Thread-safe observable state manager.

    Uses RLock to protect state modifications. All state changes are
    atomic and notify observers after releasing the lock to prevent
    deadlock.
    """

    def __init__(self) -> None:
        self._lock = threading.RLock()
        self._state = State()
        self._subscribers: dict[str, list[Callable]] = {}

    def toggle(self) -> bool:
        """Toggle mouse mode and notify subscribers.

        Returns:
            New mouse mode after toggle
        """
        # Acquire lock for state modification
        with self._lock:
            # Toggle state
            if self._state.mouse_mode == MouseMode.ENABLED:
                self._state.mouse_mode = MouseMode.DISABLED
            else:
                self._state.mouse_mode = MouseMode.ENABLED

            # Capture new value inside lock
            new_mode = self._state.mouse_mode
            enabled = new_mode == MouseMode.ENABLED

        # Notify OUTSIDE lock (prevents deadlock)
        self._notify("mouse_mode", new_mode)
        return enabled
```

### Testing Strategy

**Coverage Target:** 80%+ for all modules

```python
# test_config.py
import pytest
from pathlib import Path
from mouse_on_numpad.core.config import ConfigManager


class TestConfigManager:
    """Test ConfigManager functionality."""

    def test_load_creates_defaults(self, tmp_path: Path) -> None:
        """Test that missing config creates defaults."""
        config = ConfigManager(config_dir=tmp_path)
        assert config.get("movement.base_speed") == 10

    def test_nested_access(self, tmp_path: Path) -> None:
        """Test dot-notation nested key access."""
        config = ConfigManager(config_dir=tmp_path)
        config.set("movement.base_speed", 15)
        assert config.get("movement.base_speed") == 15

    def test_save_backup(self, tmp_path: Path) -> None:
        """Test that config.json.bak is created."""
        config = ConfigManager(config_dir=tmp_path)
        config.set("audio.volume", 75)
        assert (tmp_path / "config.json.bak").exists()
```

**Test File Naming:**
- `test_*.py` for test files
- Test class names: `Test<Module>`
- Test method names: `test_<functionality>_<scenario>`

---

## Python Version & Dependencies

### Minimum Version: Python 3.10

**Use features from 3.10+:**
- Type union with `|` instead of `Union`
- Match statements (3.10)
- Structural pattern matching (3.10)
- Positional-only parameters with `/` (3.8+)

```python
# Good: Python 3.10+ union syntax
def process(data: dict[str, Any] | None) -> str:
    pass

# Bad: Python 3.8 syntax (outdated)
from typing import Union
def process(data: Union[dict, None]) -> str:
    pass
```

### Dependencies

**Core Runtime:**
- pynput (input capture)
- PyGObject (GTK bindings)
- pulsectl (audio control)
- python-xlib (X11 protocol)

**Development:**
- pytest (testing)
- pytest-cov (coverage)
- ruff (formatting & linting)
- mypy (type checking)

**Adding New Dependencies:**
1. Update `pyproject.toml` dependencies
2. Document why it's needed in PR description
3. Check for LGPL/GPL compatibility
4. Add import to `src/mouse_on_numpad/core/__init__.py` if core utility

---

## Linting & Formatting

### Ruff Configuration

```toml
[tool.ruff]
line-length = 100
target-version = "py310"

[tool.ruff.lint]
select = ["E", "F", "W", "I", "B", "C4", "UP"]  # Error, Fix, Warn, Import, etc.
ignore = ["E501"]  # Line too long (handled by formatter)
```

**Before Committing:**
```bash
# Format code
ruff format src/

# Check for linting issues
ruff check --fix src/

# Type check
mypy --strict src/
```

### Pre-commit Checks

**Required before committing:**
1. `ruff format` passes
2. `ruff check` passes
3. `mypy --strict` passes
4. `pytest` passes

---

## Security Guidelines

### Data Handling

**No Credentials in Code:**
```python
# Bad: Hard-coded credentials
PASSWORD = "secret123"  # ❌ Never do this

# Good: Load from environment
import os
password = os.environ.get("APP_PASSWORD")
```

**File Permissions:**
```python
# Good: Secure file permissions
config_file.chmod(0o600)  # Owner read/write only
log_dir.chmod(0o700)      # Owner read/write/execute only

# Bad: World-readable sensitive files
config_file.chmod(0o644)  # ❌ Others can read
```

**Input Validation:**
```python
# Good: Whitelist validation
ALLOWED_KEYS = {"movement", "audio", "status_bar"}
if key not in ALLOWED_KEYS:
    raise ValueError(f"Invalid key: {key}")

# Bad: Blacklist (incomplete)
if key not in ["password", "secret"]:
    process(key)  # Still allows other sensitive keys
```

### Logging Best Practices

**Never Log Sensitive Data:**
```python
# Bad: Logs password
logger.info(f"Login attempt: {username} {password}")

# Good: Only logs safe information
logger.info(f"Login attempt for user: {username}")
logger.debug(f"Password hash: {hash(password)}")
```

---

## Git Commit Guidelines

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:** feat, fix, docs, refactor, test, chore, perf, style

**Example:**
```
feat(state-manager): add thread-safe state notifications

- Implement observer pattern for state changes
- Add RLock protection for state modifications
- Notifications occur outside lock to prevent deadlock
- Add 18 new tests for thread safety

Closes #42
```

**Rules:**
- Use present tense ("add" not "added")
- Focus on *why*, not *what*
- Reference issue numbers
- Keep subject under 50 characters
- Separate subject from body with blank line

---

## Code Review Checklist

Before submitting PR, verify:

- [ ] Type hints on all function signatures
- [ ] Docstrings on all public functions/classes
- [ ] No linting errors (`ruff check`)
- [ ] No type errors (`mypy --strict`)
- [ ] Tests pass (`pytest`)
- [ ] Code coverage >80% for new code
- [ ] No hard-coded credentials or secrets
- [ ] No "TODO" comments without context/phase
- [ ] Follows thread-safety guidelines
- [ ] Error handling is explicit (no broad except)
- [ ] Log messages are informative
- [ ] No commented-out code (except temporary debug)

---

## Common Patterns

### Observer Pattern (State Changes)

```python
# Register observer
def handle_state_change(key: str, value: Any) -> None:
    logger.info(f"State {key} changed to {value}")

state_mgr.subscribe("mouse_mode", handle_state_change)

# Trigger notification
state_mgr.toggle()  # Calls handle_state_change("mouse_mode", ...)
```

### Configuration Access

```python
# Get with default
speed = config.get("movement.base_speed", default=10)

# Set nested value
config.set("audio.volume", 75)

# Get entire config (deep copy)
all_config = config.get_all()
```

### Error Logging

```python
from mouse_on_numpad.core import ErrorLogger

logger = ErrorLogger()

try:
    dangerous_operation()
except SpecificError as e:
    logger.error("Operation failed: %s", e, exc_info=True)
except Exception as e:
    logger.exception("Unexpected error: %s", e)
```

---

## Known Limitations & Improvements

### Current Limitations
- XDG fallback uses simple `os.environ.get()` (consider platformdirs)
- No hot config reload (would need async watcher)
- Logging flushes after every call (impacts performance)

### Planned Improvements (Future Phases)
1. Switch to `platformdirs` for better XDG handling
2. Implement async state change notifications
3. Reduce logging I/O by buffering non-critical messages
4. Add dataclass validation for config schema
5. Implement config hot-reload on file change

---

## References

- **Python Style:** PEP 8, PEP 484 (type hints)
- **Testing:** pytest official docs
- **Architecture:** `docs/system-architecture.md`
- **Development Rules:** `CLAUDE.md`

---

**Standards Version:** 1.0
**Last Updated:** 2026-01-17
**Phase:** Core Infrastructure (Phase 1)
