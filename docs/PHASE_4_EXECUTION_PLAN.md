# FocusGram Story Kit — Phase 4 Execution Plan
## Editing Capabilities Expansion

**Repository:** `atharvakapse831/focusgram_story_kit`  
**Branch:** `phase-4/editing-capabilities`  
**Base Commit:** `f888af1` on `phase-1/implementation`  
**Authoritative Plan Reference:** [`docs/STORY_KIT_IMPLEMENTATION_PLAN.md`](STORY_KIT_IMPLEMENTATION_PLAN.md) Section 5.4 & [`docs/STORY_KIT_FEATURE_INVENTORY.md`](STORY_KIT_FEATURE_INVENTORY.md)  
**UX Level Target:** UX-2 (Creator-Grade Polish & Completeness)  

---

## 1. Objectives & Scope Boundaries

Phase 4 expands the editor from the Phase 3 MVP into a full-featured, creator-grade story editing suite.

### In Scope (Phase 4):
1. **Crop, Rotate, Flip, Fit/Fill, Filters, and Adjustments:**
   - Non-destructive image adjustment metadata (brightness, contrast, saturation, warmth, flip horizontal/vertical, filter presets: none, sepia, grayscale, vintage, cool, warm).
   - Preview rendering via color matrix and transform.
   - Parity in `StoryStillImageExporter`.
2. **Text Workspace & Typography:**
   - Expanded text properties: outline/stroke, drop shadow, line spacing, letter spacing, font family registry/fallback.
   - Rich text editing bottom sheet with interactive typography controls.
   - Parity in preview canvas and offscreen export.
3. **Drawing, Brushes & Basic Shapes:**
   - `DrawingElementPayload` with smooth stroke paths, customizable brush types (pen, marker, neon, eraser), color, opacity, and stroke width.
   - `ShapeElementPayload` supporting geometric primitives (rectangle, circle, line, arrow, star, heart) with customizable stroke and fill.
   - Stroke-level undo/redo integrated with `CommandHistory`.
   - Full export rasterizer support.
4. **Stickers, Emojis, Asset Providers:**
   - Injectable `StoryAssetProvider` abstraction with built-in categorized emoji & sticker packs.
   - Sticker/emoji selector bottom sheet.
5. **Backgrounds & Templates:**
   - Linear and radial gradient backgrounds (`StoryGradientBackground`), textures, and presets.
   - Editable story template presets (`StoryTemplate`) generating pre-configured multi-element layouts.
   - Preview and export rasterization parity.
6. **Gallery & Media Preparation Pipeline:**
   - `StoryMediaPickerAdapter` interface with default implementation.
   - Media validation, dimension probing, and normalization helpers.
7. **Camera & Capture Adapter:**
   - Replaceable `StoryCaptureAdapter` interface with permission states (`granted`, `denied`, `permanentlyDenied`, `restricted`).
   - Graceful camera denial handling with fallback to gallery import.
8. **Layer Management, Snapping & Alignment Guides:**
   - Center X and Center Y snapping guidelines with visual alignment indicators during drag.
   - Element lock (`isLocked`) and visibility toggle (`isVisible`) UI and commands.
   - Layer manager bottom sheet with z-order reordering, locking, and visibility controls.
9. **Theming, Localization & Accessibility:**
   - `StoryKitEditorTheme` design tokens for customization.
   - Localizable string bundle `StoryKitStrings`.
   - Accessible semantics, mobile touch targets, and RTL layout compatibility.
10. **Testing & Verification:**
    - Full unit, widget, and serialization test suite covering all new capabilities.
    - Zero analyzer warnings under `flutter_lints` 5.0.0.

### Strictly Out of Scope (Deferred to Phase 5 or Later):
- Video timeline, scrubber, video trim, audio track mixing, and video export (Phase 5).
- Cloud backend asset synchronizers, template marketplaces, or third-party paid asset APIs.
- FocusGram backend route wiring or auth token handling.
- Modifying Mobile's unrelated auth files.

---

## 2. Baseline Architecture Audit & Extension Points

| Subsystem | Phase 3 Baseline State | Phase 4 Expansion |
|---|---|---|
| **Element Payloads** (`lib/models/element_payloads.dart`) | `Text`, `Image`, `Sticker`, `Card`, `Unknown` | Add `DrawingElementPayload`, `ShapeElementPayload`. Expand `TextElementPayload` (outline, shadow, line/letter spacing). Expand `ImageElementPayload` (adjustments, filters, flip). |
| **Element Types** (`lib/models/story_element.dart`) | `text`, `image`, `sticker`, `card`, `unknown` | Add `drawing`, `shape` to `StoryElementType`. |
| **Page Background** (`lib/models/story_page.dart`) | `backgroundColor`, `backgroundAsset` | Add `backgroundGradient` (`StoryGradientBackground`) to `StoryPage`. |
| **Editor State** (`lib/editor/editor_state.dart`) | Tools: `select`, `text`, `sticker`, `background` | Add `draw`, `shape`, `layers`, `adjust`. Add snapping state (`snapLines`). |
| **Editor Controller** (`lib/editor/editor_controller.dart`) | Basic CRUD commands, transform, page management | Add commands: `UpdateImageAdjustmentsCommand`, `AddDrawingStrokeCommand`, `ClearDrawingCommand`, `ToggleElementLockCommand`, `ToggleElementVisibilityCommand`, `SetPageGradientCommand`. |
| **Canvas View** (`lib/editor/canvas/canvas_element_view.dart`) | Renders basic text, image, sticker, card | Add drawing path rendering (`CustomPaint`), shape rendering, image filter color matrices, and text outline/shadows. |
| **Canvas Gestures** (`lib/editor/canvas/story_editor_canvas.dart`) | Element tap & scale/drag/rotate | Add drawing mode pointer tracking (`onPanStart/Update/End`), snapping detection and guideline rendering. |
| **Export Engine** (`lib/export/still_image_exporter.dart`) | Basic text, card, placeholder | Add drawing stroke paths, shapes, text outline/shadow, image color filters, and gradient backgrounds. |
| **Public API** (`lib/focusgram_story_kit.dart`) | Phase 1-3 exports | Export all new models, adapters, asset providers, themes, and commands. |

---

## 3. Milestones & Implementation Sequence

### Milestone 1: Models & Serialization Contracts
- **File:** `lib/models/image_adjustments.dart` (New)
  - `ImageAdjustments`, `ImageFilterPreset`.
- **File:** `lib/models/drawing_stroke.dart` (New)
  - `DrawingStroke`, `DrawingBrushType`, `DrawingPoint`.
- **File:** `lib/models/shape_payload.dart` (New)
  - `ShapeType`, `ShapeElementPayload`.
- **File:** `lib/models/gradient_background.dart` (New)
  - `StoryGradientBackground`, `StoryGradientType`.
- **File:** `lib/models/story_template.dart` (New)
  - `StoryTemplate`, preset template catalog.
- **File:** `lib/models/element_payloads.dart` (Modify)
  - Expand `TextElementPayload` with outline, shadow, spacing.
  - Expand `ImageElementPayload` with adjustments and filters.
  - Integrate `DrawingElementPayload` and `ShapeElementPayload`.
- **File:** `lib/models/story_element.dart` (Modify)
  - Add `drawing` and `shape` to `StoryElementType`.
- **File:** `lib/models/story_page.dart` (Modify)
  - Add `gradient` support to `StoryPage`.
- **Tests:** `test/phase4_models_test.dart` (New)
  - JSON round-trip serialization and equality verification for all new models.

### Milestone 2: Media, Capture & Asset Adapters
- **File:** `lib/media/media_picker_adapter.dart` (New)
  - `StoryMediaPickerAdapter`, `DefaultMediaPickerAdapter`.
- **File:** `lib/media/capture_adapter.dart` (New)
  - `StoryCaptureAdapter`, `CameraPermissionStatus`, `DefaultCaptureAdapter`.
- **File:** `lib/assets/asset_provider.dart` (New)
  - `StoryAssetProvider`, `DefaultStoryAssetProvider`, `StoryStickerItem`, `StoryAssetCategory`.
- **Tests:** `test/asset_and_adapters_test.dart` (New)
  - Verify adapters, permissions, sticker packs, and category lookup.

### Milestone 3: Editor Commands & Controller Logic
- **File:** `lib/editor/editor_commands.dart` (Modify)
  - `AddDrawingStrokeCommand`, `ClearDrawingCommand`, `UpdateImageAdjustmentsCommand`, `ToggleElementLockCommand`, `ToggleElementVisibilityCommand`, `SetPageGradientCommand`.
- **File:** `lib/editor/editor_state.dart` (Modify)
  - Add `draw`, `shape`, `layers`, `adjust` to `EditorTool`.
  - Add active brush settings and alignment snapping state.
- **File:** `lib/editor/editor_controller.dart` (Modify)
  - Add drawing methods (`addDrawingStroke`, `clearDrawing`), shape creation, lock/visibility toggling, and gradient setting.
- **Tests:** `test/phase4_commands_test.dart` (New)
  - Stroke-level undo/redo, command execution, and state transitions.

### Milestone 4: Canvas Rendering, Gestures & Layer Management
- **File:** `lib/editor/canvas/canvas_element_view.dart` (Modify)
  - Render rich typography (outlines, shadows, font fallback), filtered images, shapes, and drawing layers.
- **File:** `lib/editor/canvas/drawing_canvas_overlay.dart` (New)
  - Interactive stroke drawing gesture catcher and live painter.
- **File:** `lib/editor/canvas/snapping_guidelines.dart` (New)
  - Center/edge guideline detection and visual indicator overlays.
- **File:** `lib/editor/canvas/story_editor_canvas.dart` (Modify)
  - Integrate drawing overlay, snapping guides, and locked-element hit test bypass.
- **File:** `lib/editor/panels/layer_manager_sheet.dart` (New)
  - Modal sheet listing elements in z-order with lock, hide, delete, and reorder controls.
- **File:** `lib/editor/panels/drawing_toolbar.dart` (New)
  - Brush type, color, stroke width, and eraser controls.
- **File:** `lib/editor/panels/shape_picker_sheet.dart` (New)
  - Shape selection sheet (rectangle, circle, star, arrow, heart, line).
- **File:** `lib/editor/panels/image_adjustment_sheet.dart` (New)
  - Sliders for brightness, contrast, saturation, warmth, and filter preset buttons.
- **File:** `lib/editor/panels/rich_text_editor_sheet.dart` (New)
  - Interactive font family, size, alignment, shadow, outline, and color controls.
- **File:** `lib/editor/panels/sticker_picker_sheet.dart` (New)
  - Tabbed sheet displaying emojis and local stickers via `StoryAssetProvider`.
- **File:** `lib/editor/panels/template_picker_sheet.dart` (New)
  - Preset layout selector to bootstrap new story pages.

### Milestone 5: Deterministic Export Pipeline Parity
- **File:** `lib/export/still_image_exporter.dart` (Modify)
  - Paint gradients and textures in background.
  - Paint drawing stroke paths with correct brush caps, joins, and colors.
  - Paint basic shapes with stroke and fill.
  - Paint text outlines, shadows, and spacing.
  - Paint image color filter matrices and flip transforms.
- **Tests:** `test/phase4_exporter_test.dart` (New)
  - Verify exported PNG rasters for drawing, shapes, gradients, and typography without editor chrome.

### Milestone 6: Theme, Localization, Accessibility & Editor Shell Polish
- **File:** `lib/theme/story_kit_theme.dart` (New)
  - Custom design tokens for editor chrome.
- **File:** `lib/localization/story_kit_strings.dart` (New)
  - Centralized string bundle with English defaults.
- **File:** `lib/editor/story_kit_editor.dart` (Modify)
  - Integrate new tool buttons (Draw, Shapes, Stickers, Adjust, Layers, Templates).
  - Connect sheets to tool actions.
  - Add semantic descriptions and responsive safe-area padding.
- **File:** `lib/focusgram_story_kit.dart` (Modify)
  - Export all new public models, adapters, and UI classes.
- **Tests:** `test/story_editor_phase4_widget_test.dart` (New)
  - Complete widget interaction test suite for all Phase 4 features.

---

## 4. Verification Gates & Quality Checklist

| Gate | Requirement | Tool / Command |
|---|---|---|
| **Gate 1** | Code formatting strictly satisfied | `dart format --output=none --set-exit-if-changed .` |
| **Gate 2** | Zero static analysis issues under `flutter_lints` 5.0.0 | `flutter analyze` |
| **Gate 3** | All 58 existing tests + new Phase 4 tests pass | `flutter test --reporter expanded` |
| **Gate 4** | Mobile user changes preserved untouched | `git -C "E:\code_plus_academy\Mobile\Mobile" status --short` |
| **Gate 5** | PR created against `phase-1/implementation` | `gh pr create` |
