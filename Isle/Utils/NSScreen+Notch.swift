import AppKit

extension NSScreen {
    static var builtIn: NSScreen? {
        screens.first { $0.isBuiltIn }
    }

    var isBuiltIn: Bool {
        guard
            let id = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
        else { return false }
        return CGDisplayIsBuiltin(id) != 0
    }

    /// Returns the physical notch size, or `.zero` on notchless displays.
    var notchSize: CGSize {
        guard safeAreaInsets.top > 0 else { return .zero }
        let leftPadding = auxiliaryTopLeftArea?.width ?? 0
        let rightPadding = auxiliaryTopRightArea?.width ?? 0
        guard leftPadding > 0, rightPadding > 0 else { return .zero }
        return CGSize(
            width: frame.width - leftPadding - rightPadding,
            height: safeAreaInsets.top
        )
    }
}
