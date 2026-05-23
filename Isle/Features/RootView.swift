import SwiftUI

struct RootView: View {
    @Bindable var presenter: NotchPresenter
    @Bindable var media: MediaService
    @Bindable var calendar: CalendarService
    @Bindable var finance: FinanceService
    let notchSize: CGSize

    private var isExpanded: Bool { presenter.state == .hovered }

    private var currentWidth: CGFloat {
        isExpanded ? NotchLayout.expandedWidth : max(notchSize.width, 200)
    }

    private var currentHeight: CGFloat {
        isExpanded ? NotchLayout.expandedHeight : max(notchSize.height, 32)
    }

    private var cornerRadius: CGFloat {
        isExpanded ? NotchLayout.cornerRadiusExpanded : NotchLayout.cornerRadiusCollapsed
    }

    private var shapeSpring: Animation {
        .spring(response: 0.42, dampingFraction: 0.82, blendDuration: 0)
    }

    private var notchShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: 0,
            bottomLeadingRadius: cornerRadius,
            bottomTrailingRadius: cornerRadius,
            topTrailingRadius: 0,
            style: .continuous
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                Color.black

                AudioVisualizer(
                    accentColor: media.artworkAccent,
                    isActive: media.isPlaying && isExpanded,
                    cornerRadius: cornerRadius
                )

                ExpandedContent(
                    media: media,
                    calendar: calendar,
                    finance: finance,
                    notchHeight: notchSize.height
                )
                .opacity(isExpanded ? 1 : 0)
                .scaleEffect(isExpanded ? 1 : 0.96, anchor: .top)
                .animation(
                    .easeOut(duration: 0.18).delay(isExpanded ? 0.10 : 0),
                    value: isExpanded
                )

                topHighlight
            }
            .frame(width: currentWidth, height: currentHeight)
            .clipShape(notchShape)
            .shadow(color: .black.opacity(isExpanded ? 0.45 : 0), radius: 22, x: 0, y: 10)
            .animation(shapeSpring, value: isExpanded)
            .compositingGroup()

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private var topHighlight: some View {
        LinearGradient(
            colors: [.white.opacity(0.08), .white.opacity(0)],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 1.5)
        .blendMode(.plusLighter)
        .allowsHitTesting(false)
    }
}

private struct ExpandedContent: View {
    @Bindable var media: MediaService
    @Bindable var calendar: CalendarService
    @Bindable var finance: FinanceService
    let notchHeight: CGFloat

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            NowPlayingView(media: media)
                .frame(width: 260, alignment: .leading)

            divider

            CalendarStripView(calendar: calendar)
                .frame(maxWidth: .infinity, alignment: .leading)

            divider

            FinanceView(finance: finance)
                .frame(width: 130, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.top, notchHeight + 10)
        .padding(.bottom, 12)
    }

    private var divider: some View {
        Rectangle()
            .fill(.white.opacity(0.08))
            .frame(width: 1, height: 68)
    }
}
