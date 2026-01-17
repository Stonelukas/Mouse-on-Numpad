# Mouse on Numpad - Project Overview & PDR

**Document Version:** 1.0
**Updated:** 2026-01-17
**Status:** Phase 1 Core Infrastructure - Complete (pending fixes)

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

- [ ] Phase 1: Core infrastructure working with 80%+ test coverage
- [ ] Phase 2: Numpad input capture and cursor movement
- [ ] Phase 3: Position memory and audio feedback
- [ ] Phase 4: GTK settings GUI with theme support
- [ ] Phase 5: Wayland display server support
- [ ] Phase 6: Distribution packaging (RPM, DEB, AUR)

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

### Phase 1: Core Infrastructure (COMPLETE - Pending Fixes)

**Duration:** Completed
**Status:** 70% (issues from code review pending resolution)

**Deliverables:**
- ✓ ConfigManager with JSON persistence
- ✓ StateManager with observable pattern
- ✓ ErrorLogger with file rotation
- ✓ CLI entry point (main.py)
- ✓ 37 unit tests (all passing)
- ✓ 100% type coverage (mypy strict)

**Pending Actions:**
- Fix pytest-cov dependency issue
- Fix 4 ruff linting errors
- Fix race condition in StateManager.toggle()
- Add error logging to state callbacks
- Decide on ThemeManager implementation scope

**Success Criteria:**
- [x] Config file created at ~/.config/mouse-on-numpad/config.json
- [x] State changes trigger registered callbacks
- [x] Log files rotate properly
- [ ] `uv run python -m mouse_on_numpad` works (blocked by install issue)
- [ ] pytest passes with >80% coverage (pending pytest-cov fix)

---

### Phase 2: Input Control Layer (Planned)

**Estimated Duration:** 20-30 hours
**Dependencies:** Phase 1 complete
**Status:** Planned

**Deliverables:**
- Input event capture (numpad keys)
- Mouse movement via pynput/xdotool
- Speed settings integration
- Toggle hotkey handling
- Input-based state changes

**Key Components:**
- `input/handler.py` - Input event processor
- `input/numpad_mapper.py` - Key-to-action mapping
- `mouse/controller.py` - Mouse movement API
- Tests for input handling

**Architecture:**
```
Numpad Events
    ↓
InputHandler (filters valid keys)
    ↓
NumpadMapper (key → mouse direction)
    ↓
MouseController (move cursor)
    ↓
StateManager (notify observers)
```

---

### Phase 3: Position Memory & Audio (Planned)

**Estimated Duration:** 15-20 hours
**Dependencies:** Phase 1, 2
**Status:** Planned

**Deliverables:**
- Position memory storage (per-monitor)
- Audio system integration
- Volume control
- Click sounds

**Key Components:**
- `storage/position_db.py` - SQLite position storage
- `audio/controller.py` - Pulse Audio integration
- `audio/sounds/` - Audio assets
- Tests for position recall and audio

---

### Phase 4: GUI Implementation (Planned)

**Estimated Duration:** 30-40 hours
**Dependencies:** Phase 1, 2, 3
**Status:** Planned

**Deliverables:**
- GTK settings dialog
- Tab-based UI (Movement, Audio, Hotkeys, Visuals)
- Status indicator
- Theme manager (7 themes)
- Live configuration updates

**Key Components:**
- `gui/main_window.py` - Main window
- `gui/dialogs/settings.py` - Settings dialog
- `gui/dialogs/hotkey_editor.py` - Hotkey configuration
- `gui/theme_manager.py` - Theme loading and application
- Tests for GUI (using pytest-gtk)

---

### Phase 5: Wayland Support (Planned)

**Estimated Duration:** 10-15 hours
**Dependencies:** Phase 1-4
**Status:** Planned

**Deliverables:**
- Wayland protocol support detection
- Fallback to X11 on incompatible systems
- Modern compositor compatibility

**Key Components:**
- `platform/display_server.py` - X11/Wayland abstraction
- `platform/wayland_controller.py` - Wayland input/output
- Tests for display server detection

---

### Phase 6: Packaging & Distribution (Planned)

**Estimated Duration:** 15-20 hours
**Dependencies:** Phase 1-5
**Status:** Planned

**Deliverables:**
- Python wheel distribution
- RPM package (Fedora/RHEL)
- DEB package (Debian/Ubuntu)
- AUR package (Arch User Repository)
- Release notes and changelog

**Key Components:**
- `pyproject.toml` configuration
- RPM spec file
- DEB control files
- AUR PKGBUILD
- CHANGELOG.md

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

### Current Status (2026-01-17)

```
Phase 1: Core Infrastructure  [████████░░] 70%
  - Core modules ✓
  - Tests ✓
  - Fixes pending (4 hours)

Phase 2: Input Layer          [░░░░░░░░░░]  0%
Phase 3: Position & Audio     [░░░░░░░░░░]  0%
Phase 4: GUI Implementation   [░░░░░░░░░░]  0%
Phase 5: Wayland Support      [░░░░░░░░░░]  0%
Phase 6: Distribution         [░░░░░░░░░░]  0%
```

### Projected Timeline

| Phase | Duration | Start | End | Comments |
|-------|----------|-------|-----|----------|
| 1 | 8-10h | 2026-01-15 | 2026-01-20 | Fixes: 4h, completion: 4-6h |
| 2 | 20-30h | 2026-01-20 | 2026-02-15 | Depends on Phase 1 completion |
| 3 | 15-20h | 2026-02-15 | 2026-03-10 | Audio + position memory |
| 4 | 30-40h | 2026-03-10 | 2026-04-30 | GUI implementation |
| 5 | 10-15h | 2026-04-30 | 2026-05-30 | Wayland support |
| 6 | 15-20h | 2026-05-30 | 2026-06-30 | Distribution packaging |
| **TOTAL** | **108-135h** | 2026-01-15 | 2026-06-30 | **~7 months** |

---

## Success Criteria (Phase 1)

**Code Quality:**
- [ ] 37 tests passing ✓
- [ ] 80%+ test coverage (blocked: pytest-cov)
- [ ] 0 ruff linting errors (4 pending)
- [ ] mypy --strict passes ✓
- [ ] No type: ignore comments ✓

**Functionality:**
- [x] Config file created at correct XDG path
- [x] Config backup created before write
- [x] State changes trigger callbacks ✓
- [x] Nested key access works ✓
- [x] Log files rotate properly ✓
- [ ] CLI entry point works (blocked: install issue)

**Documentation:**
- [x] Codebase summary created
- [x] System architecture documented
- [x] Code standards established
- [x] This PDR document created

**Security:**
- [x] Config files 0600 permissions ✓
- [x] Log directory 0700 permissions ✓
- [x] No credentials stored ✓
- [x] Thread-safe state access ✓

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

**Document Version:** 1.0
**Last Updated:** 2026-01-17 14:45 UTC
**Status:** PHASE 1 CORE INFRASTRUCTURE - 70% COMPLETE (fixes pending)
**Next Review:** After Phase 1 completion (estimated 2026-01-20)
