# Phase 1 — Repository Audit Report

**Status:** Complete (source-level audit; runtime checks blocked — see §4)  
**Repository:** [atharvakapse831/focusgram_story_kit](https://github.com/atharvakapse831/focusgram_story_kit)  
**Audited branch/commit:** `main` @ `a5e6cc9f74d2169a25eb51139a30ff73d7f47baf` (branch tip resolved 2026-10-26 UTC; full-file contents re-read at this tip)  
**Audit executor:** Ashna-X1 (AshnaAI), via GitHub read-only inspection — full-file source reads, no local Flutter toolchain available in this environment  
**Scope:** Audit only. No production code was changed. No features were implemented. No FocusGram Content-to-Story work was started.

## 1. Executive summary

The package is a small, coherent pre-1.0 Flutter library implementing a story **viewer** and a JSON-safe **interactive overlay engine** (poll, quiz, emoji slider, question box, countdown, link, mention). There is no editor, canvas, draft persistence, export, or CI in the tree. The public API is a small curated barrel. Two test files exist covering the codec and renderer; the viewer itself has **no dedicated tests**.

The source review found several **confirmed defects** by code trace (empty-input crash, PageView rendering the current item on every page, tap-down navigation racing overlay interaction, video failure path leaking a controller, dual video-progress advance paths that can double-advance) and several **high-probability risks** that require runtime reproduction (stale async video assignment, exactly-once completion, progress/timer interactions). These findings are consistent with the static risk table R1–R14 in `STORY_KIT_IMPLEMENTATION_PLAN.md` §2; this report confirms the code-level evidence and adds severities.

**Runtime verification is blocked** in this environment: no Flutter SDK, no Dart SDK, and no shell access are available to the audit executor. Commands required by the execution plan (`flutter --version`, `dart --version`, `flutter doctor -v`, `flutter pub get`, `flutter analyze`, `dart format --set-exit-if-changed`, `flutter test`, `flutter pub outdated`) were **not run** and are recorded as blocked with reasons in §4. No result is invented.

**Phase 2 readiness: CONDITIONAL GO** — see §9.

## 2. Revision and environment

| Field | Value |
|---|---|
| Repository | `atharvakapse831/focusgram_story_kit` (private, Dart, default branch `main`) |
| Audited commit | `a5e6cc9f74d2169a25eb51139a30ff73d7f47baf` |
| Clean local checkout | Not possible — audit executed via GitHub API full-file reads (no shell/host environment available) |
| Flutter version | Not run — blocked (no Flutter SDK in audit environment) |
| Dart version | Not run — blocked (no Dart SDK in audit environment) |
| OS / runner | Ashna-X1 agent environment; GitHub API access only |
| `flutter pub get` | Not run — blocked |
| `flutter analyze` | Not run — blocked |
| `dart format --set-exit-if-changed` | Not run — blocked |
| `flutter test` | Not run — blocked |
| CI result | Not applicable — no `.github/` or other workflow directory exists in the tree (verified by full root listing) |

## 3. Repository map (complete, verified against root + `lib/` + `test/` + `docs/` listings)

| Area | Files | Static observation |
|---|---|---|
| Public API | `lib/focusgram_story_kit.dart` (6 exports) | Barrel exports models, overlays, codec, viewer, renderer. No accidental internal exposure found |
| Models | `lib/models/story_item_model.dart`, `story_group_model.dart` | Plain `const`-constructible classes; no toJson/fromJson on item/group models; `sharedContent` is dynamic `Map<String, dynamic>?` |
| Overlay models | `lib/overlays/story_overlay.dart` | 7 concrete overlay types + base class; `toJson` only; no schema version; `dx/dy` documented 0.0–1.0 but unvalidated |
| Codec | `lib/overlays/overlay_codec.dart` | `decodeStoryOverlay` (nullable) + `decodeOverlayList` (drops failures/unknowns) |
| Viewer | `lib/viewer/story_kit_viewer.dart` | Single `StatefulWidget` owning PageView, progress AnimationController, video controller, gestures, chrome |
| Renderer | `lib/viewer/story_overlay_renderer.dart` | Stateless dispatcher + per-type widgets; local interaction state in poll/quiz/slider/question/countdown states |
| Tests | `test/overlay_codec_test.dart` (8 test cases), `test/story_overlay_renderer_test.dart` (7 test cases) | Codec + renderer only; no viewer tests |
| Manifest | `pubspec.yaml` | `^3.5.0` Dart, `>=3.24.0` Flutter; deps `cached_network_image ^3.4.1`, `video_player ^2.9.2`; dev: `flutter_lints ^5.0.0` |
| Docs | `README.md` + 4 `docs/` files (2 are this audit's plan/report pair) | See §6 doc conflicts |
| Missing | No `analysis_options.yaml`, no `.github/`, no `example/`, no root `LICENSE`, no `CHANGELOG.md`, no lockfile | Confirmed absent by full listing |

## 4. Verification log

All runtime checks are **blocked**: this audit environment has no Flutter SDK, no Dart SDK, and no shell execution capability; only GitHub read access is available. Per the execution plan ("If Flutter is unavailable, mark the command **blocked** and identify the required environment; never invent a result"), none of the following commands were executed:

| Check | Status | Reason / required environment |
|---|---|---|
| `git status --short` / local checkout | Blocked | No shell/host environment |
| `flutter --version`, `dart --version`, `flutter doctor -v` | Blocked | Flutter/Dart SDK not installed in audit environment |
| `flutter pub get` | Blocked | Requires Dart SDK |
| `flutter analyze` | Blocked | Requires Flutter SDK; also note `analysis_options.yaml` is missing from the repo (AUD-015) |
| `dart format --set-exit-if-changed .` | Blocked | Requires Dart SDK |
| `flutter test --reporter expanded` | Blocked | Requires Flutter SDK |
| `flutter test --coverage` | Blocked | Requires Flutter SDK |
| `flutter pub outdated` | Blocked | Requires Dart SDK |
| CI checks | Not applicable | No workflow files exist in the repository |

**Residual risk from blocked checks:** compile errors, analyzer issues, formatting drift, and actual test outcomes are unknown. Every "confirmed" defect below is confirmed by **code trace only** (logic-level reasoning over the full source), not by executed reproduction. The first Phase 2 task must run the full command battery in a developer environment and convert these to reproduced (or disproven) findings.

## 5. Requirement traceability matrix

| Requirement area (inventory §3.x) | Source evidence | Test evidence | Status | Finding |
|---|---|---|---|---|
| 3.1 Public API & integration | `lib/focusgram_story_kit.dart`; no FocusGram internals imported | None | Implemented — unverified | No example app (AUD-011); no versioning policy docs |
| 3.2 Project/document model | `StoryItemModel`, `StoryGroupModel` | None (models lack JSON round-trip entirely) | Partial — models exist but **no serialization, validation, or schema version** | AUD-004, AUD-006; versioned `StoryProject` schema is Phase 2 work |
| 3.3 Viewer & playback | `lib/viewer/story_kit_viewer.dart` | **No viewer tests** | Implemented — unverified; **confirmed defects** in empty-input, PageView rendering, video failure path | AUD-001, AUD-002, AUD-003, AUD-008, AUD-009, AUD-014 |
| 3.4 Overlay system & codecs | `story_overlay.dart`, `overlay_codec.dart` | `overlay_codec_test.dart` (8) — good malformed-input coverage for a skeleton | Implemented — partially verified | Silent unknown-type data loss: AUD-005; unvalidated coordinates: AUD-006; hashtag/location/GIF/text-sticker types **absent from code** despite README claims: AUD-012 |
| 3.5 Editor shell/pages | None | None | Not present (planned Phase 3) | — |
| 3.5.1 Content-to-Story | `StoryItemModel.sharedContent` (dynamic map) only | None | Not present; **explicitly out of Phase 1 scope** — remains in its designated later phase (Phase 6 per implementation plan) | AUD-004 records the schema contract ambiguity for later phases |
| 3.6 Camera/capture | None | None | Not present (planned) | — |
| 3.7 Gallery import | None | None | Not present (planned) | — |
| 3.8 Crop/adjustments | None | None | Not present (planned Phase 4) | — |
| 3.9 Text/typography | None (no text overlay class) | None | Not present (planned) | — |
| 3.10 Stickers/GIF | None | None | Not present (planned) | — |
| 3.11 Drawing | None | None | Not present (planned Phase 4) | — |
| 3.12 Backgrounds/templates | None | None | Not present (planned) | — |
| 3.13 Canvas/layers | None | None | Not present (planned Phase 3) | — |
| 3.14 Video editing/composition | None | None | Not present (planned Phase 5) | — |
| 3.15 Animation/motion | None | None | Not present (planned Phase 5) | — |
| 3.16 Undo/redo/drafts | None | None | Not present (planned Phase 3) | — |
| 3.17 Rendering/export | None | None | Not present (planned Phase 3+) | — |
| 3.18 Performance/resources | Partial: viewer disposes controllers | None | Partial — unverified; video leak paths exist | AUD-008, AUD-009 |
| 3.19 UX/accessibility/localization | Hard-coded English strings, fixed styles in viewer/renderer | None | Not present | AUD-013 |
| 3.20 Platform compatibility | `pubspec` declares Flutter `>=3.24.0`; no platform files | None | Unverified — no build evidence | — |
| 3.21 Security/privacy | Link URL validation in codec (http/https only) | Covered in codec tests | Partial — one validation exists; overlay payloads otherwise unvalidated | AUD-005, AUD-006 |
| 3.22 Developer experience/extension | None (no registry/interfaces) | None | Not present (planned) | — |
| 3.23 Testing/CI/docs/release | 2 test files; no CI, no changelog, no license, no example | — | Partial | AUD-010, AUD-011, AUD-015, AUD-016 |

## 6. Documentation conflicts (reported, not silently resolved)

1. **Phase numbering mismatch (major):** `STORY_KIT_FEATURE_INVENTORY.md` §5 uses a Phase 0–5 sequence in which "Phase 1" is viewer verification, "Phase 2" is the minimum editor (and lists Content-to-Story import in its "Phase 2"). `STORY_KIT_IMPLEMENTATION_PLAN.md` §1 uses Phases 1–7 with Content-to-Story in **Phase 6**. These two sequences are not reconciled. Per the standing engineering instruction, the **seven-phase plan is authoritative** for this audit (audit = its Phase 1). The inventory's §5 should be updated to reference the seven-phase plan before Phase 2 begins — flagged as D-01 (P2 documentation decision).
2. **README vs code — overlay types:** README advertises hashtag, location, GIF, and text stickers; `story_overlay.dart` contains only poll, quiz, slider, question, countdown, link, mention. AUD-012.
3. **README vs code — viewer features:** README mentions "reply input" and "seen-tracking callback"; `StoryKitViewer` exposes `onGroupViewed` (seen) but **no reply input exists anywhere in the viewer**. AUD-013.
4. **pubspec comment vs dependency:** pubspec comment says "No native plugin platforms in this package", yet `video_player` (a platform-plugin dependency) is declared. This is a packaging expectation mismatch, not necessarily a build defect — hosts must provide plugin registration. AUD-014.
5. **Audit report template vs current tip:** the pre-existing audit template recorded baseline `9dde74c…`; the audited tip is `a5e6cc9…`. This report supersedes it with the current tip and full-file re-reads.

## 7. Findings register

Confirmed defect = proven by complete code trace. Suspected = requires runtime reproduction. Coverage gap = missing test. Category labels per the execution plan.

| ID | Sev | Category | Evidence (file/symbol) | Description | Impact | Recommended action | Status |
|---|---|---|---|---|---|---|---|
| AUD-001 | P1 | Confirmed defect | `story_kit_viewer.dart` `initState`, `_item`, `_group` | Empty `groups` (or group with no items, after navigation edge) → `widget.groups[_groupIndex]` on empty list throws `RangeError` before any empty state can render | Crash on host misuse/malformed data; no UX-0 empty state | Add guard + defined empty state + tests (Phase 2 task) | Confirmed by trace |
| AUD-002 | P1 | Confirmed defect | `story_kit_viewer.dart` `build` → `PageView.builder` `itemBuilder` | `itemBuilder(context, index)` ignores `index` and renders `_item` (current global item) for **every** page | All visible/off-screen pages show the current group's item; group swipe shows wrong content | Pass `widget.groups[index]` data into page build; add PageView test | Confirmed by trace |
| AUD-003 | P1 | Confirmed defect | `story_kit_viewer.dart` `_handleTapDown` + `Positioned.fill` GestureDetector order | Navigation fires on **pointer-down**, and the full-screen translucent detector sits **above** the overlay renderer in the Stack | (a) Every tap starts navigation before long-press recognition → long-press-to-pause cannot work as designed; (b) full-screen detector may win/compete in overlay hit-testing → tapping a poll/link can also navigate | Navigate on confirmed tap (onTap), re-layer or re-scope hit regions; widget tests for overlay-tap vs navigation | Confirmed by trace |
| AUD-004 | P1 | Design risk | `story_item_model.dart` `sharedContent` | Dynamic `Map<String, dynamic>?` with no schema/version/validation contract | Shape drift between FocusGram and kit; malformed data untraceable | Keep frozen in Phase 2; design typed/versioned payload adapter in Phase 6 (do **not** expand ad hoc now) | Suspected → design decision |
| AUD-005 | P1 | Design risk | `overlay_codec.dart` `decodeStoryOverlay`/`decodeOverlayList` | Unknown types decode to `null` and the list decoder **silently drops** them; failed link/countdown decodes also vanish | An older client that decodes and re-saves a draft **loses** newer overlay content (user content corruption on round-trip) | Phase 2: structured decode result or opaque unknown-element preservation + migration-safe API; add round-trip regression fixture | Confirmed semantics; risk scenario suspected |
| AUD-006 | P1 | Design risk | `story_overlay.dart` `normalizedDx/Dy`; codec defaults `?? 0.5` | No finite/range validation: NaN/Inf/negative/out-of-range `dx/dy` pass through | Overlays can be positioned off-canvas or invisible; malformed external data produces broken layout | Phase 2: validate + clamp at decode with documented policy; malformed-input tests | Suspected |
| AUD-007 | P2 | Design risk | `story_kit_viewer.dart` `_onVideoTick` + `_progress` status listener | Two independent completion paths: (1) video-position listener advancing at `fraction >= 1.0`, (2) AnimationController `completed` status also calling `_advance()`. Both can fire for one completion | Potential double-advance (skipped story item) or race on pause; contradicts inventory 3.3 "no overlapping timers/stale callbacks" | Phase 2: single authoritative progress clock; controlled-clock test | Suspected — needs reproduction |
| AUD-008 | P1 | Confirmed defect | `story_kit_viewer.dart` `_loadVideo` catch path | On initialization failure the locally created `controller` is **never disposed** (only the member `_videoController` is nulled, which was already disposed) | `VideoPlayerController` leak on every failed video load (platform resource retention across items) | Phase 2: dispose in catch/finally with ownership token; add fake-player failure test | Confirmed by trace |
| AUD-009 | P1 | Suspected defect | `_loadVideo` async gap | If the user navigates while `initialize()` is in flight, the awaited result still installs into `_videoController` (only the not-mounted early-return guards widget death, not **item change**); also no generation token cancels stale loads | Stale controller can override the current item's video; orphaned playback possible | Phase 2: load-generation token + dispose-on-supersede; widget test with fake player | Suspected — needs reproduction |
| AUD-010 | P2 | Coverage gap | No `test/story_kit_viewer_test.dart` | The most defect-dense component (viewer) has zero tests: no navigation, progress, pause, video lifecycle, or disposal tests | Regressions undetectable; blocks exactly-once/lifecycle acceptance in Phase 2 | Phase 2: add viewer test suite with fake player before changing behavior | Confirmed gap |
| AUD-011 | P2 | Coverage gap | No `example/` app | No consumer integration exists | Public API usability unproven (inventory 3.1 acceptance) | Add example app in a later approved phase (implementation plan places docs/example in Phase 7; a smoke example may come earlier) | Confirmed gap |
| AUD-012 | P1 | Doc defect | `README.md` "What's inside" vs `story_overlay.dart` | README advertises hashtag, location, GIF, text sticker overlays — none exist in code | Users/hosts integrate expecting missing features | Correct README to list only implemented types; add missing types only in their planned phase | Confirmed |
| AUD-013 | P2 | Doc defect | `README.md` vs `story_kit_viewer.dart` | README claims "reply input"; viewer has none. Also: hard-coded English strings/styles everywhere (accessibility/localization absent); no app-lifecycle observer (progress/player not paused on backgrounding) | Misleading docs; missing UX-1 baseline | Correct README; lifecycle/observer + pause-reason design in Phase 2 | Confirmed |
| AUD-014 | P1 | Manifest risk | `pubspec.yaml` comment + `video_player` dep | Comment asserts "No native plugin platforms in this package" while `video_player` requires platform plugin registration in the host | Host setup confusion; test/build behavior unverified without runtime | Update comment to document host obligations; verify build in Phase 2 environment | Confirmed mismatch |
| AUD-015 | P2 | Coverage gap | No `analysis_options.yaml` | `flutter_lints` is a dev dependency but no analysis options enable it | Lint rules inactive; analyzer behavior undefined | Phase 2: add `analysis_options.yaml` including `package:flutter_lints/flutter.yaml`; then run analyzer | Confirmed gap |
| AUD-016 | P2 | Coverage gap | No CI (`.github/` absent), no `LICENSE`, no `CHANGELOG.md`, no lockfile policy | No automated checks; licensing/provenance unclear (README cites porting from `flutter_story_view` 0.0.4 and `flutter_story_editor` 0.0.2 — both abandoned; attribution/licensing terms of that porting are not documented) | Release/compliance gaps; provenance obligation unverified | Add lightweight CI + LICENSE + changelog + license review of ported patterns in a later approved phase (implementation plan: Phase 7; CI may come earlier) | Confirmed gap |
| AUD-017 | P3 | Coverage gap | `story_overlay_renderer.dart` per-type widgets | Poll/quiz/slider/question hold **local interaction state**; no persistence/restoration contract; overlay bounds unclipped (Stack `clipBehavior: Clip.none`); countdown displays raw `DateTime.now()` clock | State loss on rebuild/page change; overlays can render outside canvas; time not injectable for tests | Phase 2/3: move durable response state to model/controller; define bounds policy; inject clock | Confirmed design property |

**Severity definitions used:** P0 = crash/data loss across core use (none confirmed, but AUD-001/AUD-005 approach it and are P1 pending runtime confirmation). P1 = primary viewer/codec behavior broken, repeatable lifecycle leak, major data-corruption risk. P2 = important edge path/gap with recoverable impact. P3 = polish/design-property observation.

## 8. Risk register

| Risk ID | Risk | Sev | Likelihood | Evidence | Mitigation |
|---|---|---|---|---|---|
| R-01 | All runtime evidence missing (compile, analyze, tests unrun) | High | Certain | §4 blocked log | Phase 2 kickoff must run full battery in dev environment before any code change |
| R-02 | Double-advance / stale video controller races | High | Medium | AUD-007, AUD-009 | Reproduce with fake player + controlled clock; single progress clock; load token |
| R-03 | Unknown overlay content silently lost on decode/re-save | High | Medium | AUD-005 | Preservation or structured-decode design in Phase 2 |
| R-04 | Viewer crashes on empty/invalid input | High | High (on misuse) | AUD-001 | Guard + empty state + tests |
| R-05 | Gesture conflicts break both navigation and overlay interaction | High | High | AUD-003 | Tap-vs-down redesign + widget tests |
| R-06 | Ported-code license/provenance obligations unverified | Medium | Unknown | README porting note; no LICENSE | License review in later phase before any publish |
| R-07 | Docs mislead hosts (README features, phase-numbering conflict) | Medium | Certain | §6 | Documentation corrections in Phase 2 preflight |

## 9. Phase 2 readiness assessment

**Recommendation: CONDITIONAL GO.**

Phase 2 (core architecture & viewer/overlay contracts) may begin once these conditions are met:

1. **Runtime baseline (blocking):** execute the §4 command battery in a developer environment with Flutter installed; record real versions, analyzer output, and test results. Convert trace-confirmed findings into reproduced findings (or disprove them).
2. **Pre-Phase-2 design decisions (blocking):** approve (a) single authoritative progress-clock design (AUD-007), (b) unknown-overlay preservation/structured-decode policy (AUD-005), (c) coordinate validation policy (AUD-006), (d) pause-reason aggregation + public pause/resume contract (AUD-003/R-07). These are Phase 2's opening tasks per the implementation plan §5.
3. **Non-blocking, do early:** add `analysis_options.yaml` (AUD-015); correct README overclaims (AUD-012/013); add viewer regression tests **before** behavior changes (AUD-010) per the plan's "regression tests first" rule.
4. **Deferred by design:** example app, CI, LICENSE/changelog, provenance review (implementation plan Phase 7; AUD-011/016). FocusGram Content-to-Story remains in its designated later phase — untouched.

## 10. Final result summary

- Requirement areas reviewed: 22 (all inventory §3.x sections) — all mapped in §5
- Implemented — verified: 0 (no runtime evidence exists)
- Implemented — unverified: 3 (public API, viewer, overlay codec/renderer)
- Partial: 4 (document model, performance ownership, security validation, testing/CI docs)
- Planned / not present: 15 (all editor, media, export, capture, animation features)
- Confirmed defects: 5 (AUD-001, AUD-002, AUD-003, AUD-008, AUD-012) + 2 doc defects (AUD-013, AUD-014 mismatch)
- Suspected defects / design risks: 5 (AUD-004, AUD-005, AUD-006, AUD-007, AUD-009)
- Coverage gaps: 6 (AUD-010, AUD-011, AUD-015, AUD-016, AUD-017, viewer tests)
- Test commands: 0 run — all blocked (§4); 15 test cases exist in 2 files (8 codec + 7 renderer), outcomes unverified
- Analyzer/format: not run — blocked
- Dependencies: `cached_network_image ^3.4.1`, `video_player ^2.9.2` — declared only; resolution unverified

## 11. Phase 1 exit gate

- [x] Every current source file has been read (full contents) and mapped to requirements (§3, §5)
- [x] Test/analyzer commands attempted or blocked **with reason** (§4) — none invented
- [x] Dependency, platform, license/provenance, public API, lifecycle, and documentation reviews complete (§3, §5, §7 AUD-014/016)
- [x] Confirmed defects have evidence and reproduction reasoning; clearly separated from suspected risks and coverage gaps (§7)
- [x] Unknowns explicitly listed; no unsupported pass claims (§4 residual risk)
- [x] Next implementation tasks ordered by prerequisite and impact (§9 and `docs/PHASE_1_EXIT_CRITERIA.md` §3)
- [x] No feature implementation or FocusGram Content-to-Story integration was introduced during the audit
- [x] Phase 2 go/no-go recommendation recorded with explicit conditions (§9)

**Exit decision: Phase 1 COMPLETE** (source-level audit complete; runtime verification remains a blocking Phase 2 entry condition, documented in §4/§9 rather than silently skipped).
