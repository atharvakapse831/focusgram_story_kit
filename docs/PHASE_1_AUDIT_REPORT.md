# Phase 1 — Repository Audit Report

**Status:** Executed — static audit complete; runtime verification blocked (see §4)  
**Repository:** [atharvakapse831/focusgram_story_kit](https://github.com/atharvakapse831/focusgram_story_kit)  
**Audited baseline:** `main` @ `a5e6cc9f74d2169a25eb51139a30ff73d7f47baf`  
**Audit artifacts committed to:** branch `phase-1-audit`  
**Exit criteria:** `docs/PHASE_1_EXIT_CRITERIA.md`  
**Audit executor:** coding agent via GitHub API (read-only source access; no local Flutter toolchain)

## 1. Executive summary

The package is a small pre-1.0 library: 7 production Dart files (barrel, 2 models,
2 overlay files, viewer, renderer), 2 test files, manifest, and docs. Every
production file and test file was read in full at the audited SHA.

The overlay codec and renderer are the strongest areas: typed models, deliberate
null-on-unknown decoding, URL validation, and 10 codec tests plus 7 renderer
widget tests. The viewer is the weakest area: code inspection confirms multiple
high-severity defects (crash on empty input, PageView rendering the current item
on every page, pointer-down navigation that defeats hold-to-pause, a stale
asynchronous video-init race, a double-advance path at video completion, and an
overlay-interaction pause with no resume path). **No viewer widget tests exist**,
so none of these are runtime-reproduced yet; they are code-trace-confirmed with
exact symbols, and reproduction is the first Phase 2 testing task.

**Current exit decision:** CONDITIONAL GO — see §9 and §10.

## 2. Revision and environment

| Field | Value |
|---|---|
| Repository | `atharvakapse831/focusgram_story_kit` |
| Branch reviewed | `main` |
| Commit SHA | `a5e6cc9f74d2169a25eb51139a30ff73d7f47baf` |
| Tree entries at root | 6 (`.gitignore`, `README.md`, `docs/`, `lib/`, `pubspec.yaml`, `test/`) |
| Flutter version | Not run — blocked (no local toolchain in audit environment) |
| Dart version | Not run — blocked |
| OS / runner | GitHub API only; no checkout, shell, or code-execution integration |
| `flutter pub get` | Blocked |
| `flutter analyze` | Blocked |
| `flutter test` | Blocked |
| CI | No `.github/` directory; no workflow files in tree (confirmed absent) |
| Audit executor | Coding agent (Ashna-X1) via GitHub connector |

## 3. Repository map (all files read in full)

| Area | Files | Audited state |
|---|---|---|
| Public API | `lib/focusgram_story_kit.dart` | Barrel exports 6 files; usable via barrel alone (statically); no example app to confirm |
| Models | `lib/models/story_item_model.dart`, `story_group_model.dart` | Item: id, mediaUrl, type, duration (default 5s), caption, overlays, createdAt?, `sharedContent` dynamic map. Group: userId, username, avatarUrl?, items. **No toJson/fromJson at model level; no equality/copyWith; lists not defensively copied** |
| Overlay contract | `lib/overlays/story_overlay.dart` | Base + 7 types: poll, quiz, slider, question, countdown, link, mention. Position is normalized center point only — no size/rotation/scale/z-order/timing |
| Codec | `lib/overlays/overlay_codec.dart` | Type-dispatched decode; null on unknown type; defaults dx/dy 0.5. Wrong-typed fields can throw (AUD-015) |
| Viewer | `lib/viewer/story_kit_viewer.dart` | Playback state machine; multiple confirmed-by-trace defects (§6) |
| Renderer | `lib/viewer/story_overlay_renderer.dart` | Stateless dispatcher + per-type widgets; hit-test comment documented; slider/countdown gaps |
| Tests | `test/overlay_codec_test.dart`, `test/story_overlay_renderer_test.dart` | Codec: 10 cases. Renderer: 7 widget cases. **No viewer tests, no slider test, no public API smoke test** |
| Manifest | `pubspec.yaml` | v0.1.0; Dart ^3.5.0, Flutter >=3.24.0; deps `cached_network_image ^3.4.1`, `video_player ^2.9.2`; dev `flutter_test`, `flutter_lints ^5.0.0`. **No `analysis_options.yaml` in tree — lints package is not wired up** |
| Hygiene | `.gitignore`, `README.md`, 4 docs | No `LICENSE`, no `CHANGELOG.md`, no `example/`, no `.github/`, no `analysis_options.yaml`, no lockfile (gitignored — acceptable for a package) |

## 4. Verification log

Per the execution plan §3: missing evidence is never a pass. The audit
environment has **no Flutter SDK, no shell, and no checkout** — only GitHub API
read access. All runtime commands are therefore **blocked**, with the required
environment stated.

| Check | Status | Result / evidence |
|---|---|---|
| Pin exact SHA + full tree | Done | `main` @ `a5e6cc9f...`; root + `lib/`, `test/`, `docs/` listings captured; no truncated listings |
| Read all Dart sources + tests | Done | All 9 Dart files read in full via GitHub API (sizes 286–18258 bytes) |
| `flutter --version` / `dart --version` / `flutter doctor -v` | **Blocked** | Requires a machine with Flutter ≥3.24 toolchain; not available in this audit environment |
| `flutter pub get` | **Blocked** | Same reason; dependency resolution unverified |
| `flutter analyze` | **Blocked** | Analyzer status unknown; also no `analysis_options.yaml` exists, so defaults would apply |
| `flutter test --reporter expanded` | **Blocked** | Test pass/fail unknown at runtime; static test-content mapping in §5 |
| `flutter test --coverage` | **Blocked** | Same reason |
| `flutter pub outdated` | **Blocked** | Same reason |
| Platform builds | **Blocked** | Requires Android/iOS toolchains |
| License review | Done (static) | No LICENSE file in tree; dependencies' licenses unreviewed; ported-code attribution (flutter_story_view / flutter_story_editor per README) undocumented |
| CI checks | Done (static) | No `.github/` directory; no in-repo CI exists to run |

**Remaining risk from blocked commands:** analyzer and test outcomes are
unknown; any finding marked "confirmed by trace" still needs runtime
reproduction before its fix is designed. This is condition C-1 in §10.

## 5. Requirement traceability matrix

Statuses use the inventory's vocabulary. No status is "verified" without test
evidence; nothing was runtime-verified in this audit.

| Requirement area (inventory §) | Source evidence | Test evidence | Status | Finding / next action |
|---|---|---|---|---|
| 3.1 Public API / host integration | Barrel exports all intended files; no app-private imports | None (no smoke test, no example) | Implemented — unverified | Add export smoke test + example app (Phase 2/7) |
| 3.2 Project/model schema | `story_item_model.dart`, `story_group_model.dart` | None — **models have no JSON serialization at all** | Partial | Model-level codec/schema/versioning is Phase 2 architecture work |
| 3.4 Overlay model/codec | 7 overlay types + codec | 10 codec cases | Implemented — unverified | Wrong-type crash paths (AUD-015); unknown-type drop policy (AUD-004) |
| 3.3 Viewer playback/navigation | `story_kit_viewer.dart` | **None** | Partial — multiple confirmed-by-trace defects | AUD-007…014; viewer widget tests are the first Phase 2 test task |
| Media/rendering/lifecycle | Viewer video path | None | Partial | Stale-init race (AUD-011), error-path leak (AUD-013) |
| 3.5/3.13 Editor canvas, pages, layers | Not present in tree | — | Planned (Phase 3) | Not a Phase 1 failure |
| 3.6–3.12 Capture, gallery, crop, text, stickers, drawing, backgrounds | Not present in tree | — | Planned (Phase 4) | Not a Phase 1 failure |
| 3.14/3.15 Video editing/animation | Not present in tree | — | Planned (Phase 5) | Not a Phase 1 failure |
| 3.5.1 Content-to-Story | Only untyped `sharedContent` map on the item model | None | Planned (Phase 6) — correctly **not** implemented | Do not expand `sharedContent` before the typed payload phase |
| 3.16 Undo/redo/drafts | Not present in tree | — | Planned (Phase 3) | Not a Phase 1 failure |
| 3.17 Export contract | Not present in tree | — | Planned (Phase 3) | Not a Phase 1 failure |
| 3.19 Accessibility | No `Semantics` anywhere in viewer/renderer | None | Not started (P1) | Later phase, record as gap |
| 3.23 CI/docs/release | No CI, no LICENSE/CHANGELOG/example | — | Missing | AUD-001/002/024 |

## 6. Findings register

Categories: **CD** = confirmed defect (code-trace confirmed; runtime repro
pending), **TG** = test gap, **DR** = design risk, **PF** = planned feature
(not a defect). Severity per execution-plan guidance.

| ID | Sev | Cat | Evidence (file / symbol) | Impact & recommended action |
|---|---|---|---|---|
| AUD-001 | Medium | CD | No `.github/` in tree | No in-repo CI. Add a lightweight analyze+test workflow as a separately approved task (Phase 2 setup or Phase 7) |
| AUD-002 | Medium | CD | No `example/` directory | Consumer integration unverifiable. Add example app in an approved later task |
| AUD-003 | Medium | DR | `story_item_model.dart` → `sharedContent` is `Map<String, dynamic>?`, no schema/version | Ambiguous persistence boundary. Per plan: do not expand before Phase 6 typed payload + adapter |
| AUD-004 | Medium | CD | `overlay_codec.dart` → unknown type returns null; `decodeOverlayList` filters nulls | Forward-compat data loss: older client decoding + re-saving drops newer overlays. Phase 2: opaque/unknown element or structured decode result |
| AUD-005 | Medium | CD | `pubspec.yaml` comment "No native plugin platforms" vs `video_player ^2.9.2` dependency | Misleading manifest; widget tests over the viewer will need channel mocks; hosts need plugin registration. Fix comment + document host setup (doc-only change, Phase 2) |
| AUD-006 | High | CD | `story_kit_viewer.dart` → `initState`: `initialGroupIndex.clamp(0, widget.groups.length - 1)`; `_item`: clamp against `items.length - 1` | **Empty `groups` or empty `items` throws `ArgumentError` (clamp with min > max) → crash on open.** Phase 2: defined empty state + tests |
| AUD-007 | High | CD | `story_kit_viewer.dart` → `itemBuilder` ignores `index`, renders `_buildMedia(_item)` + `_item.overlays` for every page | Every PageView page displays the *current* item's media/overlays; group paging is cosmetic. Fix in Phase 2 with per-index state + tests |
| AUD-008 | High | CD | `story_kit_viewer.dart` → `_handleTapDown` navigates on `onTapDown` (pointer-down) | Navigation fires before long-press can be recognized → hold-to-pause unreachable; violates plan UX rule "confirmed tap, not pointer-down" |
| AUD-009 | High | DR | `story_kit_viewer.dart` → full-screen `GestureDetector(behavior: translucent)` **with no child**, stacked above overlays | Hit-test outcome is defective in either branch: (a) translucent+childless never hit-tests → all navigation dead, or (b) it absorbs → overlay taps never reach overlays. Renderer tests pass standalone, so this integration is untested. Runtime widget test required to pin the branch |
| AUD-010 | High | CD | `_loadVideo` installs controller unconditionally when `mounted`, with no item/token check | Stale-async race: switching items during `initialize()` plays the wrong item's video/audio; concurrent `_loadVideo` corrupts `_videoLoading` and starts a phantom progress. Phase 2: load token + ownership rules |
| AUD-011 | High | CD | `_onVideoTick` sets `_progress.value = 1.0` (fires `AnimationStatus.completed` → `_advance`) **and** then calls `_advance()` when `fraction >= 1.0` | Double advance at video completion: skips an item; on the last item, `onViewerFinished` + `maybePop` can fire twice. Phase 2: single authoritative progress clock |
| AUD-012 | High | CD | Overlay interaction → `onOverlayInteractionStarted` → `_setPaused(true)`; the only resume path is long-press-end | After any overlay interaction the story stays paused forever; no public resume API (plan R7 confirmed). Phase 2: pause-reason aggregation + public resume contract |
| AUD-013 | Medium | CD | `_loadVideo` catch block: local `controller` not disposed on failure | Leaked `VideoPlayerController` per failed video. Dispose in catch; add failure test |
| AUD-014 | Medium | CD | `overlay_codec.dart` → `json['options'] as List?` throws `TypeError` if options is a String; `Map<String, dynamic>.from(m)` throws on non-String keys | Malformed payload crashes the decoder — violates P0 "malformed JSON never crashes". Phase 2 validation + tests |
| AUD-015 | Medium | CD | `_advance` final branch: `Navigator.of(context).maybePop()` | Library pops the host route implicitly; throws without a `Navigator` ancestor. Phase 2: host-controlled close option |
| AUD-016 | Medium | CD | No `didUpdateWidget` in viewer State | Replacing `groups` after mount is unhandled; stale indices can `RangeError`. Phase 2 |
| AUD-017 | Medium | CD | README claims viewer "reply input"; overlays "hashtag, location, GIF/text stickers"; poll "poll_options structured maps with legacy options fallback" | None of these exist in source; codec reads only legacy `options`. README overstates implementation (violates inventory §3.23 "documentation states known limitations honestly"). Doc correction in Phase 2 |
| AUD-018 | Medium | CD | No `analysis_options.yaml` despite `flutter_lints ^5.0.0` dev dependency | Lints not actually enabled. Add config (approved doc/config task) |
| AUD-019 | Medium | CD | No `LICENSE`, no `CHANGELOG.md` in tree | Reusable package has no license — blocks any future publish; ported-code attribution (flutter_story_view/flutter_story_editor) undocumented |
| AUD-020 | High | TG | No viewer widget tests; no public-API smoke test; slider overlay has **no test at all** | Viewer defects above are unprotected and unverified. First Phase 2 task: characterization tests before any behavior change |
| AUD-021 | Medium | TG | Codec gaps: slider decode, countdown round-trip, wrong-typed fields, non-finite/out-of-range dx/dy | Add per plan §4 Task 4 case list |
| AUD-022 | Medium | DR | `story_overlay.dart`: position = normalized center only; no size/rotation/scale/z-order/timing; renderer Stack `Clip.none` unclipped | Insufficient for editor canvas and video composition (plan R10/R12). Phase 2 versioned geometry contract |
| AUD-023 | Low | CD | `_chromeHidden` set false on long-press-end but never set true | Dead/unfinished feature |
| AUD-024 | Low | CD | `_CountdownWidgetState` 1s `Timer.periodic` ignores viewer pause | Countdown ticks while story is paused |
| AUD-025 | Low | CD | `_SliderWidgetState._value = 0` ignores `minValue ≠ 0` | Displays out-of-range value before first drag |
| AUD-026 | Low | DR | Models expose mutable `List`/`Map` fields; no equality/copyWith | Inconsistent with "immutable models" goal; note for Phase 2 schema |
| AUD-027 | Medium | DR | No `Semantics` labels on tap zones, progress, overlay controls | Accessibility (inventory §3.19, P1) not started; later phase |
| AUD-028 | Low | CD | Seen tracking is group-level only (`onGroupViewed`); README says "seen-tracking callback" | Per-item seen semantics undefined; document or implement in Phase 2 |

## 7. Risk register (updated from template)

| Risk ID | Risk | Severity | Likelihood | Mitigation |
|---|---|---|---|---|
| R-01 | Analyzer/test outcomes unknown (all runtime commands blocked) | High until run | Certain (blocked) | Run `flutter pub get`, `analyze`, `test` in a clean checkout — condition C-1 before Phase 2 code |
| R-02 | Viewer defects AUD-006…012 ship unprotected | High | Confirmed by trace | Characterization tests first, then targeted fixes in Phase 2 |
| R-03 | Unknown overlay data loss on decode+re-save | Medium | Confirmed | Phase 2 codec policy (AUD-004) |
| R-04 | No CI; SDK/dependency matrix unrepresented | Medium | Confirmed | Approved CI task before Phase 2 merge work |
| R-05 | License/provenance unresolved (no LICENSE; ported patterns) | Medium | Confirmed | Choose license; document attribution (Phase 7 at latest) |

## 8. Final result summary

- Requirement areas reviewed: 16 (all inventory areas applicable to current scope)
- Implemented — verified: **0** (nothing is runtime-verified; all commands blocked)
- Implemented — unverified: 2 (public barrel surface; overlay model/codec/renderer with tests that are themselves unexecuted)
- Partial: 2 (viewer playback/navigation; media/lifecycle)
- Planned: 9 (editor, capture, crop, text, stickers, drawing, video editing, animation, content-to-story, drafts, export — per phase plan)
- Deferred: 1 (Content-to-Story, Phase 6 by design)
- Critical findings: 0 confirmed at runtime; 7 High confirmed by code trace
- High: 7 · Medium: 14 · Low: 7 (see §6)
- Test command summary: all runtime checks **blocked** — no toolchain in audit environment
- Analyzer summary: unknown (blocked); note `analysis_options.yaml` absent
- Dependency/platform summary: unversioned resolution unverified; `video_player` plugin vs manifest comment conflict (AUD-005)
- License/provenance summary: no LICENSE; attribution undocumented (AUD-019)

## 9. Document conflicts (reported, not silently resolved)

1. **Phase numbering:** `STORY_KIT_IMPLEMENTATION_PLAN.md` defines a seven-phase sequence (1 audit … 7 hardening); `STORY_KIT_FEATURE_INVENTORY.md` §5 lists a six-phase "Phase 0–5" sequence. Per owner instruction, the seven-phase implementation plan is authoritative. The inventory's §5 remains a requirements catalogue, not the delivery sequence.
2. **README vs source:** README claims reply input, hashtag/location/GIF/text stickers, and `poll_options` wire-format support that do not exist in the audited source (AUD-017).
3. **Manifest vs dependency:** pubspec comment says "No native plugin platforms" while `video_player` is a platform plugin (AUD-005).

## 10. Phase 1 exit gate

- [x] Every current source file read in full and mapped to requirements (§3, §5).
- [x] Runtime commands run **or blocked with reason** (§4 — all blocked: no toolchain; per exit criteria §3 this is recorded, not treated as pass).
- [x] Dependency, platform, license/provenance, public API, lifecycle, and documentation reviews completed (static; runtime portions blocked).
- [x] Confirmed defects have evidence: exact file/symbol; runtime reproduction steps pending (C-1).
- [x] Unknowns explicitly listed; no unsupported pass claims remain.
- [x] Next tasks ordered by prerequisite and impact (§11).
- [x] No feature implementation or FocusGram sharing integration introduced during the audit.

## 11. Exit recommendation and conditions

**Recommendation: CONDITIONAL GO.**

The static audit is complete and the codebase is small, coherent, and
layered; the confirmed defects are tractable Phase 2 work, and nothing blocks
starting Phase 2 *planning*. The gate opens fully when these conditions are met:

- **C-1 (hard, before any Phase 2 code):** Execute in a clean checkout of
  `a5e6cc9f...` (or later tip): `flutter --version`, `dart --version`,
  `flutter pub get`, `flutter analyze`, `flutter test --reporter expanded`,
  `flutter pub outdated`. Record outcomes here. No finding may be treated as
  runtime-confirmed, and no fix designed, until analyze/test establish the
  actual baseline.
- **C-2:** First Phase 2 implementation task = characterization tests for the
  viewer (empty input, navigation, pause, video completion, overlay-vs-zone
  hit testing — resolves both branches of AUD-009) **before** any behavior change.
- **C-3:** Owner resolves document conflicts in §9 (phase numbering; README
  corrections; manifest comment).
- **C-4:** Approve adding `analysis_options.yaml` (config-only change) so
  `flutter_lints` actually applies.

**Ordered next tasks (Phase 2, pending approval):** characterization tests
(C-2) → viewer correctness (AUD-006…016) → codec validation + unknown-payload
policy (AUD-004/014) → versioned geometry/schema contract (AUD-022/026).

**STOP.** Phase 1 ends here. No Phase 2 work begins without explicit owner
approval per `AGENTS.md` §4 and the exit criteria's exit rule.
