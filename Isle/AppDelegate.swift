import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var coordinator: NotchCoordinator?
    private var statusBar: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let coordinator = NotchCoordinator()
        coordinator.start()
        self.coordinator = coordinator

        let statusBar = StatusBarController()
        statusBar.install()
        self.statusBar = statusBar
    }

    func applicationWillTerminate(_ notification: Notification) {
        coordinator?.stop()
        coordinator = nil
        statusBar?.uninstall()
        statusBar = nil
    }
}
