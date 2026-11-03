# FocusGram Story Kit — Known Technical Issues & Mitigations

**Status:** Technical Limitations & Risk Register  
**Repository:** `atharvakapse831/focusgram_story_kit`  
**Branch:** `main`  
**Date:** 2026-11-02  

---

## 1. Technical Limitations & Mitigation Register

| Issue ID | Component | Limitation / Risk | Impact | Implemented Mitigation |
|---|---|---|---|---|
| **ISSUE-1** | `pro_video_editor` | Requires Dart `>=3.12.0 <4.0.0` | Incompatible with current `sdk: ^3.5.0` environment | Defer integration of `pro_video_editor` until base Dart SDK is updated. Use lightweight native Media3 / AVFoundation channel as the primary video engine. |
| **ISSUE-2** | Memory / Image Decoding | Decoding uncompressed 48MP camera images can trigger OOM on memory-constrained devices | Out-of-memory crash during multi-page editing | Downsample imported photos to 1080x1920 target canvas dimensions inside background Dart isolate (`compute`). |
| **ISSUE-3** | Video Variable Frame Rate (VFR) | Mobile camera recordings with variable frame rates can cause audio desync after multiple cuts | Audio drift in trimmed/split clips | Force constant frame rate (CFR 30fps) transcoding and fixed 44.1kHz audio sample rate during native export. |
| **ISSUE-4** | `easy_video_editor` Concurrency | `VideoEditorBuilder.cancel()` lacks synchronous termination barrier | Possible race condition if a new export starts immediately after cancellation | Enforce single-session mutex lock in `StoryExportService`; wait for native termination acknowledgement before freeing resources. |
| **ISSUE-5** | Storage Leakage | Aborted export jobs leave orphaned temporary files on device storage | Storage consumption over time | Create unique session subdirectories under `/tempDir/story_kit/session_${uuid}/`; enforce atomic cleanup on success, failure, cancel, and app startup. |
