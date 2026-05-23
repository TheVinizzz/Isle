import SwiftUI

struct NowPlayingView: View {
    @Bindable var media: MediaService

    private var hasPlayback: Bool { media.source != .none }

    /// iOS Dynamic Island-grade spring.
    private var trackSpring: Animation {
        .spring(response: 0.48, dampingFraction: 0.82, blendDuration: 0)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            artworkContainer

            VStack(alignment: .leading, spacing: 1) {
                titleText
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .contentTransition(.opacity)
                    .id("title-\(media.trackChangeID)")
                    .transition(textTransition)

                Text(media.artist)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .id("artist-\(media.trackChangeID)")
                    .transition(textTransition)

                HStack(spacing: 4) {
                    TransportButton(symbol: "backward.fill", size: 16, hit: 28) {
                        media.previousTrack()
                    }
                    TransportButton(
                        symbol: media.isPlaying ? "pause.fill" : "play.fill",
                        size: 18,
                        hit: 32,
                        bounceValue: media.isPlaying
                    ) {
                        media.togglePlayPause()
                    }
                    TransportButton(symbol: "forward.fill", size: 16, hit: 28) {
                        media.nextTrack()
                    }
                    Spacer(minLength: 0)
                }
                .padding(.top, 4)
                .disabled(!hasPlayback)
                .opacity(hasPlayback ? 1 : 0.4)
            }
            .animation(trackSpring, value: media.trackChangeID)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var titleText: some View {
        if hasPlayback {
            Text(media.title)
        } else {
            Text("Not playing")
        }
    }

    // MARK: - Artwork

    private var artworkContainer: some View {
        ZStack(alignment: .bottomTrailing) {
            artworkLayer
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(.white.opacity(0.08), lineWidth: 0.5)
                )
                .id(media.trackChangeID)
                .transition(artworkTransition)

            if hasPlayback {
                sourceBadge
                    .offset(x: 3, y: 3)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(trackSpring, value: media.trackChangeID)
    }

    @ViewBuilder
    private var artworkLayer: some View {
        if let image = media.artwork {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            ZStack {
                LinearGradient(
                    colors: [Color(white: 0.18), Color(white: 0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: "music.note")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
                    .symbolRenderingMode(.hierarchical)
            }
        }
    }

    private var sourceBadge: some View {
        Circle()
            .fill(Color(nsColor: media.source.accentColor))
            .frame(width: 11, height: 11)
            .overlay(
                Circle()
                    .stroke(.black, lineWidth: 1.5)
            )
    }

    // MARK: - Transitions

    private var artworkTransition: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.88).combined(with: .opacity),
            removal: .scale(scale: 1.08).combined(with: .opacity)
        )
    }

    private var textTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        )
    }
}

private struct TransportButton: View {
    let symbol: String
    let size: CGFloat
    let hit: CGFloat
    var bounceValue: AnyHashable? = nil
    let action: () -> Void

    @State private var isHovered = false
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size, weight: .medium))
                .foregroundStyle(.primary)
                .symbolRenderingMode(.hierarchical)
                .symbolEffect(.bounce, value: bounceValue ?? AnyHashable(symbol))
                .scaleEffect(isPressed ? 0.86 : (isHovered ? 1.12 : 1.0))
                .animation(.spring(response: 0.28, dampingFraction: 0.7), value: isHovered)
                .animation(.spring(response: 0.18, dampingFraction: 0.6), value: isPressed)
                .frame(width: hit, height: hit)
                .contentShape(Rectangle())
                .background(
                    Circle()
                        .fill(.white.opacity(isHovered ? 0.08 : 0))
                        .frame(width: hit - 2, height: hit - 2)
                )
        }
        .buttonStyle(.plain)
        .pointerCursor()
        .onHover { hovering in
            isHovered = hovering
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}
