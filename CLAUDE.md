# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A tiny sandboxed macOS SwiftUI app ("Local Projector") that plays every `.mov` / `.mp4` / `.m4v` in a user-chosen folder, shuffled, on an endless loop. Intended for unattended display (kiosk/projector use). macOS 15.0+, Swift 5, no third-party dependencies.

## Naming (easy to trip over)

The repo, folder, Xcode project and scheme are all `SimplePlayer`, but the **target and product are `LocalProjector`** (`LocalProjector.app`). The display name is "Local Projector" and the window title is "Projector". Bundle ID remains `nz.patrick.SimplePlayer`.

## Build

Requires macOS with Xcode (it cannot be built in a Linux container). There are no test targets and no linter configured.

```sh
xcodebuild -project SimplePlayer.xcodeproj -scheme SimplePlayer -configuration Debug build
xcodebuild -project SimplePlayer.xcodeproj -scheme SimplePlayer -configuration Release build
```

The project uses Xcode 16 file-system-synchronized groups (`objectVersion = 77`): new files dropped into `SimplePlayer/` are picked up automatically — do not hand-edit `project.pbxproj` to add sources. Info.plist is mostly generated from `INFOPLIST_KEY_*` build settings; `SimplePlayer/Info.plist` is an empty stub.

## Architecture

Three pieces, wired together in `ContentView`:

- **`Conductor`** (`@Observable`, held as `@State` in `ContentView`) owns all state: the selected folder, the list of video URLs, and `booted` / `loading` / `bootError` flags that drive which UI `ContentView` shows. Its failure cases live in `enum ConductorError`.
- **Folder persistence via security-scoped bookmarks.** Because the app is sandboxed, access to the picked folder is persisted as a `.withSecurityScope` bookmark in `UserDefaults` under the key `LastPickedFolder`, and restored on `onAppear`. Any code that swaps or clears the folder must balance `startAccessingSecurityScopedResource()` / `stopAccessingSecurityScopedResource()`. Folder scanning is non-recursive and extension-filtered in `refreshItemsFromSelectedDirectory()`.
- **`VideoPlayerView`** wraps an `AVQueuePlayer`. It shuffles and enqueues all URLs; when observing `currentItem` shows the queue has drained, it refills it — this is how the endless loop works. It also re-populates whenever `urls` changes.

`SimplePlayerApp` uses a single `Window` scene (not `WindowGroup`), so only one window can exist.

## Entitlements

Debug uses `SimplePlayer/SimplePlayer.entitlements`; Release uses `LocalProjectorRelease.entitlements` at the repo root. They are currently identical (sandbox + read-only user-selected files, Downloads, Movies/Music/Pictures; no network). Change both together unless the divergence is intentional. Hardened runtime is enabled.
