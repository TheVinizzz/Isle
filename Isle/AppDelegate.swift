import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var coordinator: NotchCoordinator?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let coordinator = NotchCoordinator()
        coordinator.start()
        self.coordinator = coordinator

        // First-launch welcome card. Self-marks "seen" in UserDefaults so it
        // won't show again on subsequent launches.
        WelcomeManager.shared.showIfNeeded()
    }

    func applicationWillTerminate(_ notification: Notification) {
        coordinator?.stop()
        coordinator = nil
    }
}
