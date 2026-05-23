# Changelog

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
