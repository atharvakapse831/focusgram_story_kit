
# FocusGram Story Kit — Detailed Implementation Plan

**Status:** Proposed implementation plan, not an implementation report  
**Repository:** atharvakapse831/focusgram_story_kit  
**Branch:** main  
**Baseline snapshot:** main at commit 46ddc39eb3cafafd8f08963bf4fa6ba10b1d0d88 (25 October 2026)  
**Requirements source:** STORY_KIT_FEATURE_INVENTORY.md

This plan is based on a source-level review of the current repository. Flutter commands and device tests have not been executed as part of writing this plan. Phase 1 must establish that evidence before any feature is labelled runtime-verified.

## 1. Executive direction and task order

The repository is a pre-1.0 Flutter package currently focused on the story viewer and structured interactive overlays. The implementation tree does not yet show a dedicated editor canvas, edit-command/history subsystem, draft persistence, deterministic still-image exporter, or video timeline/export engine.

Follow this sequence. Do not jump to FocusGram sharing early.

1. **Phase 1 — Repository audit and baseline.** Inspect every file, run tests/analyzer/dependency checks from a clean checkout, complete the traceability matrix, record evidence and risks. Audit only; no production behavior changes.
2. **Phase 2 — Core architecture and viewer/overlay contracts.** Define the document/layer schema, coordinate rules, lifecycle contracts and result/error models. Reproduce and fix confirmed viewer/codec issues with regression tests.
3. **Phase 3 — Minimum usable editor.** Build document state, canvas, page management, selectable/movable layers, basic text/stickers, undo/redo, draft save/reopen and still-image export.
4. **Phase 4 — Editing capabilities expansion.** Add crop/filters, drawing, background/templates, gallery improvements, capture adapter, themes, accessibility, and polished creator UX.
5. **Phase 5 — Video and animation.** Implement timeline/timebase, trim, timed overlays, audio policy, export jobs, cancellation, and lifecycle-safe video behavior.
6. **Phase 6 — FocusGram Content-to-Story integration.** Add typed share payloads for image/video posts, the currently visible carousel item, long/short video, dedicated article cards and note cards. This remains late by design.
7. **Phase 7 — Hardening and release readiness.** Complete platform matrix, performance, accessibility, docs, example app, CI, dependency/license review and release criteria.

The requirements inventory is the full feature catalogue. This plan specifies order, technical implications, UX quality, implementation instructions and acceptance gates.

## 2. Current repository baseline

### Observed structure

The last inspected tree has 21 entries. Principal files:

- Public API: **lib/focusgram_story_kit.dart**
- Models: **lib/models/story_item_model.dart**, **lib/models/story_group_model.dart**
- Overlay contract/codec: **lib/overlays/story_overlay.dart**, **lib/overlays/overlay_codec.dart**
- Viewer/renderer: **lib/viewer/story_kit_viewer.dart**, **lib/viewer/story_overlay_renderer.dart**
- Tests: **test/overlay_codec_test.dart**, **test/story_overlay_renderer_test.dart**
- Manifest/docs: **pubspec.yaml**, **README.md**, **docs/PHASE_1_AUDIT_REPORT.md**, **docs/PHASE_1_EXECUTION_PLAN.md**, **docs/STORY_KIT_FEATURE_INVENTORY.md**

A dedicated editor/canvas, page editor, history/command implementation, draft repository, export backend, example app, and tracked CI workflow do not appear in that tree snapshot. Confirm absence in the clean-checkout audit. The tree summary also did not show a root license/changelog; verify before recording either as absent.

### Manifest observations

The inspected manifest declares package version 0.1.0, Dart constraint ^3.5.0, Flutter >=3.24.0, runtime dependencies cached_network_image and video_player, plus flutter_test and flutter_lints. A manifest comment says story_editor_pro remains a host-app dependency. These are static observations, not build/test evidence. Phase 1 must resolve dependencies and review exact versions, platform setup, licenses and provenance. Do not add multiple overlapping editor packages before small compatibility spikes.

### Existing model and overlay observations

- StoryItemModel supports image/video, media URL, image duration defaulting to five seconds, overlays, optional createdAt and a dynamic sharedContent map.
- StoryGroupModel contains user identity/avatar and an ordered list of story items.
- StoryOverlay currently stores ID and normalized center position only. Concrete classes visible in the source include poll, quiz, slider, question, countdown, link and mention.
- The README also mentions hashtag, location, GIF and text stickers, but corresponding model/renderer classes are not visible in the inspected source. Reconcile claims with actual support.
- The codec returns null for unknown/invalid cases in several paths, and list decoding drops those entries.
- The viewer uses a progress AnimationController and video position listener, owns a VideoPlayerController, and handles navigation/gestures in one State class.
- The renderer positions overlays in a Stack and hard-codes several visual styles.
- Only codec and overlay-renderer test files are visible; there is no dedicated viewer lifecycle test file in the current tree.

### Static risks to reproduce, not assumed runtime defects

| ID | Source-level observation | Potential impact | Required follow-up |
|---|---|---|---|
| R1 | Viewer indices access groups/items directly and initialization clamps against groups.length - 1. | Empty input may fail before a graceful empty state. | Reproduce in Phase 1; add empty/invalid-index tests in Phase 2. |
| R2 | PageView builder receives an index but renders through the current _item getter. | Off-screen pages may display current content rather than their indexed group. | Trace and test page reuse before changing it. |
| R3 | Full-screen tap detector is layered after the media/overlay stack and navigation uses onTapDown. | It may win overlay hit-testing; pointer-down may navigate before long-press recognition. | Create overlay-tap and hold-to-pause widget tests. |
| R4 | Video progress is set by both an AnimationController and a video-position listener, each with an advance path. | Completion may advance twice. | Reproduce with controlled clock/player; choose one authoritative progress source. |
| R5 | Video initialization failure has no dedicated retryable video state; catch path does not visibly dispose its local controller. | Resource leak, stale async assignment or confusing image-like failure UI may occur. | Add failure/disposal/stale-load tests and explicitly track ownership. |
| R6 | No app lifecycle observer or pause-reason aggregation is visible. | Progress/player may resume or pause incorrectly during app inactivity, overlays or buffering. | Test lifecycle; define pause state machine. |
| R7 | Overlay interaction pauses viewer internally; no public resume/controller is visible in public exports. | Host may not have a documented way to resume after handling interaction UI. | Trace the public contract; define controller/callback contract. |
| R8 | Unknown overlay types decode to null and list decoding filters failures. | Newer content can be lost when older clients decode and re-save it. | Decide unknown-payload preservation or typed diagnostics without breaking old callers. |
| R9 | Some codec fields cast dynamic JSON directly; coordinate values have no visible finite/range validation. | Malformed external data may throw or place invisible content. | Add malformed/wrong-type/non-finite/out-of-range tests. |
| R10 | Overlay model has position but no size, rotation, opacity, z-order, bounds or timing. | Full canvas manipulation and video composition cannot share a reliable model. | Introduce a versioned StoryProject/StoryElement contract in Phase 2. |
| R11 | sharedContent is a dynamic map. | Content-to-Story payload shape and ownership are ambiguous. | Do not expand ad hoc before Phase 6; add typed payload plus migration adapter then. |
| R12 | Overlay Stack is unclipped and styling is hard-coded. | Bounds, customization and canvas-edge behavior are inconsistent. | Define geometry/bounds policy, theming and tests before editor UX grows. |
| R13 | Some widgets own local interaction state (countdown/question/poll/quiz). | Parent updates, state restoration and host persistence may be inconsistent. | Test widget reuse/update semantics; move durable state to an explicit controller/model where needed. |
| R14 | Example app, CI workflow, root license/changelog are not visible in the summarized tree. | Consumer integration and release quality are difficult to verify. | Confirm during audit; add/document in Phase 7 if still missing. |

Phase 1 must record confirmed defect vs. test gap vs. design risk vs. planned feature separately. Do not claim runtime behavior without reproducing it.

## 3. Global UX standard

### UX quality levels

- **UX-0 — Correctness baseline:** deterministic interactions, empty/loading/error/cancel paths, no dead controls or hidden state.
- **UX-1 — Production polish:** consistent layout/tokens, safe areas, responsive controls, visible progress/errors, accessible semantics and state preservation.
- **UX-2 — Creator-grade:** contextual tools, direct manipulation, snapping guides, precise selection/transform handles, fast tool switching, refined motion, reliable undo/redo and preview/export parity.

Do not build UX-2 animation before the state and geometry are correct. UI must be substantially more sophisticated than the reference repos, but it should be coherent rather than a copy of another product.

### Editor layout requirements

- The story canvas is the primary surface, centered in the available space, 9:16 by default and configurable by document aspect ratio.
- The top safe-area row contains close/back, undo, redo and next/export. Controls have accessible labels and disabled states.
- A configurable contextual tool rail exposes media, text, stickers, drawing, background, crop/filters and page/timeline tools.
- Selecting a tool opens a panel/sheet containing relevant controls. Keep the canvas visible when practical, but let the keyboard and multiline text editor have enough room.
- Layer selection shows accurate bounds and handles. Snapping guides and selection chrome remain separate from exported pixels.
- Small phones prioritize usable one-handed bottom sheets. Wider screens can use side panels but must not alter persisted story coordinates.
- Every workflow has deliberate states: no media, loading, dirty, denied permission, unsupported format, export progress, successful export, cancelled and recoverable failure.

### Gesture rules

- Viewer and editor gesture policies must be separate.
- Viewer navigation must respond to a confirmed tap, not initial pointer-down. A recognized long press pauses without also advancing.
- Overlay controls have explicit gesture priority; tapping an interactive poll/link/question must not trigger previous/next story navigation.
- Editor one-pointer drag moves a layer; two-pointer gesture may scale/rotate; handles have defined priority.
- A gesture sequence commits one undo operation at gesture end. Pointer updates must not create hundreds of history entries.
- Canvas-to-screen mapping is shared by render, hit-test, selection and snapping. Keyboard, toolbar, sheet and safe-area changes do not rewrite document coordinates.
- Define clipping and out-of-bounds policy explicitly per element type.
- Pause reasons are aggregated: touch hold, app inactive, overlay interaction/modal, buffering and caller-requested pause. Clearing one reason must not resume if another is still active.

### Design system and performance expectations

- Define reusable tokens for surface, text, accent, selection, success/error, spacing, radii, elevation, typography, motion and disabled states.
- Theme, strings, fonts, icons, tool order and optional chrome slots are injectable.
- Support RTL and localized text without hard-coded left/right assumptions. Use semantics/focus order and non-color-only state indication.
- Target 160–240 ms for simple UI transitions as an initial design range; offer reduced-motion behavior and validate on device.
- Establish a device matrix before freezing performance budgets. At 60 Hz, use 16.7 ms as the target frame budget for representative simple layer interactions and record misses with profiler evidence.
- Measure cold-open/first-preview, drag frame times, memory peak, image export, video export and cancellation latency in release builds. Do not claim smoothness from analyzer/unit tests alone.

## 4. Architecture contracts to settle before feature work

### Canonical document

Introduce a versioned project format:

- **StoryProject:** project ID, schema version, revision, canvas spec, ordered pages and optional project metadata.
- **StoryPage:** stable page ID, base media/background, page display duration, ordered elements, optional timeline.
- **StoryMediaAsset:** stable asset ID, source kind, URI/handle, MIME type, dimensions, orientation, optional duration/audio metadata and thumbnail reference.
- **StoryElement:** stable ID, type-specific payload, normalized transform, opacity, z-order, visibility/lock flags, optional timing and crop/clip.
- Types can include text, image/sticker, drawing paths, shapes, background, video and future content cards.

Persist normalized canvas coordinates. Explicitly define anchor/pivot, width/height, rotation units, transform order, crop/fit behavior, z-order tie-breaking, clipping, fonts, timing and output size. The current normalized center point is not sufficient by itself.

### State ownership

Keep document state (serializable), interaction state (selection/gesture/snap), UI state (tool/sheet/keyboard), and playback/export state (clock/jobs/resources) separate. Use commands for edit operations and transaction/coalescing for gestures/sliders. Bound history by count and estimated memory.

### Rendering and integration

- Build an immutable render plan from a project snapshot.
- Preview and export may have different backends, but share geometry, crop, layer order and timing semantics.
- A screenshot of the editor UI is not the export architecture.
- Image and video render/export are separate backends behind typed APIs.
- Static PNG overlays are acceptable only for a static MVP; they cannot represent time-ranged layers, animated stickers or keyframes.
- Host apps supply capture/picker, draft storage, asset resolution, source navigation and publishing callbacks. No FocusGram endpoints, auth state or backend DTOs are hard-coded into core library code.
- Keep third-party packages behind adapters where practical. Validate SDK support, licensing/provenance, serialization fit, lifecycle control and output correctness before choosing a dependency.

## 5. Phase plans and exit gates

### Phase 1 — Repository audit and baseline

**Tasks**
1. Pin exact main SHA and inspect clean checkout/full tree.
2. Read all Dart sources, tests, manifest, docs, ignored/generated files, licensing, workflows and example/platform files.
3. Run and record: flutter --version; dart --version; flutter doctor -v; flutter pub get; flutter analyze; flutter test --reporter expanded; flutter pub outdated. Run coverage if supported.
4. Record each command, tool version, exit code and relevant output. If Flutter is unavailable, mark blocked and state why.
5. Trace model/codec edge cases; viewer loading, timing, navigation, gestures, errors, lifecycle and disposal; renderer bounds and input state.
6. Check whether README overlay claims map to real classes/renderers; review dependency metadata and provenance.
7. Fill docs/PHASE_1_AUDIT_REPORT.md with traceability matrix, findings, severity, risk, evidence and next tasks.

**UX level:** UX-0; reproduce behavior only, no editor redesign.

**Acceptance**
- Every current source file is mapped to feature requirements.
- Analyzer/tests/dependency outcomes are reported with real evidence or explicit blocked status.
- Confirmed defects, test gaps, risks and missing features are separate categories.
- Findings identify file/symbol, reproduction, user impact, severity and next step.
- Audit report has a go/no-go recommendation and unresolved unknowns.
- No product feature or Content-to-Story integration is implemented during the audit.

### Phase 2 — Core architecture and viewer/overlay contracts

**Tasks**
1. Review findings and prioritize confirmed crash/data-loss/lifecycle risks.
2. Approve versioned document/layer schema, coordinate semantics and validation.
3. Define decode diagnostics and unknown type behavior. Prefer an unknown/opaque element or structured decode result; if nullable decoding must remain for compatibility, add a safer API and migration path rather than silently breaking callers.
4. Define viewer state machine and one authoritative progress clock.
5. Define pause-reason aggregation and public pause/resume or interaction-completion contract.
6. Add guards for empty group/item lists, invalid indices, stale async video initialization and controller cleanup.
7. Add retryable media error state and explicit video rendering branch.
8. Add lifecycle observation and exactly-once completion behavior; make route pop host-controlled or an explicit option.
9. Add regression tests before behavior changes.

**UX level:** UX-0 correctness plus UX-1 empty/loading/error states.

**Acceptance**
- Empty/invalid input yields a defined empty/error state.
- Overlay taps and long-press behavior are tested and non-conflicting.
- Video advances exactly once at completion; initialization races cannot install stale controllers.
- All errors have recoverable states and owned controllers/listeners/timers are disposed.
- Pause reasons behave independently.
- Unknown/malformed codec behavior is documented and migration-safe.
- Public API exposes documented lifecycle controls.

### Phase 3 — Minimum usable editor

**Tasks**
1. Implement StoryProject/StoryPage/StoryElement, serialization, validation and migrations.
2. Implement EditorSession/controller and dirty revision.
3. Build canvas with one canonical transform for paint/hit-test/selection/snapping.
4. Add page strip: add, duplicate, reorder, select, delete.
5. Add image import and background.
6. Add selectable/movable/scalable/rotatable/reorderable text, image and static sticker layers.
7. Add command history, grouped gesture transactions and undo/redo.
8. Add draft save/restore behind repository interface.
9. Build deterministic still-image render/export.
10. Add an example flow: create → edit → save → reopen → export.

**UX level:** UX-2 for canvas and editor navigation; UX-1 for remaining controls.

**Acceptance**
- Round-trip preserves IDs, geometry, style, order and media references.
- Page operations maintain content and predictable selection.
- Gestures are stable at canvas edges and one logical gesture produces one undo entry.
- Save/reopen restores editable document rather than only a flattened image.
- Export excludes controls, selection handles and guides.
- Geometry agrees between preview and export within documented tolerance.
- Example uses public API only.

### Phase 4 — Editing capabilities expansion

**Tasks**
1. Crop, rotate, flip, fit/fill, filters and adjustments.
2. Text workspace with typography, background, outline/shadow, line spacing, wrapping and fallback.
3. Drawing/brush/eraser/basic shapes with stroke-level undo.
4. Local stickers/emoji/image/GIF abstraction and custom asset provider.
5. Solid/gradient/image/texture backgrounds and editable templates.
6. Better gallery/metadata/thumb pipeline.
7. Camera through replaceable adapter with permission/lifecycle/error behavior.
8. Layer panel, snapping/guides, lock/hide, and optional grouping.
9. Theme, localization, RTL, semantics, responsive layouts and motion polish.
10. Profile expensive media operations.

**UX level:** UX-2 creator-grade.

**Acceptance**
- Every enabled tool works and has disabled/loading/empty/error/cancel states.
- Supported properties survive save/reopen/export.
- Drawing/text/layers stay aligned after crop and resize.
- Camera denial does not block gallery import.
- Themes/tools are configurable without forking editor screens.
- Large source media and history/caches remain bounded.

### Phase 5 — Video and animation

**Tasks**
1. Run a cross-platform spike to select video editing/export backend; review native dependencies and licenses.
2. Define video clip, trim ranges, timebase, playback speed and audio policy.
3. Implement timeline/scrubber/thumbnails/cover selection.
4. Implement time-ranged overlays and animation schema only when both preview and export support it.
5. Implement export job IDs, progress, cancel, typed errors, status/result and guaranteed cleanup.
6. Verify orientation, crop, duration, frame rate, audio sync, backgrounding, disk full, corrupt files and concurrent exports.
7. Define long video behavior as explicit full clip, selected trim/window, segments, or clear rejection.

**UX level:** UX-2.

**Acceptance**
- Preview and output share the selected trim range; duration is within one output frame when supported.
- Audio is preserved/muted/added only according to explicit settings.
- Progress and cancellation reflect real work.
- Failed/cancelled jobs clean temporary outputs and never report success.
- Timing and animation are deterministic.
- Unsupported codecs/effects return actionable typed errors.
- No video is silently truncated.

### Phase 6 — FocusGram Content-to-Story integration (late, by design)

**Tasks**
1. Define typed/versioned StorySharePayload and source/media descriptors.
2. Map legacy dynamic sharedContent through a compatibility adapter; do not spread dynamic map access through editor code.
3. Add image-post layer, preserving source media and crop/layout.
4. Share the exact visible carousel slide using selected index plus media ID; default current slide must not revert to the first image.
5. Add playable video content layer with explicit full-duration/selected-duration/trim/segmentation policy.
6. Add distinct article card and note card renderers with theme hooks, stable source reference, title/summary/author/cover where available.
7. Make imported content a regular editable layer that can move, resize, rotate where supported, duplicate, delete, reorder, and be layered with text/stickers/images/drawings/background.
8. Keep inner video aspect ratio/crop independent from outer layer transform.
9. Preserve source ID/deep link and dispatch source-open through host callback.
10. Add payload fixtures and host integration example.

**UX level:** UX-2, with purpose-designed article/note cards.

**Acceptance**
- Fixtures for image post, carousel slide N, short video, long video, article and note.
- Carousel tests assert exact media ID/index.
- Article and note are visually distinct and handle missing fields without overflow.
- Imported layer survives transform/save/reopen/export.
- Videos remain playable and follow explicit duration rules.
- Source navigation is host-controlled; core makes no hidden API/auth/network calls.
- Imported content coexists with all regular editing layers.

### Phase 7 — Hardening and release

**Tasks**
1. Run full unit/widget/golden/integration regression.
2. Add CI for format, analyzer, tests and supported target builds.
3. Benchmark frame time, memory, import/export, player count and temporary files.
4. Verify accessibility, localization, permissions, cancellation, lifecycle and malformed inputs.
5. Complete README, quick start, API docs, changelog, license/dependency inventory, example and publishing dry run as appropriate.
6. Reconcile the inventory status using code/test evidence.

**UX level:** UX-2 on all advertised flows.

**Acceptance**
- Every declared platform builds and passes smoke/integration tests.
- P0 criteria pass or have a documented approved waiver.
- No unresolved critical data loss, silent failure, or unmanaged lifecycle path.
- Performance/output quality is measured on the device matrix.
- Known limitations and implemented/partial/planned states are documented truthfully.

## 6. Per-feature implementation cards

### 6.1 Public API and host integration
**Priority:** P0. **UX:** UX-1. **Depends on:** Phase 1 audit.

Implementation: document public symbols; separate configuration from mutable session state; provide typed results/errors/progress; inject media/capture/storage/asset/export services; keep implementation classes internal; add example consumer using only public exports.

Acceptance: fresh sample compiles; no app-private imports; disposal/lifecycle documented; invalid config typed; host controls navigation, persistence, publishing and analytics.

### 6.2 Project model, codecs and validation
**Priority:** P0. **UX:** UX-0. **Depends on:** Phase 1 audit.

Implementation: introduce versioned project/page/element; stable IDs; normalized geometry; media references; typed decode results; explicit defaults and validation; migrations; unknown overlay policy; legacy contract fixtures.

Acceptance: type-safe round-trip; malformed fields do not crash public decoder; unknown types are preserved or explicitly diagnosed; migration tests pass; no silent geometry/data loss.

### 6.3 Viewer and progress
**Priority:** P0. **UX:** UX-2. **Depends on:** Phase 2.

Implementation: state machine, empty state, valid indices, exact gesture routing, pause reasons, one progress clock, video load token, retry, app lifecycle, exactly-once completion, explicit route close policy.

Acceptance: zero groups/items safe; taps don't double navigate; hold pauses only after recognition; video advances once; stale controllers are disposed; callbacks and route behavior deterministic.

### 6.4 Overlay renderers
**Priority:** P0 for current types; P1 for new editor types. **UX:** UX-2. **Depends on:** schema and viewer.

Implementation: registry/type mapping; common theme; per-type renderers; defined bounds/clipping/hit tests; persisted response state where needed; accessible labels; no duplicate callback paths.

Acceptance: each advertised overlay has model/codec/render/interaction tests; unknown type follows policy; interactive tap does not navigate viewer; localization/theme work; README matches actual support.

### 6.5 Editor shell and pages
**Priority:** P0. **UX:** UX-2. **Depends on:** schema and canvas.

Implementation: EditorSession, dirty state, page strip, add/duplicate/reorder/delete, close confirmation, contextual tool panels, keyboard-aware text mode, empty/loading/error states.

Acceptance: page ordering is stable; selection after deletion predictable; dirty state cannot silently vanish; layout/safe areas do not alter stored canvas geometry.

### 6.6 Canvas, layers and gestures
**Priority:** P0 model/order; P1 full interaction. **UX:** UX-2. **Depends on:** schema.

Implementation: canonical transform, normalized bounds, anchors, z-order and clip policy; hit-test; select/move/scale/rotate; handles and snapping; duplicate/lock/hide/reorder; command transaction per gesture.

Acceptance: geometry round-trips; hit tests match visible layer; edge/pointer cancellation tests pass; one gesture one undo; editor chrome never exported.

### 6.7 Media ingestion and backgrounds
**Priority:** P0 image import; P1 capture/video. **UX:** UX-2. **Depends on:** asset model and renderer.

Implementation: picker/source adapters, metadata validation, EXIF orientation, bounded thumbnails, durable references for drafts, solid/gradient/image backgrounds, missing-media recovery and permission states.

Acceptance: picker cancel is normal; unsupported media has clear error; original source is used for final export; orientation/aspect ratio correct; background changes preserve unrelated layers.

### 6.8 Text/typography
**Priority:** P1. **UX:** UX-2. **Depends on:** canvas and renderer.

Implementation: serializable text element; font registry/fallback; keyboard-driven editor submode; multiline/wrapping/alignment/line-spacing; color/background/outline/shadow; transform controls; localization tests.

Acceptance: text remains editable after reopen; styles persist; Unicode/emoji/RTL/long text tested; missing fonts have deterministic fallback; preview/export layout within documented tolerance.

### 6.9 Stickers, emoji and GIF
**Priority:** P1 local; P2 remote. **UX:** UX-2. **Depends on:** canvas/assets/renderers.

Implementation: sticker model and library interface; local asset provider; transforms/order; optional injected remote provider; explicit GIF preview/image/video export policy; bounded cache and offline fallback.

Acceptance: local stickers function offline; transforms persist; missing assets do not crash; GIF export behavior is explicit; custom preview-only widgets cannot silently disappear from output.

### 6.10 Drawing and markup
**Priority:** P1. **UX:** UX-2. **Depends on:** canvas, history and renderer.

Implementation: stroke representation in canonical coordinates, pen/marker/eraser, color/width/opacity, stroke undo/redo, optional shapes, pointer cancellation and coalesced updates.

Acceptance: smooth strokes; one undo per committed stroke; alignment preserved after resize/crop; cancellation cannot corrupt data; memory bounded for long paths.

### 6.11 Crop and image adjustment
**Priority:** P1. **UX:** UX-2. **Depends on:** asset and render contracts.

Implementation: crop/fit/fill/rotate/flip, filter and adjustment parameters, efficient preview-resolution path, non-destructive metadata, reset/before-after controls, golden fixtures.

Acceptance: preview/export transforms agree; originals retained; reset deterministic; sliders responsive; unsupported filters visible as unsupported rather than ignored.

### 6.12 Drafts and history
**Priority:** P0 core; P1 autosave. **UX:** UX-1/2. **Depends on:** document and commands.

Implementation: execute/revert commands, transaction/coalescing, bounded history, DraftRepository interface, atomic saves, schema migration, missing asset recovery, dirty/save callbacks.

Acceptance: undo exact; failed commands don't mutate; drag coalesced; save/reopen retains editability; save errors visible and work retained in memory.

### 6.13 Still-image export
**Priority:** P0. **UX:** UX-2 output fidelity. **Depends on:** renderer/document.

Implementation: immutable render plan; source/background/layer composition; output profile and ownership; typed progress/result/error/cancel; metadata validation; golden fixtures.

Acceptance: no UI chrome, correct dimensions/order/alpha/crop; pixel tests within documented tolerance; output verified; cancellation/failure cleanup works.

### 6.14 Camera and gallery
**Priority:** P1. **UX:** UX-2. **Depends on:** media adapters.

Implementation: camera/picker interface; photo/video capture where supported; permission states; retake/confirm; orientation and metadata; app lifecycle handling; capability-specific controls.

Acceptance: denial doesn't block import; device unavailable handled; capture returns expected type/orientation; camera resources release on every exit.

### 6.15 Video/timeline/animation
**Priority:** P2, Phase 5. **UX:** UX-2. **Depends on:** video backend spike, timeline and renderer.

Implementation: clip/trim/timebase; scrubber; cover selection; audio policy; per-layer intervals; export job ID/progress/cancel; platform parity; output probing and cleanup.

Acceptance: trim duration within one frame where supported; audio sync verified; concurrent jobs isolated; cancellation no partial output; no silent long-video truncation.

### 6.16 Content-to-Story
**Priority:** P1 product feature but Phase 6 sequence. **UX:** UX-2. **Depends on:** editor, media, layer, save/export and video contracts.

Implementation: typed/versioned share payload; source descriptor; current carousel item ID/index; image/video content layer; dedicated note/article renderers; movable/resizable content cards; host source-open callback; legacy sharedContent adapter.

Acceptance: exact visible slide imported; article/note look distinct; video is playable; selected duration or full duration explicit; metadata/deep link preserved; layer editable and composable; no core API/auth assumptions.

### 6.17 Theming, accessibility and localization
**Priority:** P1. **UX:** UX-2. **Depends on:** shell and controls.

Implementation: theme/string/motion tokens; custom fonts/icons/tool order; responsive/RTL layouts; semantic labels/focus; reduced motion; accessible sliders and errors.

Acceptance: host customization needs no screen fork; supported RTL/localized text fits; primary actions accessible; keyboard/sheet transitions do not alter canvas coordinates.

### 6.18 Performance, privacy, security
**Priority:** P0 continuous work. **UX:** UX-0 correctness, UX-2 responsiveness. **Depends on:** all media paths.

Implementation: bounded caches, stable resource ownership, cancellation/stale callbacks, temp cleanup, no hidden network, input validation, low-sensitivity logs and profiling.

Acceptance: repeated sessions don't leak; source media isn't uploaded implicitly; malformed payloads fail safely; cancelled jobs clean temp output; metrics recorded on real devices.

### 6.19 Tests, docs, example and release
**Priority:** P0. **UX:** not a screen feature, but release gate. **Depends on:** all feature changes.

Implementation: unit/widget/golden/platform/integration tests; regression fixtures; example host app; CI; README/API docs; license/provenance and changelog; release checklist.

Acceptance: declared platforms build; relevant tests pass; output is probed; every verified status has evidence; known gaps are documented; package API is usable outside FocusGram app.

## 7. UX and acceptance matrix

| Area | Minimum usable UX | Target UX | Must-pass evidence |
|---|---|---|---|
| Viewer | Progress, navigation, pause, loading/error | Lifecycle-aware playback and refined chrome | Exactly-once navigation, no gesture conflicts, disposal |
| Overlay models | Validated structured payload | Extensible, themeable, forward-safe overlays | Codec round-trip, malformed/unknown handling |
| Editor/pages | Canvas, pages, selection and basic layers | Contextual panels, responsive layout, snapping | Page/history/geometry tests |
| Text/stickers/drawing | Create and transform independently | Rich tools, high-quality typography/brushes | Save/reopen/export parity |
| Background/crop/filter | Basic non-destructive controls | Templates, adjustment panels, polished preview | Source preserved, render comparison |
| Draft/history | Save/reopen and undo/redo | Autosave/recovery and bounded history | Snapshot equality, failure recovery |
| Image export | Correct output without UI chrome | High-quality profiles and fast rendering | Golden + metadata checks |
| Video | Explicit trim/playback/export state | Timeline/timing/audio polish | Duration, sync, cancel, device tests |
| Content-to-Story | Typed imports/cards | Carousel semantics and premium article/note cards | Payload contract and source identity |
| Performance/platform | Safe resource lifecycle | Responsive interaction on device matrix | Profiling, memory, platform smoke tests |

## 8. Required test matrix

| Layer | Coverage | Evidence |
|---|---|---|
| Models/codecs | Round-trip, malformed fields, unknown type, version migration, numeric bounds | Canonical JSON assertions and decode outcomes |
| Viewer | Empty input, image duration, video progress, tap/long press, previous/next, completion | Widget tests with controlled clock/player |
| Lifecycle | Stale video init, app inactive, overlay pause, dispose, retry | Fake player tests plus device tests where required |
| Overlay hit tests | Interactive overlay taps, tap outside, gesture priority | Tests assert only intended callback fires |
| Canvas | Move/scale/rotate, snapping, bounds, pointer cancel, keyboard/sheet | Gesture and coordinate tests |
| Persistence/history | Undo/redo, grouped gesture, failed save, reopen, migrations | Snapshot equality and bounded memory checks |
| Image renderer | Crop, orientation, text, alpha, drawing, z-order, clipping | Golden image + output metadata |
| Video export | Trim, duration, audio, orientation, cancellation, concurrent jobs | Inspect/probe actual media and temp directory |
| Content share | Each source kind, carousel slide N, article/note optional data | Contract fixtures + host integration example |
| Performance | Many layers, large media, repeated sessions/export | Release-mode frame/memory/time metrics |

Phase 1 command outcomes must be captured from a real environment. Source inspection is not a substitute for Flutter analyze or test output.

## 9. Suggested implementation issues

Create these after Phase 1 evidence, not before confirming the details:

- SK-001 Complete audit report and requirement traceability matrix.
- SK-002 Define safer overlay codec validation and unknown-payload policy.
- SK-003 Add viewer empty-state and item/group navigation tests.
- SK-004 Fix gesture hit testing and tap/long-press priority if reproduced.
- SK-005 Make video progress, initialization, retry and controller lifecycle deterministic.
- SK-006 Approve versioned StoryProject/StoryPage/StoryElement schema.
- SK-007 Add EditorSession, document store and edit commands.
- SK-008 Build canonical canvas transforms, hit testing and gesture transactions.
- SK-009 Implement page strip/editor shell.
- SK-010 Add image import, text and static sticker layers.
- SK-011 Add undo/redo and draft save/reopen.
- SK-012 Implement still-image render plan and parity tests.
- SK-013 Add crop, filters, drawing, backgrounds/templates and editor UX.
- SK-014 Add capture/gallery adapters and lifecycle tests.
- SK-015 Prototype video trim/export/audio strategy on Android/iOS.
- SK-016 Implement video job API, timing and animation.
- SK-017 Implement FocusGram Content-to-Story payload/card/video layers in Phase 6.
- SK-018 Complete accessibility, performance, CI, package docs and release gates.

These are proposed task IDs/titles, not existing tickets.

## 10. Definition of done

A feature is complete only when:
1. Behavior and state ownership are specified.
2. UX covers normal, empty, loading, disabled, cancellation, failure and retry states as applicable.
3. Serialization/persistence has versioning and round-trip tests.
4. Preview/export semantics are consistent for supported outputs.
5. Gestures do not conflict with parent/viewer interactions.
6. Controllers, timers, listeners, media and temporary files have deterministic cleanup.
7. Unit/widget/golden/integration tests cover critical behavior.
8. Performance is measured where decoding/rendering/playback/export is affected.
9. Public API, example, limits and known gaps are documented.
10. Inventory status changes only with source/test evidence.

## 11. Official engineering references

- Flutter architecture guide: https://docs.flutter.dev/app-architecture/guide
- Flutter architecture recommendations and testing: https://docs.flutter.dev/app-architecture/recommendations
- Flutter package/plugin development: https://docs.flutter.dev/packages-and-plugins/developing-packages
- Flutter testing overview: https://docs.flutter.dev/testing/overview
- Dart analyzer: https://dart.dev/tools/dart-analyze
- Dart package layout: https://dart.dev/tools/pub/package-layout

These are supporting references, not proof that this repository currently satisfies the recommendations.

## 12. Final implementation instruction

Start with Phase 1. Do not change production behavior during the audit. Record tool versions and real command outputs, finish the traceability matrix, and then follow Phases 2–7 in order. Keep FocusGram Content-to-Story integration in Phase 6 after the reusable editor, document model, render/export and playback behavior are stable.

**End of implementation plan.**
