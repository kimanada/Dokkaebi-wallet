import Foundation

public struct CalendarEvent: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public var title: String
    public var startsAt: Date
    public var endsAt: Date
    public var isAllDay: Bool
    public var location: String?
    public var visibility: Visibility
    public var participantIDs: [UUID]
    public var color: PaletteColor

    public init(id: UUID = UUID(), title: String, startsAt: Date, endsAt: Date, isAllDay: Bool = false,
                location: String? = nil, visibility: Visibility = .family,
                participantIDs: [UUID] = [], color: PaletteColor = .pine) {
        self.id = id
        self.title = title
        self.startsAt = startsAt
        self.endsAt = max(endsAt, startsAt)
        self.isAllDay = isAllDay
        self.location = location
        self.visibility = visibility
        self.participantIDs = participantIDs
        self.color = color
    }

    /// 일정이 특정 날짜(그 날 00:00 ~ 다음 날 00:00)와 겹치는지
    public func occurs(on day: Date, calendar: Calendar) -> Bool {
        let start = calendar.startOfDay(for: day)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return false }
        return startsAt < end && endsAt >= start
    }
}
