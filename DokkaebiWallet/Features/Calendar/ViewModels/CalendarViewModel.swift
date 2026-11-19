import Foundation
import Observation

public enum CalendarDisplayMode: String, CaseIterable, Sendable {
    case month, week, day

    public var displayName: String {
        switch self {
        case .month: return "월"
        case .week: return "주"
        case .day: return "일"
        }
    }
}

public struct CalendarDay: Identifiable, Hashable, Sendable {
    public let date: Date
    public let dayNumber: Int
    public let isInDisplayedMonth: Bool
    public let isToday: Bool
    public let isSunday: Bool
    public let isSaturday: Bool
    /// 점으로 표시할 일정 색 (최대 3개)
    public let eventColors: [PaletteColor]
    public var id: Date { date }
}

@MainActor
@Observable
public final class CalendarViewModel {
    public var mode: CalendarDisplayMode = .month
    public private(set) var selectedDate: Date
    public private(set) var displayedMonth: Date
    public private(set) var events: [CalendarEvent] = []
    public private(set) var error: AppError?
    public private(set) var isLoading = false

    private let dependencies: AppDependencies
    private let now: @Sendable () -> Date

    public init(dependencies: AppDependencies, now: @escaping @Sendable () -> Date = { Date() }) {
        self.dependencies = dependencies
        self.now = now
        let calendar = dependencies.dateFormatting.calendar
        let today = calendar.startOfDay(for: now())
        self.selectedDate = today
        self.displayedMonth = calendar.dateInterval(of: .month, for: today)?.start ?? today
    }

    public var isUsingMockData: Bool { dependencies.isUsingMockData }
    private var calendar: Calendar { dependencies.dateFormatting.calendar }
    private var formatting: DateFormatting { dependencies.dateFormatting }

    public var title: String {
        switch mode {
        case .month, .week: return formatting.monthTitle(mode == .month ? displayedMonth : selectedDate)
        case .day: return formatting.dayLabel(selectedDate, relativeTo: now())
        }
    }

    public static let weekdaySymbols = ["일", "월", "화", "수", "목", "금", "토"]

    /// 월간 보기 6주(42칸) 격자. 주는 일요일부터 시작한다.
    public var monthGrid: [CalendarDay] {
        let firstWeekday = calendar.component(.weekday, from: displayedMonth) // 1 = 일요일
        guard let gridStart = calendar.date(byAdding: .day, value: -(firstWeekday - 1), to: displayedMonth) else { return [] }
        return (0..<42).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: gridStart).map(makeDay)
        }
    }

    /// 선택한 날짜가 속한 주 (일~토)
    public var weekDays: [CalendarDay] {
        let weekday = calendar.component(.weekday, from: selectedDate)
        guard let start = calendar.date(byAdding: .day, value: -(weekday - 1), to: selectedDate) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start).map(makeDay) }
    }

    public var eventsOnSelectedDate: [CalendarEvent] {
        events(on: selectedDate)
    }

    public func events(on date: Date) -> [CalendarEvent] {
        events.filter { $0.occurs(on: date, calendar: calendar) }
            .sorted { lhs, rhs in
                if lhs.isAllDay != rhs.isAllDay { return lhs.isAllDay }
                return lhs.startsAt < rhs.startsAt
            }
    }

    public func isSelected(_ day: CalendarDay) -> Bool {
        calendar.isDate(day.date, inSameDayAs: selectedDate)
    }

    public func load(groupID: UUID) async {
        guard let first = monthGrid.first?.date, let last = monthGrid.last?.date,
              let end = calendar.date(byAdding: .day, value: 1, to: last) else { return }
        // 주·일 보기가 다음 달로 넘어갈 수 있으므로 선택일 주변도 포함한다.
        let from = min(first, calendar.date(byAdding: .day, value: -7, to: selectedDate) ?? first)
        let to = max(end, calendar.date(byAdding: .day, value: 8, to: selectedDate) ?? end)
        isLoading = true
        defer { isLoading = false }
        do {
            events = try await dependencies.calendar.fetchEvents(groupID: groupID, from: from, to: to)
            error = nil
        } catch {
            self.error = .wrap(error)
        }
    }

    public func select(_ date: Date) {
        selectedDate = calendar.startOfDay(for: date)
        if let month = calendar.dateInterval(of: .month, for: selectedDate)?.start, month != displayedMonth {
            displayedMonth = month
        }
    }

    /// 보기 모드에 따라 한 달 / 한 주 / 하루씩 이동한다.
    public func move(by value: Int) {
        switch mode {
        case .month:
            guard let month = calendar.date(byAdding: .month, value: value, to: displayedMonth) else { return }
            displayedMonth = month
            selectedDate = calendar.isDate(month, equalTo: now(), toGranularity: .month)
                ? calendar.startOfDay(for: now()) : month
        case .week:
            if let date = calendar.date(byAdding: .day, value: 7 * value, to: selectedDate) { select(date) }
        case .day:
            if let date = calendar.date(byAdding: .day, value: value, to: selectedDate) { select(date) }
        }
    }

    public func goToToday() {
        select(now())
    }

    private func makeDay(_ date: Date) -> CalendarDay {
        let weekday = calendar.component(.weekday, from: date)
        return CalendarDay(
            date: date,
            dayNumber: calendar.component(.day, from: date),
            isInDisplayedMonth: calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month),
            isToday: calendar.isDate(date, inSameDayAs: now()),
            isSunday: weekday == 1,
            isSaturday: weekday == 7,
            eventColors: Array(events(on: date).map(\.color).prefix(3))
        )
    }
}
