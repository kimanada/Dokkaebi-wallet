import Foundation

/// 날짜·시간 표시 규칙 (DESIGN_SYSTEM.md §3). 모든 표시는 그룹 시간대(기본 Asia/Seoul) 기준이다.
public struct DateFormatting: Sendable {
    public let timeZone: TimeZone
    public let locale: Locale

    public init(timeZone: TimeZone = AppDefaults.timeZone, locale: Locale = AppDefaults.locale) {
        self.timeZone = timeZone
        self.locale = locale
    }

    public var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        calendar.locale = locale
        return calendar
    }

    private func formatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateFormat = format
        return formatter
    }

    /// 예: "11월 19일 (수)". 기준 날짜와 연도가 다르면 "2025년 11월 19일 (수)"
    public func dayLabel(_ date: Date, relativeTo now: Date = Date()) -> String {
        let sameYear = calendar.component(.year, from: date) == calendar.component(.year, from: now)
        return formatter(sameYear ? "M월 d일 (E)" : "yyyy년 M월 d일 (E)").string(from: date)
    }

    /// 예: "오후 3:20"
    public func time(_ date: Date) -> String {
        formatter("a h:mm").string(from: date)
    }

    /// 예: "2026년 11월"
    public func monthTitle(_ date: Date) -> String {
        formatter("yyyy년 M월").string(from: date)
    }

    /// 예: "11.19"
    public func shortDate(_ date: Date) -> String {
        formatter("M.d").string(from: date)
    }

    /// 마감일까지 남은 일수 표시. 예: "D-3", "D-Day", "D+2"
    public func dDay(_ date: Date, from now: Date = Date()) -> String {
        let start = calendar.startOfDay(for: now)
        let target = calendar.startOfDay(for: date)
        let days = calendar.dateComponents([.day], from: start, to: target).day ?? 0
        switch days {
        case 0: return "D-Day"
        case let d where d > 0: return "D-\(d)"
        default: return "D+\(-days)"
        }
    }
}
