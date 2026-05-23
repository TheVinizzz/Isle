import AppKit

/// Borderless, transparent panel that sits over the physical notch.
///
/// Uses `NSPanel` with `.nonactivatingPanel` so it can receive mouse events
/// (including clicks on SwiftUI buttons) without activating the app or
/// stealing focus from the user's current window.
final class NotchWindow: NSPanel {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        // NSPanel behaviors for menu-bar-overlay usage.
        isFloatingPanel = true
        becomesKeyOnlyIfNeeded = true
        hidesOnDeactivate = false
        worksWhenModal = true

        // Visual / interaction config.
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isMovable = false
        ignoresMouseEvents = false
        animationBehavior = .none

        // Sit above the menu bar and notifications.
        level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 8)
        collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
            .ignoresCycle
        ]
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
