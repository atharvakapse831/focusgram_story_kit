# Phase 1 — Repository Audit & Baseline Execution Plan

**Repository:** [atharvakapse831/focusgram_story_kit](https://github.com/atharvakapse831/focusgram_story_kit)  
**Branch reviewed:** `main`  
**Baseline commit:** `9dde74c0a52d4fc9a7483f20e01cf63ddadf705e`  
**Scope:** Assess existing code and capture evidence. Do not implement editor features, refactor production code, or add FocusGram content-sharing integration in this phase.

## 1. Goal

Produce a reliable, repeatable picture of the package's real state before any implementation sequence is chosen. Every feature status must be evidence-backed; README claims and planned-inventory checkboxes are not proof that behavior works.

### Required deliverables

1. [`docs/PHASE_1_AUDIT_REPORT.md`](PHASE_1_AUDIT_REPORT.md) — baseline results, per-feature status, findings, risks, logs, and exit decision.
2. [`docs/PHASE_1_EXECUTION_PLAN.md`](PHASE_1_EXECUTION_PLAN.md) — this plan.
3. A requirement traceability matrix linking each relevant section in [`STORY_KIT_FEATURE_INVENTORY.md`](STORY_KIT_FEATURE_INVENTORY.md) to source evidence, tests, and status.
4. A prioritized issue list with exact paths/symbols, reproducible evidence, severity, impact, and recommended next action.
5. An evidence bundle or report appendix recording commit SHA, toolchain versions, command invocations, exit codes, and captured summaries.

## 2. Baseline observed from GitHub (not yet a runtime verification)

At reviewed commit `9dde74c...`, the recursive tree returned 19 entries and was not truncated. It includes:

- Public barrel: `lib/focusgram_story_kit.dart`
- Models: `lib/models/story_item_model.dart`, `story_group_model.dart`
- Overlays: `lib/overlays/story_overlay.dart`, `overlay_codec.dart`
- Viewer: `lib/viewer/story_kit_viewer.dart`, `story_overlay_renderer.dart`
- Two test files: `test/overlay_codec_test.dart`, `test/story_overlay_renderer_test.dart`
- `pubspec.yaml`, `README.md`, and the feature inventory.

The current manifest declares Dart `^3.5.0`, Flutter `>=3.24.0`, runtime dependencies `cached_network_image` and `video_player`, plus `flutter_test` and `flutter_lints`. The README describes a pre-1.0 viewer/overlay skeleton, and the inventory itself explicitly warns that it is a target scope rather than proof of implementation.

No `.github` directory appears in the reviewed recursive tree. That means a repository-owned GitHub Actions workflow was not present in this snapshot; it does **not** rule out checks run by external systems or prove no CI exists elsewhere.

Source samples show that the item model currently supports image/video, a display duration, overlays, and an optional `Map<String, dynamic>? sharedContent`; the decoder returns `null` for unknown overlay types. These are audit leads only. Phase 1 must inspect edge cases and tests before classifying them as defects.

**Not yet verified:** local toolchain availability; dependency resolution; test outcome; analyzer outcome; build/runtime behavior; platform compatibility; video plugin lifecycle behavior; coverage; license/compliance; or release readiness.

## 3. Operating rules

- Freeze scope to audit, run existing checks, document findings, and propose follow-up work.
- Do not change production behavior during the audit. If a blocker requires a tiny setup/documentation correction to run checks, document it first and isolate that change for explicit review.
- Use a clean checkout of the recorded commit; do not use an already-mutated working tree as the only evidence.
- Record exact commands, versions, working directory, time, exit code, and relevant output.
- Distinguish **not present**, **not applicable**, **not run**, **blocked**, and **failed**. Do not treat missing evidence as a pass.
- For every finding, identify the code path and consequence. Separate confirmed defects from questions that need runtime reproduction.
- Do not add FocusGram API/auth/backend dependencies or implement share payloads in Phase 1.

## 4. Ordered work breakdown

### Task 1 — Pin and inventory the audited revision

1. Confirm repository, default branch, exact commit SHA, clean checkout, and full tree.
2. Enumerate all source, tests, manifests, analysis config, docs, examples, assets, platform folders, lockfiles, licenses, and CI files.
3. Confirm no files are omitted by truncated directory/API listings.
4. Capture the tree and revision in the report.

**Evidence:** commit SHA; full tree; a file inventory with size and role.

### Task 2 — Establish the toolchain and reproducible baseline

In a clean checkout, capture:

```bash
git status --short
git rev-parse HEAD
flutter --version
dart --version
flutter doctor -v
flutter pub get
flutter analyze
flutter test --reporter expanded
flutter pub outdated
```

Where supported by the installed toolchain, also record:

```bash
flutter test --coverage
```

Notes:
- Run one command at a time and preserve each exit code and output.
- If Flutter is unavailable, mark the command **blocked** and identify the required environment; never invent a result.
- `flutter doctor -v` is environment context, not a package pass/fail verdict.
- `flutter pub outdated` reports candidate updates; an outdated package is not automatically a defect. Assess compatibility and changelogs before recommending upgrades.
- `flutter test --coverage` generates coverage only where supported by the selected runner; coverage volume is not proof of behavioral completeness.
- Do not run automatic dependency upgrades or `--fix` commands during baseline capture.

**Evidence:** tool versions; dependency resolution result; analyzer output; per-test results; coverage summary if available; outdated-dependency report.

### Task 3 — Audit package contract and public API

Inspect:
- `pubspec.yaml`: SDK constraints, dependency classes, version, assets, plugin/platform declarations, metadata.
- `lib/focusgram_story_kit.dart`: every public export and accidental exposure of internal helpers.
- Public constructors, enums, callbacks, widget parameters, controller contracts, error/result behavior, and documented lifecycle.
- Import boundaries and any dependency on FocusGram app internals, networking, auth, routing, or persistence.

Questions:
- Can a host application use the package via the barrel file alone?
- Are defaults and units clear and backward-compatible?
- Are mutable collections exposed from otherwise stable model objects?
- Are public APIs and exported types consistent with docs?
- Are breaking changes and pre-1.0 instability explicit?

**Evidence:** API/export checklist; public symbol map; sample-client integration feasibility (if actual example app is absent, report that limitation).

### Task 4 — Audit data models and serialization

Inspect:
- `StoryItemModel` and `StoryGroupModel`
- all `StoryOverlay` variants and `toJson` forms
- overlay decoding and list-decoding helpers
- JSON type assumptions, defaults, nullable fields, IDs, coordinates, numeric boundaries, URL validation, date/time formats, unknown fields/types, and malformed payloads.

Test cases to inspect or add later as backlog recommendations (do not create product behavior in this phase):
- round-trip encode/decode per known overlay type;
- missing required keys and wrong JSON value types;
- unknown type and unknown fields;
- empty/oversized lists and invalid indices;
- non-finite/out-of-range coordinates or numbers;
- timezone and invalid date parsing;
- stable ID and metadata preservation;
- schema versioning / migration strategy;
- whether silently dropping unknown overlays loses user content.

Record behavior first; propose changes only in findings/backlog.

### Task 5 — Audit viewer state, media lifecycle, and rendering

Read viewer and renderer fully, plus related tests. Trace:
- initial state → media loading → playback/progress → pause/resume → previous/next item/group → completion → error/retry → disposal;
- timer ownership/cancellation and widget lifecycle changes;
- image/network caching/loading/error behavior;
- video controller creation, initialization, pause, completion, app lifecycle, listener management, and disposal;
- interactions between video duration, progress indicator, gesture zones, and overlay tappability;
- callback invocation semantics (exactly-once where required), mounted checks, async races, and stale callbacks;
- layout constraints, safe areas, varying aspect ratios, text overflow, hit testing, and accessibility.

The README/model mention a default 30-second video cap. Verify where that rule is implemented, whether it applies consistently, and whether it is a product requirement or an undocumented limitation. Do not change the rule in Phase 1.

### Task 6 — Audit tests and testability

Map test cases to behaviors rather than counting tests. Review:
- normal paths, edge cases, failure paths, and lifecycle cases;
- deterministic timing or timer control;
- fake/mock media boundaries versus tests requiring real platform plugins;
- test data fidelity and meaningful assertions;
- widget disposal and asynchronous error handling;
- regression tests for each confirmed bug;
- missing tests that block confidence.

Minimum expected coverage *areas* are not a numeric coverage target: codec/model tests, viewer navigation/progress tests, overlay rendering/interaction tests, media loading/error tests, lifecycle/disposal tests, and public API smoke tests. For unimplemented editor functionality, mark the tests as future requirements, not current failures.

### Task 7 — Dependency, platform, and supply-chain review

For each direct dependency:
- record declared and resolved versions, purpose, transitive dependencies, maintenance/release signals, known compatibility constraints, and upgrade risk;
- review whether `video_player` introduces platform plugin requirements despite the manifest comment saying there are no native plugin platforms in this package;
- validate the real supported platform matrix instead of assuming pure Dart/UI means platform-neutral;
- inspect minimum SDK constraints against package dependencies and CI/toolchain availability;
- identify unpinned or unsafe dependency overrides and missing lockfile policy (for a reusable package, decide whether a lockfile is committed for a reason, rather than blindly requiring one);
- examine license file/dependency license obligations and attribution requirements;
- optionally run pub.dev's package health tooling such as `pana` in a disposable copy only, because package-scoring tools may modify files.

Do not auto-upgrade packages as part of this audit.

### Task 8 — Review repository hygiene and developer experience

Check:
- README matches actual behavior and setup;
- package license and copyright/attribution for ported/adapted code;
- changelog/versioning and issue/reporting instructions;
- examples or example host app;
- formatting and static-analysis configuration;
- CI definitions and whether CI results are available;
- ignored files, generated output, secrets, local paths, accidental app-specific imports;
- docs for unsupported platforms, media limits, and known constraints.

If no workflow is tracked, recommend a lightweight CI workflow for future implementation phases but do not add one during the audit unless separately approved.

### Task 9 — Build the traceability matrix and risk register

For every feature area in the inventory, record:
- requirement ID/section;
- expected behavior;
- source file/symbol;
- related test(s);
- status: implemented-verified / implemented-unverified / partial / planned / deferred / blocked;
- evidence and commit SHA;
- gap and next action.

Risk record fields:
- ID and title;
- severity (Critical / High / Medium / Low / Info);
- likelihood;
- user/package impact;
- reproducibility/evidence;
- affected files/symbols;
- mitigation/recommended task;
- dependencies and suggested phase.

Severity guidance:
- **Critical:** data loss, crashes across core use, severe security/privacy exposure, or package unusable under supported baseline.
- **High:** primary viewer/codec behavior broken, repeatable lifecycle leak/crash, major data corruption, or unusable supported platform.
- **Medium:** important edge path broken, recoverable inconsistency, significant portability or maintainability risk.
- **Low:** isolated polish/doc issue with limited impact.
- **Info:** uncertainty, observation, or improvement suggestion without demonstrated defect.

Prioritize proven user-visible breakage above style cleanup.

### Task 10 — Exit review and next-phase recommendation

1. Summarize confirmed defects separately from unverified risks and planned/missing functionality.
2. Group fixes by prerequisite and impact; identify blockers to Phase 2 core architecture/editor.
3. Give a go/no-go recommendation with explicit outstanding unknowns.
4. Ensure future feature implementation tasks can be independently tested and acceptance-checked.

## 5. Initial priority questions specific to this repository

These are hypotheses to verify, not pre-declared bugs:

1. **Video policy and lifecycle:** how the 30-second cap interacts with actual video duration, progress, app lifecycle, and disposal.
2. **Model persistence boundary:** `StoryItemModel.sharedContent` is a dynamic map but no schema/version contract is visible in the current model excerpt; assess validation and compatibility requirements.
3. **Unknown overlay handling:** codec comments indicate unknown types become `null`; determine whether list decoding silently discards them and whether this is acceptable for forward compatibility.
4. **Dependency/platform declaration:** `video_player` is declared while the manifest comment says there are no native plugin platforms; verify build/test behavior and clarify package versus host app plugin setup.
5. **Test breadth:** the tree shows two test files; inspect their actual assertion coverage and identify lifecycle, viewer flow, and public API gaps.
6. **CI evidence:** no tracked `.github` folder was present in the repository tree. Find out whether other CI is configured; otherwise record that clean-run evidence must be produced manually.
7. **Example integration:** no example directory appears in the current tree; verify whether a simple host app can consume public APIs without private imports.
8. **License/provenance:** investigate licensing and attribution for code patterns ported from third-party story packages and for each dependency.

## 6. Completion checklist

- [ ] Audited SHA and clean checkout recorded.
- [ ] Complete tree and file inventory saved.
- [ ] Toolchain versions captured.
- [ ] Dependency resolution attempted and outcome recorded.
- [ ] Analyzer and tests run or explicitly blocked with reason.
- [ ] All production Dart files in the current tree read, not just snippets.
- [ ] Model/codec/viewer/rendering/lifecycle assessment completed.
- [ ] Public API, dependency, supported-platform, license, and docs reviews completed.
- [ ] Each inventory category has an evidence-backed status.
- [ ] Findings have severity, repro/evidence, file/symbol, and next action.
- [ ] Phase 1 audit report is complete and independently understandable.
- [ ] No product feature implementation or FocusGram content-sharing changes were made.
- [ ] Exit review recommends the next implementation task based on audit evidence.

## 7. Authoritative reference sources

- Flutter testing overview: https://docs.flutter.dev/testing/overview
- Flutter testing and debugging: https://docs.flutter.dev/testing
- Dart analyzer: https://dart.dev/tools/dart-analyze
- Dart analysis options: https://dart.dev/tools/analysis
- Pub package layout conventions: https://dart.dev/tools/pub/package-layout
- Pub dependencies: https://dart.dev/tools/pub/dependencies
- Pub outdated command: https://dart.dev/tools/pub/cmd/pub-outdated
- pub.dev package scoring / `pana`: https://pub.dev/help/scoring
- GitHub Actions workflow syntax: https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions

Use these as guidance, not as a substitute for inspecting this repository or running the actual commands.
