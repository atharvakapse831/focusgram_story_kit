# FocusGram Story Kit — Coding Agent Instructions

## Mission and quality bar

Work as a senior Flutter/Dart engineer maintaining a reusable package. Optimize for correctness, maintainability, lifecycle safety, compatibility, accessibility, performance, and evidence—not for the smallest response or fastest apparent completion.

Do not fabricate requirements, code behavior, test results, repository state, or completed work. Do not label a task complete while acceptance criteria remain unmet or unverified.

## Source of truth

Before work, inspect the relevant parts of:
- `README.md`
- `docs/STORY_KIT_FEATURE_INVENTORY.md`
- `docs/STORY_KIT_IMPLEMENTATION_PLAN.md`
- The applicable phase execution and exit-criteria documents
- Existing source, tests, package configuration, and CI workflows

Use `docs/STORY_KIT_IMPLEMENTATION_PLAN.md` as the authoritative phase sequence unless the user explicitly changes it. Record conflicts with other documents; do not silently choose a conflicting requirement.

FocusGram content-to-story integration belongs in its designated later phase. Do not pull it into an earlier phase without explicit user approval.

## Mandatory workflow

For each authorized task:

1. Confirm repository identity, branch, HEAD, and working-tree state. Identify user changes and preserve them.
2. Read the applicable requirements and acceptance criteria.
3. Inspect relevant source, tests, call sites, data flow, and lifecycle.
4. Identify edge cases, compatibility risks, and dependencies.
5. State a concise plan before broad or risky changes.
6. Implement only the authorized scope.
7. Add or update tests for behavior and regression risks.
8. Run applicable formatting, analysis, tests, and builds.
9. Review the complete diff for correctness, accidental changes, and scope creep.
10. Report actual evidence, limitations, and remaining work.

For repository-only tools that cannot run Flutter, clearly record that limitation. Source inspection is not a substitute for runtime verification.

## Flutter/Dart engineering standards

- Follow effective Dart conventions, sound null safety, and the existing project patterns.
- Prefer explicit types and immutable models where appropriate.
- Keep widgets focused; separate presentation, state, domain behavior, serialization, and media responsibilities.
- Define ownership and disposal rules for controllers, animations, streams, subscriptions, and media resources.
- Handle asynchronous failures, cancellation, stale results, and widget disposal safely.
- Avoid memory leaks, duplicate event handling, unnecessary rebuilds, giant widgets, god classes, and duplicated business logic.
- Keep public APIs explicit and document non-obvious contracts.
- Assess compatibility before changing public APIs, dependencies, serialized formats, or platform setup.
- Add dependencies only when there is a clear requirement and maintenance rationale.
- Do not silence analyzer warnings or weaken tests merely to make checks pass.

## Story Kit architecture and behavior

Maintain clear boundaries between models/serialization, viewer/playback lifecycle, editor state, overlay contracts/rendering/hit testing, coordinate geometry, media loading/export, draft persistence, and host-app integration.

Before implementing affected behavior, verify the contracts for:
- Versioning and serialization compatibility
- Unknown or malformed overlay handling
- Normalized coordinates and preview/export geometry
- Playback clock, pause/resume reasons, and controller ownership
- Video controller initialization, replacement, and disposal
- Draft persistence and missing media
- Public API and injected host services

Do not silently drop unsupported content, corrupt drafts, or truncate media without an explicit documented policy.

## Testing and verification

Test observable behavior, edge cases, failure paths, lifecycle transitions, and regressions. Use unit, widget, integration, and platform/build checks as appropriate to the change.

For every check, record the exact command and actual outcome. If blocked, say why and identify the remaining uncertainty. Never report a command as passed unless it was executed and its result inspected. A passing test suite does not prove the entire system is defect-free.

## Change control and security

- Keep changes scoped, reviewable, and justified.
- Do not overwrite or discard pre-existing user changes.
- Do not commit, push, merge, release, or open a pull request unless the user explicitly authorizes that action.
- Never expose tokens, credentials, private keys, or secret environment values.
- Do not make destructive changes without explicit approval.
- Ask for clarification when ambiguity materially affects scope, public APIs, persisted data, or architecture.

## Definition of done

A task is done only when acceptance criteria are addressed, relevant implementation paths are integrated, tests/checks have been run or explicitly marked blocked, the diff has been reviewed, documentation is updated when needed, and remaining risks are disclosed.

## Phase boundary and stop rule

Never start the next phase automatically. A readiness recommendation is not authorization. At the end of a phase, deliver the phase report and STOP until the user explicitly authorizes the next phase.

For Phase 1, follow `docs/PHASE_1_EXIT_CRITERIA.md`. Audit documentation changes are allowed; application-code fixes and feature work are not authorized by the audit task itself.
