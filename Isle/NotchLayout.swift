import Foundation

/// Single source of truth for notch panel geometry.
/// Used by both the SwiftUI layer (to size the shape) and the window controller
/// (to compute hit-test zones for hover hysteresis).
enum NotchLayout {
    /// Hosting window width. Wide enough for max expanded panel + animation room.
    static let windowWidth: CGFloat = 820
    /// Hosting window height. Generous so expand animation has room.
    static let windowHeight: CGFloat = 200

    /// Expanded panel width.
    static let expandedWidth: CGFloat = 720
    /// Expanded panel height.
    static let expandedHeight: CGFloat = 140

    /// Corner radius (continuous squircle) for bottom corners when expanded.
    static let cornerRadiusExpanded: CGFloat = 24
    /// Corner radius when collapsed (matches physical notch curvature).
    static let cornerRadiusCollapsed: CGFloat = 10

    /// Grace margin around the activation zone over the physical notch.
    static let collapsedHitGrace: CGFloat = 6
    /// Grace margin around the expanded panel for hover retention.
    static let expandedHitGrace: CGFloat = 6
}
