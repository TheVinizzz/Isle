# Contributing to Isle

Thanks for considering a contribution. Isle is a small, focused project — quality and consistency matter more than feature volume.

## Ground rules

- Keep the binary small and the idle CPU at zero. Every feature must pause when not visible.
- Public APIs only. No `MediaRemote.framework` private symbols, no entitlements that block direct distribution.
- HIG-aligned typography, semantic colors, and `.continuous` corner styles. No raw opacities where `.primary` / `.secondary` / `.tertiary` apply.
- One coherent commit per change. Conventional Commits format (`feat:`, `fix:`, `refactor:`, `docs:`, `chore:`, `ci:`).

## Development setup

```bash
brew install xcodegen
git clone https://github.com/TheVinizzz/Isle.git
cd Isle
xcodegen generate
open Isle.xcodeproj
```

Requires Xcode 16+, macOS 14+ on Apple Silicon.

## Project layout

See [README.md → Project layout](README.md#project-layout).

Services are `@MainActor @Observable` (no Combine, no actors for UI models). Views bind via `@Bindable`. Notifications are torn down on `stop()`; `URLSession` calls have explicit timeouts; `TimelineView` pauses when not visible.

## Adding a widget

1. Create `Isle/Services/<Name>Service.swift` — `@MainActor @Observable`, owns its data + observers.
2. Create `Isle/Features/<Name>/<Name>View.swift` — receives the service via `@Bindable`.
3. Wire it in `NotchCoordinator` (lifecycle), `NotchWindowController` (init signature), and `RootView` (layout).
4. Add layout dimensions to `Isle/NotchLayout.swift` if needed — don't hardcode in views.
5. Localize user-visible strings via `Localizable.xcstrings`.

## Before opening a PR

- [ ] `xcodebuild build` passes locally
- [ ] No new warnings
- [ ] HIG audit: typography sizes, semantic colors, hit targets (28pt min, 32pt for primary actions)
- [ ] `pointerCursor()` applied to every new clickable surface
- [ ] If you touched layout, screenshot the result

## Reporting bugs

Use the issue template. Include macOS version, MacBook model, the source app (Spotify / Music) if relevant, and a screenshot. Logs from `log show --predicate 'process == "Isle"' --info --last 5m` are gold.
