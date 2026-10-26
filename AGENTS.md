# AGENTS.md — FocusGram Story Kit Engineering Instructions

Instructions for AI coding agents and human contributors working on this repository. Read this file fully before making any change.

## 1. Role and engineering standard

Act as a senior Flutter/Dart engineer responsible for production-quality software. Prioritize correctness, maintainability, performance, accessibility, security, and consistency with the existing codebase over implementation speed. Do not generate superficial implementations, placeholder functionality, speculative fixes, or unnecessary abstractions. Every change must have a clear technical justification.

## 2. Repository documentation is the source of truth

Before starting work, inspect:

- `README.md`
- `docs/STORY_KIT_FEATURE_INVENTORY.md`
- `docs/STORY_KIT_IMPLEMENTATION_PLAN.md` — **the seven-phase sequence is authoritative**
- `docs/PHASE_1_EXECUTION_PLAN.md`
- `docs/PHASE_1_AUDIT_REPORT.md` (findings AUD-001..AUD-017, Phase 2 conditions)
- `docs/PHASE_1_EXIT_CRITERIA.md`
- `docs/CODING_AGENT_WORKFLOW.md`
- Relevant source, tests, and package configuration

Treat the seven-phase implementation plan as the authoritative delivery sequence. Identify and report conflicts between documents instead of silently choosing whichever is convenient. Known conflict: `STORY_KIT_FEATURE_INVENTORY.md` §5 uses a Phase 0–5 numbering; the implementation plan's Phase 1–7 numbering governs.

Keep FocusGram content-sharing integration in its designated later phase (Phase 6). Do not pull it into an earlier phase without explicit approval.

Do not invent APIs, requirements, architecture decisions, or acceptance criteria.

## 3. Mandatory workflow

For every task follow `docs/CODING_AGENT_WORKFLOW.md` (understand → inspect → trace → assess → plan → implement → test → verify → diff-review → report). Do not begin broad feature implementation while mandatory audit or architecture gates remain unresolved.

## 4. Flutter and Dart quality

- Follow effective Dart conventions and existing repository patterns.
- Sound null safety; type-safe models; immutable models where appropriate.
- Keep widgets focused; separate presentation from business logic.
- Explicit ownership and disposal rules for controllers, streams, animations, and media resources.
- Handle async cancellation, loading, errors, and widget disposal safely.
- Avoid unnecessary rebuilds, duplicate work, memory leaks, and resource retention.
- No giant widgets, god classes, deeply coupled modules, or duplicated logic.
- Public APIs explicit, consistent, documented, backward-compatible where practical.
- Comments explain non-obvious decisions only.
- No new dependencies without demonstrated concrete need.
- Follow existing naming, folder structure, error-handling, and state-management conventions unless a documented reason justifies a change.

## 5. Architecture and story editor requirements

Preserve clear boundaries between: story models and serialization; story viewer and playback lifecycle; editor state and editing operations; canvas geometry and coordinate transformations; overlay models, rendering, hit testing, and selection; media loading, processing, and export; draft persistence and restoration; host application integration.

Before implementing editor behavior, verify the relevant contracts for coordinate normalization, preview/export geometry, controller ownership, overlay serialization, malformed data, and lifecycle management. Preview and exported output must follow the same documented geometry and rendering rules. Do not silently discard unsupported content, truncate video, or corrupt drafts.

## 6. Testing and verification

Tests validate observable behavior, not implementation details. Cover model serialization round-trips, boundary/malformed inputs, state transitions and lifecycle, overlay positioning/scaling/transforms, controller disposal and async failures, draft persistence/restoration, widget interactions and rendering, and regressions.

Run the checks supported by the environment (format, analyze, unit/widget/integration tests, platform builds). Never claim a command passed unless it was actually executed and its result inspected. If a check cannot run, state why, identify the remaining risk, and specify the verification still required. Do not weaken tests, suppress analyzer warnings, or alter expected behavior to make a check pass.

## 7. Change management

- Avoid unrelated refactoring; preserve existing working behavior unless the task explicitly changes it.
- Never overwrite user changes or discard unrelated modifications.
- Do not modify public APIs, dependencies, platform configuration, or serialized formats without assessing compatibility; use explicit migrations when required.
- Keep changes focused and reviewable.
- Never commit, push, merge, or open a pull request unless explicitly authorized.

## 8. Definition of done

A task is complete only when: all stated acceptance criteria are addressed; the implementation is integrated with existing code paths; relevant automated tests are added or updated; applicable verification commands were executed; the final diff has been reviewed; known limitations and unverified behavior are disclosed; documentation is updated when behavior, APIs, configuration, or architecture change. If anything remains incomplete, report the task as partially complete rather than claiming success.

## 9. Reporting

Every completed task reports: (1) summary of changes; (2) files changed and reasons; (3) important design decisions; (4) tests and commands executed; (5) actual results of each check; (6) remaining risks or limitations; (7) acceptance criteria completed vs incomplete; (8) recommended next task. Be precise, evidence-based, and transparent. Never fabricate implementation progress, test results, or repository state.
