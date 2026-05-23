import EventKit
import SwiftUI

struct CalendarStripView: View {
    @Bindable var calendar: CalendarService

    @State private var isStripHovered = false

    private let cal: Calendar = .current
    private var now: Date { Date() }

    private var monthLabel: String {
        let raw = calendar.focusedDate.formatted(.dateTime.month(.abbreviated))
        let trimmed = raw.hasSuffix(".") ? String(raw.dropLast()) : raw
        return trimmed.prefix(1).uppercased() + trimmed.dropFirst()
    }

    private var days: [Date] {
        (-2...2).compactMap { offset in
            cal.date(byAdding: .day, value: offset, to: calendar.focusedDate)
        }
    }

    private var nextEvent: EKEvent? {
        calendar.events.first { event in
            calendar.isOnToday ? event.endDate >= now : true
        }
    }

    private var spring: Animation {
        .spring(response: 0.36, dampingFraction: 0.82, blendDuration: 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 6) {
                monthButton

                navStrip

                Spacer(minLength: 0)
            }
            .onHover { isStripHovered = $0 }

            EventRow(event: nextEvent, authorized: calendar.authorized)
        }
    }

    // MARK: - Month label (click resets to today)

    private var monthButton: some View {
        Button {
            calendar.resetToToday()
        } label: {
            Text(monthLabel)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(calendar.isOnToday ? .primary : Color(nsColor: .systemBlue))
                .fixedSize()
                .contentShape(Rectangle())
                .animation(spring, value: calendar.isOnToday)
        }
        .buttonStyle(.plain)
        .pointerCursor()
        .help(calendar.isOnToday ? "Today" : "Reset to today")
    }

    // MARK: - Day strip with hover-revealed chevrons

    private var navStrip: some View {
        HStack(spacing: 0) {
            NavChevron(direction: .left) { calendar.shift(days: -7) }
                .opacity(isStripHovered ? 1 : 0)
                .animation(.easeInOut(duration: 0.18), value: isStripHovered)

            HStack(spacing: 2) {
                ForEach(days, id: \.timeIntervalSince1970) { date in
                    DayCell(
                        date: date,
                        isToday: cal.isDateInToday(date),
                        isFocused: cal.isDate(date, inSameDayAs: calendar.focusedDate)
                    ) {
                        calendar.focus(on: date)
                    }
                    .id(date.timeIntervalSince1970)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            .animation(spring, value: calendar.focusedDate)

            NavChevron(direction: .right) { calendar.shift(days: 7) }
                .opacity(isStripHovered ? 1 : 0)
                .animation(.easeInOut(duration: 0.18), value: isStripHovered)
        }
    }
}

// MARK: - Day cell (clickable)

private struct DayCell: View {
    let date: Date
    let isToday: Bool
    let isFocused: Bool
    let onTap: () -> Void

    @State private var isHovered = false

    private let cal: Calendar = .current

    private var weekdaySymbol: String {
        date.formatted(.dateTime.weekday(.narrow))
    }

    private var dayNumber: String {
        date.formatted(.dateTime.day())
    }

    private var dayNumberColor: Color {
        if isToday { return Color(nsColor: .systemBlue) }
        if isFocused { return .primary }
        return .secondary
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text(weekdaySymbol)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .fixedSize()

                Text(dayNumber)
                    .font(.system(
                        size: isFocused ? 17 : 13,
                        weight: isFocused ? .semibold : .medium,
                        design: .rounded
                    ))
                    .monospacedDigit()
                    .foregroundStyle(dayNumberColor)
                    .lineLimit(1)
                    .fixedSize()
            }
            .frame(width: 24, height: 36)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.white.opacity(isFocused && !isToday ? 0.10 : (isHovered ? 0.06 : 0)))
            )
            .contentShape(Rectangle())
            .animation(.spring(response: 0.28, dampingFraction: 0.78), value: isHovered)
            .animation(.spring(response: 0.32, dampingFraction: 0.82), value: isFocused)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .pointerCursor()
    }
}

// MARK: - Chevron nav button

private struct NavChevron: View {
    enum Direction { case left, right }
    let direction: Direction
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: direction == .left ? "chevron.left" : "chevron.right")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(isHovered ? .primary : .tertiary)
                .frame(width: 14, height: 36)
                .contentShape(Rectangle())
                .animation(.easeInOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .pointerCursor()
    }
}

// MARK: - Event row

private struct EventRow: View {
    let event: EKEvent?
    let authorized: Bool

    var body: some View {
        HStack(spacing: 6) {
            if let event {
                Circle()
                    .fill(Color(cgColor: event.calendar.cgColor))
                    .frame(width: 6, height: 6)

                Text(event.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer(minLength: 4)

                Text(event.startDate.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            } else {
                Image(systemName: "calendar")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)

                if authorized {
                    Text("Nothing scheduled")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text("Allow Calendar access")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }
}
