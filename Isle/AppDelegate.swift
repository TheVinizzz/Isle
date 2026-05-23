import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var coordinator: NotchCoordinator?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let coordinator = NotchCoordinator()
        coordinator.start()
        self.coordinator = coordinator
    }

    func applicationWillTerminate(_ notification: Notification) {
        coordinator?.stop()
        coordinator = nil
    }
}
