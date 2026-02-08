# Code Review: Full Project Audit (5-Phase Implementation)

## Code Review Summary

### Scope
- **Files reviewed**: 46 source files, 17 test files
- **LOC (source)**: ~5,174
- **LOC (tests)**: ~4,017
- **Focus**: Full audit of 5-phase implementation (build blockers, refactor, docs, tests, polish)
- **Test result**: 262 passed, 1 skipped, 73% coverage
- **Lint result**: 60 ruff issues (38 E402, 10 I001, 7 F401, 1 F841)

### Overall Assessment

The refactoring is well-executed. The daemon.py monolith (505 LOC) has been cleanly split into 7 focused modules with a backward-compatible `__init__.py` re-export. The main_window.py (413 LOC) split into 6 tab modules is equally clean. Thread safety patterns are preserved correctly through the split. The tray_icon.py rewrite from pystray (GTK3) to Gio.Notification (GTK4-native) correctly eliminates the GTK3/4 conflict. No behavioral regressions detected.

---

### Critical Issues

**None found.** No security vulnerabilities, data loss risks, or breaking changes identified.

---

### High Priority

#### H1. Path Traversal in Profile Load (Medium-High Security)
**File**: `/home/stonelukas/Projects/mouse-on-numpad/src/mouse_on_numpad/core/config.py:163-172`

`_load_profile()` takes `name` directly and constructs `profiles_dir / f"{name}.json"` without sanitization. While `_save_profile()` sanitizes with `"".join(c for c in name if c.isalnum() or c in "-_")`, the load path does NOT sanitize, allowing path traversal like `"../../etc/something"`.

```python
# Current (unsafe):
def _load_profile(profiles_dir: Path, name: str) -> dict[str, Any] | None:
    profile_path = profiles_dir / f"{name}.json"
    ...

# Fix: validate resolved path stays within profiles_dir
def _load_profile(profiles_dir: Path, name: str) -> dict[str, Any] | None:
    profile_path = (profiles_dir / f"{name}.json").resolve()
    if not str(profile_path).startswith(str(profiles_dir.resolve())):
        return None  # Path traversal attempt
    ...
```

Same issue exists in `_delete_profile()` (line 175-184). Both should sanitize or validate.

**Impact**: An attacker who controls the profile name (e.g., via crafted config file) could read arbitrary JSON files or delete files with `.json` extension outside the profiles directory.

#### H2. IPC Status File in /tmp Without Safe Creation (Medium-High Security)
**File**: `/home/stonelukas/Projects/mouse-on-numpad/src/mouse_on_numpad/daemon/ipc_manager.py:8,17-22`

`STATUS_FILE = Path("/tmp/mouse-on-numpad-status")` uses a predictable path in `/tmp`. A malicious user could create a symlink at that path pointing to another file, and when the daemon writes `"enabled"/"disabled"`, it would overwrite the target file.

```python
# Current:
STATUS_FILE = Path("/tmp/mouse-on-numpad-status")

# Fix: use XDG_RUNTIME_DIR (per-user, not world-readable)
import os
STATUS_FILE = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp")) / "mouse-on-numpad-status"
```

Additionally, consider using `O_CREAT | O_EXCL` or checking `os.path.islink()` before writing.

#### H3. Hardcoded LD_PRELOAD Path
**File**: `/home/stonelukas/Projects/mouse-on-numpad/src/mouse_on_numpad/daemon/ipc_manager.py:31`

```python
env["LD_PRELOAD"] = "/usr/lib/libgtk4-layer-shell.so"
```

This assumes an Arch/Fedora lib path. On Debian/Ubuntu, the library is at `/usr/lib/x86_64-linux-gnu/libgtk4-layer-shell.so`. This will silently fail on non-Arch distros with no error message, making the indicator not work.

```python
# Fix: search common paths or use ldconfig
import shutil
lib_paths = [
    "/usr/lib/libgtk4-layer-shell.so",
    "/usr/lib/x86_64-linux-gnu/libgtk4-layer-shell.so",
    "/usr/lib64/libgtk4-layer-shell.so",
]
for path in lib_paths:
    if os.path.exists(path):
        env["LD_PRELOAD"] = path
        break
```

#### H4. Movement Controller Thread Safety Gap
**File**: `/home/stonelukas/Projects/mouse-on-numpad/src/mouse_on_numpad/input/movement_controller.py:147-153`

`_record_move()` and `_move_history` are accessed from the movement thread without lock protection, but `undo()` is called from the main key handler thread. This is a race condition.

```python
# _record_move (called from _movement_loop thread):
def _record_move(self, dx: int, dy: int) -> None:
    self._move_history.append((dx, dy))  # No lock
    if len(self._move_history) > max_levels:
        self._move_history = self._move_history[-max_levels:]  # List reassignment race

# undo (called from key handler thread):
def undo(self) -> bool:
    if not self._move_history:  # No lock
        return False
    dx, dy = self._move_history.pop()  # No lock
```

Fix: protect `_move_history` with `self._lock` in both methods.

---

### Medium Priority

#### M1. Unused Imports (F401 Lint Errors)
**7 unused imports** detected by ruff. Examples:

- `mouse_factory.py:65`: `from ..input.uinput_mouse import UinputMouse` at module level serves no purpose (it's imported inside the function on line 49). This also causes an import error if `evdev` is not installed (the whole point of the try/except pattern above).

#### M2. `_merge_defaults` Logic Inverted
**File**: `/home/stonelukas/Projects/mouse-on-numpad/src/mouse_on_numpad/core/config.py:53-63`

The merge logic is subtly wrong for nested dictionaries. When merging user config with defaults:

```python
result = defaults.copy()  # Start with defaults
for key, value in config.items():
    if key in result and isinstance(result[key], dict) and isinstance(value, dict):
        result[key] = self._merge_defaults(value, result[key])
    else:
        result[key] = value  # User value overrides
```

The recursive call passes `(value, result[key])` which means `value` (user config) is treated as `config` and `result[key]` (defaults) is treated as `defaults`. This is correct. However, it uses shallow `.copy()` instead of `copy.deepcopy()` for `defaults`, which means nested default dicts can be mutated across calls. This is only a problem if `_merge_defaults` is called multiple times with the same defaults object (unlikely in practice since `DEFAULT_CONFIG` is deepcopied at load time, but fragile).

#### M3. MonitorManager Refreshes on Every Public Call
**File**: `/home/stonelukas/Projects/mouse-on-numpad/src/mouse_on_numpad/input/monitor_manager.py`

`get_monitors()`, `get_primary()`, `get_monitor_at()`, and `get_next_monitor_center()` all call `_refresh_monitors()` which queries Xrandr over the X11 connection. During active mouse movement, `clamp_to_screens()` (via `PositionMemory.load_position`) will repeatedly query Xrandr. Consider caching with a TTL (e.g., 5 seconds).

#### M4. Daemon Coordinator has 13 Parameters in `handle_key`
**File**: `/home/stonelukas/Projects/mouse-on-numpad/src/mouse_on_numpad/daemon/hotkey_dispatcher.py:48-64`

`handle_key()` takes 13 positional parameters. This is a code smell inherited from the monolith split. Consider grouping related state into a context object:

```python
@dataclass
class KeyHandlerContext:
    state: StateManager
    mouse: Any
    movement: MovementController
    scroll: ScrollController
    tray: TrayIcon
    write_status: Callable
    held_buttons: set[str]
    save_mode: dict
    load_mode: dict
    save_position: Callable
    load_position: Callable
    cycle_monitor: Callable
```

#### M5. Config Reload in Movement Loop
**File**: `/home/stonelukas/Projects/mouse-on-numpad/src/mouse_on_numpad/input/movement_controller.py:80-85`

The movement loop calls `self._config.reload()` every ~1 second. `reload()` reads and parses a JSON file from disk. During active mouse movement, this adds unnecessary I/O latency. Consider using a file-change watcher or checking mtime before reloading.

#### M6. YdotoolMouse Missing `press`/`release` Methods
**File**: `/home/stonelukas/Projects/mouse-on-numpad/src/mouse_on_numpad/daemon/mouse_factory.py:13-36`

`YdotoolMouse` implements `move`, `click`, `scroll`, `close` but lacks `press()` and `release()` methods that `UinputMouse` provides. The daemon's held-button toggle feature (`hotkey_dispatcher.py:176-186`) calls `mouse.press()` and `mouse.release()`, which will raise `AttributeError` on the ydotool fallback.

```python
# Fix: add to YdotoolMouse
def press(self, button: str = "left") -> None:
    """Press and hold (ydotool: simulate via click down)."""
    btn_map = {"left": "0x40", "right": "0x41", "middle": "0x42"}
    btn = btn_map.get(button, "0x40")
    subprocess.run(["ydotool", "click", btn], check=False)

def release(self, button: str = "left") -> None:
    """Release button (ydotool: simulate via click up)."""
    btn_map = {"left": "0x80", "right": "0x81", "middle": "0x82"}
    btn = btn_map.get(button, "0x80")
    subprocess.run(["ydotool", "click", btn], check=False)
```

#### M7. Duplicate Dev Dependencies
**File**: `/home/stonelukas/Projects/mouse-on-numpad/pyproject.toml:36-42,76-82`

Dev dependencies are declared in both `[project.optional-dependencies].dev` and `[dependency-groups].dev`. This is redundant and risks version drift.

---

### Low Priority

#### L1. Import Ordering (60 Ruff Issues)
38 E402 (module-level import not at top) and 10 I001 (unsorted imports). Most E402 are inherent to GTK's `gi.require_version()` pattern and can be suppressed with `# noqa: E402`. The I001 issues are auto-fixable: `ruff check --fix`.

#### L2. Test File `test_daemon_coordinator.py` Deep Nesting
**File**: `/home/stonelukas/Projects/mouse-on-numpad/tests/test_daemon_coordinator.py:35-48`

The daemon fixture has 12 levels of nested `with patch(...)`. Consider using `@patch` decorators or `unittest.mock.patch.multiple()`:

```python
@pytest.fixture
def daemon(config, state, logger):
    patches = {
        "create_mouse_controller": MagicMock(),
        "MonitorManager": MagicMock(),
        "PositionMemory": MagicMock(),
        # ...
    }
    with patch.multiple("mouse_on_numpad.daemon.daemon_coordinator", **patches):
        yield Daemon(config, state, logger)
```

#### L3. `speaker-test` for Audio Feedback
**File**: `/home/stonelukas/Projects/mouse-on-numpad/src/mouse_on_numpad/input/audio_feedback.py:91-106`

`speaker-test` is ALSA utility meant for hardware testing, not programmatic tone generation. It plays through all channels sequentially and may produce unexpected output. Consider `pw-cat` (PipeWire) or `paplay` with generated PCM data instead.

#### L4. `app.py` Docstring Outdated
**File**: `/home/stonelukas/Projects/mouse-on-numpad/src/mouse_on_numpad/app.py:3`

```python
"""Note: TrayIcon uses pystray (GTK 3) and runs in daemon.py separately."""
```

This references pystray which was removed in Phase 1. TrayIcon now uses GTK4 Gio.Notification. Update the docstring.

---

### Edge Cases Found

1. **KeyboardCapture device grab failure**: If `device.grab()` fails (line keyboard_capture.py:61), the device is still used ungrabbed. Keys will be duplicated (once through the daemon, once through the system). This is handled with a warning log, which is acceptable as a degraded-mode fallback, but users should be informed more prominently.

2. **Signal handler in non-main thread**: `signal.signal()` in `daemon_coordinator.py:118-119` must be called from the main thread. If `Daemon.start()` is called from a non-main thread, it will raise `ValueError`. This is currently fine since `main.py` calls it from the main thread, but worth documenting.

3. **Hotkey keycode collisions**: `HotkeyConfig` maps keycodes to different actions. If a user configures the same keycode for multiple actions (e.g., `scroll_right` and `secondary_monitor` both default to keycode 73), behavior depends on dict insertion order and if-else priority in the dispatcher. The Alt modifier check (line 157) works as intended for keycode 73, but custom configurations could create ambiguity.

4. **Config file backup race**: `_save()` does `shutil.copy2` then `open(w)`. If the process crashes between backup and write, the config file may be truncated. Consider writing to a temp file then `os.rename()` for atomic write.

---

### Positive Observations

1. **Clean module boundaries**: The daemon package split correctly preserves the original API via `__init__.py` re-export. All existing imports (`from .daemon import Daemon`) continue to work.

2. **Thread safety**: `StateManager` uses `RLock` with proper acquire/release patterns. Notification callbacks are executed outside the lock to avoid deadlocks. The copy-then-notify pattern (line state_manager.py:74-82) is correct.

3. **XDG compliance**: Config uses `XDG_CONFIG_HOME`, logs use `XDG_DATA_HOME`. File permissions are set to `0o700` (dirs) and `0o600` (files).

4. **Defensive error handling**: Every subprocess call uses `check=False` with proper exception handling. Device disconnection is handled gracefully in `keyboard_capture.py`. UInput cleanup uses both `__exit__` and `__del__`.

5. **Position memory per-monitor-config hashing**: `PositionMemory` uses SHA256 of monitor arrangement to key positions, so saved positions remain valid only when the monitor layout matches. This is a thoughtful design.

6. **No `shell=True`**: All subprocess calls use list arguments, eliminating shell injection risk.

7. **Test coverage meaningful**: 73% with 262 tests. Daemon coordinator, hotkey dispatcher, state manager, and config are all well-tested. The mock setup for Xlib/randr in test_monitor_manager.py is thorough.

---

### Recommended Actions (Prioritized)

1. **H1**: Sanitize profile name in `_load_profile()` and `_delete_profile()` to prevent path traversal
2. **H2**: Move IPC status file from `/tmp/` to `$XDG_RUNTIME_DIR`
3. **H4**: Add lock protection around `_move_history` access in `MovementController`
4. **M6**: Add `press()`/`release()` stubs to `YdotoolMouse` to prevent `AttributeError` on fallback
5. **H3**: Search multiple lib paths for `libgtk4-layer-shell.so`
6. **M7**: Remove duplicate dev dependency declaration
7. **L1**: Run `ruff check --fix` for auto-fixable import ordering, add `# noqa: E402` for GTK pattern
8. **L4**: Update outdated pystray references in docstrings

### Metrics

| Metric | Value |
|--------|-------|
| Type Coverage | Not measured (mypy strict configured but not run) |
| Test Coverage | 73% (262 tests) |
| Linting Issues | 60 (38 E402 inherent to GTK, 10 auto-fixable I001, 7 F401, 1 F841) |
| Files > 200 LOC | 0 source files (all under limit after refactor) |
| Subprocess shell=True | 0 (clean) |
| Hardcoded secrets | 0 |

### Unresolved Questions

1. Should `MonitorManager` use a TTL cache for Xrandr queries, or is per-call refresh acceptable for the current usage patterns?
2. Is the `speaker-test` approach for audio feedback intentionally temporary, or should it be replaced with a proper audio generation approach?
3. The indicator subprocess (`--indicator` mode) uses `LD_PRELOAD` for gtk4-layer-shell. Is there a runtime check/graceful fallback if the library is not installed?
