# Changelog

## v0.1.5 — Launch-time playback hydration

- `MediaService.start()` now spawns an AppleScript probe 1.5 seconds after launch so already-playing Spotify or Music tracks populate the widget without needing the user to advance a track. Previously the now-playing state only appeared on the first state change after Isle started.
- Spotify probe pulls `artwork url` inline with the title/artist/album/state query, so cover art lands in the same TCC round-trip instead of triggering a second AppleScript call.
- Replaced the one-shot `probeInitialStateIfNeeded` (gated by a `hasProbedInitialState` flag) with `probeCurrentStateIfStale` that re-tries when state is empty or stale. Lets users recover after declining the initial TCC prompt without restarting the app.

## v0.1.4 — Homebrew tap

- Published [TheVinizzz/homebrew-isle](https://github.com/TheVinizzz/homebrew-isle) — `brew install --cask TheVinizzz/isle/isle` is now the primary install path. Homebrew strips the macOS quarantine flag automatically, so installing this way avoids Gatekeeper prompts entirely (including the prompt that hit `Install Isle.command` inside the DMG).
- README install section reordered: Homebrew first, curl second, DMG third.

## v0.1.3 — Collapsed-state layout fix

- Conditionally render `ExpandedContent` and `AudioVisualizer` only when the panel is hovered. Their combined intrinsic width (~680pt rigid widths from NowPlaying + Calendar + Finance + dividers) was forcing the content `ZStack` to grow past the collapsed pill's `.frame(200, 32)`, ballooning the visible panel.
- Added explicit `.frame(width: currentWidth, height: currentHeight)` to the content layer before `.clipShape(notchShape)` so the shape's path is generated against the panel's intended size rather than the children's intrinsic bounds.

## v0.1.2 — Installer experience

- `scripts/install.sh` — one-line remote installer. Curl-downloaded artifacts skip the quarantine attribute browsers add, so installing this way avoids the "Apple cannot verify this app" prompt entirely.
- DMG now includes `Install Isle.command` — double-clicking it copies the app to `/Applications`, clears any quarantine flag, and launches Isle.
- DMG `README.txt` documents both paths for users who'd rather not use Terminal.
- README install section rewritten with primary curl path, manual fallback, and uninstall command.

## v0.1.1 — Shadow color leak fix

- Split the root `ZStack` into two layers: a clean black silhouette that owns the drop shadow, and a clipped content layer that owns the audio visualizer and widgets. The previous structure let the visualizer's `.plusLighter` blend mode tint the drop shadow with the artwork accent color, producing a faint horizontal halo below the panel.

## v0.13 — Audio halo & polish

- Bottom-edge audio visualizer: three offset sine waves + linear-gradient glow tinted by the artwork's average color (Apple Music lock-screen pattern).
- Animation pauses when playback pauses or panel collapses — zero idle CPU.
- Inner mask + reshaped wave positions stop the glow bleeding past the rounded corners.

## v0.12 — Status bar + app icon

- Status bar item with menu: About, Launch at Login (`SMAppService.mainApp`), GitHub link, Quit (⌘Q).
- App icon generator script (`scripts/generate-icon.swift`) renders all required sizes via SwiftUI `ImageRenderer`.

## v0.11 — Layout polish

- `NowPlayingView` width raised to 260pt, artwork 56×56, title 14pt semibold.
- Outer HStack now top-aligned — artwork and transport row share the same baseline.
- Pointer cursor rewritten with state tracking and `onDisappear` cleanup to prevent stuck cursors.

## v0.10 — Finance widget

- Third column: USD-BRL + BTC-BRL via AwesomeAPI BR (public, no auth).
- 5-minute refresh, monospaced-digit price, `systemGreen`/`systemRed` change indicator with arrow glyph.
- 3-column layout: NowPlay | Calendar | Finance.

## v0.9 — Overflow fix

- Replaced `.overlay` with single ZStack + `.clipShape(notchShape)` so content stays inside the rounded boundary.
- Tightened day cells, chevrons, and divider geometry.

## v0.8 — Calendar navigation

- `CalendarService.focusedDate` with `focus(on:)` / `shift(days:)` / `resetToToday()`.
- Clickable day cells, hover-revealed `‹ ›` chevrons (±7 days), `Mai` label tap to snap back.
- `pointerCursor()` modifier applied to every interactive element.

## v0.7 — Track change animation

- `MediaService.trackChangeID` bumped on title or artist change.
- Artwork cross-fades with scale; title and artist slide vertically — Apple Music app pattern.
- Symbol bounce effect on play/pause toggle; hover scale + circular highlight on transport buttons.
- Spotify-green / Apple Music-pink source badge on the artwork corner.

## v0.6 — Localization & Spotify artwork fix

- `CFBundleAllowMixedLocalizations` + `Date.FormatStyle` so weekdays and months render in the system language.
- String catalog (`Localizable.xcstrings`) with pt-BR translations.
- Spotify dropped `Artwork URL` from `DistributedNotification` payloads — added AppleScript fallback via `artwork url of current track`.

## v0.5 — Clickability fix

- `NSWindow` → `NSPanel` with `.nonactivatingPanel` so mouse clicks reach SwiftUI buttons without activating the app.
- Lazy AppleScript probe on first hover so the now-playing widget populates without needing a track change.

## v0.4 — Real integrations

- `MediaService` consuming `com.spotify.client.PlaybackStateChanged` and `com.apple.Music.playerInfo` notifications.
- Playback control via AppleScript (`osascript`).
- `CalendarService` with `EKEventStore.requestFullAccessToEvents` and `EKEventStoreChanged` throttled refresh.
- HIG audit applied: typography, spacing, semantic colors, hit targets, hierarchical SF Symbols.

## v0.3 — Hover hysteresis

- Separate hit-test zones per state: tight zone over the physical notch when collapsed, full expanded panel + grace when hovered, so the cursor can travel into the content without collapsing the panel.
- `UnevenRoundedRectangle(.continuous)` squircle, iOS Dynamic Island spring specs, top inner highlight.

## v0.2 — NowPlaying + Calendar shells

- Added stub NowPlaying widget and calendar strip with today highlighted.
- Reduced expanded size; bigger bottom corner radius to blend with the physical notch.

## v0.1 — Foundation

- Borderless window over the physical notch, level `statusBar + 8`.
- Multi-display + hot-plug rebuild via `didChangeScreenParametersNotification`.
- Hover state machine with global + local mouse monitors.
- Spring-animated expand and collapse.
