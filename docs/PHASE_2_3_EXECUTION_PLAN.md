# FocusGram Story Kit — Phase 2 & Phase 3 Execution Plan

**Repository:** [atharvakapse831/focusgram_story_kit](https://github.com/atharvakapse831/focusgram_story_kit)  
**Related application:** [Code-Plus-Academy/Mobile](https://github.com/Code-Plus-Academy/Mobile)  
**Planning date:** 2026-10-27  
**Planning baseline:** Story Kit \`main\` at \`285b0f7d29e6c7fdb5b08a86731eb51196efbdde\`  
**Status:** Planning document only. No product code is changed by this plan.

## 1. Executive summary

This roadmap defines the next two delivery phases after Phase 1 (repository stabilization and verification):

- **Phase 2 — FocusGram content sharing and Story Kit viewer integration.** Integrate Story Kit into Mobile's existing Stories experience, establish a typed shared-content contract, render dedicated story cards for image posts, video posts, short videos, long videos, articles, and notes, and route card interactions to the real source content. Preserve Mobile's existing backend upload/publish behavior.
- **Phase 3 — Story Kit editor MVP and production integration.** Build the reusable editing core—draft model, editor shell, page/layer state, image import, canvas manipulation, text/stickers/overlays, deterministic image export—and connect its result to Mobile's existing publish pipeline. Add video editing only to the extent specified below; defer costly advanced editing features until the core editor is stable.

The phases are intentionally separated. Phase 2 makes the current Story viewer and share-to-Story experience use the package's clean public contract. Phase 3 adds package-owned editing capabilities. **Mobile app code must not be imported into the Story Kit package.** The dependency direction is Mobile → Story Kit; Story Kit remains reusable and host-agnostic.

### Non-negotiable sequencing gate

Phase 1 is **not considered passed** until its required verification and exit criteria are evidenced. Phase 2 implementation must not start before the Phase 1 exit review approves it. Phase 3 depends on Phase 2's shared-content contract and integration tests.

This roadmap can be reviewed and broken into issues now; it does not waive Phase 1 verification.

## 2. Source audit and current-state evidence

The plan is based on the current source structure and the Mobile Story implementation—not on an assumption that the package already has an editor or content cards.

### Story Kit package

- The package currently exports models, overlays/codec, and viewer APIs through \`lib/focusgram_story_kit.dart\`.
- \`StoryItemModel\` currently represents image/video media, duration, caption, overlays, creation time, and optional \`Map<String, dynamic>? sharedContent\`.
- \`StoryKitViewer\` accepts story groups and viewer callbacks. Its current rendering path has no FocusGram-specific typed content-card renderer or host source resolver.
- The existing package is viewer/overlay-focused. The editor is a planned feature, not a completed package API.

Relevant source:
- [Story item model](../lib/models/story_item_model.dart)
- [Story Kit viewer](../lib/viewer/story_kit_viewer.dart)
- [Public exports](../lib/focusgram_story_kit.dart)
- [Feature inventory and broader target scope](STORY_KIT_FEATURE_INVENTORY.md)

### Mobile Stories feature

- Mobile currently declares \`story_editor_pro: ^1.0.3\`; it does not currently depend on this Story Kit package.
- Mobile already has \`SharedContentModel\` and \`StoryItemModel.sharedContent\`, with existing type values such as \`carousel\`, \`video\`, \`code\`, \`short\`, and \`post\`.
- \`StoryEditorWrapper\` uses \`StoryEditorPro\` and receives a \`StoryShareResult\`. It optimistically adds a story, then invokes the existing \`StoryRepository.uploadStory\` path with the generated file and shared-content metadata.
- \`RichSharedContentCard\` is currently a Mobile-owned viewer widget.
- Mobile's story viewer handles shared-content taps and navigates to source screens. Its current handler constructs some detail models from the compact shared-content fields; the integration must verify that those models contain sufficient real source data and must not navigate with placeholder/empty media data.

Relevant source:
- [Mobile pubspec](https://github.com/Code-Plus-Academy/Mobile/blob/main/pubspec.yaml)
- [Mobile story models](https://github.com/Code-Plus-Academy/Mobile/blob/main/lib/feature/stories/data/models/story_model.dart)
- [Mobile story editor wrapper](https://github.com/Code-Plus-Academy/Mobile/blob/main/lib/feature/stories/presentation/views/story_editor_wrapper.dart)
- [Mobile rich shared-content card](https://github.com/Code-Plus-Academy/Mobile/blob/main/lib/feature/stories/presentation/views/widgets/rich_shared_content_card.dart)
- [Mobile story viewer](https://github.com/Code-Plus-Academy/Mobile/blob/main/lib/feature/stories/presentation/views/story_viewer_screen.dart)
- [Mobile story repository](https://github.com/Code-Plus-Academy/Mobile/blob/main/lib/feature/stories/data/repositories/story_repository.dart)

### Architecture decision

| Concern | Owner |
|---|---|
| Story UI primitives, typed portable models, viewer/editor behavior, card rendering hooks | Story Kit package |
| FocusGram content models, API/auth, content resolution, route/deep-link handling, upload/publish, analytics | Mobile app |
| Backend story persistence and upload contract | Existing backend; validate before changing |
| Adapter from Mobile story/content models to Story Kit models | Mobile app |
| Story Kit's source-open interaction | Package callback; Mobile performs navigation |

Do not import Mobile routes, repositories, Cubits, theme classes, models, or widgets into Story Kit. If the current Mobile card's design is to be reused, recreate it using package-owned primitives or extract a genuinely shared, app-neutral UI package in a separately approved change.

## 3. Phase dependency and delivery map

\`\`\`
Phase 1 verification and exit review
                 |
                 v
Phase 2A: shared-content contract + package viewer cards
                 |
                 v
Phase 2B: Mobile adapter + source resolution + existing upload flow
                 |
                 v
Phase 2 exit review / regression evidence
                 |
                 v
Phase 3A: editor draft model + shell + image composition
                 |
                 v
Phase 3B: export + Mobile publish adapter + editor integration
                 |
                 v
Phase 3C: video core (only after image editor is stable)
                 |
                 v
Phase 3 final acceptance / release decision
\`\`\`

Deliver each phase through small reviewable pull requests. Avoid one large cross-repository PR that mixes package API design, Mobile integration, and editor implementation.

---

# Phase 2 — FocusGram Content Sharing and Story Kit Integration

## 4. Phase 2 goal

Use Story Kit as the reusable Story viewer engine and shared-content rendering contract while retaining Mobile as the authority for FocusGram content, source resolution, navigation, story upload, and backend persistence.

A user must be able to share the following content to a Story and see an intentional, readable Story representation:

1. Image post
2. Video post
3. Short video
4. Long video
5. Article
6. Note

The Story must preserve a stable reference to the source. Tapping the card must open the correct real content in Mobile. A video type must not be represented as a misleading empty player or an unrelated placeholder.

## 5. Phase 2 scope

### In scope

- Finalize a versioned, serializable shared-content model in Story Kit.
- Preserve backward compatibility for existing Mobile shared-content payloads and stories.
- Add package-owned shared-content card rendering and a host callback for source navigation.
- Integrate Story Kit's viewer into Mobile through an adapter that maps Mobile story models/groups into package models.
- Connect Mobile's existing Share/Add to Story entry points to the current editor flow and retain the existing upload/publish pipeline.
- Resolve source content through Mobile's existing repositories/cache/routes or a newly approved app-owned resolver.
- Define and implement the rendering behavior for all six content kinds.
- Verify the backend's accepted shared-content field names, response shape, and persistence behavior before changing any API contract.
- Add package and app tests, feature fallback behavior, and rollout documentation.

### Not in scope

- Importing Mobile feature widgets or app business logic into Story Kit.
- Rewriting the backend story API without a verified compatibility requirement and separately reviewed migration.
- Replacing \`story_editor_pro\` with a new Story Kit editor in Phase 2.
- Full camera capture, video editing, music, advanced filters, or editor export.
- Adding hidden network requests, authentication, route navigation, or FocusGram analytics to Story Kit.
- Breaking existing story payloads or dropping unknown shared-content fields silently.

## 6. Phase 2 task sequence

### P2-0 — Phase 1 exit gate and integration baseline

**Owner:** Maintainer / integration lead  
**Depends on:** Phase 1

1. Complete the outstanding Phase 1 verification, including the required toolchain-based checks and any remaining lifecycle tests.
2. Record the exact accepted Story Kit commit, test/analyzer outputs, and unresolved risks.
3. Pin the Mobile base commit used for integration.
4. Confirm a clean working tree and establish package dependency consumption (private Git dependency, workspace/path development, or another approved mechanism). Do not commit credentials or local-only paths.
5. Verify whether the package is consumed as a Git dependency, a local package, or another deployment artifact; choose a repeatable developer and CI setup.

**Exit:** Phase 1 is formally passed; both source revisions and package-consumption method are recorded.

### P2-1 — Define the shared-content contract

**Owner:** Story Kit package, with Mobile/backend review  
**Depends on:** P2-0

Design and implement a typed contract; exact public symbol names are an API-design task, not pre-approved names. The contract should include:

- schema/version identifier;
- a stable source ID and source kind;
- display metadata (title, excerpt/description, author/source identity, thumbnail/cover where available);
- a canonical source URI/deep link when available;
- selected media identity/index for a carousel or multi-image post;
- optional content-specific preview metadata;
- a clear distinction between persisted metadata and runtime-resolved media handles.

Recommended source-kind enum values: \`imagePost\`, \`videoPost\`, \`shortVideo\`, \`longVideo\`, \`article\`, \`note\`. Existing legacy types (\`post\`, \`carousel\`, \`video\`, \`short\`, \`code\`, and any values found in real persisted data) must be mapped or preserved without data loss.

**Contract rules**

- Stable IDs and source kind are required; optional display fields may be absent.
- Do not serialize temporary file paths, expired signed URLs, credentials, or runtime player handles as permanent source data.
- Do not assume that the current Mobile model's \`description\` is a complete article body or note body.
- If a share is invoked from a carousel slide, preserve that selected slide's identity/index. Never silently reset to slide zero.
- Keep unknown type/version data recoverable where safe; provide a fallback renderer rather than crashing.
- Add model validation and JSON round-trip tests before integrating the contract into the app.

**Exit:** API proposal reviewed; compatibility map and migration/fallback behavior documented; tests pass.

### P2-2 — Add package-owned shared-content rendering

**Owner:** Story Kit package  
**Depends on:** P2-1

1. Add a shared-content rendering surface in the package, integrated with the viewer's existing layer/render path.
2. Render dedicated card variants for image post, video post, short video, long video, article, and note. Keep article and note visually distinct.
3. Use package-owned styling primitives and configuration. Do not import Mobile \`AppColors\`, typography, theme, or \`RichSharedContentCard\`.
4. Add a host-provided callback such as an open-source/content action. The package should return the typed source reference; Mobile decides which route to open.
5. Make loading, missing thumbnail, malformed payload, unsupported kind, unavailable source, and error states deterministic and accessible.
6. Define how the shared-content card composes with story media, captions, overlays, hit testing, and tap zones. Avoid making the entire story card accidentally trigger previous/next navigation.
7. Keep rendering read-only in Phase 2; editing/moving a structured content layer belongs to Phase 3.

**Content-specific rendering requirements**

| Kind | Required representation |
|---|---|
| Image post | Image/cover preview and source metadata; preserve selected image identity |
| Video post | Video-specific card treatment, playable preview only when a host resolver supplies a valid playable asset; otherwise clearly identify it as a source preview |
| Short video | Short-video badge/visual treatment; source reference and valid playback/preview when available |
| Long video | Long-video treatment; do not imply the whole source plays inside the Story if it does not |
| Article | Article-specific card using available headline, excerpt, publisher/author, and cover |
| Note | Note-specific card using note content/title and author; visually distinct from an article |

**Exit:** package widget tests cover every kind, fallback path, interaction callback, and accessibility semantics.

### P2-3 — Integrate Story Kit viewer into Mobile

**Owner:** Mobile app  
**Depends on:** P2-2

1. Add the Story Kit package through the approved dependency method.
2. Add an app-owned adapter that maps Mobile's \`StoryGroupModel\`/\`StoryItemModel\` into Story Kit group/item models.
3. Keep Mobile's backend-facing models and repository separate from Story Kit's portable models.
4. Map the existing story media URL/type, durations, captions, timestamps, overlays, and shared-content payload with explicit conversions.
5. Wire viewer callbacks back into Mobile's existing seen-tracking, group navigation, reactions, and source-open behavior as supported.
6. Preserve current story loading, empty/error states, group order, and story expiration behavior.
7. Remove or retire the old viewer only after parity tests and feature-flagged validation; avoid leaving two competing viewers in the same production path.

**Exit:** Mobile displays the same fetched story data through Story Kit without changing the backend payload contract; core viewer behaviors are regression-tested.

### P2-4 — Connect Share/Add to Story entry points

**Owner:** Mobile app  
**Depends on:** P2-1 and P2-3

1. Inventory all content screens and existing share entry points for posts, video posts, short/long videos, articles, and notes.
2. Add or normalize a single app-owned adapter that creates the typed shared-content descriptor from the actual source model.
3. Keep the existing \`StoryEditorWrapper\` and \`StoryEditorPro\` flow for Phase 2 unless a separate approved change establishes editor parity.
4. Pass the selected content reference/metadata through the editor wrapper and existing story creation path.
5. Ensure cancel, back, permission failure, and editor failure do not create a story or orphaned upload.
6. Ensure the UI labels and card type are consistent with the source content type.

**Exit:** every supported source kind can reach the existing Story creation flow; cancel/error paths do not publish.

### P2-5 — Resolve source content and navigate correctly

**Owner:** Mobile app  
**Depends on:** P2-4

1. Trace the source-open behavior for each type to the canonical app route.
2. Reuse real source models from repositories/cache when available; fetch missing data through app-owned APIs only where supported.
3. Do not synthesize a video model with an empty video URL or a detail model with placeholder-only content and treat that as successful navigation.
4. Verify route parameters, IDs, media identity, and author metadata.
5. Define behavior when source is deleted, private, expired, unavailable, or user lacks permission: show a graceful unavailable state, not a crash.
6. Preserve source-open semantics through app deep links when the host supports them.

**Exit:** source-open tests prove each content kind resolves to the correct source destination and has a graceful unavailable path.

### P2-6 — Preserve and validate upload/persistence behavior

**Owner:** Mobile app + backend reviewer  
**Depends on:** P2-4

1. Trace the current editor result → optimistic StoryCubit update → \`StoryRepository.uploadStory\` → backend response → final StoryCubit update pipeline.
2. Confirm backend accepts the current \`shared_content_id\` and \`shared_content_type\` fields and determine how it returns \`shared_content\`.
3. Preserve current upload progress, notification lifecycle, upload failure handling, optimistic item reconciliation, and story expiration.
4. Verify that the package's typed model can be adapted to the existing backend response without requiring a schema migration.
5. If a backend change is unavoidable, specify it separately with compatibility, rollout, and rollback steps; do not quietly change backend field names in the Mobile client.
6. Confirm that no source-only fields or private content are accidentally exposed in the public story payload.

**Exit:** existing upload contract remains compatible; publish success/failure and metadata round-trip are tested.

### P2-7 — Cross-repository regression and acceptance testing

**Owner:** Story Kit + Mobile  
**Depends on:** P2-2 through P2-6

Test at minimum:

- One payload for each of the six required content kinds.
- Legacy persisted payloads for every real type found in repository/backend fixtures.
- Missing title, description, author, avatar, thumbnail, media URL, and canonical URI.
- Carousel slide N remains slide N after share and after reload.
- Source open from each card maps to the correct route/model.
- Deleted/private/unavailable source behavior.
- Story upload success, failure, cancellation, and retry.
- Story viewer navigation, progress, overlays, and seen tracking remain unchanged.
- Malformed/unknown payloads do not crash the viewer.
- Mobile adapter conversion is stable in both directions where serialization is used.

### P2-8 — Phase 2 exit and rollout

- Publish a package integration sample and Mobile integration notes.
- Keep the new viewer behind a feature flag or controlled rollout until regression evidence is accepted.
- Compare old/new viewer behavior on story navigation, media playback, overlays, callbacks, card layout, and error handling.
- Record known limitations and exact commits.
- Remove the flag only after acceptance; preserve a rollback path to the prior viewer.

## 7. Phase 2 acceptance criteria

Phase 2 is complete only when all of the following are true:

- [ ] Phase 1 has passed its exit review.
- [ ] Story Kit has a typed, versioned, app-agnostic shared-content contract.
- [ ] All six content types render intentional Story cards, with article/note as distinct card types.
- [ ] Story Kit contains no Mobile imports, FocusGram API calls, auth, or routing.
- [ ] Mobile consumes Story Kit through an adapter and keeps its backend models/repositories app-owned.
- [ ] Existing story publishing/upload behavior is preserved and verified.
- [ ] Tapping every card opens the correct real source or an explicit unavailable state.
- [ ] Carousel selected-media identity is preserved.
- [ ] Legacy payloads and unknown/missing optional fields have safe fallback behavior.
- [ ] Package and Mobile tests pass; relevant analyzer/format/build checks are recorded.
- [ ] Rollout/rollback instructions and remaining risks are documented.

---

# Phase 3 — Story Kit Editor MVP and Mobile Publishing Integration

## 8. Phase 3 goal

Build a reusable editor in Story Kit that can create a Story draft from media, compose editable layers, preview the final result, and hand an export result to a host app. Integrate the editor with Mobile's existing story publish flow without embedding FocusGram upload or backend logic in the package.

**Phase 3 is an editor MVP, not a promise to deliver every item in the complete feature inventory.** Camera capture, advanced video timelines, music, online sticker catalogs, advanced filters, and complex motion remain deferred unless separately estimated and accepted.

## 9. Phase 3 scope

### In scope

- Stable editor draft/project model and serialization.
- Editor shell and page management.
- Undo/redo and dirty-state handling.
- Canvas/layer model with z-order and transformations.
- Image import and image-first composition.
- Text, stickers, drawings, backgrounds, and supported structured overlays.
- Preview and deterministic image export.
- Explicit editor result/error contract.
- Mobile adapter that sends the exported result through the existing Story upload/publish path.
- Core video import/playback/preview only after image-editor exit criteria pass, with a documented duration policy and lifecycle cleanup.

### Deferred from Phase 3 MVP

- Camera capture/recording.
- Advanced multi-track video timeline, music/audio mixing, and complex animation.
- Cloud sticker/GIF search providers.
- Advanced filters and high-cost effects.
- Collaborative editing, cloud draft sync, and template marketplace.
- Any server-side editor project persistence unless required and separately approved.

## 10. Phase 3 task sequence

### P3-0 — Phase 2 exit gate and product MVP agreement

**Owner:** Maintainer / product reviewer  
**Depends on:** Phase 2

1. Confirm Phase 2 acceptance criteria and rollout evidence.
2. Agree on Phase 3 MVP canvas dimensions, supported export formats, maximum input/output size, supported platforms, and performance target.
3. Decide whether the current \`story_editor_pro\` dependency remains as a fallback during migration and when it can be removed.
4. Confirm package dependency consumption and test/build environments.

**Exit:** MVP decisions are written down; no implementation starts on ambiguous export or publish semantics.

### P3-1 — Draft model, serialization, and editor API

**Owner:** Story Kit package  
**Depends on:** P3-0

Define package-owned models for:

- draft/story project and schema version;
- page/canvas settings;
- media references and resolved media assets;
- ordered layer list with stable IDs;
- transforms (normalized position/bounds, rotation, scale, crop);
- text/sticker/drawing/background/structured shared-content elements;
- page duration and supported timing metadata;
- validation errors and export result.

Rules:

- Store portable descriptors; resolve runtime file/network/platform handles through injected host adapters.
- Do not store Mobile domain objects or FocusGram IDs as package-owned business models. A source reference may be preserved as opaque typed metadata.
- Define deterministic z-order and coordinate conventions before gesture code.
- Add serialization fixtures, versioning, malformed-draft behavior, and compatibility tests.
- Keep public exports curated; avoid exposing internal editor state classes.

**Exit:** models round-trip, schema behavior is documented, and public API review passes.

### P3-2 — Editor shell and page state

**Owner:** Story Kit package  
**Depends on:** P3-1

Implement:

- editor entry widget with host configuration and callbacks;
- single-page editor first, then add/duplicate/reorder/delete page operations;
- selected-page and selected-layer state;
- dirty-state tracking and save/discard/cancel decisions;
- empty/loading/error states;
- undo/redo for committed editor operations;
- toolbar/control slots that allow host customization without package forks;
- responsive layout and safe-area behavior.

**Exit:** deterministic state transitions, no silent draft loss, and widget/state tests for page operations and editor lifecycle.

### P3-3 — Canvas and layer manipulation

**Owner:** Story Kit package  
**Depends on:** P3-2

Implement the shared canvas system:

- normalized coordinates and canvas-to-screen conversion;
- selection, move, resize/scale, rotate, duplicate, delete;
- bring-forward/send-back and stable z-order;
- snapping/guides where feasible;
- hit testing and gesture cancellation;
- multi-touch behavior and scale boundaries;
- selection handles/guides that are editor-only and never appear in export.

**Exit:** geometry remains stable across canvas resize, save/load, and supported transforms; gesture tests cover cancellation and edge limits.

### P3-4 — Image import, crop, and backgrounds

**Owner:** Story Kit package, with Mobile adapter  
**Depends on:** P3-3

1. Add a host-injected image picker/import adapter. Story Kit should not hardcode FocusGram's picker or permissions.
2. Validate supported image types, dimensions, and file size.
3. Support image as page media or as an editable layer.
4. Implement fit/fill, crop, pan/zoom, orientation handling, and reset.
5. Add solid/gradient/image background support.
6. Handle canceled picker, missing/expired URI, decode failure, unsupported format, and oversized media.
7. Ensure source media is not destructively modified.

**Exit:** imported image composition is repeatable; crop preview matches export within documented tolerance.

### P3-5 — Text, stickers, drawing, and overlay editing

**Owner:** Story Kit package  
**Depends on:** P3-3

Implement editor interactions for the supported existing overlay types and the MVP set:

- add/edit/move/resize/rotate/delete text;
- text style and wrapping with deterministic model representation;
- local/injected sticker assets;
- drawing strokes with undo/redo;
- existing interactive overlays (poll, quiz, slider, question, countdown, link, mention) where the current package models and Phase 1 verification support them;
- selection and layer order;
- host callbacks for interactive actions, without package-side backend behavior.

**Exit:** every supported element can be added, edited, saved, reopened, and previewed; tests verify model/render parity and editor controls do not leak into output.

### P3-6 — Preview and image export

**Owner:** Story Kit package  
**Depends on:** P3-4 and P3-5

1. Define a package export contract: file/bytes or host-supplied output sink, MIME type, dimensions, duration where relevant, and structured metadata/source references.
2. Implement image export at the agreed Story canvas size/aspect ratio.
3. Ensure editor chrome, selection handles, safe-area guides, and debug overlays are excluded.
4. Ensure content cards have documented export semantics: pixels are rendered into the story image while source metadata/callback references remain separately available for the viewer.
5. Handle export progress, cancellation, temporary files, and failures without losing the draft.
6. Add golden/widget tests or deterministic render tests where the environment supports them.

**Exit:** exported output is viewable, correctly dimensioned, and stable; cancellation/failure retains the draft and cleans up partial files.

### P3-7 — Mobile editor/publish adapter

**Owner:** Mobile app  
**Depends on:** P3-6

1. Add a Mobile adapter that opens the package editor with selected content/media and app theme/config.
2. Keep upload and publish in the existing \`StoryEditorWrapper\`/\`StoryRepository\` path unless a separately approved change replaces it.
3. Map the package export result to the existing upload contract; pass shared-content metadata separately, not by trusting only the raster output.
4. Preserve upload progress notifications, optimistic story updates, reconciliation, error state, retry, and success feedback.
5. Ensure user cancel does not upload; export failure does not publish; upload failure retains a retryable draft/result where practical.
6. Do not serialize ephemeral file paths into long-lived story metadata.

**Exit:** Mobile can create a story with the new editor and publish it using the existing backend contract; all upload outcomes are tested.

### P3-8 — Video import and playback core (conditional milestone)

**Owner:** Story Kit package + Mobile adapter  
**Depends on:** P3-6 image-editor acceptance; media lifecycle tests

This milestone is allowed only after the image-editor core is stable.

1. Support video import and preview with a host-injected asset resolver/picker.
2. Define explicit duration policy: source duration, selected trim window, or story display window. Never silently truncate long video.
3. Define mute/audio policy and story progress interaction.
4. Handle loading/buffering, pause/resume, app lifecycle, initialization failure, and player disposal.
5. Preserve media aspect ratio and selected crop.
6. If video export/compositing is too expensive or platform-fragile for the MVP, return a structured video result to the host and document the boundary rather than claiming a rendered video export.
7. Preserve the prior editor path behind a rollback flag until the supported platform matrix is verified.

**Exit:** video import/preview works on the agreed platforms, duration behavior is explicit, and lifecycle tests show no leaked player/timer/audio state.

### P3-9 — Final integration, documentation, and release gate

**Owner:** Story Kit + Mobile  
**Depends on:** all accepted Phase 3 milestones

- Verify package API from a host app using only public exports.
- Run package tests/analyzer/format checks and Mobile tests/analyzer/build checks in the supported environment.
- Validate image export and, if accepted, video preview/export on supported platforms.
- Add an example host integration and update package README/API docs.
- Review performance, memory, accessibility, failure paths, and temp-file cleanup.
- Document package version/dependency pinning and migration/rollback steps.
- Remove the old editor dependency only when replacement parity and rollout criteria are met.

## 11. Phase 3 acceptance criteria

- [ ] Phase 2 has passed its exit review.
- [ ] Story Kit exposes a documented, app-agnostic editor API through curated exports.
- [ ] Draft/project models are versioned and serialization-tested.
- [ ] Page and layer operations are deterministic and undoable where supported.
- [ ] Image import, crop, text, stickers, backgrounds, drawing, and accepted overlays work.
- [ ] Preview/export matches the documented canvas size and excludes editor chrome.
- [ ] Export cancellation/failure preserves the draft and cleans partial output.
- [ ] Mobile publishes through its existing backend flow and preserves shared-content references.
- [ ] User cancellation and upload/export failure do not create an unintended published story.
- [ ] Video behavior is either verified against P3-8 acceptance or explicitly deferred; no unsupported claim of full video editing/export.
- [ ] Tests, build/analyzer evidence, sample integration, migration notes, and rollback are recorded.

## 12. Cross-phase test matrix

| Area | Phase 2 tests | Phase 3 tests |
|---|---|---|
| Models/contracts | versioning, legacy mapping, JSON round-trip, missing/unknown fields | draft schema, layer serialization, migration fixtures |
| Viewer/editor | story navigation, progress, overlays, card interactions | page/layer state, undo/redo, gesture cancellation |
| Content kinds | all six kinds, article/note distinction, selected carousel slide | content element placement/editing and source metadata preservation |
| Source routing | correct source model/route, unavailable/private/deleted cases | source reference survives edit/export/publish |
| Upload/publish | existing upload contract, success/failure/retry, progress notification | editor result → upload adapter; cancel/export error does not publish |
| Media | missing thumbnail/URL, malformed payload, viewer lifecycle | import validation, crop, image export; video lifecycle if P3-8 accepted |
| Compatibility | old story fixtures and backend response fixtures | old editor fallback, saved draft version compatibility |
| Quality | package/app analyzer, tests, supported build checks | same, plus performance, memory, accessibility, output inspection |

## 13. Risks and mitigations

| Risk | Mitigation |
|---|---|
| Story Kit API accidentally becomes FocusGram-specific | Enforce package/app boundary in review; no app imports/network/auth/routes in package |
| Existing persisted story payloads break | Gather real fixtures; add legacy mapping and unknown-field fallback before rollout |
| Viewer migration regresses story controls | Feature-flagged rollout; compare callback, navigation, overlay, progress, and lifecycle behavior |
| Video card appears playable but lacks real media | Explicit preview-vs-player state; host resolver required for playable media |
| Carousel shares wrong slide | Preserve selected media ID/index and assert exact identity in tests |
| Mobile source navigation uses placeholder detail data | Resolve real source models; unavailable state if fetch fails |
| New editor duplicates upload/publish logic | Package returns an export result; Mobile retains upload ownership |
| Private package dependency fails in CI/dev | Select and document reproducible authenticated dependency strategy; never embed credentials |
| Editor scope expands into advanced video/filters/camera | Phase 3 MVP acceptance list is the scope boundary; defer optional features |
| Phase 1 is treated as passed without toolchain evidence | Hard gate and explicit phase exit review |

## 14. Suggested PR and issue breakdown

### Phase 2 PRs

1. **P2-A:** Story Kit typed shared-content contract + tests.
2. **P2-B:** Story Kit shared-content card renderers + viewer integration.
3. **P2-C:** Mobile package dependency + story adapter + viewer parity.
4. **P2-D:** Share entry-point normalization + source resolver/navigation.
5. **P2-E:** Upload/backend compatibility tests + rollout and documentation.

### Phase 3 PRs

1. **P3-A:** Draft schema + editor API + state shell.
2. **P3-B:** Canvas/layers + transformations.
3. **P3-C:** Image import/crop/background + text/sticker/drawing elements.
4. **P3-D:** Preview/export contract + image export.
5. **P3-E:** Mobile editor adapter + existing upload pipeline.
6. **P3-F:** Conditional video core.
7. **P3-G:** Final acceptance, docs, and migration cleanup.

Each PR should state its scope, changed package/app boundaries, tests run, known limitations, and acceptance criteria addressed. Avoid merging a dependent PR before its predecessor is accepted.

## 15. Workflow, CI, and status discipline

- Keep Phase 1 stabilization changes isolated from Phase 2/3 feature work.
- Do not add or modify GitHub Actions until Phase 1 passes, consistent with the Phase 1 execution plan.
- After Phase 1 passes, add CI for package format/analyzer/tests and Mobile adapter tests/build checks as appropriate.
- Use status labels consistently: **implemented-verified**, **implemented-unverified**, **partial**, **planned**, **deferred**, or **blocked**.
- Record exact repository, branch, commit SHA, command, toolchain, and result for every acceptance review.
- Never report a phase complete because its code was written; completion requires the exit criteria and evidence.

## 16. Final definition of done

The Phase 2/3 roadmap is complete as a planning artifact when the team has reviewed:

- the dependency direction and package/app ownership;
- the typed content contract and legacy compatibility strategy;
- Phase 2 and Phase 3 task ordering and exit gates;
- the explicit editor MVP boundary and deferred features;
- test, rollout, rollback, and CI requirements.

The implementation phases are complete only after their respective acceptance checklists pass.
