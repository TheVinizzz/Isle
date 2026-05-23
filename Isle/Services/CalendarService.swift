import EventKit
import Foundation
import Observation

@MainActor
@Observable
final class CalendarService {
    private(set) var events: [EKEvent] = []
    private(set) var authorized: Bool = false
    /// The day the strip is centered on. Defaults to today; user can navigate.
    private(set) var focusedDate: Date = Calendar.current.startOfDay(for: Date())

    private let store = EKEventStore()
    private var refreshTask: Task<Void, Never>?
    private var observer: NSObjectProtocol?

    init() {
        observer = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: store,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.scheduleRefresh() }
        }
    }

    func bootstrap() async {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .notDetermined:
            do {
                let granted = try await store.requestFullAccessToEvents()
                authorized = granted
                if granted { await refresh() }
            } catch {
                authorized = false
            }
        case .fullAccess:
            authorized = true
            await refresh()
        default:
            authorized = false
            events = []
        }
    }

    // MARK: - Navigation

    func focus(on date: Date) {
        focusedDate = Calendar.current.startOfDay(for: date)
        Task { await refresh() }
    }

    func shift(days: Int) {
        guard let next = Calendar.current.date(byAdding: .day, value: days, to: focusedDate)
        else { return }
        focus(on: next)
    }

    func resetToToday() {
        focus(on: Date())
    }

    var isOnToday: Bool {
        Calendar.current.isDateInToday(focusedDate)
    }

    // MARK: - Refresh

    private func scheduleRefresh() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await self?.refresh()
        }
    }

    func refresh() async {
        guard authorized else { return }
        let cal = Calendar.current
        let start = cal.startOfDay(for: focusedDate)
        guard let end = cal.date(byAdding: .day, value: 1, to: start) else { return }
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        let results = store.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }
        events = results
    }
}
