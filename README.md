# FocusGram Story Kit

FocusGram's custom Flutter story engine. Built in-house after auditing
`flutter_story_view` 0.0.4 and `flutter_story_editor` 0.0.2 (both abandoned
since Jan 2024) — the useful patterns from both were ported here, and the
package combines with `story_editor_pro` on the capture side.

## What's inside

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
  models/                      # StoryItem, StoryGroup, overlay models
  overlays/                    # overlay definitions + JSON codecs
  viewer/                      # StoryKitViewer + progress/chrome widgets
```

## Status

Pre-1.0 skeleton. Viewer and overlay engine first; editor integration
points (per-page overlay state, per-type undo) land in the next commits.
