import AppKit
import CoreImage

extension NSImage {
    /// Sample the artwork's average color using Core Image's `CIAreaAverage`
    /// filter — same approach used to pull tint colors from album art in
    /// macOS Music and the iOS lock screen now-playing halo.
    var averageColor: NSColor? {
        guard let tiff = tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let ciImage = CIImage(bitmapImageRep: bitmap)
        else { return nil }

        let extent = ciImage.extent
        guard let filter = CIFilter(name: "CIAreaAverage") else { return nil }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgRect: extent), forKey: kCIInputExtentKey)
        guard let output = filter.outputImage else { return nil }

        var bytes = [UInt8](repeating: 0, count: 4)
        let ctx = CIContext(options: [.workingColorSpace: NSNull()])
        ctx.render(
            output,
            toBitmap: &bytes,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )

        return NSColor(
            red: CGFloat(bytes[0]) / 255.0,
            green: CGFloat(bytes[1]) / 255.0,
            blue: CGFloat(bytes[2]) / 255.0,
            alpha: 1.0
        )
    }
}

extension NSColor {
    /// Boosts saturation + clamps brightness so muted/grey averages turn into
    /// vivid accents suitable for glow effects (mirrors Apple Music's tint
    /// extraction behavior).
    func vibrant(saturationFactor: CGFloat = 1.6, minBrightness: CGFloat = 0.55) -> NSColor {
        guard let rgb = usingColorSpace(.sRGB) else { return self }
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        rgb.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        let newSat = min(1.0, s * saturationFactor)
        let newBri = max(minBrightness, min(1.0, b * 1.15))
        return NSColor(hue: h, saturation: newSat, brightness: newBri, alpha: a)
    }
}
