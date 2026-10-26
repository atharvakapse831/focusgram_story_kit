# Coding Agent Workflow

**Repository:** atharvakapse831/focusgram_story_kit  
**Applies to:** every task performed by any coding agent in this repository  
**Companion documents:** `AGENTS.md` (rules), `docs/STORY_KIT_IMPLEMENTATION_PLAN.md` (phase sequence), `docs/PHASE_1_EXIT_CRITERIA.md` (audit gate)

## 1. Mandatory per-task workflow

1. Understand the requirement and its acceptance criteria.
2. Inspect the existing implementation and all relevant call sites.
3. Trace the complete data flow and lifecycle affected by the change.
4. Identify dependencies, edge cases, regression risks, and architectural constraints.
5. Propose a concise implementation plan for non-trivial work.
6. Implement the smallest complete, maintainable solution.
7. Add or update appropriate tests.
8. Run relevant formatting, static analysis, and tests.
9. Inspect the final diff for regressions, accidental changes, and incomplete work.
10. Report the results with evidence.

For large or risky changes, divide the work into small, independently verifiable steps. Do not begin broad feature implementation while mandatory audit or architecture gates remain unresolved.

## 2. Pre-flight reading (every task)

- `README.md`
- `docs/STORY_KIT_FEATURE_INVENTORY.md`
- `docs/STORY_KIT_IMPLEMENTATION_PLAN.md`
- `docs/PHASE_1_AUDIT_REPORT.md` (current state, findings, blockers)
- `docs/PHASE_1_EXIT_CRITERIA.md` (whether the audit gate is closed)
- Relevant source code, tests, and `pubspec.yaml`

## 3. Branch and write discipline

- Work on a task branch created from a verified `main` HEAD; never write to `main`.
- Do not commit, push, or open a pull request unless explicitly authorized in chat.
- Preserve all existing content; never overwrite user changes or discard unrelated modifications.
- Keep changes focused and reviewable; avoid unrelated refactoring.

## 4. Verification rules

- Run every check the environment supports: formatting, `flutter analyze`, `flutter test`, platform builds where applicable.
- Never claim a command passed unless it was executed and its output inspected.
- If a check cannot run, record it as BLOCKED with the reason, the remaining risk, and the verification still required.
- Never weaken tests, suppress analyzer warnings, or alter expected behavior to make a check pass.

## 5. Reporting contract

End every task with an 8-section report:

1. Summary of changes
2. Files changed and reasons
3. Important design decisions
4. Tests and commands executed
5. Actual results of each check
6. Remaining risks or limitations
7. Acceptance criteria completed versus incomplete
8. Recommended next task

Report partial completion as partial. Never fabricate implementation progress, test results, or repository state.

## 6. Findings and conflict handling

- Source-level observations must be labeled as such; they are not runtime-confirmed defects until reproduced with evidence.
- Record findings in `docs/PHASE_1_AUDIT_REPORT.md` (during Phase 1) or in the task report with file/symbol references (later phases).
- Report conflicts between documents (e.g., C1–C3 in the audit report) explicitly; never silently pick one side.
- Do not invent APIs, requirements, architecture decisions, or acceptance criteria.

## 7. Phase discipline

- Follow the seven-phase sequence in `docs/STORY_KIT_IMPLEMENTATION_PLAN.md`.
- FocusGram content-sharing integration stays in Phase 6 without explicit approval.
- Phase 2 work may not begin until `docs/PHASE_1_EXIT_CRITERIA.md` is fully satisfied.

## 8. Flutter/Dart quality bar

- Sound null safety, immutable models where appropriate, focused widgets, presentation/logic separation.
- Explicit ownership and disposal rules for controllers, streams, animations, and media resources.
- Safe async: cancellation, loading, errors, disposal; no leaks, duplicate work, or stale async assignment.
- No dependencies without demonstrated concrete need; no giant widgets or god classes.
- Follow existing naming, structure, error-handling, and state-management conventions unless a documented reason justifies a change.
