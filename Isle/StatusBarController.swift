import AppKit
import ServiceManagement

@MainActor
final class StatusBarController: NSObject {
    private var statusItem: NSStatusItem?

    func install() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            let image = NSImage(
                systemSymbolName: "rectangle.center.inset.filled",
                accessibilityDescription: "Isle"
            )
            image?.isTemplate = true
            button.image = image
            button.toolTip = "Isle"
        }
        item.menu = buildMenu()
        statusItem = item
    }

    func uninstall() {
        if let statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
        statusItem = nil
    }

    // MARK: - Menu

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self

        let aboutItem = NSMenuItem(
            title: "Isle",
            action: nil,
            keyEquivalent: ""
        )
        aboutItem.isEnabled = false
        menu.addItem(aboutItem)

        let versionItem = NSMenuItem(
            title: "Version \(Self.versionString)",
            action: nil,
            keyEquivalent: ""
        )
        versionItem.isEnabled = false
        menu.addItem(versionItem)

        menu.addItem(.separator())

        let launchItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launchItem.target = self
        launchItem.identifier = .launchAtLogin
        menu.addItem(launchItem)

        menu.addItem(.separator())

        let websiteItem = NSMenuItem(
            title: "GitHub Repository",
            action: #selector(openRepository),
            keyEquivalent: ""
        )
        websiteItem.target = self
        menu.addItem(websiteItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit Isle",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    // MARK: - Actions

    @objc private func toggleLaunchAtLogin() {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled {
                try service.unregister()
            } else {
                try service.register()
            }
        } catch {
            NSLog("Isle: failed to toggle launch at login — \(error.localizedDescription)")
        }
    }

    @objc private func openRepository() {
        if let url = URL(string: Self.repositoryURL) {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    // MARK: - Constants

    private static var versionString: String {
        let info = Bundle.main.infoDictionary
        let v = info?["CFBundleShortVersionString"] as? String ?? "0.0"
        let b = info?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    private static let repositoryURL = "https://github.com/TheVinizzz/Isle"
}

extension StatusBarController: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        if let item = menu.item(withIdentifier: .launchAtLogin) {
            item.state = SMAppService.mainApp.status == .enabled ? .on : .off
        }
    }
}

private extension NSUserInterfaceItemIdentifier {
    static let launchAtLogin = NSUserInterfaceItemIdentifier("launchAtLogin")
}

private extension NSMenu {
    func item(withIdentifier id: NSUserInterfaceItemIdentifier) -> NSMenuItem? {
        items.first { $0.identifier == id }
    }
}
