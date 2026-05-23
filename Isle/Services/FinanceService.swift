import Foundation
import Observation

@MainActor
@Observable
final class FinanceService {
    struct Quote: Identifiable, Equatable {
        let id: String          // "USD-BRL"
        let symbol: String      // "USD"
        let price: Double
        let pctChange: Double   // signed
        let formattedPrice: String
    }

    private(set) var quotes: [Quote] = []
    private(set) var lastUpdated: Date?
    private(set) var isLoading: Bool = false
    private(set) var hasError: Bool = false

    /// Refresh interval — FX moves on minute scale, crypto faster but 5min is
    /// honest for a passive widget without hammering the API.
    private let refreshInterval: TimeInterval = 300

    /// AwesomeAPI BR — public, no auth, supports USD/EUR/BTC/ETH against BRL.
    /// Docs: https://docs.awesomeapi.com.br/
    private let endpoint = URL(string: "https://economia.awesomeapi.com.br/json/last/USD-BRL,BTC-BRL")!

    private var refreshTask: Task<Void, Never>?

    func start() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            await self?.refresh()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(self?.refreshInterval ?? 300))
                guard !Task.isCancelled else { return }
                await self?.refresh()
            }
        }
    }

    func stop() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        do {
            var request = URLRequest(url: endpoint)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.timeoutInterval = 10
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                hasError = true
                return
            }
            let raw = try JSONDecoder().decode([String: RawQuote].self, from: data)
            let parsed = Self.parse(raw: raw)
            if !parsed.isEmpty {
                quotes = parsed
                lastUpdated = Date()
                hasError = false
            } else {
                hasError = true
            }
        } catch {
            hasError = true
        }
    }

    private struct RawQuote: Decodable {
        let code: String
        let codein: String
        let bid: String
        let pctChange: String
    }

    private static func parse(raw: [String: RawQuote]) -> [Quote] {
        // Preserve API order with manual key list so display is stable.
        let preferredOrder = ["USDBRL", "BTCBRL", "EURBRL", "ETHBRL"]
        return preferredOrder.compactMap { key in
            guard let q = raw[key],
                  let price = Double(q.bid),
                  let pct = Double(q.pctChange)
            else { return nil }
            return Quote(
                id: "\(q.code)-\(q.codein)",
                symbol: q.code,
                price: price,
                pctChange: pct,
                formattedPrice: Self.format(price: price)
            )
        }
    }

    private static let compactFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = .current
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f
    }()

    private static let decimalFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = .current
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f
    }()

    private static func format(price: Double) -> String {
        if price >= 100_000 {
            // 393000 → "393 K" (compact)
            let thousands = price / 1000
            let str = compactFormatter.string(from: NSNumber(value: thousands)) ?? "\(Int(thousands))"
            return "\(str)K"
        }
        if price >= 1000 {
            // 5990 → "5.990,00"
            return decimalFormatter.string(from: NSNumber(value: price)) ?? "\(price)"
        }
        // 5.59 → "5,59"
        return decimalFormatter.string(from: NSNumber(value: price)) ?? "\(price)"
    }
}
