# Phase 3: Update Documentation

## Context
- Parent plan: [plan.md](plan.md)
- Depends on: [Phase 1](phase-01-fix-build-blockers.md)
- Source: [Project Health Audit](reports/project-health-audit.md)

## Overview
- **Priority:** High
- **Effort:** 4h
- **Status:** completed
- **Description:** Fix critically outdated docs — README describes wrong project, PDR says 70% Phase 1 but 80% of Phases 1-5 are done

## Key Insights
- README.md describes AutoHotkey Windows file structure, not the Python Linux project
- Docs last updated 2026-01-17/18, ~3 weeks of development undocumented
- PDR, system-architecture.md, codebase-summary.md all describe Phase 1 only
- 5 plan phases have been executed but docs don't reflect this
- Missing: CHANGELOG.md, accurate HOTKEYS.md

## Requirements
- README.md must describe the actual Python/Linux project
- All docs/*.md files must reflect current implementation state (Phases 1-5)
- Installation instructions must include system dependencies (GTK4, input group)
- New contributors should be able to understand the project from docs alone

## Related Code Files
- `README.md` — complete rewrite needed
- `docs/project-overview-pdr.md` — update phase status
- `docs/system-architecture.md` — update to reflect daemon+GUI+backends
- `docs/codebase-summary.md` — update file listing and module descriptions
- `docs/installation.md` — add system deps (GTK4, udev, ydotool)
- `docs/HOTKEYS.md` — verify exists and is accurate

## Implementation Steps
1. Rewrite README.md: project description, features, installation, usage, screenshots placeholder
2. Update project-overview-pdr.md: mark Phases 1-4 complete, Phase 5 partial, Phase 6 planned
3. Update system-architecture.md: add daemon architecture, GUI layer, backend abstraction diagram
4. Update codebase-summary.md: list all 31 files with current descriptions
5. Update installation.md: add system dependencies section (GTK4, input group, ydotool)
6. Verify HOTKEYS.md accuracy against actual keycode_mappings.py
7. Create CHANGELOG.md with entries from recent git commits

## Todo List
- [ ] Rewrite README.md
- [ ] Update PDR phase status
- [ ] Update system architecture doc
- [ ] Update codebase summary
- [ ] Add system deps to installation.md
- [ ] Verify/create HOTKEYS.md
- [ ] Create CHANGELOG.md

## Success Criteria
- README.md accurately describes Python/Linux project
- No doc references "AutoHotkey" as current implementation
- Phase status reflects reality (1-4 complete, 5 partial)
- New user can install following docs alone
- CHANGELOG.md covers commits since 2026-01-18

## Risk Assessment
- **Low risk**: Documentation-only changes, no code affected
- May miss features if only reading code — cross-reference with git log

## Next Steps
- Phase 5 (polish) will add project.urls to pyproject.toml linking to docs
