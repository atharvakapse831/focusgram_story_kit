# AGENTS.md — Instructions for Coding Agents

This file defines the operating rules for any coding agent working in this repository. It is a binding reference alongside the repository docs. Where a task instruction conflicts with repository documentation, report the conflict explicitly instead of silently choosing whichever is convenient.

## Authoritative documents

Before starting any task, read:

1. `README.md`
2. `docs/STORY_KIT_FEATURE_INVENTORY.md`
3. `docs/STORY_KIT_IMPLEMENTATION_PLAN.md` — the seven-phase sequence is the authoritative delivery order
4. `docs/PHASE_1_EXECUTION_PLAN.md`
5. `docs/PHASE_1_AUDIT_REPORT.md` — current audit state, findings, and blockers
6. `docs/PHASE_1_EXIT_CRITERIA.md` — what Phase 1 must satisfy before Phase 2 begins
7. `docs/CODING_AGENT_WORKFLOW.md` — the mandatory per-task workflow

Relevant source code, tests, and `pubspec.yaml` must be inspected before any change.

## Non-negotiable rules

- **Phase discipline.** The seven-phase implementation plan is the authoritative delivery sequence. Never pull later-phase work into an earlier phase. FocusGram content-sharing integration stays in Phase 6 without explicit approval.
- **Audit gates block feature work.** Do not begin broad feature implementation while mandatory audit or architecture gates remain unresolved. Phase 1 is currently BLOCKED (see the audit report, Section 9).
- **Never fabricate.** Never claim a command passed unless it was actually executed and its output inspected. If a check cannot run, record it as BLOCKED with the reason and the remaining risk.
- **Evidence over assumption.** Do not invent APIs, requirements, architecture decisions, or acceptance criteria. Source-level observations are not runtime-confirmed defects; label them accordingly.
- **No silent data loss.** Do not silently discard unsupported content, truncate video, or corrupt drafts.
- **No unauthorized writes.** Never commit, push, or open a pull request unless explicitly authorized in chat. Never write to `main`.
- **Minimal changes.** No unrelated refactoring, no dependency additions without demonstrated concrete need, no modifications to public APIs, serialized formats, or platform configuration without compatibility assessment.
- **Conflicts are reported.** Known documentation conflicts are recorded in `docs/PHASE_1_AUDIT_REPORT.md` Section 6 (C1–C3). Report new ones the same way.

## Verification and reporting

- Run the checks supported by the environment: formatting, analyzer, unit/widget tests, and platform builds where available. Do not weaken tests or suppress analyzer warnings to make checks pass.
- End every task with the 8-section report defined in `docs/CODING_AGENT_WORKFLOW.md`.
- If any requirement remains incomplete, report the task as partially complete rather than claiming success.

## Current repository state (2026-10-26)

- Phase 1 static audit: complete (findings F1–F9, conflicts C1–C3 recorded).
- Phase 1 runtime verification: BLOCKED — no Flutter/Dart toolchain available to the audit agent; all runtime checks must be run in a suitable Flutter environment and recorded in the audit report before Phase 1 can close.
- No CI exists in this repository; all verification is manual until CI is added in an approved follow-up.
