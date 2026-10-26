# Coding Agent Workflow — FocusGram Story Kit

The mandatory workflow for every task in this repository, whether executed by an AI agent or a human contributor. Companion to `AGENTS.md`.

## The 10-step workflow

1. **Understand the requirement and its acceptance criteria.** If criteria are ambiguous or conflicting, report the conflict; do not silently choose.
2. **Inspect the existing implementation and all relevant call sites.** Read before writing. Never change code you have not read in full.
3. **Trace the complete data flow and lifecycle** affected by the change — including controllers, listeners, timers, media resources, and disposal paths.
4. **Identify dependencies, edge cases, regression risks, and architectural constraints.** For Flutter/Dart: async gaps, stale-callback risks, disposal ordering, and widget rebuild behavior must be called out explicitly.
5. **Propose a concise implementation plan for non-trivial work.** State the smallest complete, maintainable solution and its trade-offs before writing code.
6. **Implement the smallest complete, maintainable solution.** Minimal and focused changes addressing one concern at a time. No placeholders, no speculative abstractions.
7. **Add or update appropriate tests** validating observable behavior: normal paths, boundary conditions, malformed inputs, state transitions, lifecycle and disposal, and regressions introduced by the change.
8. **Run relevant formatting, static analysis, and tests.** `dart format --set-exit-if-changed .`, `flutter analyze`, `flutter test` (plus relevant builds/integration tests where applicable). Never claim a command passed unless it was executed and its result inspected. If a check cannot run, record why, the residual risk, and the verification still required.
9. **Inspect the final diff for regressions, accidental changes, and incomplete work.** Ensure no unrelated files, unrelated refactors, or user modifications were touched.
10. **Report results with evidence** using the 8-section format in `AGENTS.md` §9.

## Working rules

- **Large or risky changes:** divide into small, independently verifiable steps. Prefer characterization tests before changing behavior with weak coverage; create seams before deep refactoring (Strangler Fig pattern for large replacements).
- **Gates:** do not begin broad feature implementation while mandatory audit or architecture gates are unresolved. Phase 2 entry conditions are listed in `docs/PHASE_1_EXIT_CRITERIA.md`.
- **Branches and writes:** never write to `main`. Use a focused branch per task. Never commit, push, merge, or open a PR without explicit authorization.
- **Docs:** update documentation whenever behavior, APIs, configuration, or architecture change; record status only with source/test evidence (inventory status vocabulary in `docs/STORY_KIT_FEATURE_INVENTORY.md` §2).
- **Findings and phases:** audit findings (AUD-xxx) are resolved in their designated phase per `docs/STORY_KIT_IMPLEMENTATION_PLAN.md`; do not pull later-phase work (e.g., FocusGram Content-to-Story) forward without explicit approval.
- **Blocked work:** document blockers precisely — the missing prerequisite, the residual risk, and the exact next action — rather than silently skipping.
- **Stopping condition:** when the current phase's exit criteria are satisfied, stop and report. Do not continue into the next phase without explicit approval, even if the recommendation is GO.
