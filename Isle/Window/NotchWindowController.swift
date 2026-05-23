import AppKit
import SwiftUI

@MainActor
final class NotchWindowController: NSWindowController {
    private let presenter: NotchPresenter
    private let media: MediaService
    private let calendar: CalendarService
    private let finance: FinanceService
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private weak var screenRef: NSScreen?

    init(
        screen: NSScreen,
        presenter: NotchPresenter,
        media: MediaService,
        calendar: CalendarService,
        finance: FinanceService
    ) {
        self.presenter = presenter
        self.media = media
        self.calendar = calendar
        self.finance = finance
        self.screenRef = screen

        let frame = Self.frame(for: screen)
        let window = NotchWindow(contentRect: frame)

        let host = NSHostingView(
            rootView: RootView(
                presenter: presenter,
                media: media,
                calendar: calendar,
                finance: finance,
                notchSize: screen.notchSize
            )
        )
        host.frame = NSRect(origin: .zero, size: frame.size)
        host.autoresizingMask = [.width, .height]
        window.contentView = host

        super.init(window: window)
        installEventMonitors()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    override func showWindow(_ sender: Any?) {
        window?.orderFrontRegardless()
    }

    func reposition(on screen: NSScreen) {
        screenRef = screen
        guard let window else { return }
        window.setFrame(Self.frame(for: screen), display: true, animate: false)
        if let host = window.contentView as? NSHostingView<RootView> {
            host.rootView = RootView(
                presenter: presenter,
                media: media,
                calendar: calendar,
                finance: finance,
                notchSize: screen.notchSize
            )
        }
    }

    override func close() {
        removeEventMonitors()
        super.close()
    }

    private static func frame(for screen: NSScreen) -> NSRect {
        let x = screen.frame.midX - NotchLayout.windowWidth / 2
        let y = screen.frame.maxY - NotchLayout.windowHeight
        return NSRect(
            x: x,
            y: y,
            width: NotchLayout.windowWidth,
            height: NotchLayout.windowHeight
        )
    }

    private func installEventMonitors() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            Task { @MainActor in self?.handleMouseMoved(event) }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            self?.handleMouseMoved(event)
            return event
        }
    }

    private func removeEventMonitors() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }

    private func handleMouseMoved(_ event: NSEvent) {
        guard let screen = screenRef else { return }
        let notch = screen.notchSize
        guard notch != .zero else { return }

        let mouseLocation = NSEvent.mouseLocation
        let topY = screen.frame.maxY
        let centerX = screen.frame.midX

        let wasCollapsed = presenter.state == .collapsed
        let shouldBeHovered: Bool
        switch presenter.state {
        case .collapsed:
            shouldBeHovered = isInside(
                mouse: mouseLocation,
                topY: topY,
                centerX: centerX,
                halfWidth: notch.width / 2 + NotchLayout.collapsedHitGrace,
                height: notch.height + NotchLayout.collapsedHitGrace
            )
        case .hovered:
            shouldBeHovered = isInside(
                mouse: mouseLocation,
                topY: topY,
                centerX: centerX,
                halfWidth: NotchLayout.expandedWidth / 2 + NotchLayout.expandedHitGrace,
                height: NotchLayout.expandedHeight + NotchLayout.expandedHitGrace
            )
        }

        presenter.setHovered(shouldBeHovered)

        // Lazy probe on the first transition into the hovered state — populates
        // the now-playing widget without needing a track-change notification.
        if wasCollapsed && shouldBeHovered {
            Task { @MainActor [media] in
                await media.probeInitialStateIfNeeded()
            }
        }
    }

    private func isInside(
        mouse: NSPoint,
        topY: CGFloat,
        centerX: CGFloat,
        halfWidth: CGFloat,
        height: CGFloat
    ) -> Bool {
        guard mouse.y >= topY - height, mouse.y <= topY else { return false }
        return abs(mouse.x - centerX) <= halfWidth
    }
}
