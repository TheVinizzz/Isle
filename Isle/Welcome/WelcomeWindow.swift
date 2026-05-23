import AppKit

/// Borderless rounded window for the first-launch welcome card.
/// Transparent background so the SwiftUI card can paint its own continuous-
/// corner shape.
final class WelcomeWindow: NSWindow {
    static let size = NSSize(width: 480, height: 460)

    init() {
        super.init(
            contentRect: NSRect(origin: .zero, size: Self.size),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false // SwiftUI card draws its own
        isMovableByWindowBackground = true
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        animationBehavior = .none

        level = .floating
        collectionBehavior = [.fullScreenAuxiliary]

        center()
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
