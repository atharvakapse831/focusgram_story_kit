# Coding Agent Workflow and Change Control

## 1. Goal

Make FocusGram Story Kit work predictable, reviewable, testable, and safe. Follow this workflow for every authorized task.

## 2. Source-of-truth order

1. Explicit user instructions for the current task
2. `AGENTS.md`
3. `docs/STORY_KIT_IMPLEMENTATION_PLAN.md` for phase sequence
4. `docs/STORY_KIT_FEATURE_INVENTORY.md` for feature scope and acceptance intent
5. Applicable phase execution and exit-criteria documents
6. Existing source/tests as evidence of current behavior

If sources conflict, document the conflict. Ask for clarification when it changes scope, compatibility, or architecture; do not silently invent a resolution.

## 3. Before changes

- Verify repository owner/name, branch, current HEAD, and working-tree status.
- Identify existing user changes and never overwrite them.
- Read relevant requirements, source, tests, and call sites.
- Identify data flow, resource lifecycle, dependencies, failure paths, and regression risks.
- Define a bounded plan and observable acceptance criteria for non-trivial work.

## 4. During implementation

- Make the smallest complete solution consistent with the architecture.
- Keep unrelated refactors out of the change.
- Use typed models, explicit contracts, and clear ownership.
- Handle asynchronous races, errors, disposal, and malformed inputs.
- Add tests for normal behavior, edge cases, and regressions.
- Update docs when behavior, public APIs, configuration, or architecture changes.
- Do not pull features forward from later phases without explicit approval.

## 5. Verification and review

- Run applicable formatting, analysis, tests, and builds.
- Record exact commands and actual results.
- Treat unavailable tooling as blocked, not passed.
- Review the complete diff for correctness, accidental edits, secrets, compatibility, and scope creep.
- Report failures and unresolved risks plainly; do not weaken tests to hide them.

## 6. Git and authorization

Do not commit, push, merge, release, or create a pull request unless the user explicitly authorizes that action. When authorized, verify the target repository/branch and current HEAD first, make a focused commit, and report the resulting commit SHA and changed paths. Never force-push or rewrite history unless specifically authorized.

## 7. Completion report

Every final report must include:
- Summary and files changed
- Acceptance criteria completed and incomplete
- Design decisions and compatibility impact
- Tests/commands executed and actual results
- Blockers, limitations, and remaining risks
- Recommended next action

Do not claim a task is complete while required criteria remain unmet.

## 8. Phase gates — mandatory

A phase boundary requires an explicit user approval to continue. A recommendation, checklist completion, or apparent lack of remaining work does not authorize the next phase.

At the end of a phase, publish its report and STOP. Do not start follow-up implementation tasks automatically.

For Phase 1, follow `docs/PHASE_1_EXIT_CRITERIA.md`; audit documentation updates are in scope, but application-code fixes and feature development require separate explicit authorization.
