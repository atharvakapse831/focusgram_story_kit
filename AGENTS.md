# AGENTS.md — FocusGram Story Kit Coding Agent Rules

This repository is a production Flutter/Dart package. These rules bind every
coding agent (human or automated) working in this repository.

## 1. Repository documentation is the source of truth

Read these before starting any task:

- `README.md` — package overview and current implementation claims.
- `docs/STORY_KIT_FEATURE_INVENTORY.md` — target scope and acceptance criteria.
- `docs/STORY_KIT_IMPLEMENTATION_PLAN.md` — authoritative phase sequence.
- `docs/PHASE_1_EXECUTION_PLAN.md` — audit-only procedure.
- `docs/PHASE_1_AUDIT_REPORT.md` — evidence record; only as good as the runs recorded in it.
- `docs/PHASE_1_EXIT_CRITERIA.md` — the Phase 1 exit gate.
- `docs/CODING_AGENT_WORKFLOW.md` — required per-task workflow.
- Relevant source code, tests, and package configuration.

Treat the seven-phase sequence in `STORY_KIT_IMPLEMENTATION_PLAN.md` as
authoritative. Do not silently pick between conflicting documents — report
the conflict in your final report and act on the most restrictive reading
until the owner resolves it.

Keep FocusGram Content-to-Story integration in its planned later phase. Never
pull it forward without explicit owner approval.

## 2. Mandatory per-task workflow

Follow `docs/CODING_AGENT_WORKFLOW.md` for every task. In brief:

1. Understand the requirement and acceptance criteria.
2. Inspect the existing implementation and every relevant call site.
3. Trace the complete data flow and lifecycle the change touches.
4. Identify dependencies, edge cases, regressions, and architectural constraints.
5. Propose a plan for non-trivial work before implementing.
6. Implement the smallest complete, maintainable solution.
7. Add or update tests that validate observable behavior.
8. Run relevant formatting, static analysis, and tests; inspect results.
9. Review the final diff for regressions, accidental changes, and incomplete work.
10. Report results with evidence.

## 3. Quality bar

- No placeholder functionality, speculative fixes, or unnecessary abstractions.
- Every change needs a clear technical justification.
- Preserve existing public APIs and behavior unless a redesign is requested.
- Do not begin broad feature work while audit or architecture gates are open.

## 4. Stop rules

- Never implement application features during an audit-only task.
- Never commit, push, or open pull requests without explicit authorization.
- When a phase's exit criteria are met, update the phase documentation,
  provide the final report, and stop. Do not begin the next phase.

## 5. Verification honesty

- Never claim a command passed unless it was actually executed and inspected.
- Never fabricate implementation progress, test results, or repository state.
- If a check cannot run, say so, identify the remaining risk, and state the
  verification still required.
