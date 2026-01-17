# Documentation Index - Mouse on Numpad

**Updated:** 2026-01-17
**Project Status:** Phase 1 Core Infrastructure - 70% Complete

---

## Quick Navigation

### For New Developers
Start here to understand the project:
1. **[Project Overview & PDR](./project-overview-pdr.md)** - What is this project? Goals, requirements, timeline
2. **[Code Standards](./code-standards.md)** - How to write code that fits the project
3. **[System Architecture](./system-architecture.md)** - How everything fits together

### For Contributors
Working on specific features:
1. **[Codebase Summary](./codebase-summary.md)** - Structure of Python package, current Phase 1 modules
2. **[System Architecture](./system-architecture.md)** - Architecture patterns, data flow, thread safety
3. **[Code Standards](./code-standards.md)** - Linting, testing, security guidelines

### For Product Managers
Planning and tracking:
1. **[Project Overview & PDR](./project-overview-pdr.md)** - 6-phase timeline, 108-135 hour estimate, success criteria
2. **[System Architecture](./system-architecture.md)** - Risk assessment, scalability considerations

### For DevOps/Distribution
Building and packaging:
1. **[Codebase Summary](./codebase-summary.md)** - Dependencies, build system (uv + hatchling)
2. **[Project Overview & PDR](./project-overview-pdr.md)** - Phase 6: Packaging & Distribution (RPM, DEB, AUR)

---

## Documentation Files

### Core Documentation (Phase 1)

#### [codebase-summary.md](./codebase-summary.md)
- **Type:** Reference
- **Lines:** 364
- **Audience:** All developers
- **Contents:**
  - Project structure and package layout
  - Core modules: ConfigManager, StateManager, ErrorLogger
  - CLI entry point usage
  - Test coverage (37 tests, 79%)
  - Dependencies and build setup
  - Known issues and next steps

#### [system-architecture.md](./system-architecture.md)
- **Type:** Technical Design
- **Lines:** 585
- **Audience:** Architects, senior developers
- **Contents:**
  - Layered architecture (GUI, App, Core, System)
  - Component interactions and data flow
  - Thread model and safety guarantees
  - XDG directory layout
  - Error handling strategies
  - Testing approach
  - Performance and scalability

#### [code-standards.md](./code-standards.md)
- **Type:** Guidelines & Standards
- **Lines:** 593
- **Audience:** All contributors
- **Contents:**
  - Python style (naming, type hints, formatting)
  - Module organization (<200 lines)
  - Error handling and thread safety
  - Testing requirements (80%+ coverage)
  - Security guidelines
  - Git commit conventions
  - Code review checklist

#### [project-overview-pdr.md](./project-overview-pdr.md)
- **Type:** Strategic Planning
- **Lines:** 539
- **Audience:** PMs, architects, stakeholders
- **Contents:**
  - Product overview and goals
  - Functional/non-functional requirements
  - Technical architecture and tech stack
  - 6-phase implementation plan
  - Risk assessment
  - 7-month timeline estimate
  - Success criteria

### Legacy Documentation (Windows Version)

#### [API.md](./API.md)
- AutoHotkey API reference for Windows version
- Keep for feature parity reference

#### [USAGE.md](./USAGE.md)
- Usage guide for Windows version
- Useful for understanding feature set

#### [HOTKEYS.md](./HOTKEYS.md)
- Default hotkey bindings
- Reference for Linux port feature set

#### [THEMING.md](./THEMING.md)
- Theme system documentation
- 7 color themes from Windows version

#### [SETTINGS_GUI.md](./SETTINGS_GUI.md)
- Settings dialog layout
- Reference for Phase 4 GUI design

#### [README.md](./README.md)
- Project overview (high-level)
- Quick start information

---

## Reading Paths by Role

### Backend Developer (Python)
1. Code Standards → naming, type hints, testing
2. System Architecture → threading, observer pattern
3. Codebase Summary → current module structure
4. Project Overview → Phase 2-3 planning

**Key Skills:** Python, threading, asyncio, pytest

### Frontend Developer (GTK GUI)
1. System Architecture → layered design
2. Project Overview → Phase 4 requirements
3. Code Standards → GUI testing patterns
4. SETTINGS_GUI.md → design reference

**Key Skills:** GTK, Glade, event handling, responsive design

### QA/Tester
1. Code Standards → testing requirements, coverage targets
2. Codebase Summary → test structure (37 tests)
3. Project Overview → success criteria, acceptance tests
4. System Architecture → error handling and edge cases

**Key Skills:** pytest, test automation, edge case analysis

### DevOps/Release Engineer
1. Codebase Summary → dependencies, build system
2. Project Overview → Phase 6 packaging requirements
3. Code Standards → CI/CD expectations

**Key Skills:** Python packaging, RPM/DEB, CI/CD

### Technical Writer
1. Project Overview → product goals and features
2. Codebase Summary → current implementation
3. Code Standards → documentation requirements
4. System Architecture → technical explanations

**Key Skills:** Technical writing, Markdown, API documentation

---

## Phase-Based Navigation

### Phase 1: Core Infrastructure (Current)
- **Status:** 70% complete (4 fixes pending)
- **Read:** Project Overview (Phase 1), System Architecture (Phase 1 section)
- **Focus:** ConfigManager, StateManager, ErrorLogger
- **Tests:** 37 tests, all passing
- **Estimate:** 4 more hours to complete

### Phase 2: Input Control Layer (Planned)
- **Status:** Not started
- **Read:** Project Overview (Phase 2), System Architecture (data flow)
- **Focus:** Input event capture, numpad mapping
- **Estimate:** 20-30 hours

### Phase 3: Position Memory & Audio (Planned)
- **Status:** Not started
- **Read:** Project Overview (Phase 3)
- **Focus:** Position database, Pulse Audio integration
- **Estimate:** 15-20 hours

### Phase 4: GUI Implementation (Planned)
- **Status:** Not started
- **Read:** Project Overview (Phase 4), SETTINGS_GUI.md
- **Focus:** GTK dialog, theme manager
- **Estimate:** 30-40 hours

### Phase 5: Wayland Support (Planned)
- **Status:** Not started
- **Read:** Project Overview (Phase 5), System Architecture (deployment)
- **Focus:** Display server abstraction
- **Estimate:** 10-15 hours

### Phase 6: Packaging & Distribution (Planned)
- **Status:** Not started
- **Read:** Project Overview (Phase 6), Codebase Summary (dependencies)
- **Focus:** RPM, DEB, AUR packages
- **Estimate:** 15-20 hours

---

## Key Metrics

| Metric | Value | Reference |
|--------|-------|-----------|
| Total Project Estimate | 108-135 hours | Project Overview |
| Phase 1 Status | 70% (4 fixes pending) | Project Overview |
| Test Coverage | 79% (37/37 passing) | Codebase Summary |
| Type Coverage | 100% (mypy strict) | Code Standards |
| Code Style | PEP 8 + ruff | Code Standards |
| Lines of Code (Phase 1) | ~1,157 | Codebase Summary |
| Documentation (this release) | 2,081 lines | Generated |

---

## Important References

### Plans & Reports
- **Phase 1 Plan:** `plans/260117-1353-linux-port/phase-01-core-infrastructure.md`
- **Code Review:** `plans/reports/code-reviewer-260117-1421-phase1-core-infra.md`
- **Docs Report:** `plans/reports/docs-manager-260117-1434-phase1-documentation.md`
- **Linux Port Plan:** `LINUX_PORT_PLAN.md`

### Configuration
- **Project Config:** `pyproject.toml` (build, test, lint config)
- **Development Rules:** `CLAUDE.md` (contribution guidelines)

### Source Code
- **Core Modules:** `src/mouse_on_numpad/core/`
- **Tests:** `tests/`
- **Entry Point:** `src/mouse_on_numpad/main.py`

---

## Getting Started

### 1. Understand the Project
Read: **Project Overview & PDR** (10 min)

### 2. Set Up Development Environment
```bash
# Install package in editable mode
uv pip install -e .

# Install dev dependencies
uv pip install -e ".[dev]"

# Run tests
uv run pytest
```

### 3. Read Architecture
Read: **System Architecture** (15 min)

### 4. Check Code Standards
Read: **Code Standards** (15 min)

### 5. Review Current Code
Read: **Codebase Summary** (10 min)

### 6. Start Contributing
- Pick an issue or task from Phase 1 fixes
- Follow Code Standards
- Write tests for new code
- Submit PR

---

## FAQ

**Q: Where do I find the Python code?**
A: `src/mouse_on_numpad/` - See Codebase Summary for structure.

**Q: How do I run tests?**
A: `uv run pytest` - See Code Standards for testing requirements.

**Q: What's the project timeline?**
A: 6 phases, 108-135 hours, ~7 months. See Project Overview.

**Q: How do I add a new feature?**
A: Follow Code Standards, add tests (>80% coverage), get code review.

**Q: When will Phase 2 start?**
A: After Phase 1 completes (estimated 2026-01-20).

**Q: Can I use async/await?**
A: Not in Phase 1 (threading in Phase 2, GTK event loop Phase 4).

**Q: Where is the GUI?**
A: Phase 4 (30-40 hours). Current release is CLI + core infrastructure.

**Q: How do I report a bug?**
A: File issue on GitHub with reproduction steps and logs from ~/.local/share/mouse-on-numpad/logs/

---

## Document Maintenance

**Last Updated:** 2026-01-17
**Next Review:** After Phase 1 completion (2026-01-20)
**Update Frequency:** After each phase completion

**To Update This Index:**
1. Add new documentation file here
2. Update phase navigation if phase status changes
3. Update metrics if coverage/size changes
4. Keep reading paths current with new docs

---

## Related Projects

- **Original Windows Version:** AutoHotkey v2 implementation (reference for feature set)
- **Linux Desktop Tools:** Part of accessibility ecosystem

---

**Index Version:** 1.0
**Generator:** docs-manager
**Status:** CURRENT

For questions, check the relevant documentation file or review the CLAUDE.md guidelines.
