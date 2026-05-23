import AppKit
import SwiftUI

struct FinanceView: View {
    @Bindable var finance: FinanceService

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if finance.quotes.isEmpty {
                placeholder
            } else {
                ForEach(finance.quotes.prefix(2)) { quote in
                    FinanceRow(quote: quote)
                        .id(quote.id)
                        .transition(.opacity.combined(with: .offset(y: 4)))
                }
            }
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.85), value: finance.quotes)
    }

    private var placeholder: some View {
        VStack(alignment: .leading, spacing: 6) {
            placeholderRow
            placeholderRow
        }
        .redacted(reason: .placeholder)
    }

    private var placeholderRow: some View {
        HStack(spacing: 6) {
            Text("USD")
                .font(.system(size: 10, weight: .semibold))
            Text("0,00")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
            Spacer(minLength: 0)
            Text("0,00%")
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundStyle(.tertiary)
    }
}

private struct FinanceRow: View {
    let quote: FinanceService.Quote

    private var isUp: Bool { quote.pctChange >= 0 }

    private var changeColor: Color {
        isUp ? Color(nsColor: .systemGreen) : Color(nsColor: .systemRed)
    }

    private var changeText: String {
        String(format: "%.2f%%", abs(quote.pctChange))
    }

    var body: some View {
        HStack(spacing: 6) {
            Text(quote.symbol)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.tertiary)
                .frame(width: 28, alignment: .leading)

            Text(quote.formattedPrice)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .lineLimit(1)
                .fixedSize()

            Spacer(minLength: 4)

            HStack(spacing: 2) {
                Image(systemName: isUp ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 8, weight: .bold))
                Text(changeText)
                    .font(.system(size: 10, weight: .medium))
                    .monospacedDigit()
            }
            .foregroundStyle(changeColor)
        }
    }
}
