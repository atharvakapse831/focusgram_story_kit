# Phase 2 — FocusGram Content Sharing Integration Verification Report

**Status:** BLOCKED / AWAITING MAINTAINER ACTION  
**Date:** 2026-10-29  
**Scope:** FocusGram Story Kit (`focusgram_story_kit`) and FocusGram Mobile (`Mobile`)  
**Gate Status:** Phase 1 formally approved. Phase 2 local implementation and unit/widget tests are 100% verified across both repositories, and Story Kit CI passes. However, Mobile CI on GitHub Actions is blocked by cross-repository Git authentication for the private Story Kit repository. **Phase 2 remains BLOCKED until the maintainer decides on the access configuration. Phase 3 (Story Kit Editor MVP) is strictly GATED and has NOT started.**

---

## 1. Executive Summary

Phase 2 implementation establishes end-to-end integration between FocusGram's content ecosystem and the reusable, domain-independent `focusgram_story_kit` package. Users can share posts, long videos, shorts, articles, and notes into their stories, and viewers render interactive shared-content cards with typed deep-link navigation into the host application.

All 4 technical blockers identified during the initial Phase 2 review have been implemented and verified locally:
1. **Story Kit Viewer Integrated into Mobile:** `StoryViewerScreen` now instantiates `StoryKitViewer`, connecting `StoryContentAdapter.toStoryKitGroup` to map stories, interactive stickers/overlays, and shared cards.
2. **Real Content Data & Safe Navigation:** Full content flow traced through `SharedContentModel`, `StoryEditorWrapper`, and `StoryContentAdapter`. Videos and shorts verify real media URLs; if missing, they resolve asynchronously via `ExploreRepository.instance.getVideoById(id)` before navigating, never opening broken playback screens. Articles resolve via `fetchArticle(id)`, and posts route via deep link or documented author profile fallback.
3. **Order-Independent Equality & HashCode:** `StorySharedContent.hashCode` now sorts `extra` map keys deterministically, matching `mapEquals` behavior regardless of key insertion order.
4. **Reproducible Dependency Setup & Documented CI Configuration:** Configured `focusgram_story_kit` as a Git dependency referencing the repository and branch `phase-2/content-sharing`. Documented multi-repo authentication requirements for private repositories in GitHub Actions CI.

---

## 2. Multi-Repository Verification Evidence

### 2.1 `focusgram_story_kit`

| Check | Toolchain / Environment | Exit Code | Result | Evidence |
|---|---|---|---|---|
| **Pub Dependencies** | Flutter 3.47.8 • Dart 3.13.7 | `0` | **PASS** | 76 dependencies resolved cleanly |
| **Dart Format** | `dart format --output=none --set-exit-if-changed .` | `0` | **PASS** | 14 files checked, 0 changed |
| **Static Analysis** | `flutter analyze` (with `package:flutter_lints`) | `0` | **PASS** | 0 issues found |
| **Unit & Widget Tests** | `flutter test --reporter expanded` | `0` | **PASS** | 40/40 tests passed in ~3s |
| **GitHub Actions CI** | Ubuntu 24.04 • [Run 40765716230](https://github.com/atharvakapse831/focusgram_story_kit/actions/runs/40765716230) | `0` | **SUCCESS** | Full test & verification suite passed on PR #4 |

### 2.2 FocusGram `Mobile`

| Check | Toolchain / Environment | Exit Code | Result | Evidence |
|---|---|---|---|---|
| **Pub Dependencies (Local)** | Flutter 3.47.8 • Dart 3.13.7 | `0` | **PASS** | Git dependency `focusgram_story_kit` resolved via local credentials |
| **Dart Format** | `dart format` (stories & tests) | `0` | **PASS** | 12 files checked, 0 changed |
| **Static Analysis** | `flutter analyze lib/feature/stories test/feature/stories` | `0` | **PASS** | 0 issues found (with async mounted guards) |
| **Unit & Widget Tests** | `flutter test test/feature/stories/ --reporter expanded` | `0` | **PASS** | 14/14 tests passed in ~3s |
| **GitHub PR** | [PR #55](https://github.com/Code-Plus-Academy/Mobile/pull/55) | Open | **DELIVERED** | Ready for review |
| **GitHub Actions CI** | Ubuntu 24.04 • [Run 40764841196](https://github.com/Code-Plus-Academy/Mobile/actions/runs/40764841196) | `69` | **FAILURE** | Git clone failed: `fatal: could not read Username for 'https://github.com'` (private repo auth) |

---

## 3. Detailed Resolution of Phase 2 Blockers

### Blocker 1: Integrate Story Kit's Viewer into Mobile
- **Problem:** `StoryViewerScreen` used the legacy `RichSharedContentCard` and manual animation controllers without instantiating `StoryKitViewer`.
- **Resolution:**
  - Extended `StoryKitViewer` with optional `itemHeaderBuilder`, `footerBuilder`, and `onItemChanged` hooks to allow host apps to supply custom chrome while preserving Story Kit's playback engine, overlay renderer, and gesture handling.
  - Replaced manual playback in `StoryViewerScreen` with `StoryKitViewer(groups: _kitGroups, controller: _viewerController, ...)`.
  - Wired `onSharedContentTap`: pauses playback, invokes `StoryContentAdapter.handleSharedContentNavigation`, and resumes safely when navigation returns (guarded by `mounted`).
  - Added `test/feature/stories/story_viewer_screen_test.dart` verifying that `StoryViewerScreen` renders `StoryKitViewer` and card taps pause and navigate.

### Blocker 2: Fix Real Content Data and Navigation
- **Problem:** Video and short cards passed `videoUrl: ''`, which crashed or failed in `VideoDetailScreen` / `ShortsFeedScreen`. Feed posts navigated blindly to profile without post targeting.
- **Resolution:**
  - Added optional backward-compatible fields `mediaUrl`, `deepLinkUrl`, and `extra` to `SharedContentModel`.
  - In `StoryContentAdapter.handleSharedContentNavigation`:
    - For `longVideo`: checks `extra['videoUrl']` or resolves asynchronously via `ExploreRepository.instance.getVideoById(content.id)`. If video URL is missing or resolution fails, does NOT navigate to broken playback screens (returns `false` gracefully).
    - For `shortVideo`: checks `extra['videoUrl']` or resolves via `ExploreRepository.instance.getVideoById(content.id)`.
    - For `article`: checks `extra['content']` or resolves via `ExploreRepository.instance.fetchArticle(content.id)`.
    - For `note`: checks `extra['fileUrl']` and routes to `NoteDetailScreen`.
    - For `imagePost` / `videoPost`: routes to `deepLinkUrl` if present, with documented fallback to author profile (`AppRoute.navigateToProfile`).
  - Mapped Mobile's `InteractiveSticker` (link, mention, custom) to Story Kit `StoryOverlay` (`LinkOverlay`, `MentionOverlay`, `UnknownStoryOverlay`).
  - Added 12 new test cases in `test/feature/stories/story_content_adapter_test.dart` validating all 6 content types, repository resolution, and failure paths.

### Blocker 3: Correct `StorySharedContent` Equality and HashCode
- **Problem:** `StorySharedContent.hashCode` used `Object.hashAll(extra.entries)`, which was insertion-order dependent and violated `hashCode` consistency with `mapEquals`.
- **Resolution:**
  - Implemented `_hashExtra(Map<String, dynamic> map)` which sorts map keys deterministically before hashing.
  - Added regression test `equality and hashCode are consistent regardless of extra map insertion order` in `test/story_shared_content_test.dart`.

### Blocker 4: Mobile Dependency Resolution & CI Multi-Repo Access
- **Problem:** `Mobile/pubspec.yaml` used `path: ../../Story library`, which assumed a specific local directory structure.
- **Resolution:**
  - Updated `Mobile/pubspec.yaml` to reference `focusgram_story_kit` as a Git dependency:
    ```yaml
    focusgram_story_kit:
      git:
        url: https://github.com/atharvakapse831/focusgram_story_kit.git
        ref: phase-2/content-sharing
    ```
  - **CI Root Cause:** `atharvakapse831/focusgram_story_kit` is a private repository. The default `GITHUB_TOKEN` provided to GitHub Actions in `Code-Plus-Academy/Mobile` has scope only for `Code-Plus-Academy/Mobile`. During `flutter pub get`, Git fails to clone the repository:
    ```
    Git error. Command: `git clone --mirror https://github.com/atharvakapse831/focusgram_story_kit.git /home/runner/.pub-cache/_temp/dirWUSZUE`
    fatal: could not read Username for 'https://github.com': No such device or address
    exit code: 128
    Failed to update packages.
    ```
  - **Remediation Options Requiring Maintainer Approval:**
    1. **Option 1 (Recommended):** Make `atharvakapse831/focusgram_story_kit` public. As a reusable design-system component library with no private backend logic or secrets, making it public allows standard Git dependency resolution across all host repositories and public CI runners without credentials.
    2. **Option 2:** Add a read-only Personal Access Token (PAT) secret named `STORY_KIT_PAT` to `Code-Plus-Academy/Mobile` repository settings, and add a CI step before `flutter pub get`:
       ```yaml
       - name: Configure Git for Private Dependencies
         run: git config --global url."https://${{ secrets.STORY_KIT_PAT }}@github.com/".insteadOf "https://github.com/"
       ```
    3. **Option 3:** Transfer or mirror `focusgram_story_kit` into the `Code-Plus-Academy` organization.

---

## 4. Repositories & Review Links

- **Story Kit Repository:** [`atharvakapse831/focusgram_story_kit`](https://github.com/atharvakapse831/focusgram_story_kit)
  - **Branch:** `phase-2/content-sharing` (Commit `be60659`)
  - **Pull Request:** [PR #4](https://github.com/atharvakapse831/focusgram_story_kit/pull/4)
  - **CI Run:** [Run 40765716230 (SUCCESS)](https://github.com/atharvakapse831/focusgram_story_kit/actions/runs/40765716230)
- **Mobile Repository:** [`Code-Plus-Academy/Mobile`](https://github.com/Code-Plus-Academy/Mobile)
  - **Branch:** `feat/story-kit-content-sharing-adapter` (Commit `5ac62de`)
  - **Pull Request:** [PR #55](https://github.com/Code-Plus-Academy/Mobile/pull/55)
  - **CI Run:** [Run 40764841196 (FAILURE)](https://github.com/Code-Plus-Academy/Mobile/actions/runs/40764841196/job/123086080273) (Blocked on private repo git authentication)

---

## 5. Phase 2 Exit Criteria Traceability Matrix

| Exit Criterion | Status | Evidence / Verification |
|---|---|---|
| **1. Domain Independence** | **PASS** | Story Kit has zero imports or references to FocusGram Mobile classes. All shared content models are generic (`StorySharedContent`, `StoryKitContentType`). |
| **2. Content Types Supported** | **PASS** | All 6 FocusGram content types (`imagePost`, `videoPost`, `shortVideo`, `longVideo`, `article`, `note`) supported with badges and serialization. |
| **3. Mobile Viewer Integration** | **PASS** | `StoryViewerScreen` directly instantiates `StoryKitViewer`. Custom chrome provided via `itemHeaderBuilder` and `footerBuilder`. Verified in `story_viewer_screen_test.dart`. |
| **4. Tap-to-Navigate & Playback Pause** | **PASS** | Tapping a shared content card pauses playback and invokes `onSharedContentTap`. Safe resumption on navigation return guarded by `context.mounted`. |
| **5. Content Safety & Routing** | **PASS** | Missing video URLs resolve via `ExploreRepository.getVideoById` or fail gracefully without opening blank screens. Articles resolve via `fetchArticle`. Notes route with `fileUrl`. |
| **6. Equality & HashCode Contract** | **PASS** | `StorySharedContent.hashCode` deterministic with sorted keys (`_hashExtra`). Verified in `story_shared_content_test.dart`. |
| **7. Code Quality & Linting** | **PASS** | `dart format` passes (0 changed). `flutter analyze` reports 0 issues in both Story Kit and Mobile story modules. |
| **8. Automated Test Suite** | **PASS** | 40/40 tests pass in Story Kit; 14/14 tests pass in Mobile stories module. |
| **9. Story Kit CI Pipeline** | **PASS** | GitHub Actions Run 40765716230 succeeded on PR #4. |
| **10. Host App CI Pipeline** | **BLOCKED** | GitHub Actions Run 40764841196 on Mobile PR #55 failed on `flutter pub get` due to private repository Git authentication. |

---

## 6. Formal Phase 2 Exit Review Verdict & Stop Rule

### Verdict: **BLOCKED / AWAITING MAINTAINER ACTION**

While all code changes, architecture contracts, unit tests, widget tests, and Story Kit CI have been verified and confirmed with 100% pass rates, **Phase 2 cannot be declared fully COMPLETE until the Mobile CI pipeline can independently clone and verify `focusgram_story_kit`**.

### Required Maintainer Decision:
The maintainer must select and execute one of the following actions to resolve the CI authentication block:
- **Decision A (Recommended):** Make `atharvakapse831/focusgram_story_kit` public.
- **Decision B:** Provide a read-only PAT secret (`STORY_KIT_PAT`) to `Code-Plus-Academy/Mobile` and authorize a workflow update in `.github/workflows/ci.yml`.
- **Decision C:** Transfer/mirror `focusgram_story_kit` into the `Code-Plus-Academy` organization.

### Phase 3 Status:
**Phase 3 (Story Kit Editor MVP) is strictly GATED and has NOT started.** No Phase 3 branches, commits, PRs, or implementation code will be created until Phase 2 is formally unblocked, approved, and Phase 3 authorization is granted by the maintainer.
