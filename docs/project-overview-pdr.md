# Mouse on Numpad - Project Overview & PDR

**Document Version:** 3.0
**Updated:** 2026-02-08
**Status:** Phases 1-5 COMPLETE, Phase 6 Next (Distribution)

---

## Product Overview

### What is Mouse on Numpad?

Mouse on Numpad is an accessibility tool that allows users to control the mouse cursor using numpad keys, providing an alternative input method for users who prefer keyboard-based mouse control.

**Original Product:** Windows AutoHotkey v2 implementation with GUI settings, hotkey customization, 7 color themes, and persistent position memory.

**Current Project:** Linux port using modern Python + GTK stack, maintaining feature parity while embracing Linux conventions.

---

## Project Goals

### Primary Objectives (Phase 1-6)

1. **Functional Parity** - Replicate all features from Windows version
2. **Linux-Native** - Use GTK instead of AutoHotkey, follow XDG standards
3. **Modular Architecture** - Enable incremental feature development
4. **High Quality** - 80%+ test coverage, type-safe Python, clean code
5. **Maintainable** - Clear documentation, architectural clarity, easy to extend

### Success Metrics

- [x] Phase 1: Core infrastructure (config, state, logging) COMPLETE
- [x] Phase 2: Numpad input capture via evdev COMPLETE
- [x] Phase 3: Position memory per monitor + audio feedback COMPLETE
- [x] Phase 4: GTK4 settings GUI with 6 tabs + profiles COMPLETE
- [x] Phase 5: Wayland/X11 multi-backend support COMPLETE
- [→] Phase 6: Distribution packaging (wheel, RPM, DEB, AUR) NEXT
- [ ] Phase 7: Extended testing and user feedback

---

## Product Development Requirements (PDR)

### Functional Requirements

#### Phase 1: Core Infrastructure (COMPLETE)
- **FR 1.1:** Configuration persistence (JSON, XDG compliance)
- **FR 1.2:** Observable state management (thread-safe)
- **FR 1.3:** Structured logging with rotation
- **FR 1.4:** CLI entry point (--status, --toggle, --version)

#### Phase 2: Input Control Layer
- **FR 2.1:** Capture numpad key events (X11)
- **FR 2.2:** Map keys to mouse movement (8 directions)
- **FR 2.3:** Adjustable movement speed (5-50 pixels/step)
- **FR 2.4:** Toggle on/off via hotkey or button

#### Phase 3: Position Memory & Audio
- **FR 3.1:** Save/restore cursor positions per monitor
- **FR 3.2:** Play audio feedback (click sounds)
- **FR 3.3:** Volume control (0-100%)
- **FR 3.4:** Persist positions across sessions

#### Phase 4: GUI Implementation
- **FR 4.1:** Settings dialog with tabs (Movement, Audio, Hotkeys, Visuals)
- **FR 4.2:** Theme selection (7 color themes)
- **FR 4.3:** Status indicator (tray or window)
- **FR 4.4:** Live configuration updates

#### Phase 5: Wayland Support
- **FR 5.1:** Detect and support modern display servers
- **FR 5.2:** Fallback to X11 on incompatible systems
- **FR 5.3:** Proper window compositing

#### Phase 6: Packaging & Distribution
- **FR 6.1:** Python wheel distribution
- **FR 6.2:** Linux distribution packages (RPM, DEB)
- **FR 6.3:** AUR community package
- **FR 6.4:** Release versioning and changelog

### Non-Functional Requirements

#### Performance
- **NFR 1:** Input latency <10ms (numpad press to cursor move)
- **NFR 2:** CPU usage <5% when idle
- **NFR 3:** Memory footprint <50MB
- **NFR 4:** Config load time <100ms

#### Reliability
- **NFR 5:** 99.9% uptime during operation (robust error handling)
- **NFR 6:** Graceful degradation on missing audio hardware
- **NFR 7:** Config file corruption recovery
- **NFR 8:** Log rotation without data loss

#### Security
- **NFR 9:** Configuration stored with 0600 permissions (owner-only)
- **NFR 10:** Logs stored with 0700 directory permissions
- **NFR 11:** No credentials or sensitive data stored
- **NFR 12:** Input validation on all user-provided data

#### Maintainability
- **NFR 13:** 80%+ test coverage on core modules
- **NFR 14:** All functions have type hints (mypy --strict compliant)
- **NFR 15:** Code modular with <200 line files
- **NFR 16:** Clear architecture documentation

#### Compatibility
- **NFR 17:** Python 3.10+ support
- **NFR 18:** Linux-only (X11 initial, Wayland Phase 5)
- **NFR 19:** GTK 3.0+ compatible
- **NFR 20:** Works on Arch, Fedora, Debian, Ubuntu

---

## Project Scope

### Included in Scope
- Numpad-to-mouse cursor movement
- Movement speed adjustment
- Position memory (per monitor)
- Audio feedback system
- Settings GUI (GTK)
- Hotkey customization
- Color themes (7 from Windows version)
- X11 and Wayland support

### Out of Scope (Future Consideration)
- Windows/macOS port (Phase 1 focused on Linux)
- Mobile device support
- Custom language translations (English only)
- Advanced scripting/macro system
- Integration with accessibility frameworks (AT-SPI initial only)

---

## Technical Architecture

### Layered Design

```
┌─────────────────────────────────────┐
│    GUI Layer (Phase 4)              │
│  GTK Settings Dialog, Status Bar    │
├─────────────────────────────────────┤
│  Application Layer (Phase 2-3)      │
│  Input Handlers, Position Memory    │
├─────────────────────────────────────┤
│  Core Layer (Phase 1) ✓ COMPLETE    │
│  Config, State, Logging             │
├─────────────────────────────────────┤
│    System APIs (Linux)              │
│  X11/Wayland, Pulse Audio, Files    │
└─────────────────────────────────────┘
```

### Technology Stack

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| Language | Python 3.10+ | Cross-platform, readable, good testing |
| GUI Framework | GTK 3.0+ | Native Linux, well-documented |
| Input | pynput + python-xlib | Input capture, X11 protocol access |
| Audio | pulsectl | Pulse Audio control, modern Linux standard |
| Testing | pytest | Industry standard, excellent coverage tools |
| Build | uv + hatchling | Modern Python packaging, fast |
| Type Checking | mypy --strict | Catches bugs at dev time |

---

## Architectural Decisions

### Decision 1: JSON for Configuration (not YAML/TOML)

**Rationale:**
- Built-in Python support (no dependencies)
- Human-readable but strict format
- Simpler schema validation than YAML
- Adequate for current config complexity

**Tradeoff:**
- YAML: More readable for complex nested config (future consideration)

### Decision 2: Observable Pattern for State (not Redux/Zustand)

**Rationale:**
- Pure Python standard library (threading.RLock)
- Minimal overhead for current needs
- Clear separation of concerns
- Easy to test and debug

**Tradeoff:**
- Requires explicit subscribe/unsubscribe (no global store convenience)

### Decision 3: Single-threaded Phase 1 (asyncio deferred)

**Rationale:**
- Simpler code, easier to test
- Phase 2 will introduce threading for input capture
- Event loop deferred until Phase 4 (GUI)

**Evolution Path:**
```
Phase 1: Single-threaded (current)
Phase 2: Multi-threaded (input + main)
Phase 4: Event loop (GTK main loop)
Phase 5+: Async/await (if needed)
```

### Decision 4: XDG Base Directory Compliance

**Rationale:**
- Standard Linux convention
- Respects user preferences ($XDG_CONFIG_HOME, etc.)
- Enables proper backup/restore utilities
- Supports containerized environments

**Paths:**
- Config: `~/.config/mouse-on-numpad/`
- Data: `~/.local/share/mouse-on-numpad/`
- Cache: `~/.cache/mouse-on-numpad/` (Phase 3+)

---

## Implementation Phases

### Phase 1: Core Infrastructure (COMPLETE)

**Duration:** Completed
**Status:** 100% ✓

**Deliverables:**
- ✓ ConfigManager with JSON persistence (hotkeys, themes, positions)
- ✓ StateManager with observable pattern (thread-safe)
- ✓ ErrorLogger with rotating file handler
- ✓ CLI entry point (main.py with --status, --toggle, --daemon, --settings)
- ✓ 37+ unit tests (all passing)
- ✓ 100% type coverage (mypy strict)

**Completed Actions:**
- ✓ Core module architecture in place
- ✓ XDG Base Directory compliance
- ✓ Thread-safe state management
- ✓ Secure file permissions (0600/0700)
- ✓ Configuration defaults for all phases

**Success Criteria - ALL MET:**
- [x] Config file created at ~/.config/mouse-on-numpad/config.json
- [x] State changes trigger registered callbacks
- [x] Log files rotate properly
- [x] CLI entry point fully functional
- [x] pytest passes with >80% coverage

---

### Phase 2: Input Control Layer (COMPLETE)

**Estimated Duration:** 20-30 hours (completed)
**Dependencies:** Phase 1 ✓
**Status:** 100% ✓

**Deliverables:**
- ✓ evdev keyboard capture (thread-per-device)
- ✓ Mouse movement with acceleration curves
- ✓ Speed settings (base_speed, max_speed, curve types)
- ✓ Click handling (left/right/middle/drag)
- ✓ Scroll wheel emulation
- ✓ Mode toggle integration
- ✓ Input latency <10ms

**Key Components:**
- `daemon/keyboard_capture.py` - evdev event reader
- `daemon/hotkey_dispatcher.py` - Key-to-action router
- `input/movement_controller.py` - Numpad movement with acceleration
- `input/scroll_controller.py` - Scroll wheel logic
- `input/mouse_controller.py` - Low-level mouse ops
- Tests with 80%+ coverage ✓

**Architecture:**
```
evdev /dev/input/event*
    ↓
KeyboardCapture (thread per device)
    ↓
HotkeyDispatcher (keycode → action)
    ↓
MovementController/ScrollController/MouseController
    ↓
StateManager (observers notified)
```

---

### Phase 3: Position Memory & Audio (COMPLETE)

**Estimated Duration:** 15-20 hours (completed)
**Dependencies:** Phase 1, 2 ✓
**Status:** 100% ✓

**Deliverables:**
- ✓ Position memory storage (JSON, per-monitor)
- ✓ Audio system (sine wave generation, no external files)
- ✓ Volume control (0-100%)
- ✓ Click sounds and audio feedback
- ✓ Multi-monitor position tracking
- ✓ Atomic position persistence (crash-safe)

**Key Components:**
- `input/position_memory.py` - Per-monitor position storage
- `input/audio_feedback.py` - Sine wave audio generation
- `daemon/position_manager.py` - Position memory integration
- `input/monitor_manager.py` - Monitor detection & geometry
- Tests with 80%+ coverage ✓

---

### Phase 4: GUI Implementation (COMPLETE)

**Estimated Duration:** 30-40 hours (completed)
**Dependencies:** Phase 1, 2, 3 ✓
**Status:** 100% ✓

**Deliverables:**
- ✓ GTK4 settings window with 6 tabs
- ✓ Movement tab (speed, acceleration, curve)
- ✓ Audio tab (enable/volume)
- ✓ Hotkeys tab (interactive key capture)
- ✓ Appearance tab (themes, status indicator)
- ✓ Advanced tab (per-monitor memory, logging)
- ✓ Profiles tab (save/load configurations)
- ✓ Floating status indicator overlay
- ✓ System tray integration
- ✓ Live configuration updates

**Key Components:**
- `ui/main_window.py` - Main settings window
- `ui/movement_tab.py`, `audio_tab.py`, `hotkeys_tab.py`, etc.
- `ui/status_indicator.py` - GTK Layer Shell overlay
- `ui/profiles_tab.py` - Profile management
- `ui/save_profile_dialog.py` - New profile dialog
- `app.py` - GTK application coordinator
- Tests with 80%+ coverage ✓

---

### Phase 5: Wayland Support (COMPLETE)

**Estimated Duration:** 10-15 hours (completed)
**Dependencies:** Phase 1-4 ✓
**Status:** 100% ✓

**Deliverables:**
- ✓ X11 backend (RandR, XTest, XKB)
- ✓ Wayland backend (Portal APIs, DBus)
- ✓ evdev keyboard capture (works on both servers)
- ✓ uinput mouse control (works on both servers)
- ✓ Fallback strategy (graceful degradation)
- ✓ Multi-monitor detection on both servers
- ✓ GTK Layer Shell for overlay (Wayland/X11)

**Key Components:**
- `backends/base.py` - Backend abstraction
- `backends/x11_backend.py` - X11 implementation
- `backends/x11_helpers.py` - X11 helpers
- `backends/wayland_backend.py` - Wayland implementation
- `backends/evdev_backend.py` - Input device layer
- `input/display_detection.py` - Server detection
- Tests with 80%+ coverage ✓

---

### Phase 6: Packaging & Distribution (PLANNED - NEXT)

**Estimated Duration:** 15-20 hours
**Dependencies:** Phase 1-5 ✓ (all complete)
**Status:** Ready to start (NEXT PHASE)

**Deliverables - To Do:**
- [ ] Python wheel distribution (dist/mouse-on-numpad-*.whl)
- [ ] RPM package (Fedora/RHEL/Arch)
- [ ] DEB package (Debian/Ubuntu)
- [ ] AUR package (Arch User Repository)
- [ ] Release versioning (semantic versioning)
- [ ] Changelog documentation
- [ ] Installation scripts
- [ ] Desktop entry files

**Key Components:**
- `pyproject.toml` - Package metadata
- Hatchling build configuration
- RPM spec file (package.spec)
- DEB control files (debian/)
- AUR PKGBUILD script
- CHANGELOG.md
- Installation documentation in README.md

---

## Risk Assessment

### High Risk

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|-----------|
| X11 display server compatibility | Core feature broken | Medium | Add Wayland support Phase 5 |
| Numpad event handling conflicts | Feature doesn't work | Low | Proper event filtering in Phase 2 |
| Audio system unavailable | Feature broken | Medium | Graceful fallback (continue without audio) |

### Medium Risk

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|-----------|
| Performance degradation in input loop | Sluggish response | Medium | Profile Phase 2, optimize logging |
| Config file corruption | Data loss | Low | Backup strategy in Phase 1 ✓ |
| Thread safety issues | Race conditions | Low | Thread-safe design Phase 1 ✓, thorough testing |

### Low Risk

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|-----------|
| Breaking changes in GTK | GUI breaks | Low | Monitor GTK updates, abstract UI layer |
| Python version incompatibility | Package doesn't run | Low | Test on 3.10, 3.11, 3.12 |
| Distribution package conflicts | Install fails | Low | Proper version pinning, dependency docs |

---

## Timeline & Milestones

### Current Status (2026-02-08)

```
Phase 1: Core Infrastructure  [██████████] 100% ✓
  - Config, State, Logging ✓
  - Tests 100% passing ✓
  - Type hints complete ✓

Phase 2: Input Layer          [██████████] 100% ✓
  - evdev capture, movement, scroll ✓
  - All hotkey routing working ✓

Phase 3: Position & Audio     [██████████] 100% ✓
  - Per-monitor position storage ✓
  - Audio feedback system ✓

Phase 4: GUI Implementation   [██████████] 100% ✓
  - 6-tab settings window ✓
  - Status indicator overlay ✓
  - Profile management ✓

Phase 5: Wayland Support      [██████████] 100% ✓
  - X11/Wayland backends ✓
  - Multi-backend abstraction ✓

Phase 6: Distribution         [░░░░░░░░░░]  0% (NEXT)
  - Packaging & distribution (planned)
```

### Completed Timeline

| Phase | Duration | Completed | Status |
|-------|----------|-----------|--------|
| 1 | 8-10h | 2026-01-20 | Core infrastructure ✓ |
| 2 | 20-30h | 2026-02-02 | Input layer refactored ✓ |
| 3 | 15-20h | 2026-02-05 | Audio + position memory ✓ |
| 4 | 30-40h | 2026-02-06 | GUI implementation (6 tabs) ✓ |
| 5 | 10-15h | 2026-02-07 | Wayland/X11 backends ✓ |
| 6 | 15-20h | 2026-02-08+ | Distribution (NEXT) |
| **TOTAL** | **~100-120h** | 2026-01-15 to 2026-02-08 | 83% complete (5/6 phases) |

---

## Success Criteria - ALL PHASES COMPLETE

**Code Quality (All Phases):**
- [x] 37+ tests passing
- [x] 80%+ test coverage across all modules
- [x] 0 critical ruff linting errors
- [x] mypy --strict passes
- [x] No type: ignore comments in core code
- [x] PEP 8 compliant with Black formatting

**Functionality - Phases 1-5:**
- [x] Config persistence with hotkey support
- [x] State management with observers
- [x] Evdev keyboard capture working
- [x] Mouse movement with acceleration
- [x] Click and scroll actions
- [x] Position memory per-monitor
- [x] Audio feedback system
- [x] GTK4 6-tab settings GUI
- [x] Status indicator overlay
- [x] Profile save/load system
- [x] X11 backend complete
- [x] Wayland backend complete
- [x] Multi-monitor support

**Documentation:**
- [x] Codebase summary updated
- [x] System architecture documented
- [x] Code standards established
- [x] PDR document comprehensive
- [x] README.md with usage examples
- [x] API documentation (docs/)

**Security - ALL PHASES:**
- [x] Config files 0600 permissions
- [x] Log directory 0700 permissions
- [x] No credentials stored
- [x] Thread-safe state access
- [x] Input validation on configs
- [x] Graceful error handling

---

## Dependencies & Constraints

### External Dependencies
- Python 3.10+
- GTK 3.0+ (for GUI, not Phase 1)
- PulseAudio (for audio, optional)
- X11 or Wayland display server

### Internal Dependencies
- Phase 1 → Phase 2: StateManager + ConfigManager
- Phase 2 → Phase 3: Input handlers
- Phase 3 → Phase 4: Position database
- Phase 4 → Phase 5: GUI abstraction
- Phase 5 → Phase 6: Complete implementation

### Technical Constraints
- Python 3.10 minimum (f-strings, type union syntax)
- Linux-only (Phase 5+ targets Wayland)
- Single-process (no multiprocess workers)
- User-space only (no kernel drivers needed)

---

## Resource Requirements

### Development
- **Team:** 1 core developer (current)
- **CI/CD:** GitHub Actions (free)
- **Testing:** pytest (free, OSS)
- **Version Control:** Git/GitHub (free)

### Distribution
- **Hosting:** GitHub releases (free)
- **AUR:** Community maintained (free)
- **Repositories:** Fedora/Debian repos or PPA

### Documentation
- **Hosting:** GitHub wiki + /docs folder
- **Format:** Markdown
- **Tools:** GitHub Pages (free)

---

## Exit Criteria

### Phase Completion
Each phase is "complete" when:
1. All deliverables coded and committed
2. Unit tests pass with >80% coverage
3. Code review approved
4. Integration tests pass (Phase 2+)
5. Documentation updated
6. Code standards enforced

### Project Completion
Project is "complete" when:
1. All 6 phases finished
2. Feature parity with Windows version achieved
3. Packaging available (wheel, RPM, DEB, AUR)
4. User documentation comprehensive
5. Community contribution guidelines established

---

## References

- **Phase 1 Plan:** `plans/260117-1353-linux-port/phase-01-core-infrastructure.md`
- **Code Review:** `plans/reports/code-reviewer-260117-1421-phase1-core-infra.md`
- **Linux Port Plan:** `LINUX_PORT_PLAN.md`
- **Development Rules:** `CLAUDE.md`
- **System Architecture:** `docs/system-architecture.md`
- **Code Standards:** `docs/code-standards.md`

---

**Document Version:** 3.0
**Last Updated:** 2026-02-08
**Status:** PHASES 1-5 COMPLETE (83%), PHASE 6 READY TO START
**Next Phase:** Distribution packaging (Phase 6)
**Estimated Completion:** 2026-02-28 (Phase 6)
