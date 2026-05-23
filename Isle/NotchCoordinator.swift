import AppKit

@MainActor
final class NotchCoordinator {
    private var windowController: NotchWindowController?
    private let presenter = NotchPresenter()
    private let media = MediaService()
    private let calendar = CalendarService()
    private let finance = FinanceService()
    private var screenObserver: NSObjectProtocol?

    func start() {
        media.start()
        finance.start()
        Task { await calendar.bootstrap() }

        rebuildForCurrentDisplay()
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.rebuildForCurrentDisplay() }
        }
    }

    func stop() {
        media.stop()
        finance.stop()
        if let observer = screenObserver {
            NotificationCenter.default.removeObserver(observer)
            screenObserver = nil
        }
        windowController?.close()
        windowController = nil
    }

    private func rebuildForCurrentDisplay() {
        guard let screen = NSScreen.builtIn, screen.notchSize != .zero else {
            windowController?.close()
            windowController = nil
            return
        }

        if let controller = windowController {
            controller.reposition(on: screen)
        } else {
            let controller = NotchWindowController(
                screen: screen,
                presenter: presenter,
                media: media,
                calendar: calendar,
                finance: finance
            )
            controller.showWindow(nil)
            windowController = controller
        }
    }
}
