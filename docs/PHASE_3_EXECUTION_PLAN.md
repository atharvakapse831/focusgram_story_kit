# Phase 3 — Story Kit Editor MVP Execution Plan

**Repository:** [atharvakapse831/focusgram_story_kit](https://github.com/atharvakapse831/focusgram_story_kit)  
**Branch:** `phase-3/editor-mvp`  
**Base commit:** `ce4d3ae` (`phase-1/implementation` after PR #4 merge)  
**Target scope:** Section 5 (Phase 3) of [`docs/STORY_KIT_IMPLEMENTATION_PLAN.md`](STORY_KIT_IMPLEMENTATION_PLAN.md) and Section 3 of [`docs/STORY_KIT_FEATURE_INVENTORY.md`](STORY_KIT_FEATURE_INVENTORY.md).

---

## 1. Goal & Architectural Overview

Phase 3 implements the **Minimum Usable Editor (MVP)** for FocusGram Story Kit. This phase establishes the canonical document model, normalized coordinate geometry, command-based history (undo/redo), interactive multi-layer canvas, multi-page strip, draft persistence interface, deterministic still-image exporter, and the main `StoryKitEditor` widget.

### Core Contracts & Separation of Concerns

1. **Canonical Document (`StoryProject` / `StoryPage` / `StoryElement`)**:
   - Strictly serializable, versioned (schema v1), immutable data models.
   - Explicit normalized coordinate system `[0.0, 1.0]` for center positions `(x, y)` and sizes `(width, height)`, rotation in radians, and anchor pivots.
   - Layer types: Text, Image, Sticker, and Shared Content Card (bridging Phase 2 content sharing with Phase 3 canvas composition).

2. **State Ownership & Command History**:
   - Document state (serializable project model) is isolated from transient editor state (active tool, selected element, gesture in progress).
   - Command pattern (`EditorCommand`) for all document mutations:
     - `AddElementCommand`, `RemoveElementCommand`, `TransformElementCommand`, `UpdateElementPayloadCommand`, `ReorderElementCommand`, `AddPageCommand`, `RemovePageCommand`, `DuplicatePageCommand`, `SetPageBackgroundCommand`.
   - Transaction coalescing: Continuous drag/rotate/scale gestures coalesce into a single undo stack entry.
   - Memory-bounded history depth (default 50 steps).

3. **Coordinate System & Hit Testing**:
   - Canonical 9:16 aspect ratio canvas (`StoryCanvasSpec`).
   - Screen mapping: Viewport scales canvas uniformly to maintain aspect ratio with letterboxing/pillarboxing.
   - Inverted transform hit testing for rotated elements.
   - Soft-clamping policy at canvas edges to prevent elements from becoming unreachable.

4. **Draft Persistence**:
   - `StoryDraftRepository` interface with save, load, list, and delete operations.
   - `InMemoryStoryDraftRepository` default implementation for testability and headless usage.

5. **Deterministic Export**:
   - Offscreen raster export via `ui.PictureRecorder` + `Canvas` applying identical transform math to preview.
   - Strict separation: Editor chrome (handles, borders, guides) is never drawn to export.
   - Structured interactive overlays remain separate data payloads rather than being irrevocably burned into pixels.

---

## 2. Work Breakdown & Milestones

### Milestone 1: Canonical Document Models & Geometry
- `lib/models/story_canvas_spec.dart`
- `lib/models/story_transform.dart`
- `lib/models/story_media_asset.dart`
- `lib/models/element_payloads.dart`
- `lib/models/story_element.dart`
- `lib/models/story_page.dart`
- `lib/models/story_project.dart`

### Milestone 2: Command Pattern & Undo/Redo Engine
- `lib/editor/command_history.dart`
- `lib/editor/editor_commands.dart`

### Milestone 3: Editor State & Controller
- `lib/editor/editor_state.dart`
- `lib/editor/editor_controller.dart`

### Milestone 4: Interactive Canvas & Geometry Rendering
- `lib/editor/canvas/story_editor_canvas.dart`
- `lib/editor/canvas/canvas_element_view.dart`
- `lib/editor/canvas/selection_overlay.dart`

### Milestone 5: Page Strip & Navigation Management
- `lib/editor/canvas/story_page_strip.dart`

### Milestone 6: Draft Persistence Repository
- `lib/draft/draft_repository.dart`
- `lib/draft/in_memory_draft_repository.dart`

### Milestone 7: Deterministic Still-Image Exporter
- `lib/export/still_image_exporter.dart`
- `lib/export/export_result.dart`

### Milestone 8: Main Editor Widget & Public Exports
- `lib/editor/story_kit_editor.dart`
- `lib/focusgram_story_kit.dart` (curated barrel export)

### Milestone 9: Testing & Verification
- Unit tests: Serialization round-trip, transforms & hit-testing, commands & coalescing, draft repo, exporter.
- Widget tests: Editor canvas rendering, element selection, drag movement, page management, undo/redo, export flow.
- Toolchain: `dart format`, `flutter analyze`, `flutter test`.

---

## 3. Acceptance Criteria (from Implementation Plan Section 5.3)

- [ ] **AC-1:** Round-trip serialization preserves IDs, geometry, styling, order, and media references.
- [ ] **AC-2:** Page operations (add, duplicate, delete, select, reorder) maintain content and predictable selection.
- [ ] **AC-3:** Gestures are stable at canvas edges and one continuous gesture produces exactly one undo entry.
- [ ] **AC-4:** Save/reopen via draft repository restores an editable document rather than only a flattened image.
- [ ] **AC-5:** Still-image export excludes controls, selection handles, and guides.
- [ ] **AC-6:** Geometry between preview and export agrees within documented mathematical tolerance.
- [ ] **AC-7:** Public API cleanly exposes `StoryKitEditor`, `EditorController`, `StoryProject`, `StoryPage`, `StoryElement`, `StoryDraftRepository`, and export types without internal leakage.
- [ ] **AC-8:** All existing Phase 1 & 2 tests (40 tests) remain 100% passing; new tests cover all Phase 3 functionality.
- [ ] **AC-9:** Zero analyzer warnings under `flutter_lints` 5.0.0.
