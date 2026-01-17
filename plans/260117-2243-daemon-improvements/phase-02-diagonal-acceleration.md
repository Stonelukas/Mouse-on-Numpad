---
title: "Phase 2: Improve Diagonal & Acceleration"
status: pending
effort: 3h
---

# Phase 2: Improve Diagonal & Acceleration

## Problem

1. **Diagonals** - Single key-to-action mapping; no multi-key detection
2. **No acceleration** - Each step same speed; Windows version accelerates over time
3. **No max speed cap** - No configurable upper bound

## Windows Reference

From `MouseActions._MoveContinuous`:
```ahk
baseSpeed := Config.Get("Movement.BaseSpeed")       # 10
accelRate := Config.Get("Movement.AccelerationRate") # 1.02
maxSpeed := Config.Get("Movement.MaxSpeed")          # 100
moveDelay := Config.Get("Movement.MoveDelay")        # 10ms

while GetKeyState(key, "P") {
    moveX := Round(dirX * baseSpeed * currentSpeed)
    currentSpeed := currentSpeed * accelRate
    if (currentSpeed > maxSpeedMultiplier) currentSpeed := maxSpeedMultiplier
    Sleep(moveDelay)
}
```

## Design

### Movement Loop

Replace discrete `_handle_key` moves with continuous movement thread:

```python
class MovementController:
    def __init__(self, config, mouse):
        self._config = config
        self._mouse = mouse
        self._current_speed = 1.0
        self._move_thread: Thread | None = None
        self._active_dirs: set[str] = set()  # {"up", "left"} = diagonal up-left

    def start_direction(self, direction: str) -> None:
        self._active_dirs.add(direction)
        self._ensure_moving()

    def stop_direction(self, direction: str) -> None:
        self._active_dirs.discard(direction)
        if not self._active_dirs:
            self._current_speed = 1.0  # Reset on release

    def _movement_loop(self) -> None:
        while self._active_dirs:
            dx, dy = self._calc_delta()
            self._mouse.move(dx, dy)
            self._accelerate()
            sleep(self._config.get("movement.move_delay", 10) / 1000)
```

### Direction Calculation

```python
def _calc_delta(self) -> tuple[int, int]:
    base = self._config.get("movement.base_speed", 10)
    speed = int(base * self._current_speed)

    dx = dy = 0
    if "left" in self._active_dirs: dx -= speed
    if "right" in self._active_dirs: dx += speed
    if "up" in self._active_dirs: dy -= speed
    if "down" in self._active_dirs: dy += speed

    return dx, dy
```

### Config Additions

```json
{
    "movement": {
        "base_speed": 10,
        "acceleration_rate": 1.02,
        "max_speed": 100,
        "move_delay": 10,
        "curve": "exponential"
    }
}
```

## Implementation Steps

1. Create `MovementController` class in `src/mouse_on_numpad/input/movement.py`
2. Refactor `Daemon._handle_key` to use direction start/stop
3. Add acceleration curves (linear, exponential, s-curve)
4. Add config keys: acceleration_rate, max_speed, move_delay
5. Update GUI to expose new config (Phase 3)

## Files to Modify

| File | Change |
|------|--------|
| `src/mouse_on_numpad/input/movement.py` | NEW: MovementController |
| `src/mouse_on_numpad/daemon.py` | Integrate MovementController |
| `src/mouse_on_numpad/core/config.py` | Add default values |
| `tests/test_movement.py` | NEW: Tests for acceleration |

## Key Mappings (Updated)

```python
KEY_TO_DIR = {
    72: "up",        # KP8
    80: "down",      # KP2
    75: "left",      # KP4
    77: "right",     # KP6
    71: ("up", "left"),    # KP7 - diagonal
    73: ("up", "right"),   # KP9
    79: ("down", "left"),  # KP1
    81: ("down", "right"), # KP3
}
```

For diagonal keys, add both directions to `_active_dirs`.

## Success Criteria

- [ ] Hold key = continuous accelerating movement
- [ ] Multi-key diagonals (e.g., hold 8+4 = up-left)
- [ ] Dedicated diagonal keys (7,9,1,3) work
- [ ] Speed caps at max_speed
- [ ] Acceleration resets on key release
- [ ] Config values respected

## Acceleration Curves

```python
def _accelerate(self) -> None:
    curve = self._config.get("movement.curve", "exponential")
    rate = self._config.get("movement.acceleration_rate", 1.02)
    max_mult = self._config.get("movement.max_speed", 100) / self._config.get("movement.base_speed", 10)

    if curve == "linear":
        self._current_speed = min(self._current_speed + (rate - 1), max_mult)
    elif curve == "exponential":
        self._current_speed = min(self._current_speed * rate, max_mult)
    elif curve == "s-curve":
        # S-curve: slow start, fast middle, slow end
        t = self._current_speed / max_mult
        self._current_speed = min(self._current_speed + rate * (1 - abs(2*t - 1)), max_mult)
```
