# Coding Agent Workflow — FocusGram Story Kit

Mandatory per-task procedure for any coding agent in this repository.
It complements the rules in `AGENTS.md` and the phase gates in
`docs/PHASE_1_EXIT_CRITERIA.md` (and successors for later phases).

## 1. Understand

1. Read the assigned task and its acceptance criteria. Ask for missing
   requirements only when they cannot be found in the repository documents.
2. Identify the authoritative phase: check `STORY_KIT_IMPLEMENTATION_PLAN.md`
   and the current open gate. Never work ahead of an unresolved gate.
3. Inspect existing implementation and **every relevant call site** before
   changing anything.

## 2. Plan

4. Trace the complete data flow and lifecycle affected by the change:
   construction → use → update → dispose.
5. List dependencies, edge cases, regression risks, and architectural
   constraints (controllers, streams, timers, media resources, serialized
   formats, public API consumers).
6. For non-trivial work, propose a concise implementation plan before
   writing code. Split large or risky changes into independently
   verifiable steps.

## 3. Implement

7. Implement the smallest complete, maintainable solution. No placeholders,
   no speculative abstractions, no unrelated refactoring.
8. Preserve existing public interfaces and behavior unless the task
   explicitly changes them; assess compatibility for any serialized-format
   or API change and use explicit migrations where required.
9. Follow existing repository conventions (naming, folder structure,
   error handling, state management) unless a documented reason justifies
   a deviation.

## 4. Verify

10. Add or update tests validating **observable behavior**:
    serialization round trips, boundary/malformed inputs, state transitions,
    lifecycle/disposal, positioning/transform math, asynchronous failure.
11. Run the checks the environment supports and **inspect the output**:
    `dart format` (or `flutter format`), `flutter analyze`, relevant tests.
12. Never claim a command passed unless it was executed and its result
    inspected. If a check cannot run, record why, the remaining risk, and
    the verification still required.
13. Never weaken tests, suppress analyzer warnings, or alter expected
    behavior to make a check pass.

## 5. Review and report

14. Review the final diff for regressions, accidental changes, and
    incomplete work. Never overwrite unrelated user modifications.
15. Report: summary of changes, files changed and why, design decisions,
    commands run and their actual results, remaining risks/limitations,
    acceptance criteria completed vs incomplete, and the recommended next
    task. Disclose partial completion instead of claiming success.
16. Documentation must be updated when behavior, APIs, configuration, or
    architecture changes.

## 6. Change management

- No commits, pushes, or pull requests without explicit authorization.
- No feature implementation during audit-only tasks; no fixing of audit
  findings without authorization.
- Phase N+1 work begins only after the Phase N gate is approved.
- Conflicts between documents are reported, not silently resolved.

## 7. Definitions

- **Done:** acceptance criteria addressed, integrated with existing paths,
  tests added/updated, applicable checks executed and inspected, diff
  reviewed, limitations disclosed, docs updated where behavior changed.
- **Partially complete:** any requirement remains unmet — say so explicitly.
