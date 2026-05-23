import AppKit
import SwiftUI

struct WelcomeView: View {
    let onDismiss: () -> Void

    @State private var isDismissing = false

    private var dismissSpring: Animation {
        .spring(response: 0.55, dampingFraction: 0.82, blendDuration: 0)
    }

    var body: some View {
        ZStack {
            card
        }
        .frame(width: WelcomeWindow.size.width, height: WelcomeWindow.size.height)
        // "Absorbed into the notch": shrink toward the top edge while fading.
        .scaleEffect(isDismissing ? 0.06 : 1, anchor: .top)
        .offset(y: isDismissing ? -WelcomeWindow.size.height / 2 + 18 : 0)
        .opacity(isDismissing ? 0 : 1)
        .animation(dismissSpring, value: isDismissing)
    }

    // MARK: - Card

    private var card: some View {
        VStack(alignment: .leading, spacing: 28) {
            header
            featureList
            Spacer(minLength: 0)
            footer
        }
        .padding(.horizontal, 32)
        .padding(.top, 36)
        .padding(.bottom, 28)
        .background(cardBackground)
    }

    private var cardBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(white: 0.11),
                            Color(white: 0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.15), .white.opacity(0.03)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.6
                )
        }
        .shadow(color: .black.opacity(0.55), radius: 30, x: 0, y: 14)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: 16) {
            appIcon

            VStack(alignment: .leading, spacing: 3) {
                Text("Welcome to Isle")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Your MacBook notch, reimagined.")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.55))
            }

            Spacer(minLength: 0)
        }
    }

    private var appIcon: some View {
        Group {
            if let icon = NSApp.applicationIconImage {
                Image(nsImage: icon)
                    .resizable()
                    .interpolation(.high)
            } else {
                placeholderIcon
            }
        }
        .frame(width: 64, height: 64)
    }

    private var placeholderIcon: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color(white: 0.12))
            .overlay(
                Image(systemName: "rectangle.center.inset.filled")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)
            )
    }

    // MARK: - Features

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 18) {
            FeatureRow(
                symbol: "music.note",
                title: "Now Playing",
                description: "Live controls and artwork for Spotify and Apple Music."
            )
            FeatureRow(
                symbol: "calendar",
                title: "Calendar",
                description: "Today's events from macOS Calendar — navigable strip."
            )
            FeatureRow(
                symbol: "chart.line.uptrend.xyaxis",
                title: "Markets",
                description: "USD/BRL and BTC/BRL quotes refreshed every five minutes."
            )
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 18) {
            HStack(spacing: 6) {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                Text("Open source · MIT License")
                    .font(.system(size: 12, weight: .medium))
                Text("·")
                    .foregroundStyle(.white.opacity(0.25))
                githubLink
            }
            .foregroundStyle(.white.opacity(0.55))
            .frame(maxWidth: .infinity, alignment: .center)

            getStartedButton
        }
    }

    private var githubLink: some View {
        Button {
            if let url = URL(string: "https://github.com/TheVinizzz/Isle") {
                NSWorkspace.shared.open(url)
            }
        } label: {
            Text("View on GitHub →")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(nsColor: .systemBlue))
        }
        .buttonStyle(.plain)
        .pointerCursor()
    }

    private var getStartedButton: some View {
        Button(action: triggerDismiss) {
            Text("Get Started")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(
                    Capsule()
                        .fill(Color(nsColor: .systemBlue))
                )
        }
        .buttonStyle(.plain)
        .pointerCursor()
        .keyboardShortcut(.defaultAction)
    }

    // MARK: - Dismiss

    private func triggerDismiss() {
        guard !isDismissing else { return }
        isDismissing = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(560))
            onDismiss()
        }
    }
}

private struct FeatureRow: View {
    let symbol: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(nsColor: .systemBlue).opacity(0.18))
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color(nsColor: .systemBlue))
                    .symbolRenderingMode(.hierarchical)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Text(description)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.55))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }
}
