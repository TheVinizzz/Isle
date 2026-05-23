import SwiftUI

/// Background audio "halo": three offset sine-wave layers + a radial glow
/// rising from the bottom edge, tinted by the artwork's accent color.
///
/// Inspired by Apple Music's lock-screen now-playing halo. Animation pauses
/// automatically when playback pauses so the panel doesn't burn battery while
/// nothing's playing.
struct AudioVisualizer: View {
    let accentColor: Color
    let isActive: Bool
    let cornerRadius: CGFloat

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isActive)) { context in
            let t = context.date.timeIntervalSinceReferenceDate

            ZStack {
                bottomGlow(t: t)

                wave(
                    phase: t * 1.6,
                    amplitude: 8,
                    frequency: 2.0,
                    baseY: 0.55,
                    opacity: 0.32,
                    blur: 6,
                    lineWidth: 1.4
                )

                wave(
                    phase: t * 2.4 + 1.2,
                    amplitude: 6,
                    frequency: 1.5,
                    baseY: 0.68,
                    opacity: 0.42,
                    blur: 4,
                    lineWidth: 1.0
                )

                wave(
                    phase: t * 1.1 + 2.5,
                    amplitude: 4,
                    frequency: 2.7,
                    baseY: 0.78,
                    opacity: 0.26,
                    blur: 6,
                    lineWidth: 0.8
                )
            }
        }
        .mask(maskShape)
        .compositingGroup()
        .blendMode(.plusLighter)
        .opacity(isActive ? 1 : 0)
        .animation(.easeInOut(duration: 0.55), value: isActive)
        .allowsHitTesting(false)
    }

    // MARK: - Mask (matches outer notch shape, inset 1pt so blur never kisses the edge)

    private var maskShape: some View {
        UnevenRoundedRectangle(
            topLeadingRadius: 0,
            bottomLeadingRadius: cornerRadius,
            bottomTrailingRadius: cornerRadius,
            topTrailingRadius: 0,
            style: .continuous
        )
        .padding(1)
    }

    // MARK: - Layers

    private func bottomGlow(t: TimeInterval) -> some View {
        let pulse = (sin(t * 0.85) + 1) / 2 * 0.18 + 0.82
        return LinearGradient(
            stops: [
                .init(color: .clear, location: 0.00),
                .init(color: accentColor.opacity(0.10 * pulse), location: 0.45),
                .init(color: accentColor.opacity(0.30 * pulse), location: 0.78),
                .init(color: .clear, location: 1.00)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .blur(radius: 4)
    }

    private func wave(
        phase: TimeInterval,
        amplitude: CGFloat,
        frequency: CGFloat,
        baseY: CGFloat,
        opacity: CGFloat,
        blur: CGFloat,
        lineWidth: CGFloat
    ) -> some View {
        WaveShape(
            phase: CGFloat(phase),
            amplitude: amplitude,
            frequency: frequency,
            baseY: baseY
        )
        .stroke(accentColor.opacity(opacity), lineWidth: lineWidth)
        .blur(radius: blur)
    }
}

// MARK: - Wave shape

private struct WaveShape: Shape {
    var phase: CGFloat
    var amplitude: CGFloat
    var frequency: CGFloat
    /// Vertical anchor as a fraction of height (0 = top, 1 = bottom).
    var baseY: CGFloat

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.height * baseY
        let width = rect.width
        let step: CGFloat = 2

        path.move(to: CGPoint(x: 0, y: midY))
        var x: CGFloat = 0
        while x <= width {
            let normalized = x / width
            let y = midY + sin(normalized * frequency * .pi * 2 + phase) * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
            x += step
        }
        return path
    }
}
