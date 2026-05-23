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
        // The window frame is 820×200 to accommodate the expanded panel +
        // animation room, but the *visible* notch panel is much smaller.
        // Default to passing mouse events through; the window controller
        // flips this to `false` only while the cursor is over the visible
        // panel (collapsed pill or expanded card), so apps underneath remain
        // clickable everywhere else.
        ignoresMouseEvents = true
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
