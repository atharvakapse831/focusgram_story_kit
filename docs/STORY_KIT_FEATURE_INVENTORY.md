# Story Kit — Complete Feature Inventory & Implementation Roadmap

> **Purpose:** Define the intended scope, architecture boundaries, acceptance criteria, and phased delivery plan for the reusable Flutter Story Kit library in this repository.
>
> **Status discipline:** This is a target inventory, not proof that each feature exists. The repository README describes a pre-1.0 skeleton focused on the viewer and JSON overlay engine; editor integration is described as upcoming. Mark features implemented only after code inspection and verification against their acceptance criteria.
>
> **Repository:** `atharvakapse831/focusgram_story_kit`  
> **Package:** Flutter / Dart  
> **Goal:** A reusable story creation and playback engine that can be embedded by a host app without coupling the library to FocusGram-specific screens or business logic.

## 1. Product principles

1. **Library first:** expose stable widgets, models, controllers, codecs, and interfaces. Do not embed host-app navigation, API clients, authentication, analytics, storage policies, or business-specific UI.
2. **Shared editor/viewer contract:** overlays remain structured JSON-safe objects after export; supported interactive overlays are not flattened into pixels unless the caller explicitly requests a flattened export.
3. **Non-destructive composition:** retain media references, transforms, styling, order, timing, and overlay metadata for as long as the chosen project/export format permits.
4. **Predictable lifecycle:** controllers, subscriptions, decoders, temporary files, and platform resources have explicit ownership and cleanup rules.
5. **Graceful degradation:** permission denial, unsupported media, invalid payloads, missing integrations, and interrupted exports produce recoverable errors rather than crashes.
6. **Host-controlled integrations:** publishing, uploads, persistence, analytics, location lookup, GIF search, and remote fonts are supplied through injected interfaces or callbacks.
7. **Testability:** core models, codecs, and state transitions are testable without a camera or network wherever possible.

## 2. Status vocabulary

Use these labels in issues and pull requests:

- **Implemented — verified:** implementation exists and relevant acceptance tests pass.
- **Implemented — unverified:** code exists, but required runtime/platform verification is incomplete.
- **Partial:** some paths work; known cases remain.
- **Planned:** part of target scope, not yet implemented.
- **Deferred:** intentionally outside the current release.
- **Blocked:** depends on a documented prerequisite.

A checklist in this document is not evidence that implementation is complete.

## 3. Feature inventory

**Priority definitions:** **P0** = release-critical; **P1** = core/polished experience; **P2** = advanced follow-up; **P3** = optional or experimental.

### 3.1 Public package API and integration — P0

- Curated public exports from `lib/focusgram_story_kit.dart`.
- Stable models for story items/groups, media assets, canvas settings, overlays, export results, and errors.
- Public editor/viewer widgets with explicit configuration objects.
- Explicit controller lifecycle: initialize, listen, cancel, dispose.
- Callbacks for close/cancel, draft changes, export progress/success/failure, viewer navigation, seen tracking, replies, and overlay interactions.
- Typed result objects rather than ambiguous success maps.
- Dependency injection for media picking, capture, persistence, export, and optional network services.
- Semver policy and documented breaking-change expectations before 1.0.
- Example app that integrates the package without relying on FocusGram application internals.
- Documented SDK requirements, platform permissions, plugin setup, known limitations, and troubleshooting.

**Acceptance criteria**
- A fresh sample imports the package using only public exports.
- No app-private imports or FocusGram API assumptions are required.
- Controller/listener ownership and disposal are documented.
- Invalid configuration returns a typed actionable error.
- API tests catch accidental export removal and unintended public contract changes.

### 3.2 Story project and document model — P0

- Project containing one or more ordered story pages/items.
- Per-page aspect ratio, canvas dimensions, background, duration, and media source.
- Media-source abstraction for image, video, generated background, and future media kinds.
- Overlay list with stable IDs, type discriminator, normalized position, bounds, rotation, scale, anchor, layer order, and optional timing.
- Optional overlay grouping.
- Metadata and schema version for serialization/migration.
- Draft state distinct from final export state.
- Deterministic JSON encode/decode and validation.
- Forward-compatible handling of unknown overlay types where safe; preserve raw payload when feasible.
- Documented defaults for missing optional fields and validation for required fields.
- Asset references that distinguish package/app-owned assets from temporary picker/camera URIs.
- Optional per-overlay behavior configuration.

**Acceptance criteria**
- Round-trip encoding preserves supported fields and stable IDs.
- Malformed JSON yields a structured decode error and never crashes the editor.
- Unknown overlay types do not crash unrelated pages.
- Supported schema versions do not silently lose fields.
- Migrations have fixtures and tests for earlier serialized versions.

### 3.3 Story viewer and playback — P0

- Group navigation across story owners/groups through a paging controller.
- Per-item duration and progress indicator.
- Image and video display with loading/buffering/error states.
- Hold-to-pause and resume.
- Left/right tap zones for previous/next item.
- Next/previous group navigation and edge handling.
- Retry/recovery UI for media failures.
- Documented video-duration policy (the README currently mentions a 30-second cap; decide whether configurable or fixed).
- Seen-tracking callback with stable event semantics.
- Optional host-controlled reply input slot/callback.
- Accessibility semantics for navigation and controls.
- Pause on app lifecycle interruption and resume according to a documented policy.
- Dispose player/timer/animation resources on item change and widget disposal.
- Optional adjacent-item preload with bounded memory.
- Chrome slots/overrides for host-owned headers, actions, and reply panel.

**Acceptance criteria**
- Progress follows configured duration and stops while paused.
- Rapid taps, held touches, and page switches do not create overlapping timers or stale callbacks.
- Failed video initialization shows a recoverable error.
- Interactive overlays remain separate from base media.
- Seen events follow a documented rule and do not accidentally duplicate.
- Backgrounding/disposal cannot leave unwanted audio or timers running.

### 3.4 Interactive overlay system and codecs — P0 core types; P1 editing

All overlay definitions, JSON codecs, validation, and rendering must use a shared contract across editor and viewer.

**Core overlay types**
- Text and emoji stickers.
- Image/sticker assets and GIF/animated stickers.
- Mention, hashtag, location, and link sticker.
- Poll and quiz.
- Emoji slider and question box.
- Countdown.

**Overlay capabilities**
- Stable ID and type discriminator.
- Normalized canvas position/bounds, rotation, scale, and z-order.
- Type-specific style and payload.
- Optional start/end time.
- Validation and safe defaults.
- Tap/submit callbacks exposed to the host; no hidden backend calls.
- Accessible labels and useful touch targets for interactive items.
- Editor hit-testing, selection bounds, and a documented boundary policy.
- JSON import/export without baking interaction metadata into pixels.
- Legacy poll payload compatibility where required: README notes structured `poll_options` maps with fallback to legacy `options`.

**Acceptance criteria**
- Every supported type has model, codec, validation, rendering, interaction, and round-trip tests.
- Invalid payloads fail gracefully and preserve recoverable raw data where safe.
- Editor and viewer use the same documented coordinate convention.
- Exported overlay data remains independently interactive in the viewer.
- Callbacks include overlay ID and typed response data.

### 3.5 Editor shell and page management — P0

- Editor entry widget configured with initial project/media and feature flags.
- Multi-page timeline or page strip.
- Add, duplicate, reorder, select, and delete pages.
- Per-page duration controls.
- Page-level background and media replacement.
- Dirty-state tracking and explicit save/discard/cancel behavior.
- Empty/loading/error states.
- Accessibility and keyboard support where platform conventions allow.
- Responsive layout for narrow phones and larger screens/tablets.
- Injectable toolbar/control slots so host apps can customize chrome without forking.

**Acceptance criteria**
- Page order and selection stay correct after add/duplicate/delete/reorder.
- Deleting the selected page chooses a predictable neighbor.
- Dirty content cannot be silently discarded on accidental close.
- Feature flags block functionality at both UI and state/action layers.

### 3.6 Camera and capture — P1; adapter interface P0

- Replaceable capture adapter and camera lifecycle handling.
- Photo capture and video recording with explicit start/stop states.
- Configurable maximum recording duration.
- Camera flip and flash/torch when hardware permits.
- Permission request, denial, permanent denial, and system-settings guidance.
- Review captured media before adding to the story.
- Switch between capture and gallery.
- Handle interruptions, unavailable hardware, and app lifecycle transitions.
- Configurable quality/resolution and orientation policy.
- Explicit temporary-file ownership and cleanup.

**Acceptance criteria**
- Camera permission is requested only when entering relevant capture functionality.
- Denial does not crash or trap users; import remains available where possible.
- Capture returns a documented asset/result and releases hardware resources when leaving capture.
- Orientation metadata is handled correctly.
- Hosts can replace the capture adapter.

### 3.7 Gallery import and media preparation — P0 images; P1 video

- Import image and video through the system photo picker.
- Optional multi-select.
- File type and size validation.
- Read dimensions before expensive operations where practical.
- Normalize orientation during rendering/export while preserving original source when possible.
- Trim or reject media exceeding configured limits.
- Clear progress and error states.
- Handle inaccessible or expired temporary URIs.
- Optional host-supplied asset resolver for remote media.

**Acceptance criteria**
- Picker cancellation is not treated as failure.
- Unsupported formats and decode failures show actionable errors.
- Temporary picker URIs are not assumed to remain valid indefinitely.
- Expensive processing does not synchronously block the UI isolate.
- Source metadata remains available for recovery/debugging.

### 3.8 Image crop, transform, and adjustments — P1

- Fit/fill crop presets and free crop.
- Story aspect ratios including 9:16 and custom ratios.
- Pan/zoom within crop bounds.
- Rotate, optionally flip, and reset.
- Basic brightness, contrast, saturation, warmth, and vignette adjustments.
- Filter presets with adjustable intensity.
- Efficient preview rendering without full-resolution recomputation on every interaction.
- Non-destructive adjustment metadata where feasible.
- Deterministic transform math.

**Acceptance criteria**
- Crop preview matches exported result for supported ratios.
- Transform operations do not mutate the original source.
- Reset returns to documented initial values.
- Tests cover portrait, landscape, EXIF-rotated assets, and extreme zoom/pan boundaries.
- Filter parameters serialize deterministically.

### 3.9 Text and typography — P1

- Add, select, edit, move, scale, rotate, duplicate, and delete text.
- Font families through a local/injected font registry.
- Font size, color, alignment, line height, letter spacing, and decoration.
- Bold/italic where supported.
- Background/highlight, outline, shadow, and style presets.
- Text box sizing, wrapping, and alignment controls.
- Emoji/unicode and line-break support.
- Font fallback when requested fonts are unavailable.
- Optional rich-text spans only with a portable document representation.

**Acceptance criteria**
- Preview/export text layout is consistent within documented platform tolerances.
- Text edits do not unintentionally reset transform or layer order.
- Long text, emoji, combining marks, RTL text, and multiline content are tested.
- Font fallback is explicit, not silently surprising.

### 3.10 Stickers, emoji, GIF, and assets — P1 local; P2 online discovery

- Local sticker/emoji library interface.
- Sticker image import.
- GIF/animated asset abstraction.
- Add, move, scale, rotate, duplicate, delete, and reorder.
- Correct alpha/transparency handling.
- Optional injected network provider for GIF/sticker catalogue discovery.
- Provider loading, empty, error, and cancellation states.
- Attribution/licensing metadata when required by provider.
- Defined animation timing and frame policy for preview/export.

**Acceptance criteria**
- Missing network provider does not block local stickers.
- Sticker transforms persist through save/load.
- Static-export policy for animated overlays is documented.
- Downloads are bounded, cancellable, and cached only under explicit policy.

### 3.11 Drawing and markup — P1

- Pen, marker, and eraser.
- Configurable color, width, opacity, and brush type.
- Stroke-level undo/redo.
- Smooth paths and pressure input where supported.
- Optional line, arrow, rectangle, and circle tools.
- Separate drawing layer from base media and other overlays.
- Clear drawing with confirmation.
- Documented behavior when canvas/media crop changes.

**Acceptance criteria**
- Stroke ordering is deterministic and undo removes the latest committed action.
- Fast gestures do not leave gaps or unbounded path data.
- Drawing aligns correctly after resize and export.
- Pointer cancellation does not corrupt the drawing state.

### 3.12 Backgrounds and templates — P1

- Solid color and gradient backgrounds.
- User-selected image background.
- Optional pattern/texture library.
- Templates with aspect ratio, layout, and default elements.
- Per-page backgrounds.
- Replace background without deleting unrelated overlays.
- Optional palette/randomize tools.

**Acceptance criteria**
- Background data serializes and renders consistently.
- Replacing a background follows documented media-cover behavior.
- Template application is undoable and does not silently destroy content.

### 3.13 Canvas, layers, and manipulation — P0 model/order; P1 interactions

- Stable layer list/order and deterministic front/back operations.
- Select/deselect overlays.
- Move, rotate, scale, and resize via gestures/handles.
- Center snapping and optional edge guides.
- Multi-touch gesture handling.
- Canvas-to-normalized-coordinate conversion.
- Safe-area guides excluded from output.
- Lock/hide, duplicate, delete, bring forward/send backward.
- Optional multi-select/group transform later.
- Documented z-order/hit-test rules.
- Minimum/maximum scale limits and visible selection state.

**Acceptance criteria**
- Repeated transform operations serialize visible geometry within a defined tolerance.
- Canvas resizing does not cause coordinate drift.
- Gesture cancellation does not leave stuck drag/selection states.
- Handles and guides never appear in export.

### 3.14 Video editing and composition — P2 after still-image reliability

- Video import/capture, trim start/end, and preview.
- Configurable duration policy.
- Mute/unmute original audio.
- Optional injected music/audio provider.
- Timed overlays and animations.
- Cover-frame selection.
- Aspect-ratio crop and orientation.
- Encoding progress, cancellation, and failure recovery.
- Documented codec/container/resolution support matrix.
- Audio/video synchronization policy.

**Acceptance criteria**
- Export duration matches selected interval within documented tolerance.
- Preview and export crop/orientation match.
- Cancellation preserves draft and removes partial output.
- Audio behavior is deterministic.
- Unsupported codecs fail with actionable errors.

### 3.15 Animation and motion — P2

- Per-overlay entrance/exit transitions.
- Fade, scale, slide, and rotation presets.
- Timeline start/end, duration, and easing.
- Preview playback and reduced-motion behavior.
- Deterministic export rendering at selected frame times.
- Distinction between view-only UI animation and exported animation.

**Acceptance criteria**
- Animation state survives serialization.
- Preview timing uses a single clock and behaves predictably across pause/resume.
- Static-image export uses a documented frame-selection policy.
- Reduced-motion preferences are respected for nonessential UI animation.

### 3.16 Undo, redo, drafts, and persistence — P0 core; P1 autosave

- Command/state-based undo and redo.
- Support add/remove/reorder overlay, transform, text/style edit, crop, adjustments, page operations, background changes, and drawing strokes.
- Coalesce repeated drag/slider updates.
- Bounded history and memory policy.
- Draft repository interface with save, restore, discard, and interrupted-session recovery.
- Schema-versioned project persistence.
- Optional host-supplied durable/encrypted storage adapter.
- Asset-reference integrity and missing-asset recovery.
- Expose dirty and save status.

**Acceptance criteria**
- Undo/redo restores the exact prior serialized state for supported operations.
- Continuous gestures can coalesce instead of producing hundreds of entries.
- History bounds are explicit and tested.
- Autosave failure preserves in-memory work and is surfaced to the caller.
- Reopening a saved draft restores available media and overlays.

### 3.17 Rendering, export, and output contract — P0 still image; P1 video

- Still-image export at configurable resolution/format supported by platform implementation.
- Deterministic compositing of background, media crop, drawings, and visual overlays.
- Interactive overlay JSON remains separate from rendered pixels.
- Typed export result containing file/URI, dimensions, format, duration if relevant, overlay payload, warnings, and error details.
- Async progress reporting and cancellation.
- Temporary output cleanup and memory-aware rendering.
- Color/orientation policy.
- Predictable output ownership/location.
- Optional host-controlled watermark extension.
- Optional thumbnail/preview generation.

**Acceptance criteria**
- Fixed fixtures validate pixel output for supported transforms.
- Export honors aspect ratio and configured resolution.
- Errors are typed; partial files are cleaned up.
- Progress events follow a documented lifecycle through success/failure/cancel.
- Interactive overlay data is returned separately when requested.
- Selection chrome and guides are never burned into media.

### 3.18 Performance and resource management — P0

- Move expensive processing off the UI isolate where feasible.
- Reuse decoded media; avoid unnecessary full-resolution decode.
- Bounded image/video caches with explicit eviction.
- Prompt disposal of camera, video, animation, and render controllers.
- No unbounded listeners, timers, streams, or temporary files.
- Throttle high-frequency editor updates.
- Stable widget keys and focused rebuilds.
- Profile frame stability and memory on representative devices.
- Optional diagnostics without leaking sensitive paths/payloads.
- Cancellation/lifecycle checks for long-running jobs.

**Acceptance criteria**
- Repeated entry/exit cycles show no monotonic resource growth.
- Large-media processing does not freeze core interaction beyond documented budgets.
- Cache/disposal paths are explicitly tested.
- Disposing/backgrounding safely stops owned work.
- Performance claims rely on profiling, not unit tests alone.

### 3.19 UX, accessibility, localization, responsiveness — P1

- Loading, empty, permission, unsupported-format, and export-failure states.
- Mobile-appropriate touch targets.
- Screen-reader labels and semantic actions.
- High-contrast selection and state indications.
- RTL/layout-direction support.
- Centralized localizable strings.
- Keyboard shortcuts where relevant on desktop/tablet/web.
- Theme, typography, icon, toolbar, and chrome customization.
- Responsive layout and safe-area handling.
- Reduced-motion options.

**Acceptance criteria**
- Primary workflows support semantic navigation to the extent platform components allow.
- No hard-coded host branding.
- Supported narrow and large screens do not overflow.
- Localization does not rely on fixed English string dimensions.
- Themes/slots cannot break document state or controllers.

### 3.20 Platform compatibility and permissions — P0

- Document supported Flutter/Dart ranges.
- Specify Android/iOS minimum versions and required permissions.
- Keep capture, picker, filesystem, and encoder logic behind adapters.
- Detect platform capability differences.
- Handle permission denial and lifecycle interruption.
- Declare support or explicit exclusions for desktop/web by feature.
- CI analysis/test matrix across declared platforms.
- Plugin compatibility and upgrade policy.

**Acceptance criteria**
- Package compiles and tests pass for every declared target.
- Unsupported capabilities are reported rather than silently ignored.
- Permissions are minimal and documented.
- Platform behavior/limitations are documented and smoke-tested.

### 3.21 Security and privacy boundaries — P0

- No implicit uploads or external requests in core editing/viewing.
- No hidden analytics/tracking/advertising SDKs.
- Host owns identity, authorization, publishing, and backend requests.
- Temporary-media cleanup follows explicit ownership rules.
- Avoid logging user content in full by default.
- Do not expose credentials or unnecessary private paths in errors.
- Validate imported JSON and untrusted overlay payloads.
- Remote providers are opt-in.
- Document storage-retention and deletion responsibilities.

**Acceptance criteria**
- Local offline editing makes no hidden network requests.
- Malformed payload tests do not crash or bypass validation.
- Logs avoid tokens, media contents, and unnecessary user data.
- Draft deletion and temporary-file cleanup are testable.

### 3.22 Developer experience and extension points — P1

- Registry/interface for custom overlay types.
- Custom serializer/deserializer and renderer registration.
- Asset-provider interface for stickers, GIFs, and fonts.
- Capture, picker, draft/persistence, and exporter adapters.
- Optional toolbar/viewer chrome slots.
- Feature flags and capability configuration.
- Theme/localization hooks.
- Debug mode for overlay bounds, IDs, and layer order.
- Example custom overlay and adapters.
- API migration guide.

**Acceptance criteria**
- Host apps can register custom overlays without modifying package internals.
- Duplicate/invalid type registrations fail explicitly.
- Optional integrations can be omitted without breaking editor/viewer startup.
- Extension contracts have tests and examples.

### 3.23 Testing, CI, documentation, release — P0

- Unit tests for models, codecs, validation, coordinate math, state transitions, history, and configuration.
- Widget tests for editor/viewer interactions and loading/error states.
- Golden/render tests for export composition.
- Integration tests for camera, picker, and export on supported devices/emulators.
- Regression fixtures for legacy overlay/poll payloads.
- Performance/memory smoke tests with large assets and repeated sessions.
- Static analysis and format checks in CI.
- README quick start, API reference, changelog, license/dependency review, versioning, migration notes.
- Example app.
- Release checklist for Android/iOS smoke tests and package contents.

**Acceptance criteria**
- CI runs deterministic tests on pull requests.
- Bug fixes add targeted regression tests where practical.
- Release artifacts contain only intended files/dependencies.
- Documentation states known limitations honestly.
- No P0 criterion is unmet unless explicitly waived with written rationale.

## 4. Recommended architecture

Keep the package layered and dependency-injected. This is a target shape, not an instruction to move existing code blindly.

```
lib/
  focusgram_story_kit.dart          # curated public API
  src/
    core/
      config/                       # editor/viewer configuration
      errors/                       # typed errors and results
      lifecycle/                    # cancellation and disposal
    models/
      story_project.dart
      story_page.dart
      media_asset.dart
    overlays/
      story_overlay.dart
      overlay_registry.dart
      overlay_codec.dart
      types/
      renderers/
    editor/
      story_kit_editor.dart
      editor_controller.dart
      editor_state.dart
      commands/                     # undo/redo operations
      canvas/
      pages/
      panels/
    viewer/
      story_kit_viewer.dart
      viewer_controller.dart
      playback_state.dart
      progress/
    media/
      media_picker_adapter.dart
      capture_adapter.dart
      media_preparer.dart
    rendering/
      story_renderer.dart
      export_controller.dart
      export_result.dart
    persistence/
      draft_repository.dart
      project_migrations.dart
    extensions/
      asset_provider.dart
      custom_overlay.dart
test/
  models/
  codecs/
  editor/
  viewer/
  rendering/
  integration/
example/
```

### Architecture boundary rules

- Models/codecs should not depend on Flutter UI widgets unless unavoidable.
- Core overlay models/codecs must not depend on FocusGram backend DTOs; use explicit mapping/adapters.
- Editor changes should be represented by commands or equivalent testable operations.
- Rendering consumes a project snapshot and does not depend on selection chrome.
- Viewer playback state is separate from editor selection/undo state.
- Platform plugins remain behind interfaces.
- Only curated, stable types are exported from the root barrel.

## 5. Phased implementation plan

### Phase 0 — Contracts and quality baseline (P0)
1. Audit current source/tests and map each item to the status vocabulary above.
2. Stabilize project/page/media/overlay contracts and schema versions.
3. Test JSON round trips, malformed input, and legacy poll compatibility.
4. Document lifecycle, coordinate conventions, video policy, result/error contracts.
5. Set up CI analysis and unit tests.

**Exit gate:** model/codec tests pass, public boundaries are documented, and current behavior is represented accurately.

### Phase 1 — Viewer and overlay foundation (P0)
1. Verify item/group navigation, progress, pause/resume, loading/error handling, seen tracking, and disposal.
2. Verify all supported overlay renderers and callbacks.
3. Test lifecycle interruption and resource cleanup.
4. Add rapid-input, malformed-payload, and compatibility regressions.
5. Build an example viewer flow.

**Exit gate:** Sections 3.3 and 3.4 meet acceptance criteria on declared platforms.

### Phase 2 — Minimum usable editor (P0/P1)
1. Add editor entry, page state, image import, canvas, selection, transforms, and layer ordering.
2. Add text and supported sticker overlays.
3. Add backgrounds/canvas configuration.
4. Implement undo/redo for supported editor commands.
5. Add draft repository-based save/restore.
6. Add still-image export with structured overlays delivered separately.
7. Add render fixtures and verify selection chrome is excluded.

**Exit gate:** user can create a multi-page still-image story, save/reopen it, and export deterministic assets without losing structured overlay data.

### Phase 3 — Capture, drawing, polish (P1)
1. Add injectable camera/capture integration and permission states.
2. Add drawing/markup and stroke undo/redo.
3. Improve crop, filters, typography, and sticker library.
4. Improve theming, accessibility, localization, and responsive layout.
5. Stress-test repeated open/close and large assets.

**Exit gate:** core Android/iOS editor flows are reliable, with platform caveats documented.

### Phase 4 — Video and animation (P2)
1. Implement video trim/crop and clip metadata.
2. Add timed overlays and animation timeline.
3. Implement async export with cancellation/failure recovery.
4. Verify codec support and audio/video synchronization.
5. Profile memory, output size, speed, and frame consistency.

**Exit gate:** video export meets explicit timing, sync, resource, and error criteria on declared devices.

### Phase 5 — Extensibility and release hardening (P2/P3)
1. Publish custom overlay/renderer/asset-provider examples.
2. Add multi-select/group transforms, extra effects, templates, and advanced animation as prioritized.
3. Finalize API stability, docs, changelog, package checks, and migration guidance.
4. Run release checklist and document unsupported capabilities.
5. Decide which features are part of 1.0 and which remain experimental.

**Exit gate:** P0/P1 scope passes; experimental features are labelled; breaking assumptions are documented.

## 6. First usable release checklist

- [ ] README accurately distinguishes implemented and planned capabilities.
- [ ] Public API and example work without app-private imports.
- [ ] Project and overlay schemas are versioned and tested.
- [ ] Viewer navigation, pause/resume, seen callbacks, and disposal pass tests.
- [ ] Supported overlays render and round-trip without flattening interaction metadata.
- [ ] Editor supports page operations, image import, overlay manipulation, text/stickers, and backgrounds.
- [ ] Undo/redo and draft save/restore cover supported edits.
- [ ] Still-image export matches preview within defined tolerance and excludes editor chrome.
- [ ] Errors/cancellations are typed and recoverable; temporary outputs are cleaned up.
- [ ] Core code makes no hidden network requests or uploads.
- [ ] Android/iOS permissions and compatibility are documented and smoke-tested.
- [ ] Unit, widget, codec, and rendering tests pass; analysis is clean.
- [ ] Resource handling and large-media behavior are profiled on representative devices.
- [ ] All unmet P0 criteria are fixed or explicitly waived with rationale.

## 7. Deferred/optional scope

These should not delay a reliable core release unless explicitly promoted:
- Cloud asset libraries, template marketplaces, and built-in GIF search backends.
- Collaboration and concurrent editing.
- Account management, publishing APIs, upload pipelines, and social-network business rules.
- AI content generation or automatic editing.
- Professional multi-track video editing.
- Desktop/web parity for camera/video export.
- Paid asset catalogues, licensing enforcement, or analytics services.

Integrate such capabilities later through extension interfaces instead of embedding product-specific systems in the core library.

## 8. Repository-specific current-state baseline

The README on `main` describes this as a **pre-1.0 skeleton** focused on the viewer and overlay engine. It lists `StoryKitViewer`, group navigation, per-item durations, pause behavior, video loading state, tap zones, seen tracking, reply input, and JSON-backed interactive overlays. It also says editor integration points are expected in later commits.

Re-audit the actual current source before claiming any item is complete. This inventory is broader than the current README's declared implementation and is intended to guide incremental delivery.

## 9. Change-management rule

For each feature:
1. Create a scoped issue/plan referencing this section, priority, and acceptance criteria.
2. Record current status and prerequisites.
3. Implement a small coherent slice with tests.
4. Run relevant unit/widget/integration/platform verification.
5. Update this document only when status is backed by source and test evidence.
6. Do not mark a feature complete solely because code compiles or mock UI renders.

**End of inventory.**
