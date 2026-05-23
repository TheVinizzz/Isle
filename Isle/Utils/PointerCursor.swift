import AppKit
import SwiftUI

extension View {
    /// Signals "this is clickable" by swapping the system cursor to a pointing
    /// hand while the cursor is over the view. Same affordance Apple uses on
    /// links, toolbar buttons, and clickable menu items.
    ///
    /// Uses `NSCursor.push/pop` with explicit lifecycle handling so the cursor
    /// never gets stuck (e.g. if the view disappears while the cursor is over it).
    func pointerCursor() -> some View {
        modifier(PointerCursorModifier())
    }
}

private struct PointerCursorModifier: ViewModifier {
    @State private var didPush = false

    func body(content: Content) -> some View {
        content
            .onHover { hovering in
                if hovering && !didPush {
                    NSCursor.pointingHand.push()
                    didPush = true
                } else if !hovering && didPush {
                    NSCursor.pop()
                    didPush = false
                }
            }
            .onDisappear {
                if didPush {
                    NSCursor.pop()
                    didPush = false
                }
            }
    }
}
