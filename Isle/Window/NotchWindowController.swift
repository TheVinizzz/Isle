import AppKit
import ServiceManagement
import SwiftUI

@MainActor
final class NotchWindowController: NSWindowController {
    private let presenter: NotchPresenter
    private let media: MediaService
    private let calendar: CalendarService
    private let finance: FinanceService
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var rightClickMonitor: Any?
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

    // MARK: - Event monitors

    private func installEventMonitors() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            Task { @MainActor in self?.handleMouseMoved(event) }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            self?.handleMouseMoved(event)
            return event
        }
        rightClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: .rightMouseDown) { [weak self] event in
            Task { @MainActor in self?.handleRightClick(event) }
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
        if let monitor = rightClickMonitor {
            NSEvent.removeMonitor(monitor)
            rightClickMonitor = nil
        }
    }

    // MARK: - Hover (left/no button)

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

        // Capture clicks only while the cursor is over the visible panel;
        // everywhere else, let the click reach whatever app is underneath.
        // (The window frame stays full-canvas so animations have room.)
        window?.ignoresMouseEvents = !shouldBeHovered

        presenter.setHovered(shouldBeHovered)

        if wasCollapsed && shouldBeHovered {
            Task { @MainActor [media] in
                await media.probeCurrentStateIfStale()
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

    // MARK: - Right-click context menu

    private func handleRightClick(_ event: NSEvent) {
        guard let screen = screenRef,
              let window
        else { return }
        let notch = screen.notchSize
        guard notch != .zero else { return }

        let mouse = NSEvent.mouseLocation
        let topY = screen.frame.maxY
        let centerX = screen.frame.midX

        // Accept right-click anywhere inside the current panel bounds (works
        // whether collapsed or expanded).
        let halfWidth: CGFloat
        let height: CGFloat
        if presenter.state == .hovered {
            halfWidth = NotchLayout.expandedWidth / 2 + NotchLayout.expandedHitGrace
            height = NotchLayout.expandedHeight + NotchLayout.expandedHitGrace
        } else {
            halfWidth = notch.width / 2 + NotchLayout.collapsedHitGrace
            height = notch.height + NotchLayout.collapsedHitGrace
        }

        guard mouse.y >= topY - height,
              mouse.y <= topY,
              abs(mouse.x - centerX) <= halfWidth
        else { return }

        showContextMenu(at: mouse, in: window)
    }

    private func showContextMenu(at screenPoint: NSPoint, in window: NSWindow) {
        let frame = window.frame
        let windowPoint = NSPoint(
            x: screenPoint.x - frame.origin.x,
            y: screenPoint.y - frame.origin.y
        )
        let menu = buildMenu()
        menu.popUp(positioning: nil, at: windowPoint, in: window.contentView)
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        let header = NSMenuItem(title: "Isle", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)

        let version = NSMenuItem(
            title: "Version \(Self.versionString)",
            action: nil,
            keyEquivalent: ""
        )
        version.isEnabled = false
        menu.addItem(version)

        menu.addItem(.separator())

        let launch = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launch.target = self
        launch.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(launch)

        menu.addItem(.separator())

        let github = NSMenuItem(
            title: "GitHub Repository",
            action: #selector(openGitHub),
            keyEquivalent: ""
        )
        github.target = self
        menu.addItem(github)

        menu.addItem(.separator())

        let quit = NSMenuItem(
            title: "Quit Isle",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quit.target = self
        menu.addItem(quit)

        return menu
    }

    // MARK: - Menu actions

    @objc private func toggleLaunchAtLogin() {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled {
                try service.unregister()
            } else {
                try service.register()
            }
        } catch {
            NSLog("Isle: launch at login toggle failed — \(error.localizedDescription)")
        }
    }

    @objc private func openGitHub() {
        if let url = URL(string: "https://github.com/TheVinizzz/Isle") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private static var versionString: String {
        let info = Bundle.main.infoDictionary
        let v = info?["CFBundleShortVersionString"] as? String ?? "0.0"
        let b = info?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}
