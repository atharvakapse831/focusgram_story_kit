# Phase 1 — Audit Exit Criteria

## Purpose

Establish an evidence-based view of the current FocusGram Story Kit repository before feature implementation. Phase 1 is an audit, not a feature-development or remediation phase.

## Scope

Inspect, as applicable:
- Repository identity, branch, HEAD, and working-tree state
- README, feature inventory, implementation plan, execution plan, and existing audit report
- Source tree, public API, models, serialization, and dependency configuration
- Viewer playback/navigation, overlays, media/controller lifecycle, and rendering geometry
- Existing tests, their meaningful coverage, and missing regression cases
- Flutter/Dart SDK constraints, dependency resolution, platform/plugin assumptions
- CI workflows, package metadata, license/provenance, and supported-platform claims
- Conflicts among requirements, roadmap phases, and acceptance criteria

## Required deliverables

1. Updated `docs/PHASE_1_AUDIT_REPORT.md`
2. Findings register with stable IDs, severity, evidence, impact, and recommended action
3. Verification log with exact commands and actual outcomes
4. Documentation-conflict register
5. Unresolved product/architecture decisions
6. GO, CONDITIONAL GO, or NO-GO recommendation, with rationale and prerequisites
7. Explicit list of completed, blocked, and unverified criteria

## Evidence and classification

Every finding should have an ID, severity, category, description, affected path/symbol, evidence, impact, recommended remediation, and verification status.

Use these evidence classes:
- **Runtime-confirmed:** reproduced in a test or runtime with recorded evidence.
- **Source-confirmed:** directly demonstrated by inspected source, but not runtime-reproduced.
- **Suspected risk:** plausible issue requiring more evidence.
- **Coverage gap:** behavior lacks adequate automated verification.
- **Documentation conflict:** project documents disagree.
- **Blocked:** the check could not be performed, with reason recorded.

Do not call a source-level observation runtime-confirmed. A missing test is not automatically a product defect. Do not infer runtime behavior solely from static reading.

## Severity scale

- **P0 — Critical:** severe security/data-loss issue or fundamental blocker making proceeding unsafe.
- **P1 — High:** substantial correctness, lifecycle, compatibility, or architecture risk that must be resolved before the affected work proceeds.
- **P2 — Medium:** meaningful quality, performance, maintainability, or coverage concern.
- **P3 — Low:** minor, non-blocking improvement.

Severity must reflect evidence and impact, not the effort needed to fix the issue.

## Verification

Attempt applicable checks when a suitable environment is available:
- `flutter --version`, `dart --version`, and `flutter doctor -v`
- `flutter pub get`
- `dart format --output=none --set-exit-if-changed .` or the repository's documented equivalent
- `flutter analyze`
- `flutter test --reporter expanded`
- Relevant targeted tests, supported platform builds, dependency/license checks, and CI review

Record environment/tool versions, exact command, actual exit/result, and meaningful output. If blocked, state the environment limitation; do not fabricate output. Reproduction is required before labeling findings runtime-confirmed.

## Documentation and architecture gates

Explicitly assess:
- Alignment between the feature inventory and the authoritative seven-phase implementation plan
- FocusGram content-to-story integration remaining in its planned later phase
- Requirement traceability from acceptance criteria to code and tests
- Model/serialization versioning and unknown/malformed payload policy
- Viewer clock, pause/resume semantics, controller ownership, and lifecycle handling
- Normalized coordinate system and preview/export geometry
- Video duration, trimming, export, and long-video policy
- Supported platforms and native plugin expectations
- Public API compatibility and host-app integration contracts

Recommend decisions; do not silently change product scope or implement fixes during the audit.

## Exit criteria

Phase 1 may be marked COMPLETE only when:
- The relevant source and documentation have been inspected.
- Applicable verification checks have been executed, or the exit policy explicitly accepts a documented block with user approval.
- Findings and conflicts are evidence-based and correctly classified.
- Critical risks, unresolved decisions, and remaining uncertainties are documented.
- The report contains a justified readiness recommendation.
- The final diff is reviewed and contains no unauthorized application-code changes.

Discovering defects does not require fixing them during Phase 1. Remediation should be separately authorized.

## Mandatory stop rule

When the exit criteria are met, update the report, review the diff, provide the final report, and STOP. Do not begin Phase 2, implement features, or fix application code without explicit user authorization.

If required checks are blocked, mark Phase 1 **BLOCKED / NOT COMPLETE**, list outstanding criteria and the precise next action, then STOP. A GO recommendation is not permission to proceed.

## Final report format

- Phase/status
- Repository, branch, and HEAD
- Files changed
- Findings by severity and evidence class
- Commands and actual results
- Unresolved decisions and risks
- Readiness recommendation and prerequisites
- Outstanding exit criteria
- Confirmation of scope boundary and stop
