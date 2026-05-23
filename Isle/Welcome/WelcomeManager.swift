import AppKit
import SwiftUI

/// Owns the first-launch welcome window. Shows once per user (tracked in
/// `UserDefaults`); subsequent launches no-op. Dismiss callback marks the
/// flag and closes the window after the SwiftUI absorbed-into-notch
/// animation finishes.
@MainActor
final class WelcomeManager {
    static let shared = WelcomeManager()

    private static let hasShownKey = "isle.welcome.v1.shown"

    private var window: WelcomeWindow?

    func showIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: Self.hasShownKey) else { return }
        present()
    }

    /// Force-show — used for testing or a "show welcome again" menu item.
    func forceShow() {
        present()
    }

    private func present() {
        guard window == nil else {
            window?.makeKeyAndOrderFront(nil)
            return
        }

        let win = WelcomeWindow()
        let hosting = NSHostingView(rootView: WelcomeView { [weak self] in
            self?.dismiss()
        })
        hosting.frame = NSRect(origin: .zero, size: WelcomeWindow.size)
        hosting.autoresizingMask = [.width, .height]
        win.contentView = hosting

        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        window = win
    }

    private func dismiss() {
        UserDefaults.standard.set(true, forKey: Self.hasShownKey)
        window?.orderOut(nil)
        window = nil
        NSApp.setActivationPolicy(.accessory)
    }
}
