# Isle

[![Release](https://img.shields.io/github/v/release/TheVinizzz/Isle?label=download&color=blue)](https://github.com/TheVinizzz/Isle/releases/latest)
[![Build](https://github.com/TheVinizzz/Isle/actions/workflows/release.yml/badge.svg)](https://github.com/TheVinizzz/Isle/actions)
[![macOS](https://img.shields.io/badge/macOS-14.0%2B-black?logo=apple)](https://www.apple.com/macos)
[![Swift](https://img.shields.io/badge/Swift-5.10-orange?logo=swift&logoColor=white)](https://swift.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> Turn your MacBook notch into an interactive island. Music, calendar, FX rates — all in the black space you already paid for.

Isle is a free, open-source macOS menu-bar utility that turns the hardware notch on Apple Silicon MacBooks into a Dynamic Island-style hub. Hover the notch, the panel expands; move away, it collapses. No Dock icon, no main menu, just the notch.

## Features

- **Now Playing** — Apple Music + Spotify via `DistributedNotificationCenter` (no private frameworks, no Mac App Store entitlement issues). Track-change cross-fade animation, transport controls with SF Symbol bounce, source badge in the artwork corner.
- **Audio visualizer** — three offset sine waves + a linear-gradient halo tinted by the artwork's average color (Apple Music lock-screen pattern). Pauses with the music.
- **Calendar** — today's events from `EKEventStore` with calendar-color bullets. Navigable day strip: hover-revealed `‹ ›` chevrons shift the focused day by a week; click any day to load its events; click the month label to snap back to today.
- **Finance** — USD/BRL and BTC/BRL from AwesomeAPI BR. Monospaced price, `systemGreen` / `systemRed` change indicator. Polled every five minutes; no API key.
- **System integration** — status bar item with Launch at Login (`SMAppService.mainApp`), Quit, and a GitHub link. Notch hover uses an `NSPanel` with `.nonactivatingPanel` so clicks reach SwiftUI controls without stealing focus from your current window.
- **Apple-tier polish** — `UnevenRoundedRectangle(.continuous)` squircle, iOS Dynamic Island spring specs, HIG-aligned typography (SF Pro Rounded for numerals, SF Pro Text for body), semantic `.primary`/`.secondary`/`.tertiary` colors, `.systemBlue` accent, `.symbolEffect(.bounce)`, pointer-hand cursor on every interactive surface.

## Install

### Homebrew (recommended)

```bash
brew install --cask TheVinizzz/isle/isle
```

Homebrew handles the entire flow — downloads the DMG, strips the macOS quarantine flag, copies `Isle.app` to `/Applications`. **Zero Gatekeeper prompts.** Upgrades later are just `brew upgrade --cask isle`.

The tap lives at [TheVinizzz/homebrew-isle](https://github.com/TheVinizzz/homebrew-isle).

### One-line curl install

If you don't have Homebrew:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/TheVinizzz/Isle/main/scripts/install.sh)"
```

Downloads the latest release, copies `Isle.app` to `/Applications`, clears the macOS quarantine flag, and launches. Takes ~10 seconds. Also Gatekeeper-prompt-free because `curl`-downloaded files don't get the quarantine attribute browsers attach.

### DMG download

From [Releases](../../releases/latest):

1. Open `Isle-<version>.dmg`.
2. **Double-click `Install Isle.command`** inside the DMG — the first time you'll need to right-click the script and choose **Open** to bypass Gatekeeper (Apple flags downloaded shell scripts the same way it flags apps). After that one-time confirmation, the script copies the app to `/Applications`, clears quarantine, and launches Isle.

The DMG also contains the classic drag layout (drag `Isle.app` onto the `Applications` shortcut). Going that route, the first launch will show a "Apple cannot verify…" warning — bypass it with right-click → **Open** → confirm.

The build is ad-hoc signed; Developer ID + notarization lands in v1.0 once we have an Apple Developer ID. Homebrew Cask sidesteps the issue entirely, which is why we recommend it.

### After install

1. Hover the notch — the panel expands.
2. **Right-click the notch** to open the context menu (Launch at Login, GitHub, Quit).
3. Approve permission prompts as they appear:
   - **Calendar** — Full Access, to read today's events.
   - **Automation → Spotify / Music** — to control playback and fetch artwork.

Isle runs without a Dock icon or menu-bar item to keep the screen distraction-free. The app itself lives at `/Applications/Isle.app` — drag it to the Trash any time to uninstall, or use `brew uninstall --cask isle` if you installed via Homebrew.

### Requirements

- macOS 14.0 (Sonoma) or newer.
- Apple Silicon MacBook with a notch (14"/16" Pro, MacBook Air M2+).
- The app no-ops on Macs without a notch — safe to install anywhere.

### Uninstall

```bash
killall Isle && rm -rf /Applications/Isle.app
```

## How it works

```
NSScreen.safeAreaInsets.top + auxiliaryTop{Left,Right}Area
        ↓ detect notch geometry
NotchPanel (NSPanel, .nonactivatingPanel)
        ↓ borderless, level = .statusBar + 8
        ↓ collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
NSHostingView<RootView>
        ↓
SwiftUI content (clipped to UnevenRoundedRectangle continuous-corner squircle)
   ├── Color.black background
   ├── AudioVisualizer (TimelineView, paused when idle)
   ├── ExpandedContent (NowPlaying | Calendar | Finance)
   └── top highlight (1.5pt gradient .plusLighter)
```

State changes are driven by `NSEvent` global + local mouse monitors with a hysteresis state machine: a tight activation zone over the physical notch when collapsed, and a wide retention zone covering the whole expanded panel once hovered, so the cursor can travel into the content without retracting the panel.

Services are all `@MainActor @Observable` — no Combine, no actors-for-models. Notification observers are torn down on `stop()`; `URLSession` calls have explicit timeouts; `TimelineView` pauses when not visible.

## Build from source

```bash
brew install xcodegen
xcodegen generate
open Isle.xcodeproj      # then Cmd+R
```

Headless:

```bash
xcodebuild -project Isle.xcodeproj -scheme Isle -configuration Debug build
```

### Regenerate the app icon

```bash
swift scripts/generate-icon.swift
```

Renders the squircle + notch glyph at every macOS-required size and rewrites `Isle/Resources/Assets.xcassets/AppIcon.appiconset/`.

### Build a DMG locally

```bash
scripts/build-dmg.sh
```

Produces `dist/Isle-<version>.dmg` — ad-hoc signed (not notarized), drag-to-Applications layout.

## Project layout

```
Isle/
  IsleApp.swift                 entry point, .accessory activation policy
  AppDelegate.swift             lifecycle owner
  NotchCoordinator.swift        display orchestration + hot-plug
  NotchLayout.swift             single source of truth for dimensions
  StatusBarController.swift     menu bar item + Launch at Login
  Window/
    NotchWindow.swift           NSPanel subclass
    NotchWindowController.swift hover monitors, frame management
  Presenter/
    NotchPresenter.swift        @Observable hover state machine
  Services/
    MediaService.swift          Spotify + Apple Music via DistributedNotification + AppleScript
    CalendarService.swift       EventKit with EKEventStoreChanged throttle
    FinanceService.swift        AwesomeAPI poll (USD/BTC vs BRL)
  Features/
    RootView.swift              top-level SwiftUI scene
    NowPlaying/
      NowPlayingView.swift      artwork, title/artist, transport
      AudioVisualizer.swift     sine waves + glow
    Calendar/
      CalendarStripView.swift   month, day strip, event row
    Finance/
      FinanceView.swift         symbol/price/change rows
  Utils/
    NSScreen+Notch.swift        notch geometry helpers
    NSImage+AverageColor.swift  CIAreaAverage tint extraction
    PointerCursor.swift         .pointerCursor() modifier
  Resources/
    Info.plist                  LSUIElement, usage strings, localizations
    Isle.entitlements           sandbox disabled (MediaRemote needs no sandbox)
    Localizable.xcstrings       en, pt-BR
    Assets.xcassets/            AppIcon, AccentColor
scripts/
  generate-icon.swift           regenerate the AppIcon set
  build-dmg.sh                  ad-hoc-signed DMG packaging
.github/workflows/release.yml   tag-triggered CI release
```

## Permissions

| Permission | When triggered | What for |
|---|---|---|
| Calendar (Full Access) | First app launch | Reading today's events |
| Automation → Spotify | First time you click ⏯ or hover with Spotify running | Playback control + artwork URL fetch |
| Automation → Music | First time you click ⏯ with Music running | Playback control |

If you decline, the corresponding widget falls back to a polite empty state (e.g. "Allow Calendar access" / "Not playing"). You can change your mind in **System Settings → Privacy & Security → Calendars / Automation**.

The app is non-sandboxed (`com.apple.security.app-sandbox = false`) because:
- `DistributedNotificationCenter` for Spotify / Music notifications doesn't require sandbox bypass, but
- AppleScript control of other apps must not be sandboxed (Apple's Automation prompt is the gate).

## Roadmap

- [x] Notch detection, hover state machine, hysteresis
- [x] Now Playing (Spotify + Apple Music)
- [x] Track change cross-fade animation + audio halo
- [x] Calendar (EventKit) with navigation
- [x] Finance widget
- [x] Status bar + Launch at Login
- [x] Open-source release pipeline
- [ ] Apple Music artwork (via AppleScript `raw data of artwork 1` → temp file)
- [ ] File drop tray (NotchNook-style)
- [ ] Battery + brightness + volume HUD replacement
- [ ] Settings window (currencies, refresh interval, themes)
- [ ] Notification ingestion (system notifications surfaced in the notch)
- [ ] Developer-ID signing + notarization (currently ad-hoc)

## Architecture decisions

- **NSPanel `.nonactivatingPanel`** — clicks reach SwiftUI buttons without stealing focus from the user's foreground app.
- **`@MainActor @Observable`** — no Combine, no actors for UI models. Services own their own notification subscriptions; views bind via `@Bindable`.
- **DistributedNotificationCenter, not MediaRemote.framework** — Apple started gating `MediaRemote` behind a private entitlement in macOS 15.4. We sidestepped it entirely by listening to the public notifications Spotify and Music broadcast.
- **AppleScript for control** — `osascript -e "tell application … to playpause"`. One TCC prompt the first time, then permanent.
- **TimelineView for the audio halo** — `paused: !isActive` collapses CPU to zero whenever the music stops or the panel closes.
- **Single `clipShape(notchShape)`** — every layer (background, visualizer, content, top highlight) lives inside one ZStack, then the whole stack is clipped once. Solves overflow bleeding past the rounded corners.

## Acknowledgements

Isle takes inspiration from [NotchNook](https://lo.cafe/notchnook) (commercial), [TheBoredTeam/boring.notch](https://github.com/TheBoredTeam/boring.notch), [MrKai77/DynamicNotchKit](https://github.com/MrKai77/DynamicNotchKit), and [Lakr233/NotchDrop](https://github.com/Lakr233/NotchDrop). FX/crypto data via [AwesomeAPI BR](https://docs.awesomeapi.com.br/).

## License

MIT — see [LICENSE](LICENSE).
