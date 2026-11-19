import Foundation

/// 그룹의 월 시작일(1~28)을 반영한 가계부 기간 (PROJECT_PLAN.md D5).
/// 예: 월 시작일이 25일이면 11월 19일이 속한 기간은 10월 25일 ~ 11월 24일이다.
public struct BudgetPeriod: Equatable, Sendable {
    /// 기간 첫날 00:00 (그룹 시간대)
    public let start: Date
    /// 다음 기간 첫날 00:00 (이 시각은 포함하지 않음)
    public let endExclusive: Date

    public init(start: Date, endExclusive: Date) {
        self.start = start
        self.endExclusive = endExclusive
    }

    /// `date`가 속한 기간을 계산한다.
    public static func containing(
        _ date: Date,
        monthStartDay: Int,
        calendar: Calendar
    ) -> BudgetPeriod {
        let startDay = min(max(monthStartDay, 1), 28)
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let year = components.year, let month = components.month, let day = components.day else {
            preconditionFailure("날짜 구성 요소를 계산할 수 없습니다")
        }
        var startComponents = DateComponents(year: year, month: month, day: startDay)
        if day < startDay {
            // 시작일 이전이면 지난달 시작일부터
            startComponents.month = month - 1
        }
        let start = calendar.date(from: startComponents).map { calendar.startOfDay(for: $0) } ?? date
        let end = calendar.date(byAdding: .month, value: 1, to: start) ?? start
        return BudgetPeriod(start: start, endExclusive: end)
    }

    public func contains(_ date: Date) -> Bool {
        date >= start && date < endExclusive
    }

    /// 직전 기간 (전월 대비 계산용)
    public func previous(calendar: Calendar) -> BudgetPeriod {
        let previousStart = calendar.date(byAdding: .month, value: -1, to: start) ?? start
        return BudgetPeriod(start: previousStart, endExclusive: start)
    }

    /// 기간 마지막 날 (표시용)
    public func lastDay(calendar: Calendar) -> Date {
        calendar.date(byAdding: .day, value: -1, to: endExclusive) ?? endExclusive
    }
}
