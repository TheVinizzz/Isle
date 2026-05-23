#!/usr/bin/env swift

// Generates the Isle AppIcon set at every required macOS size.
// Renders a continuous-corner squircle background with a white notch glyph
// using SwiftUI's ImageRenderer (macOS 13+), then writes PNGs straight into
// Isle/Resources/Assets.xcassets/AppIcon.appiconset/.
//
// Usage:
//   cd /path/to/Notch
//   swift scripts/generate-icon.swift

import AppKit
import SwiftUI

@MainActor
struct IsleIcon: View {
    let size: CGFloat

    /// Apple's continuous-curve squircle corner ratio (22.37% of side length).
    private var cornerRadius: CGFloat { size * 0.2237 }

    var body: some View {
        ZStack {
            // Background — deep gradient with a subtle ambient warmth.
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color(red: 0.06, green: 0.06, blue: 0.08), location: 0.0),
                            .init(color: Color(red: 0.02, green: 0.02, blue: 0.04), location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Inner top highlight — gives the surface depth.
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.18), .clear],
                        startPoint: .top,
                        endPoint: .center
                    ),
                    lineWidth: max(size * 0.006, 1)
                )

            // Notch silhouette — flat top, rounded bottom corners.
            NotchGlyph()
                .fill(Color.white)
                .frame(width: size * 0.50, height: size * 0.16)
                .offset(y: -size * 0.04)

            // Accent dot — the "island" indicator below the notch.
            Circle()
                .fill(Color(red: 0.0, green: 0.48, blue: 1.0))
                .frame(width: size * 0.07, height: size * 0.07)
                .offset(y: size * 0.20)
        }
        .frame(width: size, height: size)
    }
}

struct NotchGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        let r = min(rect.height * 0.45, rect.width * 0.18)
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - r, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - r),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - Rendering pipeline

@MainActor
func render(size: CGFloat) -> Data? {
    let renderer = ImageRenderer(content: IsleIcon(size: size))
    renderer.scale = 1.0
    guard let nsImage = renderer.nsImage,
          let tiff = nsImage.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:])
    else { return nil }
    return png
}

// MARK: - Asset catalog targets

struct IconTarget {
    let logicalSize: Int
    let scale: Int
    var pixelSize: Int { logicalSize * scale }
    var filename: String { "icon_\(logicalSize)x\(logicalSize)\(scale > 1 ? "@\(scale)x" : "").png" }
    var assetEntry: [String: String] {
        [
            "idiom": "mac",
            "scale": "\(scale)x",
            "size": "\(logicalSize)x\(logicalSize)",
            "filename": filename
        ]
    }
}

let targets: [IconTarget] = [
    .init(logicalSize: 16, scale: 1),
    .init(logicalSize: 16, scale: 2),
    .init(logicalSize: 32, scale: 1),
    .init(logicalSize: 32, scale: 2),
    .init(logicalSize: 128, scale: 1),
    .init(logicalSize: 128, scale: 2),
    .init(logicalSize: 256, scale: 1),
    .init(logicalSize: 256, scale: 2),
    .init(logicalSize: 512, scale: 1),
    .init(logicalSize: 512, scale: 2)
]

let cwd = FileManager.default.currentDirectoryPath
let outDir = URL(fileURLWithPath: cwd)
    .appendingPathComponent("Isle/Resources/Assets.xcassets/AppIcon.appiconset")

try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

@MainActor
func run() {
    var generated = 0
    for target in targets {
        guard let data = render(size: CGFloat(target.pixelSize)) else {
            print("✗ Failed: \(target.filename)")
            continue
        }
        let url = outDir.appendingPathComponent(target.filename)
        do {
            try data.write(to: url)
            generated += 1
            print("✓ \(target.filename) (\(target.pixelSize)px)")
        } catch {
            print("✗ Write failed: \(target.filename) — \(error)")
        }
    }

    // Rewrite Contents.json with all entries.
    let contents: [String: Any] = [
        "images": targets.map { $0.assetEntry },
        "info": ["author": "xcode", "version": 1]
    ]
    do {
        let json = try JSONSerialization.data(
            withJSONObject: contents,
            options: [.prettyPrinted, .sortedKeys]
        )
        try json.write(to: outDir.appendingPathComponent("Contents.json"))
        print("✓ Contents.json")
    } catch {
        print("✗ Contents.json — \(error)")
    }

    print("\nGenerated \(generated)/\(targets.count) icons → \(outDir.path)")
}

DispatchQueue.main.async { run() }
RunLoop.main.run(until: Date().addingTimeInterval(2.0))
