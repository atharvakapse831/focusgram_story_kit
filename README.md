# FocusGram Story Kit

FocusGram's custom Flutter story engine. Built in-house after auditing
`flutter_story_view` 0.0.4 and `flutter_story_editor` 0.0.2 (both abandoned
since Jan 2024) — the useful patterns from both were ported here, and the
package combines with `story_editor_pro` on the capture side.

## What's inside

- **Editor MVP** (`StoryKitEditor`) — multi-page composition canvas with 9:16
  canonical aspect ratio, normalized transform manipulation (move, scale, rotate)
  with boundary clamping, text and sticker layers, FocusGram shared content card
  layers, undo/redo command history with transaction coalescing, page strip
  management (add, duplicate, delete), draft persistence repository, and deterministic
  still-image raster export.
- **Viewer** (`StoryKitViewer`) — group navigation (user → user) via PageView,
  per-item duration, 30s video cap, hold-to-pause,
  video loading state, 30%/70% tap zones, seen-tracking callback, reply input.
- **Interactive overlays** — poll, quiz, emoji slider, question box,
  countdown, link sticker, mention, hashtag, location, GIF/text stickers.
  Overlays export as JSON (never baked into pixels), so they stay tappable
  at view time.
- **Data contract** — JSON-safe overlay vocabulary shared by editor and
  viewer; compatible with FocusGram's chat poll wire format
  (`poll_options` structured maps with legacy `options` fallback).

## Layout

```
lib/
  focusgram_story_kit.dart     # public exports
  models/                      # StoryProject, StoryPage, StoryElement, StoryTransform, StoryItem, StoryGroup
  editor/                      # StoryKitEditor, EditorController, canvas, page strip, selection chrome
  overlays/                    # overlay definitions + JSON codecs
  viewer/                      # StoryKitViewer + progress/chrome widgets
  draft/                       # StoryDraftRepository & InMemoryStoryDraftRepository
  export/                      # StoryStillImageExporter & StillImageExportResult
```

## Documentation

- [Complete feature inventory](docs/STORY_KIT_FEATURE_INVENTORY.md) — full scope and priorities.
- [Detailed implementation plan](docs/STORY_KIT_IMPLEMENTATION_PLAN.md) — phase sequence, engineering implications, UI/UX standards, feature instructions, and acceptance criteria.
- [Phase 1 audit execution plan](docs/PHASE_1_EXECUTION_PLAN.md) — audit-only procedure.
- [Phase 1 audit report](docs/PHASE_1_AUDIT_REPORT.md) — evidence report template; it is not complete until checks are run and recorded.
- [Phase 2 verification report](docs/PHASE_2_VERIFICATION_REPORT.md) — Phase 2 exit review and evidence.
- [Phase 3 execution plan](docs/PHASE_3_EXECUTION_PLAN.md) — Editor MVP architectural specifications, milestones, and verification matrix.

## Status

Phase 3 Editor MVP complete. Multi-page story composition, normalized coordinate
canvas, undo/redo command history, draft persistence, and deterministic still-image
raster export fully implemented and verified with 58 automated tests.
