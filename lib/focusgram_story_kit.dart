// FocusGram Story Kit — public API surface.
export 'models/story_item_model.dart';
export 'models/story_group_model.dart';
export 'models/story_shared_content.dart';
export 'overlays/story_overlay.dart';
export 'overlays/overlay_codec.dart';
export 'viewer/story_kit_viewer.dart';
export 'viewer/story_overlay_renderer.dart';
export 'viewer/story_shared_content_card.dart';

// Phase 3 — Document Models
export 'models/story_canvas_spec.dart';
export 'models/story_transform.dart';
export 'models/story_media_asset.dart';
export 'models/element_payloads.dart';
export 'models/story_element.dart';
export 'models/story_page.dart';
export 'models/story_project.dart';

// Phase 3 — Editor & Commands
export 'editor/story_kit_editor.dart';
export 'editor/editor_controller.dart';
export 'editor/editor_state.dart';
export 'editor/command_history.dart';
export 'editor/editor_commands.dart';
export 'editor/canvas/story_editor_canvas.dart';
export 'editor/canvas/canvas_element_view.dart';
export 'editor/canvas/selection_overlay.dart';
export 'editor/canvas/story_page_strip.dart';

// Phase 3 — Draft Persistence
export 'draft/draft_repository.dart';
export 'draft/in_memory_draft_repository.dart';

// Phase 3 — Still Image Exporter
export 'export/export_result.dart';
export 'export/still_image_exporter.dart';

// Phase 4 — Expanded Editing Capabilities & Models
export 'models/image_adjustments.dart';
export 'models/drawing_stroke.dart';
export 'models/shape_payload.dart';
export 'models/gradient_background.dart';
export 'models/story_template.dart';

// Phase 4 — Media, Capture & Asset Adapters
export 'media/media_picker_adapter.dart';
export 'media/capture_adapter.dart';
export 'assets/asset_provider.dart';

// Phase 4 — Theming & Centralized Localization
export 'theme/story_kit_theme.dart';
export 'localization/story_kit_strings.dart';

// Phase 4 — Canvas Overlays & Modal Editor Panels
export 'editor/canvas/drawing_canvas_overlay.dart';
export 'editor/canvas/snapping_guidelines.dart';
export 'editor/panels/drawing_toolbar.dart';
export 'editor/panels/shape_picker_sheet.dart';
export 'editor/panels/image_adjustment_sheet.dart';
export 'editor/panels/rich_text_editor_sheet.dart';
export 'editor/panels/sticker_picker_sheet.dart';
export 'editor/panels/layer_manager_sheet.dart';
export 'editor/panels/template_picker_sheet.dart';

// Phase 5 — Video & Animation Models
export 'models/video_payload.dart';
export 'models/overlay_animation.dart';
export 'models/story_kit_configuration.dart';

// Phase 5 — Timeline Engine & Transitions
export 'timeline/timeline_state.dart';
export 'timeline/timeline_controller.dart';
export 'timeline/timeline_sync_coordinator.dart';
export 'timeline/video_transition_math.dart';

// Phase 5 — Canvas Video & Animated Overlays
export 'editor/canvas/canvas_video_view.dart';
export 'editor/canvas/animated_element_box.dart';

// Phase 5 — Video Editor Panels
export 'editor/panels/timeline_scrubber.dart';
export 'editor/panels/animation_picker_sheet.dart';
export 'editor/panels/audio_settings_sheet.dart';
export 'editor/panels/cover_picker_sheet.dart';

// Phase 5 — Video Export Pipeline & Jobs
export 'export/export_error.dart';
export 'export/video_export_job.dart';
export 'export/video_export_adapter.dart';
export 'export/story_video_overlay_rasterizer.dart';
export 'export/story_video_exporter.dart';
export 'export/story_project_exporter.dart';
