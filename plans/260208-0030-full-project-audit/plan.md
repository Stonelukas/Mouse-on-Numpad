---
title: "Full Project Audit & Improvement Plan"
description: "Comprehensive improvement plan from code quality, docs, testing, packaging, and UX audits"
status: completed
priority: P1
effort: 26h
branch: claude/plan-linux-port-T7fmn
tags: [audit, refactor, docs, testing, packaging]
created: 2026-02-08
completed: 2026-02-08
---

# Full Project Audit & Improvement Plan

## Audit Summary

Two parallel audits analyzed 31 Python files (~4,800 LOC), 12 test files (191 tests), docs, packaging, and security. Project is ~80% complete (Phases 1-5 implemented) but docs describe it as 70% Phase 1.

**Critical findings:** 3 blockers, 8 high-priority, 6 medium items.

## Audit Reports

- [Code Quality Audit](reports/code-quality-audit.md) - Architecture, code smells, thread safety
- [Project Health Audit](reports/project-health-audit.md) - Testing, docs, packaging, security, UX

## Phases

| # | Phase | Status | Effort | Priority |
|---|-------|--------|--------|----------|
| 1 | [Fix Build Blockers](phase-01-fix-build-blockers.md) | completed | 4h | Critical |
| 2 | [Refactor God Classes](phase-02-refactor-god-classes.md) | completed | 8h | Critical |
| 3 | [Update Documentation](phase-03-update-documentation.md) | completed | 4h | High |
| 4 | [Expand Test Coverage](phase-04-expand-test-coverage.md) | completed | 6h | High |
| 5 | [Polish & Package](phase-05-polish-and-package.md) | completed | 4h | Medium |

## Dependency Graph

```
Phase 1 (blockers) ─→ Phase 2 (refactor) ─→ Phase 4 (tests)
                   ─→ Phase 3 (docs)      ─→ Phase 5 (polish)
```

Phase 1 must be first. Phases 2+3 can run in parallel. Phase 4 after refactor. Phase 5 last.

## Key Metrics (Before → After)

| Metric | Before | After |
|--------|--------|-------|
| Build status | BROKEN (tray_icon import) | Passing ✓ |
| Files >200 lines | 5 (16%) | 0 (0%) ✓ |
| God classes | 1 (daemon.py 505 LOC) | 0 ✓ |
| Test count | 190 | 262 |
| Test coverage | ~58% | 73% ✓ |
| Doc accuracy | Outdated (3 weeks stale) | Current ✓ |

## Risk Assessment

- **Daemon refactor** may break hotkey behavior → mitigate with integration tests first
- **Doc rewrite** may miss features → audit against git log
- **tray_icon removal** unclear if intentional → confirm with user before fixing

## Validation Log

### Session 1 — 2026-02-08
**Trigger:** Initial plan validation after audit completion
**Questions asked:** 4

#### Questions & Answers

1. **[Architecture]** The tray_icon.py was deleted (commit 60ad622 says 'remove TrayIcon import to prevent GTK 3/4 conflict'). Was this intentional? How should we handle it?
   - Options: Remove tray completely (Recommended) | Restore with GTK4 only | Keep pystray, fix conflict
   - **Answer:** Restore with GTK4 only
   - **Rationale:** User wants tray icon feature preserved. Rewrite using GTK4-native approach avoids pystray/GTK3 conflict.

2. **[Scope]** Phase 2 proposes splitting daemon.py (505 lines) into 4 modules. The daemon currently bypasses the backend abstraction and uses evdev directly. Should the refactor also fix this?
   - Options: Split only (Recommended) | Split + use backends | Minimal split
   - **Answer:** Split only
   - **Rationale:** Pure structural refactor keeps risk low. Backend integration deferred to future phase.

3. **[Tradeoffs]** Config reload currently polls every ~1 second. Phase 5 proposes replacing with inotify/signals. This adds complexity — is it worth doing now?
   - Options: Keep polling for now (Recommended) | Switch to SIGHUP signal | Use inotify file watch
   - **Answer:** Keep polling for now
   - **Rationale:** 1s polling acceptable for desktop app. YAGNI — optimize only if profiling shows real issue.

4. **[UX]** The import/export buttons in profiles_tab.py are non-functional. What should we do?
   - Options: Remove buttons (Recommended) | Implement basic JSON export/import | Gray out with tooltip
   - **Answer:** Remove buttons
   - **Rationale:** YAGNI principle. Dead UI is worse than no UI. Re-add when feature is built.

#### Confirmed Decisions
- Tray icon: Restore with GTK4-native approach (no pystray)
- Daemon refactor: Pure structural split only, no backend integration changes
- Config reload: Keep 1s polling, defer optimization
- Import/export: Remove non-functional buttons

#### Action Items
- [ ] Phase 1: Add task to rewrite tray_icon.py using GTK4 StatusIcon or Gio.Notification
- [ ] Phase 2: Scope limited to structural split — do NOT change evdev usage
- [ ] Phase 5: Remove config reload optimization task, remove import/export buttons instead

#### Impact on Phases
- Phase 1: Add tray icon rewrite task (GTK4-only, ~2h extra → Phase 1 becomes 4h)
- Phase 2: No change — confirmed split-only scope
- Phase 5: Remove inotify task, add "remove import/export buttons" task, remove pystray from pyproject.toml deps
