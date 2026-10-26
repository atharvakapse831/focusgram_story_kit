
## 5. Source-level findings register (F1–F9)

Every finding below is a **source-level observation**: it was identified by reading the code, not by reproducing behavior at runtime. Per the Phase 1 execution plan, none of these may be labeled runtime-confirmed defects until they are reproduced with executable evidence (widget tests with controlled clock/player, or device builds). Severity is tentative and must be re-assessed after runtime reproduction. File/symbol references are exact; all were read in full.

| ID | Severity (tentative) | Category | Evidence (file/symbol) | Description | Impact | Next action |
|---|---|---|---|---|---|---|
| F1 | High | Source-level: input validation | `lib/viewer/story_kit_viewer.dart`, `_StoryKitViewerState.initState` and `_item` getter | `initialGroupIndex.clamp(0, widget.groups.length - 1)` throws `ArgumentError` when `groups` is empty (clamp with min > max); `_item` uses `_itemIndex.clamp(0, _group.items.length - 1)` which throws for an empty `items` list | Empty or malformed input may crash the viewer before any empty state can render | Add empty-groups/empty-items widget tests with a defined empty state in Phase 2 |
| F2 | High | Source-level: viewer state | `lib/viewer/story_kit_viewer.dart`, `PageView.builder` in `build` | `itemBuilder` receives `index` but renders `_buildMedia(_item)` and `_item.overlays` — the current group/item, not the indexed one | Off-screen pages display the current item's content; page reuse and adjacent-group rendering are wrong | Write page-reuse widget tests; pass the indexed group's item through the builder in Phase 2 |
| F3 | High | Source-level: gesture priority | `lib/viewer/story_kit_viewer.dart`, full-screen `GestureDetector` (`onTapDown`, `onLongPressStart/End`) layered above media/overlay Stack | Navigation fires on `onTapDown`, so any touch (including one intended as a long-press to pause, or a tap landing on an overlay's translucent area) can advance the story before long-press recognition or overlay hit-testing wins | Hold-to-pause may also advance the story; overlay taps compete with navigation zones | Create overlay-tap and hold-to-pause widget tests asserting exactly one action fires per gesture |
| F4 | High | Source-level: progress/double-advance | `lib/viewer/story_kit_viewer.dart`, `_onVideoTick` + `_progress` status listener in `initState` | Video completion has two advance paths: `_onVideoTick` calls `_advance()` when `fraction >= 1.0`, and the AnimationController's completed status also calls `_advance()` | A video item may advance twice at completion (skip an item or trigger finish early) | Reproduce with controlled clock/fake player; establish one authoritative progress source in Phase 2 |
| F5 | Medium | Source-level: video lifecycle | `lib/viewer/story_kit_viewer.dart`, `_loadVideo` catch block | On `initialize()` failure the local `controller` is never disposed (leak); there is no stale-load guard, so a slow initialization could complete after the user navigated and install a controller for an obsolete item | Resource leak on init failure; stale async assignment risk | Add failure/disposal/stale-load tests and explicit load-token ownership in Phase 2 |
| F6 | Medium | Design risk (source-level) | `lib/viewer/story_overlay_renderer.dart` (`onOverlayInteractionStarted`), `lib/viewer/story_kit_viewer.dart` (`_setPaused`) | Overlay interaction pauses the viewer internally; no public resume/lifecycle API exists on `StoryKitViewer`; no `WidgetsBindingObserver` for app lifecycle | Host apps have no documented way to resume after handling interaction UI; background/foreground behavior is undefined | Define and document a public pause/resume + lifecycle contract in Phase 2 |
| F7 | Medium | Design risk (source-level) | `lib/overlays/overlay_codec.dart`, `decodeStoryOverlay` default case and `decodeOverlayList` | Unknown overlay types and malformed entries decode to `null` and are silently filtered out of the list | Older clients that decode and re-save newer content would silently lose those overlays | Decide unknown-payload preservation or typed diagnostics in Phase 2; add unknown-type round-trip tests |
| F8 | Low | Source-level: slider geometry | `lib/viewer/story_overlay_renderer.dart`, `_SliderWidgetState` drag handler | `context.findRenderObject()` inside the State resolves to the whole overlay card's render box, not the slider row, so the drag fraction is computed against the wrong width | Slider values may be inaccurate relative to visual position | Fix scope to the slider row and add a geometry widget test (Phase 2) |
| F9 | Low | Repository hygiene | Root listing | No `LICENSE`, no `CHANGELOG.md`, no `example/`, no `.github/` CI workflow, no `analysis_options.yaml` are present in the tree | Release readiness, license clarity, CI reproducibility, and lint enforcement are missing | Address in the approved later phases (hygiene items Phase 1 records only); see docs/PHASE_1_EXIT_CRITERIA.md |

## 6. Documentation conflicts (C1–C3)

Per the engineering instructions, conflicts between documents are reported here, not silently resolved.

| ID | Conflict | Evidence |
|---|---|---|
| C1 | README "What's inside" advertises hashtag, location, GIF, and text stickers as supported overlays, but no corresponding model, codec, or renderer classes exist. The overlay contract contains exactly 7 concrete types: poll, quiz, slider, question, countdown, link, mention. | `README.md` vs `lib/overlays/story_overlay.dart` (7 classes), `lib/overlays/overlay_codec.dart` (7 cases), `lib/viewer/story_overlay_renderer.dart` (7 branches) |
| C2 | `pubspec.yaml` comment states "No native plugin platforms in this package — pure Dart/UI + widget tests", but `video_player` is a federated plugin with native platform code and is imported directly by the viewer. | `pubspec.yaml` bottom comment vs `lib/viewer/story_kit_viewer.dart` (`import 'package:video_player/video_player.dart'`) |
| C3 | The pre-update audit report cited a 19-entry tree while the implementation plan cites 21 entries for the same documented baseline. Tree entry counts also depend on directory-listing granularity and should not be used as a comparison key. | Pre-update `docs/PHASE_1_AUDIT_REPORT.md` §2 vs `docs/STORY_KIT_IMPLEMENTATION_PLAN.md` §2 |

## 7. Risk register

| Risk ID | Risk | Severity | Likelihood | Evidence / uncertainty | Mitigation |
|---|---|---|---|---|---|
| R-01 | Runtime verification of all static findings is impossible without a Flutter toolchain | High until resolved | Certain (currently blocked) | All runtime checks in Section 4 are BLOCKED | Execute Section 4 command list in a clean checkout of a suitable Flutter environment; record outputs verbatim |
| R-02 | Findings F1–F4 (crash on empty input, wrong page content, gesture conflict, double advance) could each be viewer-breaking at runtime | High (tentative, per finding) | Unknown until reproduced | Source-level only; no runtime evidence yet | Reproduce each with targeted widget tests before any Phase 2 fix |
| R-03 | Unknown overlay content is silently dropped on decode (F7), risking user content loss across client versions | Medium | Unknown until tested | `decodeOverlayList` filters failed decodes | Decide preservation/diagnostics policy in Phase 2; add round-trip fixtures |
| R-04 | No CI: every future claim of passing checks depends on manual local runs | Medium | Certain (confirmed absent) | 0 workflow runs; no `.github` directory | Add minimal CI in a separately approved follow-up task (not during the audit) |
| R-05 | Third-party port provenance/license obligations unclear (README credits `flutter_story_view`, `flutter_story_editor`); no LICENSE file exists | Medium | Unknown | No LICENSE in tree; attribution text in README/model comments | License and provenance review required before any release |
| R-06 | Analyzer/test status unknown — existing tests may not pass on current toolchains | High until checked | Unknown | No analyzer or test run has ever been recorded | Run `flutter analyze` + `flutter test --reporter expanded` in the verification environment and record results |

## 8. Final result summary (as of 2026-10-26 — partial execution)

- Total requirement areas reviewed: all areas in the pre-update traceability matrix were re-inspected at source level
- Implemented — verified: 0 (no runtime verification has ever been performed)
- Implemented — unverified: viewer playback/navigation, overlay models/codec, overlay rendering (all read in full; behavior not runtime-verified)
- Partial: this audit (static portion complete, runtime portion blocked)
- Planned: editor, drafts, export, video timeline, Content-to-Story (Phase 6, unchanged)
- Deferred: FocusGram content-sharing integration (later phase, by design)
- Blocked / not run: all 9 runtime checks in Section 4, plus runtime reproduction of F1–F5
- Critical findings: 0 confirmed (none reproduced)
- High source-level findings: F1, F2, F3, F4 (not runtime-confirmed)
- Medium source-level findings: F5, F6, F7
- Low source-level findings: F8, F9
- Test command summary: BLOCKED — no test command has been executed; no pass/fail evidence exists
- Analyzer summary: BLOCKED — never run
- Dependency/platform summary: manifest read; resolution and outdated-status BLOCKED; platform matrix undefined (C2)
- License/provenance summary: no LICENSE file exists; dependency license review not performed

## 9. Phase 1 exit gate

- [x] Every current source file has been read and mapped to the relevant requirement (15 files, Section 3).
- [x] Test/analyzer commands are run or blocked with reason (all BLOCKED; reason recorded in Section 4).
- [ ] Dependency, platform, license/provenance, public API, lifecycle, and documentation reviews are complete. (Source-level reviews done; dependency resolution, platform builds, and license review remain blocked/not run.)
- [ ] Confirmed defects have evidence and reproduction steps. (F1–F9 are source-level only; none reproduced.)
- [x] Unknowns are explicitly listed; no unsupported pass claims remain.
- [ ] Next implementation tasks are ordered by prerequisite and impact. (Pending exit-criteria assessment; see docs/PHASE_1_EXIT_CRITERIA.md.)
- [x] No feature implementation or FocusGram sharing integration was introduced during the audit. (This change is documentation-only.)

**Exit recommendation: BLOCKED / NOT COMPLETE.** The static audit is done and its findings are recorded, but Phase 1 cannot be closed until the blocked verification checks in Section 4 are executed in a suitable Flutter environment and the findings are assessed against `docs/PHASE_1_EXIT_CRITERIA.md`. Nothing in this report constitutes a runtime-confirmed defect, a clean build, or a passing test claim.
