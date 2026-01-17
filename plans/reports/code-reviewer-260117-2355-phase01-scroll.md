# Code Review: Phase 1 Scroll Support

## Scope
- Files reviewed:
  - `src/mouse_on_numpad/core/config.py` (scroll defaults)
  - `src/mouse_on_numpad/input/scroll_controller.py` (new)
  - `src/mouse_on_numpad/input/__init__.py` (exports)
  - `src/mouse_on_numpad/daemon.py` (integration)
- Lines analyzed: ~480
- Review focus: Scroll feature implementation, architecture, YAGNI/KISS/DRY
- Plan: `plans/260117-2341-windows-feature-parity/phase-01-scroll-support.md`

## Overall Assessment

**Score: 7.5/10**

Clean implementation matching Windows behavior. ScrollController mirrors MovementController architecture correctly. Thread safety handled properly. Several critical issues around duplicate methods, scroll direction mapping mismatch, and missing thread cleanup.

## Critical Issues (MUST FIX)

### 1. Duplicate `reload()` Method in ConfigManager
**File:** `src/mouse_on_numpad/core/config.py`
**Lines:** 120, 168

Two identical `reload()` methods defined. Python keeps last definition only.

**Fix:**
```python
# Remove lines 168-170 (duplicate)
```

### 2. Scroll Direction Mapping Inconsistency
**File:** Plan says `73: ("left",)` but code has `73: ("right",)`

**Phase plan (line 19):**
```python
73: ("left",),    # KEY_KP9 - scroll left
```

**Actual daemon.py (line 100):**
```python
73: ("right",),   # KEY_KP9 - scroll right (horizontal)
```

Windows version: Numpad 9 = scroll RIGHT, Numpad 3 = scroll LEFT per plan context.

**Current mapping is CORRECT for Windows parity**, but plan doc is wrong.

**Fix:** Update plan doc or verify with Windows version which direction KP9 should be.

### 3. Missing Thread Cleanup on Daemon Stop
**File:** `src/mouse_on_numpad/daemon.py`

ScrollController spawns daemon thread in `_ensure_scrolling()` but never joins threads on daemon stop. Movement controller has same issue (pre-existing).

**Impact:** Threads may run briefly after daemon shutdown.

**Fix:**
```python
def stop(self) -> None:
    """Stop the daemon."""
    self._running = False
    self.movement.stop_all()
    self.scroll.stop_all()
    # Give threads time to exit gracefully
    time.sleep(0.2)
    # ... rest of cleanup
```

## High Priority Findings

### 4. Thread Race on Speed Reset
**File:** `src/mouse_on_numpad/input/scroll_controller.py:58-59`

```python
if not self._active_dirs:
    self._current_speed = 1.0  # Reset acceleration on full stop
```

This runs in key handler thread. Meanwhile `_scroll_loop` checks `_active_dirs` without lock at line 79. Timing: key release → speed reset → scroll loop reads speed → potential 1-tick scroll after release.

**Impact:** Minor - extra scroll tick possible.

**Mitigation:** Lock already held in `stop_direction`, but `_current_speed` write should be inside lock check in `_scroll_loop`.

### 5. No Max Speed Validation
**File:** `src/mouse_on_numpad/input/scroll_controller.py:121`

If user sets `scroll.max_speed < scroll.step`, division by zero risk:
```python
max_mult = max_speed / step  # Crash if step=3, max_speed=2
```

**Fix:**
```python
max_mult = max(max_speed / step, 1.0)
```

### 6. YdotoolMouse Scroll Multiplier Hardcoded
**File:** `src/mouse_on_numpad/daemon.py:35`

```python
subprocess.run(["ydotool", "mousemove", "--wheel", "-y", str(dy * 15)], check=False)
```

Magic number `15` not documented. Differs from UInput (1:1). Creates parity issue between backends.

**Fix:** Add constant `YDOTOOL_SCROLL_MULTIPLIER = 15` with comment explaining why.

## Medium Priority Improvements

### 7. Thread Safety Pattern Inconsistent
ScrollController uses lock correctly, but `_scroll_loop` releases lock before `mouse.scroll()` call (good), then re-acquires for acceleration (also good). However, `_current_speed` update happens outside any lock.

**Suggestion:** Document why `_current_speed` writes don't need lock (single writer, eventual consistency OK for acceleration).

### 8. Config Validation Missing
Scroll config lacks validation. Negative values, zero delay, etc. not checked.

**Suggestion:**
```python
def get(self, key: str, default: Any = None) -> Any:
    value = # ... existing logic
    # Validate scroll config
    if key == "scroll.step" and value <= 0:
        return default
    # etc
```

### 9. Scroll Direction Cancellation Unclear
Holding KP7 (up) + KP1 (down) simultaneously:
```python
dy += speed  # from "up"
dy -= speed  # from "down"
# Result: dy=0, no scroll (expected)
```

Good, but not documented. Add comment in `_calc_delta`.

### 10. Config Defaults Differ from Plan
**Plan:** No `delay` mentioned in config section.
**Code:** `"delay": 30` added to config.

Plan incomplete, but code correct (matches movement pattern).

## Low Priority Suggestions

### 11. Type Hints Could Be Stronger
```python
def __init__(self, config, mouse: ScrollableProtocol) -> None:
```

`config` has no type hint. Should be `ConfigManager`.

### 12. Protocol Not Used Polymorphically
`ScrollableProtocol` defined but both `UinputMouse` and `YdotoolMouse` don't explicitly inherit it. Works via duck typing but confusing.

**Suggestion:** Add `# type: ignore[arg-type]` or make classes inherit Protocol.

### 13. Daemon Imports Out of Order
```python
# Line 11
from .core import ...
# Line 13
STATUS_FILE = ...
# Line 14
from .input import ...
```

Constant defined between imports. PEP 8: imports → constants → classes.

## Positive Observations

- **Excellent architectural consistency**: ScrollController mirrors MovementController design perfectly
- **Good thread safety**: Lock usage correct, `daemon=True` prevents zombie threads
- **Clean separation**: Protocol abstraction allows UInput/ydotool swap
- **Config hot-reload**: Reads config on each loop iteration (matches movement)
- **KISS compliance**: Simple exponential acceleration, no over-engineering
- **DRY compliance**: Reuses existing mouse.scroll() interface

## Recommended Actions

1. **CRITICAL**: Remove duplicate `reload()` method (config.py line 168-170)
2. **CRITICAL**: Verify scroll direction mapping vs Windows version (KP9=right or left?)
3. **CRITICAL**: Add thread join or sleep in daemon.stop()
4. **HIGH**: Add division-by-zero guard in scroll acceleration
5. **HIGH**: Document or constant-ize ydotool scroll multiplier
6. **MEDIUM**: Add config validation for scroll parameters
7. **LOW**: Fix import ordering in daemon.py
8. **LOW**: Add type hint for `config` parameter

## Metrics
- Type Coverage: Partial (config param missing, Protocol not enforced)
- Test Coverage: Unknown (no tests written yet per plan)
- Syntax Errors: 0 (AST parse clean)
- Import Errors: 0 (runtime import successful)
- Linting Issues: N/A (ruff/mypy not installed)

## Unresolved Questions

1. **Scroll direction correctness**: Plan doc says KP9=left, code says KP9=right. Which matches Windows?
2. **Thread cleanup strategy**: Should daemon wait for scroll/movement threads to exit, or is abrupt termination OK?
3. **ydotool multiplier origin**: Where does `* 15` come from? Is this tuned for specific ydotool version?
4. **Config delay unit**: Is 30ms realistic for scroll smoothness vs responsiveness tradeoff?
